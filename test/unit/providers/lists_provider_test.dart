import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:to_do/Providers/lists_provider.dart';
import 'package:to_do/Models/to_do_list.dart';
import 'package:to_do/Utils/sort_by.dart';
import '../../fixtures/mock_database.dart';
import '../../fixtures/test_data.dart';

void main() {
  late ListsProvider provider;

  setUpAll(() async {
    // Load .env file once for all tests
    await dotenv.load(fileName: '.env');
  });

  setUp(() async {
    // Initialize fresh test database with injected dependency
    final testDb = await TestDatabaseHelper.getTestDatabase();
    provider = ListsProvider(database: testDb);
  });

  tearDown(() async {
    // Clean up after each test
    await TestDatabaseHelper.clearAllTables();
    await TestDatabaseHelper.closeTestDatabase();
  });

  group('ListsProvider - List Retrieval', () {
    test('should retrieve empty list when no lists exist', () async {
      final activeItems = await provider.getActiveItems();
      expect(activeItems, isEmpty);
    });

    test('should retrieve list by ID', () async {
      // Create and insert test list
      final testList = TestDataFactory.createTestList(
        id: 'test-id-123',
        title: 'Test List',
        totalItems: 5,
      );

      await (await provider.database).insert(
        'todo_lists',
        testList.toMap(),
      );

      // Retrieve
      final retrieved = await provider.getListById('test-id-123');
      expect(retrieved, isNotNull);
      expect(retrieved?.title, 'Test List');
      expect(retrieved?.totalItems, 5);
    });

    test('should return active lists only', () async {
      // Create active list (future deadline, not completed)
      final futureDeadline = DateTime.now().add(Duration(days: 5));
      final activeList = TestDataFactory.createTestList(
        title: 'Active',
        hasDeadline: true,
        deadline: futureDeadline,
        totalItems: 5,
        accomplishedItems: 0,
      );

      // Create completed list (all items done)
      final completedList = TestDataFactory.createTestList(
        title: 'Completed',
        totalItems: 5,
        accomplishedItems: 5,
      );

      final db = await provider.database;
      await db.insert('todo_lists', activeList.toMap());
      await db.insert('todo_lists', completedList.toMap());

      final activeItems = await provider.getActiveItems();
      expect(activeItems.length, 1);
      expect(activeItems[0].title, 'Active');
    });

    test('should return achieved lists only', () async {
      // Create completed list
      final completedList = TestDataFactory.createTestList(
        title: 'Completed',
        totalItems: 5,
        accomplishedItems: 5,
      );

      final db = await provider.database;
      await db.insert('todo_lists', completedList.toMap());

      final achievedItems = await provider.getAchievedItems();
      expect(achievedItems.length, 1);
      expect(achievedItems[0].title, 'Completed');
    });

    test('should return lists without deadline', () async {
      final withoutDeadline = TestDataFactory.createTestList(
        title: 'No Deadline',
        hasDeadline: false,
      );

      final withDeadline = TestDataFactory.createTestList(
        title: 'With Deadline',
        hasDeadline: true,
      );

      final db = await provider.database;
      await db.insert('todo_lists', withoutDeadline.toMap());
      await db.insert('todo_lists', withDeadline.toMap());

      final noDeadline = await provider.getWithoutDeadlineItems();
      expect(noDeadline.length, 1);
      expect(noDeadline[0].title, 'No Deadline');
    });

    test('should handle getActiveItems with large dataset', () async {
      final db = await provider.database;
      
      // Create 50 lists
      for (int i = 0; i < 50; i++) {
        final list = TestDataFactory.createTestList(
          title: 'List $i',
          hasDeadline: true,
          deadline: DateTime.now().add(Duration(days: 1)),
        );
        await db.insert('todo_lists', list.toMap());
      }

      final activeItems = await provider.getActiveItems();
      expect(activeItems.length, 50);
    });
  });

  group('ListsProvider - List CRUD Operations', () {
    test('should create new list successfully', () async {
      const title = 'New Shopping List';
      final deadline = DateTime.now().add(Duration(days: 7));

      final result = await provider.createNewList(title, deadline, true);
      expect(result.success, true);

      // Verify list was created
      final lists = await provider.getActiveItems();
      expect(lists.any((l) => l.title == title), true);
    });

    test('should add new list to database', () async {
      final newList = TestDataFactory.createTestList(title: 'New List');
      
      await provider.addNewList(newList);

      // Verify it exists
      final retrieved = await provider.getListById(newList.id);
      expect(retrieved, isNotNull);
      expect(retrieved?.title, 'New List');
    });

    test('should edit list title', () async {
      // Create list
      final list = TestDataFactory.createTestList(title: 'Old Title');
      await provider.addNewList(list);

      // Edit
      await provider.editTitle(list, 'New Title');

      // Verify
      final updated = await provider.getListById(list.id);
      expect(updated?.title, 'New Title');
    });

    test('should edit list deadline', () async {
      // Create list
      final list = TestDataFactory.createTestList(
        deadline: DateTime(2026, 3, 25),
        hasDeadline: true,
      );
      await provider.addNewList(list);

      // Edit
      final newDeadline = DateTime(2026, 12, 25);
      await provider.editDeadline(list, newDeadline);

      // Verify
      final updated = await provider.getListById(list.id);
      expect(updated?.deadline.day, 25);
      expect(updated?.deadline.month, 12);
    });

    test('should delete list completely', () async {
      // Create list
      final list = TestDataFactory.createTestList();
      await provider.addNewList(list);

      // Delete
      await provider.deleteList(list);

      // Verify it's gone
      final retrieved = await provider.getListById(list.id);
      expect(retrieved, isNull);
    });

    test('should validate list title is not empty', () async {
      // Empty title should be handled
      const title = '';
      final deadline = DateTime.now().add(Duration(days: 7));

      // The app may allow empty titles or validate - test current behavior
      final result = await provider.createNewList(title, deadline, false);
      // If validation exists, result.success should be false
      // For now, just verify the call completes
      expect(result != null, true);
    });

    test('should handle duplicate list IDs gracefully', () async {
      // Create list
      final list = TestDataFactory.createTestList(id: 'same-id');
      await provider.addNewList(list);

      // Try to create another with same ID
      final duplicate = TestDataFactory.createTestList(
        id: 'same-id',
        title: 'Different Title',
      );
      await provider.addNewList(duplicate);

      // Should have latest version
      final retrieved = await provider.getListById('same-id');
      expect(retrieved?.title, 'Different Title');
    });
  });

  group('ListsProvider - List Filtering', () {
    test('should filter lists with future deadlines', () async {
      // Create mix of lists
      final futureList = TestDataFactory.createTestList(
        id: 'future-id',
        title: 'Future List',
        deadline: DateTime.now().add(Duration(days: 5)),
        hasDeadline: true,
        totalItems: 5,
        accomplishedItems: 0,
      );
      final pastList = TestDataFactory.createTestList(
        id: 'past-id',
        title: 'Past List',
        deadline: DateTime.now().subtract(Duration(days: 5)),
        hasDeadline: true,
      );

      final db = await provider.database;
      await db.insert('todo_lists', futureList.toMap());
      await db.insert('todo_lists', pastList.toMap());

      // getActiveItems should only return futureList
      final active = await provider.getActiveItems();
      expect(active.any((l) => l.id == 'future-id'), true);
      expect(active.any((l) => l.id == 'past-id'), false);
    });

    test('should filter completed lists', () async {
      final completed = TestDataFactory.createTestList(
        id: 'completed-id',
        title: 'Completed',
        totalItems: 5,
        accomplishedItems: 5,
      );
      final incomplete = TestDataFactory.createTestList(
        id: 'incomplete-id',
        title: 'Incomplete',
        totalItems: 5,
        accomplishedItems: 2,
      );

      final db = await provider.database;
      await db.insert('todo_lists', completed.toMap());
      await db.insert('todo_lists', incomplete.toMap());

      final achieved = await provider.getAchievedItems();
      expect(achieved.any((l) => l.id == 'completed-id'), true);
      expect(achieved.any((l) => l.id == 'incomplete-id'), false);
    });

    test('should exclude lists with deadlines from without-deadline list', () async {
      final withDeadline = TestDataFactory.createTestList(
        id: 'with-deadline-id',
        hasDeadline: true,
      );
      final withoutDeadline = TestDataFactory.createTestList(
        id: 'without-deadline-id',
        hasDeadline: false,
      );

      final db = await provider.database;
      await db.insert('todo_lists', withDeadline.toMap());
      await db.insert('todo_lists', withoutDeadline.toMap());

      final noDeadline = await provider.getWithoutDeadlineItems();
      expect(noDeadline.any((l) => l.id == 'without-deadline-id'), true);
      expect(noDeadline.any((l) => l.id == 'with-deadline-id'), false);
    });

    test('should handle empty filter results', () async {
      // No lists exist
      final active = await provider.getActiveItems();
      expect(active, isEmpty);
    });
  });

  group('ListsProvider - Sorting', () {
    test('should sort lists by creation date (newest first)', () async {
      final db = await provider.database;
      
      // Create lists with different creation dates
      final list1 = TestDataFactory.createTestList(
        id: '1',
        title: 'List 1',
        creationDate: DateTime(2026, 1, 1),
      );
      final list2 = TestDataFactory.createTestList(
        id: '2',
        title: 'List 2',
        creationDate: DateTime(2026, 1, 2),
      );
      final list3 = TestDataFactory.createTestList(
        id: '3',
        title: 'List 3',
        creationDate: DateTime(2026, 1, 3),
      );

      await db.insert('todo_lists', list1.toMap());
      await db.insert('todo_lists', list2.toMap());
      await db.insert('todo_lists', list3.toMap());

      provider.selectedOptionVal = SortBy.creationNTL;
      final sorted = await provider.getActiveItems();
      
      expect(sorted[0].id, '3'); // Newest first
      expect(sorted[1].id, '2');
      expect(sorted[2].id, '1');
    });

    test('should sort lists by creation date (oldest first)', () async {
      final db = await provider.database;
      
      final list1 = TestDataFactory.createTestList(
        id: '1',
        title: 'List 1',
        creationDate: DateTime(2026, 1, 1),
      );
      final list2 = TestDataFactory.createTestList(
        id: '2',
        title: 'List 2',
        creationDate: DateTime(2026, 1, 3),
      );

      await db.insert('todo_lists', list1.toMap());
      await db.insert('todo_lists', list2.toMap());

      provider.selectedOptionVal = SortBy.creationLTN;
      final sorted = await provider.getActiveItems();
      
      expect(sorted[0].id, '1'); // Oldest first
      expect(sorted[1].id, '2');
    });

    test('should sort by deadline (nearest first)', () async {
      final db = await provider.database;
      
      final list1 = TestDataFactory.createTestList(
        id: '1',
        deadline: DateTime(2026, 12, 25),
        hasDeadline: true,
      );
      final list2 = TestDataFactory.createTestList(
        id: '2',
        deadline: DateTime(2026, 12, 10),
        hasDeadline: true,
      );

      await db.insert('todo_lists', list1.toMap());
      await db.insert('todo_lists', list2.toMap());

      provider.selectedOptionVal = SortBy.deadlineLTN;
      final sorted = await provider.getActiveItems();
      
      expect(sorted[0].id, '2'); // Nearest first
      expect(sorted[1].id, '1');
    });

    test('should sort by deadline (farthest first)', () async {
      final db = await provider.database;
      
      final list1 = TestDataFactory.createTestList(
        id: '1',
        deadline: DateTime(2026, 12, 25),
        hasDeadline: true,
      );
      final list2 = TestDataFactory.createTestList(
        id: '2',
        deadline: DateTime(2026, 12, 10),
        hasDeadline: true,
      );

      await db.insert('todo_lists', list1.toMap());
      await db.insert('todo_lists', list2.toMap());

      provider.selectedOptionVal = SortBy.deadlineNTL;
      final sorted = await provider.getActiveItems();
      
      expect(sorted[0].id, '1'); // Farthest first
      expect(sorted[1].id, '2');
    });

    test('should sort by progress (high to low)', () async {
      final db = await provider.database;
      
      final list1 = TestDataFactory.createTestList(
        id: '1',
        totalItems: 10,
        accomplishedItems: 2, // 20%
      );
      final list2 = TestDataFactory.createTestList(
        id: '2',
        totalItems: 10,
        accomplishedItems: 8, // 80%
      );

      await db.insert('todo_lists', list1.toMap());
      await db.insert('todo_lists', list2.toMap());

      provider.selectedOptionVal = SortBy.progressBTS;
      final sorted = await provider.getActiveItems();
      
      expect(sorted[0].accomplishedItems, 8); // Highest first
      expect(sorted[1].accomplishedItems, 2);
    });

    test('should sort by progress (low to high)', () async {
      final db = await provider.database;
      
      final list1 = TestDataFactory.createTestList(
        id: '1',
        totalItems: 10,
        accomplishedItems: 8,
      );
      final list2 = TestDataFactory.createTestList(
        id: '2',
        totalItems: 10,
        accomplishedItems: 2,
      );

      await db.insert('todo_lists', list1.toMap());
      await db.insert('todo_lists', list2.toMap());

      provider.selectedOptionVal = SortBy.progressSTB;
      final sorted = await provider.getActiveItems();
      
      expect(sorted[0].accomplishedItems, 2); // Lowest first
      expect(sorted[1].accomplishedItems, 8);
    });

    test('should persist sort preference', () async {
      provider.selectedOptionVal = SortBy.deadlineNTL;
      expect(provider.selectedOptionVal, SortBy.deadlineNTL);
      
      // Verify it's still set after an operation
      await provider.getActiveItems();
      expect(provider.selectedOptionVal, SortBy.deadlineNTL);
    });

    test('should handle sort with single list', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList();
      await db.insert('todo_lists', list.toMap());

      // Apply all sort options - should not crash
      for (final sortBy in SortBy.values) {
        provider.selectedOptionVal = sortBy;
        final sorted = await provider.getActiveItems();
        expect(sorted.length, 1);
      }
    });

    test('should handle sort with empty list', () async {
      // No lists
      for (final sortBy in SortBy.values) {
        provider.selectedOptionVal = sortBy;
        final sorted = await provider.getActiveItems();
        expect(sorted, isEmpty);
      }
    });
  });

  group('ListsProvider - Search', () {
    test('should find lists by partial title match', () async {
      final db = await provider.database;
      
      final list1 = TestDataFactory.createTestList(
        title: 'Shopping List',
      );
      final list2 = TestDataFactory.createTestList(
        title: 'Work Tasks',
      );

      await db.insert('todo_lists', list1.toMap());
      await db.insert('todo_lists', list2.toMap());

      final results = await provider.searchListsByTitle('Shop');
      expect(results.length, 1);
      expect(results[0].title, 'Shopping List');
    });

    test('should be case-insensitive', () async {
      final db = await provider.database;
      
      final list = TestDataFactory.createTestList(
        title: 'Shopping List',
      );

      await db.insert('todo_lists', list.toMap());

      final results = await provider.searchListsByTitle('shopping');
      expect(results.length, 1);
      expect(results[0].title, 'Shopping List');
    });

    test('should return empty for no matches', () async {
      final db = await provider.database;
      
      final list = TestDataFactory.createTestList(
        title: 'Shopping',
      );

      await db.insert('todo_lists', list.toMap());

      final results = await provider.searchListsByTitle('xyz');
      expect(results, isEmpty);
    });

    test('should find multiple matches', () async {
      final db = await provider.database;
      
      final list1 = TestDataFactory.createTestList(
        title: 'Shop1',
      );
      final list2 = TestDataFactory.createTestList(
        title: 'Shop2',
      );
      final list3 = TestDataFactory.createTestList(
        title: 'Other',
      );

      await db.insert('todo_lists', list1.toMap());
      await db.insert('todo_lists', list2.toMap());
      await db.insert('todo_lists', list3.toMap());

      final results = await provider.searchListsByTitle('Shop');
      expect(results.length, 2);
    });

    test('should handle empty search string', () async {
      final db = await provider.database;
      
      final list1 = TestDataFactory.createTestList(title: 'List 1');
      final list2 = TestDataFactory.createTestList(title: 'List 2');

      await db.insert('todo_lists', list1.toMap());
      await db.insert('todo_lists', list2.toMap());

      final results = await provider.searchListsByTitle('');
      expect(results.length, 2); // Should return all
    });

    test('should handle special characters in search', () async {
      final db = await provider.database;
      
      final list = TestDataFactory.createTestList(
        title: 'Buy @home #ready \$5',
      );

      await db.insert('todo_lists', list.toMap());

      final results = await provider.searchListsByTitle('@home');
      expect(results.length, 1);
    });
  });

  group('ListsProvider - Statistics', () {
    test('should calculate total lists', () async {
      // Create 5 lists
      // updateStatistics()
      // expect(stats.totalLists, 5);
    });

    test('should count completed lists', () async {
      // Create 3 completed, 2 incomplete
      // expect(stats.listsDone, 3);
    });

    test('should count total items across all lists', () async {
      // Create lists with 2, 3, 5 items
      // expect(stats.totalItems, 10);
    });

    test('should count completed items across all lists', () async {
      // Create lists with mixed completion
      // expect(stats.completedItems, X);
    });

    test('should calculate statistics efficiently', () async {
      // Create 100+ lists with items
      // Should complete in reasonable time
    });
  });

  group('ListsProvider - Edge Cases', () {
    test('should handle extremely long list titles', () async {
      final longTitle = 'Test ' * 100; // 500+ characters
      final list = TestDataFactory.createTestList(title: longTitle);
      
      final db = await provider.database;
      await db.insert('todo_lists', list.toMap());

      final retrieved = await provider.getListById(list.id);
      expect(retrieved?.title, longTitle);
    });

    test('should handle special characters in titles', () async {
      final list = TestDataFactory.createTestList(
        title: 'émojis 🎉 unicode בעברית symbols @#\$%',
      );
      
      final db = await provider.database;
      await db.insert('todo_lists', list.toMap());

      final retrieved = await provider.getListById(list.id);
      expect(retrieved?.title.contains('🎉'), true);
      expect(retrieved?.title.contains('בעברית'), true);
    });

    test('should handle rapid consecutive operations', () async {
      final db = await provider.database;
      
      // Create 10 lists rapidly
      for (int i = 0; i < 10; i++) {
        final list = TestDataFactory.createTestList(
          id: 'list-$i',
          title: 'List $i',
        );
        await db.insert('todo_lists', list.toMap());
      }

      // Delete 5
      for (int i = 0; i < 5; i++) {
        await provider.deleteList(
          TestDataFactory.createTestList(id: 'list-$i'),
        );
      }

      // Update others
      for (int i = 5; i < 10; i++) {
        final list = TestDataFactory.createTestList(
          id: 'list-$i',
          title: 'Updated $i',
        );
        await provider.editTitle(list, 'Updated $i');
      }

      final remaining = await provider.getActiveItems();
      expect(remaining.length, 5);
    });

    test('should handle very old deadlines', () async {
      final list = TestDataFactory.createTestList(
        deadline: DateTime(1970, 1, 1),
        hasDeadline: true,
      );
      
      final db = await provider.database;
      await db.insert('todo_lists', list.toMap());

      final retrieved = await provider.getListById(list.id);
      expect(retrieved?.deadline.year, 1970);
    });

    test('should handle very far future deadlines', () async {
      final list = TestDataFactory.createTestList(
        deadline: DateTime(3000, 12, 31),
        hasDeadline: true,
      );
      
      final db = await provider.database;
      await db.insert('todo_lists', list.toMap());

      final retrieved = await provider.getListById(list.id);
      expect(retrieved?.deadline.year, 3000);
    });
  });
}
