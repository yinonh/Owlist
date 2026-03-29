import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do/Providers/lists_provider.dart';
import 'package:to_do/Utils/keys.dart';
import 'package:to_do/Utils/sort_by.dart';
import 'package:to_do/Utils/shared_preferences_helper.dart';
import '../../fixtures/mock_database.dart';
import '../../fixtures/mock_providers.dart';
import '../../fixtures/test_data.dart';

void main() {
  late ListsProvider provider;
  late MockNotificationProvider mockNotificationProvider;

  final futureDate = DateTime(2026, 12, 25);
  final pastDate = DateTime(2025, 12, 25);

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesHelper.instance.initialise();
  });

  setUp(() async {
    final testDb = await TestDatabaseHelper.getTestDatabase();
    provider = ListsProvider(database: testDb);
    mockNotificationProvider = MockNotificationProvider();
    provider.notificationProvider = mockNotificationProvider;
    provider.selectedOption = SortBy.creationNTL;
  });

  tearDown(() async {
    await TestDatabaseHelper.clearAllTables();
    await TestDatabaseHelper.closeTestDatabase();
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('ListsProvider - searchListsByTitle', () {
    test('empty string returns all lists sorted newest first', () async {
      final db = await provider.database;
      final list1 = TestDataFactory.createTestList(
        id: 'list-1', title: 'Alpha',
        creationDate: DateTime(2026, 1, 1), hasDeadline: false,
      );
      final list2 = TestDataFactory.createTestList(
        id: 'list-2', title: 'Beta',
        creationDate: DateTime(2026, 1, 2), hasDeadline: false,
      );
      final list3 = TestDataFactory.createTestList(
        id: 'list-3', title: 'Gamma',
        creationDate: DateTime(2026, 1, 3), hasDeadline: false,
      );
      await db.insert('todo_lists', list1.toMap());
      await db.insert('todo_lists', list2.toMap());
      await db.insert('todo_lists', list3.toMap());

      final results = await provider.searchListsByTitle('');

      expect(results.length, 3);
      expect(results[0].title, 'Gamma'); // newest first (creationNTL)
      expect(results[1].title, 'Beta');
      expect(results[2].title, 'Alpha');
    });

    test('partial query matches substring of title', () async {
      final db = await provider.database;
      final buy = TestDataFactory.createTestList(
        id: 'list-buy', title: 'Buy groceries', hasDeadline: false,
      );
      final call = TestDataFactory.createTestList(
        id: 'list-call', title: 'Call dentist', hasDeadline: false,
      );
      await db.insert('todo_lists', buy.toMap());
      await db.insert('todo_lists', call.toMap());

      final results = await provider.searchListsByTitle('grocer');

      expect(results.length, 1);
      expect(results[0].id, 'list-buy');
    });

    test('query matches multiple titles', () async {
      final db = await provider.database;
      await db.insert('todo_lists', TestDataFactory.createTestList(
        id: 'list-1', title: 'groceries list', hasDeadline: false,
      ).toMap());
      await db.insert('todo_lists', TestDataFactory.createTestList(
        id: 'list-2', title: 'groceries backup', hasDeadline: false,
      ).toMap());
      await db.insert('todo_lists', TestDataFactory.createTestList(
        id: 'list-3', title: 'dentist', hasDeadline: false,
      ).toMap());

      final results = await provider.searchListsByTitle('groceries');

      expect(results.length, 2);
      expect(results.every((l) => l.title.contains('groceries')), true);
    });

    test('query with no match returns empty list', () async {
      final db = await provider.database;
      await db.insert('todo_lists', TestDataFactory.createTestList(
        id: 'list-1', title: 'dentist', hasDeadline: false,
      ).toMap());

      final results = await provider.searchListsByTitle('xyz');

      expect(results, isEmpty);
    });

    test('result is sorted by current selectedOption', () async {
      final db = await provider.database;
      await db.insert('todo_lists', TestDataFactory.createTestList(
        id: 'list-1', title: 'work',
        creationDate: DateTime(2026, 1, 3), hasDeadline: false,
      ).toMap());
      await db.insert('todo_lists', TestDataFactory.createTestList(
        id: 'list-2', title: 'workout',
        creationDate: DateTime(2026, 1, 1), hasDeadline: false,
      ).toMap());

      final results = await provider.searchListsByTitle('work');

      expect(results.length, 2);
      expect(results[0].title, 'work');    // 2026-01-03 is newer
      expect(results[1].title, 'workout');
    });

    test('empty database with empty query returns empty', () async {
      final results = await provider.searchListsByTitle('');
      expect(results, isEmpty);
    });

    test('empty database with non-empty query returns empty', () async {
      final results = await provider.searchListsByTitle('anything');
      expect(results, isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('ListsProvider - updateStatistics', () {
    test('empty database returns all zeros', () async {
      final stats = await provider.updateStatistics();

      expect(stats[Keys.totalLists], 0);
      expect(stats[Keys.listsDone], 0);
      expect(stats[Keys.activeLists], 0);
      expect(stats[Keys.withoutDeadline], 0);
      expect(stats[Keys.totalItems], 0);
      expect(stats[Keys.itemsDone], 0);
      expect(stats[Keys.itemsDelayed], 0);
      expect(stats[Keys.itemsNotDone], 0);
    });

    test('counts lists and items correctly across all buckets', () async {
      final db = await provider.database;

      // Active list: has deadline in future, not complete
      await db.insert('todo_lists', TestDataFactory.createTestList(
        id: 'active-1',
        hasDeadline: true,
        deadline: futureDate,
        totalItems: 3,
        accomplishedItems: 1,
      ).toMap());

      // Achieved list: all items done (isAchieved = true via toMap logic)
      await db.insert('todo_lists', TestDataFactory.createTestList(
        id: 'achieved-1',
        hasDeadline: true,
        deadline: futureDate,
        totalItems: 4,
        accomplishedItems: 4,
      ).toMap());

      // Without-deadline list
      await db.insert('todo_lists', TestDataFactory.createTestList(
        id: 'nodt-1',
        hasDeadline: false,
        totalItems: 2,
        accomplishedItems: 0,
      ).toMap());

      final stats = await provider.updateStatistics();

      expect(stats[Keys.totalLists], 3);
      expect(stats[Keys.activeLists], 1);
      expect(stats[Keys.listsDone], 1);
      expect(stats[Keys.withoutDeadline], 1);
      expect(stats[Keys.totalItems], 9);    // 3 + 4 + 2
      expect(stats[Keys.itemsDone], 5);     // 1 + 4 + 0
      expect(stats[Keys.itemsDelayed], 0);  // achieved list has 0 undone items
      expect(stats[Keys.itemsNotDone], 4);  // 9 - 5 - 0
    });

    test('itemsDelayed counts only undone items in achieved (expired/completed) lists', () async {
      final db = await provider.database;

      // Active list: 5 total, 2 done — its undone items are NOT delayed
      await db.insert('todo_lists', TestDataFactory.createTestList(
        id: 'active-1',
        hasDeadline: true,
        deadline: futureDate,
        totalItems: 5,
        accomplishedItems: 2,
      ).toMap());

      // Achieved list (past deadline): 5 total, 3 done — 2 undone = 2 delayed
      await db.insert('todo_lists', TestDataFactory.createTestList(
        id: 'achieved-1',
        hasDeadline: true,
        deadline: pastDate,
        totalItems: 5,
        accomplishedItems: 3,
      ).toMap());

      final stats = await provider.updateStatistics();

      expect(stats[Keys.itemsDelayed], 2);  // 5 - 3 from achieved list only
      // itemsNotDone = (5+5) - (2+3) - 2 = 10 - 5 - 2 = 3
      expect(stats[Keys.itemsNotDone], 3);
    });

    test('reflects newly added list after cache invalidation', () async {
      final db = await provider.database;

      // First call on empty DB
      final first = await provider.updateStatistics();
      expect(first[Keys.totalLists], 0);

      // Add a list and invalidate cache
      await db.insert('todo_lists', TestDataFactory.createTestList(
        id: 'list-1',
        hasDeadline: true,
        deadline: futureDate,
        totalItems: 0,
      ).toMap());
      provider.invalidateCache();

      final second = await provider.updateStatistics();
      expect(second[Keys.totalLists], 1);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('ListsProvider - isListDone', () {
    test('returns true when all items accomplished and totalItems > 0', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(
        id: 'list-1',
        totalItems: 3,
        accomplishedItems: 3,
        hasDeadline: true,
        deadline: futureDate,
      );
      await db.insert('todo_lists', list.toMap());

      expect(await provider.isListDone('list-1'), true);
    });

    test('returns false when not all items accomplished', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(
        id: 'list-1',
        totalItems: 3,
        accomplishedItems: 2,
        hasDeadline: true,
        deadline: futureDate,
      );
      await db.insert('todo_lists', list.toMap());

      expect(await provider.isListDone('list-1'), false);
    });

    test('returns false when totalItems is 0 even if accomplishedItems is 0', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(
        id: 'list-1',
        totalItems: 0,
        accomplishedItems: 0,
        hasDeadline: true,
        deadline: futureDate,
      );
      await db.insert('todo_lists', list.toMap());

      // Guard: totalItems > 0 && accomplished == total — 0/0 returns false
      expect(await provider.isListDone('list-1'), false);
    });

    test('returns true when deadline has passed regardless of item count', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(
        id: 'list-1',
        totalItems: 5,
        accomplishedItems: 0,
        hasDeadline: true,
        deadline: pastDate,
      );
      await db.insert('todo_lists', list.toMap());

      expect(await provider.isListDone('list-1'), true);
    });

    test('returns false for non-existent listId', () async {
      expect(await provider.isListDone('nonexistent'), false);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('ListsProvider - editItemTitle', () {
    Future<void> insertListAndItem(dynamic db) async {
      await db.insert('todo_lists', TestDataFactory.createTestList(
        id: 'list-1',
      ).toMap());
      await db.insert('todo_items', {
        'id': 'item-1', 'listId': 'list-1',
        'title': 'Original Title', 'content': '', 'done': 0, 'itemIndex': 0,
      });
    }

    test('updates item title in the database', () async {
      final db = await provider.database;
      await insertListAndItem(db);

      await provider.editItemTitle('item-1', 'New Title');

      final rows = await db.query('todo_items', where: 'id = ?', whereArgs: ['item-1']);
      expect(rows.first['title'], 'New Title');
    });

    test('null newTitle is a no-op — original title preserved', () async {
      final db = await provider.database;
      await insertListAndItem(db);

      await provider.editItemTitle('item-1', null);

      final rows = await db.query('todo_items', where: 'id = ?', whereArgs: ['item-1']);
      expect(rows.first['title'], 'Original Title');
    });

    test('does not affect sibling items in the same list', () async {
      final db = await provider.database;
      await insertListAndItem(db);
      await db.insert('todo_items', {
        'id': 'item-2', 'listId': 'list-1',
        'title': 'Sibling Item', 'content': '', 'done': 0, 'itemIndex': 1,
      });

      await provider.editItemTitle('item-1', 'Changed');

      final sibling = await db.query('todo_items', where: 'id = ?', whereArgs: ['item-2']);
      expect(sibling.first['title'], 'Sibling Item');
    });

    test('empty string is persisted as the new title', () async {
      final db = await provider.database;
      await insertListAndItem(db);

      await provider.editItemTitle('item-1', '');

      final rows = await db.query('todo_items', where: 'id = ?', whereArgs: ['item-1']);
      expect(rows.first['title'], '');
    });

    test('non-existent itemId completes without throwing', () async {
      // Should not throw — provider catches the error internally
      await provider.editItemTitle('ghost-id', 'New Title');
    });
  });
}
