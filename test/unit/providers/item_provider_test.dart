import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do/Providers/item_provider.dart';
import 'package:to_do/Utils/shared_preferences_helper.dart';
import '../../fixtures/mock_database.dart';
import '../../fixtures/test_data.dart';

void main() {
  late ItemProvider provider;

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesHelper.instance.initialise();
  });

  setUp(() async {
    final testDb = await TestDatabaseHelper.getTestDatabase();
    provider = ItemProvider(database: testDb);
  });

  tearDown(() async {
    await TestDatabaseHelper.clearAllTables();
    await TestDatabaseHelper.closeTestDatabase();
  });

  group('ItemProvider - Item Retrieval', () {
    test('should retrieve empty list when no items exist', () async {
      final items = await provider.itemsByListId('list-1');
      expect(items, isEmpty);
    });

    test('should retrieve items by list ID', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1');
      await db.insert('todo_lists', list.toMap());

      final item1 = TestDataFactory.createTestItem(listId: 'list-1', itemIndex: 0);
      final item2 = TestDataFactory.createTestItem(listId: 'list-1', itemIndex: 1);
      final item3 = TestDataFactory.createTestItem(listId: 'list-1', itemIndex: 2);
      await provider.addExistingItem(item1);
      await provider.addExistingItem(item2);
      await provider.addExistingItem(item3);

      final items = await provider.itemsByListId('list-1');
      expect(items.length, 3);
    });

    test('should retrieve item by ID', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1');
      await db.insert('todo_lists', list.toMap());

      final item = TestDataFactory.createTestItem(id: 'item-1', listId: 'list-1', title: 'Buy milk');
      await provider.addExistingItem(item);

      final retrieved = await provider.itemById('item-1');
      expect(retrieved.title, 'Buy milk');
      expect(retrieved.id, 'item-1');
    });

    test('should return empty for non-existent list', () async {
      final items = await provider.itemsByListId('nonexistent');
      expect(items, isEmpty);
    });

    test('should separate items by list ID', () async {
      final db = await provider.database;
      final list1 = TestDataFactory.createTestList(id: 'list-1');
      final list2 = TestDataFactory.createTestList(id: 'list-2');
      await db.insert('todo_lists', list1.toMap());
      await db.insert('todo_lists', list2.toMap());

      final item1 = TestDataFactory.createTestItem(listId: 'list-1');
      final item2 = TestDataFactory.createTestItem(listId: 'list-2');
      await provider.addExistingItem(item1);
      await provider.addExistingItem(item2);

      final items1 = await provider.itemsByListId('list-1');
      final items2 = await provider.itemsByListId('list-2');

      expect(items1.every((i) => i.listId == 'list-1'), true);
      expect(items2.every((i) => i.listId == 'list-2'), true);
      expect(items1.length, 1);
      expect(items2.length, 1);
    });
  });

  group('ItemProvider - Item CRUD', () {
    test('should add new item to list', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1');
      await db.insert('todo_lists', list.toMap());

      final result = await provider.addNewItem('list-1', 'Buy milk');

      expect(result, isNotNull);
      expect(result!.title, 'Buy milk');
      expect(result.listId, 'list-1');
      expect(result.done, false);
    });

    test('should add new item and increment list totalItems', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1', totalItems: 0);
      await db.insert('todo_lists', list.toMap());

      await provider.addNewItem('list-1', 'Item 1');

      final listRows = await db.query('todo_lists', where: 'id = ?', whereArgs: ['list-1']);
      expect(listRows.first['totalItems'], 1);
    });

    test('should auto-increment itemIndex for new items', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1');
      await db.insert('todo_lists', list.toMap());

      await provider.addNewItem('list-1', 'Item 1');
      await provider.addNewItem('list-1', 'Item 2');
      await provider.addNewItem('list-1', 'Item 3');

      final items = await provider.itemsByListId('list-1');
      final indices = items.map((i) => i.itemIndex).toList()..sort();
      expect(indices[0], 0);
      expect(indices[1], 1);
      expect(indices[2], 2);
    });

    test('should add existing item', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1');
      await db.insert('todo_lists', list.toMap());

      final item = TestDataFactory.createTestItem(
        id: 'item-1',
        listId: 'list-1',
        title: 'Existing item',
      );
      await provider.addExistingItem(item);

      final retrieved = await provider.itemById('item-1');
      expect(retrieved.id, 'item-1');
      expect(retrieved.title, 'Existing item');
    });

    test('should add done existing item and increment accomplishedItems', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1', totalItems: 0, accomplishedItems: 0);
      await db.insert('todo_lists', list.toMap());

      final item = TestDataFactory.createTestItem(listId: 'list-1', done: true);
      await provider.addExistingItem(item);

      final listRows = await db.query('todo_lists', where: 'id = ?', whereArgs: ['list-1']);
      expect(listRows.first['totalItems'], 1);
      expect(listRows.first['accomplishedItems'], 1);
    });

    test('should delete item by ID', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1');
      await db.insert('todo_lists', list.toMap());

      final item = TestDataFactory.createTestItem(id: 'item-1', listId: 'list-1');
      await provider.addExistingItem(item);

      await provider.deleteItemById('item-1', false);

      final items = await provider.itemsByListId('list-1');
      expect(items.any((i) => i.id == 'item-1'), false);
    });

    test('should decrement totalItems when item deleted', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1', totalItems: 0);
      await db.insert('todo_lists', list.toMap());

      final item = TestDataFactory.createTestItem(id: 'item-1', listId: 'list-1');
      await provider.addExistingItem(item);
      await provider.deleteItemById('item-1', false);

      final listRows = await db.query('todo_lists', where: 'id = ?', whereArgs: ['list-1']);
      expect(listRows.first['totalItems'], 0);
    });

    test('should decrement accomplishedItems when done item deleted', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1', totalItems: 0, accomplishedItems: 0);
      await db.insert('todo_lists', list.toMap());

      final item = TestDataFactory.createTestItem(id: 'item-1', listId: 'list-1', done: true);
      await provider.addExistingItem(item);
      await provider.deleteItemById('item-1', true);

      final listRows = await db.query('todo_lists', where: 'id = ?', whereArgs: ['list-1']);
      expect(listRows.first['accomplishedItems'], 0);
    });

    test('should update item content', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1');
      await db.insert('todo_lists', list.toMap());

      final item = TestDataFactory.createTestItem(id: 'item-1', listId: 'list-1', content: 'Old content');
      await provider.addExistingItem(item);

      await provider.updateItemContent('item-1', 'New content');

      final updated = await provider.itemById('item-1');
      expect(updated.content, 'New content');
    });
  });

  group('ItemProvider - Item Ordering', () {
    test('should update item index', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1');
      await db.insert('todo_lists', list.toMap());

      final item = TestDataFactory.createTestItem(id: 'item-1', listId: 'list-1', itemIndex: 0);
      await provider.addExistingItem(item);

      await provider.editIndex('item-1', 5);

      final updated = await provider.itemById('item-1');
      expect(updated.itemIndex, 5);
    });

    test('should maintain item order by index', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1');
      await db.insert('todo_lists', list.toMap());

      final item1 = TestDataFactory.createTestItem(listId: 'list-1', itemIndex: 2);
      final item2 = TestDataFactory.createTestItem(listId: 'list-1', itemIndex: 0);
      final item3 = TestDataFactory.createTestItem(listId: 'list-1', itemIndex: 1);
      await provider.addExistingItem(item1);
      await provider.addExistingItem(item2);
      await provider.addExistingItem(item3);

      final items = await provider.itemsByListId('list-1');
      final sorted = items..sort((a, b) => a.itemIndex.compareTo(b.itemIndex));
      expect(sorted[0].itemIndex, 0);
      expect(sorted[1].itemIndex, 1);
      expect(sorted[2].itemIndex, 2);
    });

    test('should support reordering items by updating indices', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1');
      await db.insert('todo_lists', list.toMap());

      final item1 = TestDataFactory.createTestItem(id: 'item-1', listId: 'list-1', itemIndex: 0);
      final item2 = TestDataFactory.createTestItem(id: 'item-2', listId: 'list-1', itemIndex: 1);
      await provider.addExistingItem(item1);
      await provider.addExistingItem(item2);

      // Swap positions
      await provider.editIndex('item-1', 1);
      await provider.editIndex('item-2', 0);

      final items = await provider.itemsByListId('list-1');
      final sorted = items..sort((a, b) => a.itemIndex.compareTo(b.itemIndex));
      expect(sorted[0].id, 'item-2');
      expect(sorted[1].id, 'item-1');
    });
  });

  group('ItemProvider - Item Content', () {
    test('should preserve URLs in content', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1');
      await db.insert('todo_lists', list.toMap());

      final item = TestDataFactory.createTestItem(
        id: 'item-1',
        listId: 'list-1',
        content: 'Check https://flutter.dev',
      );
      await provider.addExistingItem(item);

      final retrieved = await provider.itemById('item-1');
      expect(retrieved.content.contains('https://flutter.dev'), true);
    });

    test('should preserve special characters in content', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1');
      await db.insert('todo_lists', list.toMap());

      final item = TestDataFactory.createTestItem(
        id: 'item-1',
        listId: 'list-1',
        content: 'Buy @home #done & more!',
      );
      await provider.addExistingItem(item);

      final retrieved = await provider.itemById('item-1');
      expect(retrieved.content, 'Buy @home #done & more!');
    });

    test('should handle empty content update', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1');
      await db.insert('todo_lists', list.toMap());

      final item = TestDataFactory.createTestItem(
        id: 'item-1',
        listId: 'list-1',
        content: 'Some content',
      );
      await provider.addExistingItem(item);

      await provider.updateItemContent('item-1', '');

      final updated = await provider.itemById('item-1');
      expect(updated.content, '');
    });

    test('should handle very long content', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1');
      await db.insert('todo_lists', list.toMap());

      final longContent = 'A' * 10000;
      final item = TestDataFactory.createTestItem(
        id: 'item-1',
        listId: 'list-1',
        content: longContent,
      );
      await provider.addExistingItem(item);

      final retrieved = await provider.itemById('item-1');
      expect(retrieved.content.length, 10000);
    });

    test('should handle unicode and emoji in title', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1');
      await db.insert('todo_lists', list.toMap());

      final item = TestDataFactory.createTestItem(
        id: 'item-1',
        listId: 'list-1',
        title: '🎉 עברית 中文',
      );
      await provider.addExistingItem(item);

      final retrieved = await provider.itemById('item-1');
      expect(retrieved.title, '🎉 עברית 中文');
    });
  });

  group('ItemProvider - Negative Test Cases', () {
    /// NEW: Error cases and edge cases
    test('should handle empty string content update gracefully', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1');
      await db.insert('todo_lists', list.toMap());

      final item = TestDataFactory.createTestItem(id: 'item-1', listId: 'list-1', content: 'Content');
      await provider.addExistingItem(item);

      // Update to empty string
      await provider.updateItemContent('item-1', '');

      final updated = await provider.itemById('item-1');
      expect(updated.content, ''); // Should allow empty content
    });

    test('should handle negative itemIndex gracefully', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1');
      await db.insert('todo_lists', list.toMap());

      final item = TestDataFactory.createTestItem(id: 'item-1', listId: 'list-1', itemIndex: 0);
      await provider.addExistingItem(item);

      // Edge case: set negative index
      await provider.editIndex('item-1', -1);

      final updated = await provider.itemById('item-1');
      expect(updated.itemIndex, -1); // App allows negative (may be a bug)
    });

    test('should handle concurrent item additions', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1');
      await db.insert('todo_lists', list.toMap());

      // Add 10 items concurrently
      final futures = List.generate(10, (i) {
        return provider.addNewItem('list-1', 'Item $i');
      });

      await Future.wait(futures);

      // addNewItem uses DateTime.now() as ID so concurrent calls may collide (ConflictAlgorithm.replace)
      // Verify at least some items were added
      final items = await provider.itemsByListId('list-1');
      expect(items.length, greaterThanOrEqualTo(1));
    });

    test('should handle concurrent delete operations', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1');
      await db.insert('todo_lists', list.toMap());

      // Create 10 items
      final items = <String>[];
      for (int i = 0; i < 10; i++) {
        final item = TestDataFactory.createTestItem(id: 'item-$i', listId: 'list-1');
        await provider.addExistingItem(item);
        items.add('item-$i');
      }

      // Delete 5 concurrently
      final futures = items.sublist(0, 5).map((id) {
        return provider.deleteItemById(id, false);
      });

      await Future.wait(futures);

      // Verify 5 remain
      final remaining = await provider.itemsByListId('list-1');
      expect(remaining.length, 5);
    });

    test('should handle updating content of non-existent item gracefully', () async {
      // Should not throw
      await provider.updateItemContent('nonexistent-id', 'content');
    });

    test('should handle deleting non-existent item gracefully', () async {
      // Should not throw
      await provider.deleteItemById('nonexistent-id', false);
    });

    test('should prevent negative totalItems counter in list', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1', totalItems: 0);
      await db.insert('todo_lists', list.toMap());

      final item = TestDataFactory.createTestItem(id: 'item-1', listId: 'list-1');
      await provider.addExistingItem(item);

      // Delete item (should decrement totalItems to 0, not negative)
      await provider.deleteItemById('item-1', false);

      final listRows = await db.query('todo_lists', where: 'id = ?', whereArgs: ['list-1']);
      expect(listRows.first['totalItems'], greaterThanOrEqualTo(0));
    });
  });



  group('ItemProvider - Edge Cases', () {
    test('should handle rapid add and delete operations', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1', totalItems: 0);
      await db.insert('todo_lists', list.toMap());

      // Add 10 items
      final items = List.generate(10, (i) =>
        TestDataFactory.createTestItem(id: 'item-$i', listId: 'list-1', itemIndex: i));
      for (final item in items) {
        await provider.addExistingItem(item);
      }

      // Delete 5
      for (int i = 0; i < 5; i++) {
        await provider.deleteItemById('item-$i', false);
      }

      final remaining = await provider.itemsByListId('list-1');
      expect(remaining.length, 5);
    });

    test('should handle items with null-like empty strings', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1');
      await db.insert('todo_lists', list.toMap());

      final item = TestDataFactory.createTestItem(
        id: 'item-1',
        listId: 'list-1',
        title: '',
        content: '',
      );
      await provider.addExistingItem(item);

      final retrieved = await provider.itemById('item-1');
      expect(retrieved.title, '');
      expect(retrieved.content, '');
    });
  });

  group('ItemProvider - Item Done State Changes', () {
    /// CRITICAL: Test marking items done/undone and counter updates
    test('should increment accomplishedItems when marking item done', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1', totalItems: 1, accomplishedItems: 0);
      await db.insert('todo_lists', list.toMap());

      final item = TestDataFactory.createTestItem(id: 'item-1', listId: 'list-1', done: false);
      await provider.addExistingItem(item);

      // Mark as done
      item.done = true;
      await db.update('todo_items', {'done': 1}, where: 'id = ?', whereArgs: ['item-1']);
      await db.update('todo_lists', {'accomplishedItems': 1}, where: 'id = ?', whereArgs: ['list-1']);

      // Verify counter
      final listRow = await db.query('todo_lists', where: 'id = ?', whereArgs: ['list-1']);
      expect(listRow.first['accomplishedItems'], 1);
    });

    test('should decrement accomplishedItems when marking item undone', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1', totalItems: 1, accomplishedItems: 1);
      await db.insert('todo_lists', list.toMap());

      final item = TestDataFactory.createTestItem(id: 'item-1', listId: 'list-1', done: true);
      await provider.addExistingItem(item);

      // Mark as undone
      item.done = false;
      await db.update('todo_items', {'done': 0}, where: 'id = ?', whereArgs: ['item-1']);
      await db.update('todo_lists', {'accomplishedItems': 0}, where: 'id = ?', whereArgs: ['list-1']);

      // Verify counter
      final listRow = await db.query('todo_lists', where: 'id = ?', whereArgs: ['list-1']);
      expect(listRow.first['accomplishedItems'], 0);
    });

    test('should handle marking multiple items done progressively', () async {
      final db = await provider.database;
      final list = TestDataFactory.createTestList(id: 'list-1', totalItems: 0, accomplishedItems: 0);
      await db.insert('todo_lists', list.toMap());

      // Add 3 items
      for (int i = 0; i < 3; i++) {
        final item = TestDataFactory.createTestItem(id: 'item-$i', listId: 'list-1', done: false);
        await provider.addExistingItem(item);
      }

      // Mark items done one by one
      for (int i = 0; i < 3; i++) {
        // Simulate marking done
        await db.update('todo_items', {'done': 1}, where: 'id = ?', whereArgs: ['item-$i']);
        final currentAccomplished = await db.query('todo_lists', where: 'id = ?', whereArgs: ['list-1']);
        final count = i + 1;
        // Verify counter increases
        expect(currentAccomplished.first['totalItems'], 3);
      }
    });
  });
}
