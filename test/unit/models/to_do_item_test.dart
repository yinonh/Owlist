import 'package:flutter_test/flutter_test.dart';
import 'package:to_do/Models/to_do_item.dart';
import '../../fixtures/test_data.dart';

void main() {
  group('ToDoItem Model Tests', () {
    test('should create item with all required fields', () {
      final item = ToDoItem(
        id: 'item-1',
        listId: 'list-1',
        title: 'Buy milk',
        content: 'From the grocery store',
        done: false,
        itemIndex: 0,
      );

      expect(item.id, 'item-1');
      expect(item.listId, 'list-1');
      expect(item.title, 'Buy milk');
      expect(item.content, 'From the grocery store');
      expect(item.done, false);
      expect(item.itemIndex, 0);
    });

    test('should create item with factory', () {
      final item = TestDataFactory.createTestItem(
        title: 'Important Task',
        content: 'Do this today',
        done: false,
      );

      expect(item.title, 'Important Task');
      expect(item.content, 'Do this today');
      expect(item.done, false);
      expect(item.id, isNotEmpty);
      expect(item.listId, isNotEmpty);
    });

    test('should handle empty content', () {
      final item = TestDataFactory.createTestItem(content: '');
      expect(item.content, '');
    });

    test('should handle empty title', () {
      final item = TestDataFactory.createTestItem(title: '');
      expect(item.title, '');
    });

    test('should allow marking item as done', () {
      final item = TestDataFactory.createTestItem(done: false);
      
      expect(item.done, false);
      
      // Simulate updating the item
      item.done = true;
      expect(item.done, true);
    });

    test('should allow marking item as not done', () {
      final item = TestDataFactory.createTestItem(done: true);
      expect(item.done, true);
      
      item.done = false;
      expect(item.done, false);
    });

    test('should maintain item order by itemIndex', () {
      final item1 = TestDataFactory.createTestItem(itemIndex: 0);
      final item2 = TestDataFactory.createTestItem(itemIndex: 1);
      final item3 = TestDataFactory.createTestItem(itemIndex: 2);

      expect(item1.itemIndex < item2.itemIndex, true);
      expect(item2.itemIndex < item3.itemIndex, true);
      expect(item1.itemIndex < item3.itemIndex, true);
    });

    test('should belong to correct list', () {
      final listId = 'shopping-list-1';
      final item = TestDataFactory.createTestItem(listId: listId);

      expect(item.listId, listId);
    });

    test('should have unique IDs for different items', () {
      final item1 = TestDataFactory.createTestItem();
      final item2 = TestDataFactory.createTestItem();

      expect(item1.id, isNot(item2.id));
    });

    test('should handle items with special characters in title', () {
      final item = TestDataFactory.createTestItem(
        title: 'Buy @#\$% special items!',
      );

      expect(item.title, 'Buy @#\$% special items!');
    });

    test('should handle items with special characters in content', () {
      final item = TestDataFactory.createTestItem(
        content: 'Get from: https://example.com/page?id=123&type=food',
      );

      expect(item.content.contains('https://'), true);
      expect(item.content.contains('&'), true);
    });

    test('should handle long content strings', () {
      final longContent = 'A' * 1000; // 1000 character string
      final item = TestDataFactory.createTestItem(content: longContent);

      expect(item.content.length, 1000);
      expect(item.content, longContent);
    });

    test('should handle long title strings', () {
      final longTitle = 'Task ' * 50; // Long title
      final item = TestDataFactory.createTestItem(title: longTitle);

      expect(item.title, longTitle);
    });

    test('should allow negative itemIndex (edge case)', () {
      final item = TestDataFactory.createTestItem(itemIndex: -1);
      expect(item.itemIndex, -1);
    });

    test('should allow large itemIndex values', () {
      final item = TestDataFactory.createTestItem(itemIndex: 999999);
      expect(item.itemIndex, 999999);
    });

    test('should support reordering items by changing itemIndex', () {
      final item = TestDataFactory.createTestItem(itemIndex: 0);
      
      // Reorder by updating index
      item.itemIndex = 5;
      expect(item.itemIndex, 5);
    });

    test('should handle items with null-like empty strings', () {
      final item = ToDoItem(
        id: '',
        listId: '',
        title: '',
        content: '',
        done: false,
        itemIndex: 0,
      );

      expect(item.id, '');
      expect(item.listId, '');
      expect(item.title, '');
      expect(item.content, '');
    });

    test('should detect URL in content', () {
      final item = TestDataFactory.createTestItem(
        content: 'Check this out: https://flutter.dev',
      );

      expect(item.content.contains('https://flutter.dev'), true);
    });

    test('should detect email in content', () {
      final item = TestDataFactory.createTestItem(
        content: 'Contact: john@example.com',
      );

      expect(item.content.contains('john@example.com'), true);
    });

    test('should handle multiple items in same list', () {
      final listId = 'list-1';
      final item1 = TestDataFactory.createTestItem(listId: listId, itemIndex: 0);
      final item2 = TestDataFactory.createTestItem(listId: listId, itemIndex: 1);
      final item3 = TestDataFactory.createTestItem(listId: listId, itemIndex: 2);

      // All items belong to same list
      expect(item1.listId, listId);
      expect(item2.listId, listId);
      expect(item3.listId, listId);

      // But have different IDs
      expect(item1.id, isNot(item2.id));
      expect(item2.id, isNot(item3.id));
    });

    test('should preserve state when creating multiple copies', () {
      final original = TestDataFactory.createTestItem(
        title: 'Original',
        done: true,
      );

      final item1 = TestDataFactory.createTestItem(
        id: original.id,
        listId: original.listId,
        title: original.title,
        done: original.done,
      );

      expect(item1.title, 'Original');
      expect(item1.done, true);
      expect(item1.id, original.id);
    });

    test('should handle rapid state changes', () {
      final item = TestDataFactory.createTestItem(done: false);

      // Toggle state multiple times
      for (int i = 0; i < 10; i++) {
        item.done = !item.done;
      }

      // Should be false (even number of toggles)
      expect(item.done, false);
    });

    test('should support updating item properties', () {
      final item = TestDataFactory.createTestItem();
      
      // Update properties
      item.title = 'Updated Title';
      item.content = 'Updated Content';
      item.done = true;
      item.itemIndex = 5;

      expect(item.title, 'Updated Title');
      expect(item.content, 'Updated Content');
      expect(item.done, true);
      expect(item.itemIndex, 5);
    });
  });
}
