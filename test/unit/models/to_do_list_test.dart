import 'package:flutter_test/flutter_test.dart';
import 'package:to_do/Models/to_do_list.dart';
import '../../fixtures/test_data.dart';

void main() {
  group('ToDoList Model Tests', () {
    test('should create list with all required fields', () {
      final now = DateTime.now();
      final list = ToDoList(
        id: 'test-id',
        userID: 'user-123',
        title: 'My Shopping List',
        hasDeadline: true,
        creationDate: now,
        deadline: now.add(Duration(days: 7)),
        totalItems: 5,
        accomplishedItems: 2,
      );

      expect(list.id, 'test-id');
      expect(list.userID, 'user-123');
      expect(list.title, 'My Shopping List');
      expect(list.hasDeadline, true);
      expect(list.creationDate, now);
      expect(list.totalItems, 5);
      expect(list.accomplishedItems, 2);
    });

    test('should create list with default factory', () {
      final list = TestDataFactory.createTestList(
        title: 'Test List',
        hasDeadline: true,
        totalItems: 10,
      );

      expect(list.title, 'Test List');
      expect(list.hasDeadline, true);
      expect(list.totalItems, 10);
      expect(list.id, isNotEmpty);
      expect(list.userID, isNotEmpty);
    });

    test('should handle empty title', () {
      final list = TestDataFactory.createTestList(title: '');
      expect(list.title, '');
    });

    test('should preserve deadline when hasDeadline is true', () {
      final deadline = DateTime(2026, 12, 25);
      final list = TestDataFactory.createTestList(
        hasDeadline: true,
        deadline: deadline,
      );

      expect(list.hasDeadline, true);
      expect(list.deadline, deadline);
    });

    test('should allow zero total items', () {
      final list = TestDataFactory.createTestList(
        totalItems: 0,
        accomplishedItems: 0,
      );

      expect(list.totalItems, 0);
      expect(list.accomplishedItems, 0);
    });

    test('should allow accomplished items equal to total items', () {
      final list = TestDataFactory.createTestList(
        totalItems: 5,
        accomplishedItems: 5,
      );

      expect(list.accomplishedItems, list.totalItems);
    });

    test('should be marked as achieved when all items completed', () {
      final list = TestDataFactory.createTestList(
        totalItems: 5,
        accomplishedItems: 5,
      );

      expect(list.isAchieved, true);
    });

    test('should be marked as achieved when deadline passed', () {
      final yesterday = DateTime.now().subtract(Duration(days: 1));
      final list = ToDoList(
        id: 'test-id',
        userID: 'user',
        title: 'Overdue List',
        hasDeadline: true,
        creationDate: DateTime.now(),
        deadline: yesterday,
        totalItems: 5,
        accomplishedItems: 0,
      );

      expect(list.isAchieved, true); // Overdue = achieved
    });

    test('should not be marked as achieved when partially complete', () {
      final list = TestDataFactory.createTestList(
        totalItems: 5,
        accomplishedItems: 2,
      );

      expect(list.isAchieved, false);
    });

    test('should not be marked as achieved when not completed but deadline valid', () {
      final tomorrow = DateTime.now().add(Duration(days: 1));
      final list = ToDoList(
        id: 'test-id',
        userID: 'user',
        title: 'Active List',
        hasDeadline: true,
        creationDate: DateTime.now(),
        deadline: tomorrow,
        totalItems: 5,
        accomplishedItems: 0,
      );

      expect(list.isAchieved, false);
    });

    test('should convert to Map correctly', () {
      final list = TestDataFactory.createTestList(
        id: 'test-id',
        title: 'Test List',
        totalItems: 5,
      );

      final map = list.toMap();

      expect(map['id'], 'test-id');
      expect(map['title'], 'Test List');
      expect(map['totalItems'], 5);
      expect(map.containsKey('creationDate'), true);
      expect(map.containsKey('deadline'), true);
    });

    test('should create from Map correctly', () {
      final now = DateTime.now();
      final map = {
        'id': 'test-id',
        'userID': 'user-123',
        'title': 'Test List',
        'hasDeadline': 1,
        'totalItems': 5,
        'accomplishedItems': 2,
        'creationDate': '2026-03-24 12:00:00',
        'deadline': '2026-03-31',
      };

      final list = ToDoList.fromMap(map);

      expect(list.id, 'test-id');
      expect(list.userID, 'user-123');
      expect(list.title, 'Test List');
      expect(list.hasDeadline, true);
      expect(list.totalItems, 5);
      expect(list.accomplishedItems, 2);
    });

    test('should handle hasDeadline boolean conversion from int', () {
      final mapTrue = {...TestDataFactory.createTestList().toMap(), 'hasDeadline': 1};
      final mapFalse = {...TestDataFactory.createTestList().toMap(), 'hasDeadline': 0};

      final listTrue = ToDoList.fromMap(mapTrue);
      final listFalse = ToDoList.fromMap(mapFalse);

      expect(listTrue.hasDeadline, true);
      expect(listFalse.hasDeadline, false);
    });

    test('should create copy with updated fields', () {
      final original = TestDataFactory.createTestList(
        title: 'Original',
        totalItems: 5,
      );

      final updated = original.copyWith(
        title: 'Updated',
        accomplishedItems: 3,
      );

      expect(updated.title, 'Updated');
      expect(updated.accomplishedItems, 3);
      expect(updated.totalItems, 5); // Unchanged
      expect(updated.id, original.id); // Same ID
    });

    test('should preserve all fields when using copyWith without parameters', () {
      final original = TestDataFactory.createTestList(title: 'Original');
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.title, original.title);
      expect(copy.totalItems, original.totalItems);
      expect(copy.accomplishedItems, original.accomplishedItems);
    });

    test('should handle creation with future deadline', () {
      final future = DateTime.now().add(Duration(days: 30));
      final list = TestDataFactory.createTestList(
        deadline: future,
        hasDeadline: true,
      );

      expect(list.deadline.isAfter(DateTime.now()), true);
    });

    test('should have unique IDs for multiple lists', () {
      final list1 = TestDataFactory.createTestList();
      final list2 = TestDataFactory.createTestList();

      expect(list1.id, isNot(list2.id));
    });

    test('should be serializable and deserializable', () {
      final original = TestDataFactory.createTestList(
        title: 'Test',
        totalItems: 10,
        accomplishedItems: 5,
      );

      final map = original.toMap();
      final restored = ToDoList.fromMap(map);

      expect(restored.title, original.title);
      expect(restored.totalItems, original.totalItems);
      expect(restored.accomplishedItems, original.accomplishedItems);
    });
  });
}
