import 'package:uuid/uuid.dart';
import 'package:to_do/Models/to_do_list.dart';
import 'package:to_do/Models/to_do_item.dart';
import 'package:to_do/Models/notification.dart';

class TestDataFactory {
  static const uuid = Uuid();

  /// Create a test ToDoList with default or custom values
  static ToDoList createTestList({
    String? id,
    String userID = 'test-user',
    String title = 'Test List',
    bool hasDeadline = false,
    DateTime? creationDate,
    DateTime? deadline,
    int totalItems = 0,
    int accomplishedItems = 0,
  }) {
    final now = DateTime.now();
    return ToDoList(
      id: id ?? uuid.v4(),
      userID: userID,
      title: title,
      hasDeadline: hasDeadline,
      creationDate: creationDate ?? now,
      deadline: deadline ?? now.add(Duration(days: 7)),
      totalItems: totalItems,
      accomplishedItems: accomplishedItems,
    );
  }

  /// Create a test ToDoItem with default or custom values
  static ToDoItem createTestItem({
    String? id,
    String? listId,
    String title = 'Test Item',
    String content = 'Test content',
    bool done = false,
    int itemIndex = 0,
  }) {
    return ToDoItem(
      id: id ?? uuid.v4(),
      listId: listId ?? uuid.v4(),
      title: title,
      content: content,
      done: done,
      itemIndex: itemIndex,
    );
  }

  /// Create a test Notifications with default or custom values
  static Notifications createTestNotification({
    String? id,
    String? listId,
    int notificationIndex = 0,
    DateTime? notificationDateTime,
    bool disabled = false,
  }) {
    final now = DateTime.now().add(Duration(hours: 1));
    return Notifications(
      id: id ?? uuid.v4(),
      listId: listId ?? uuid.v4(),
      notificationIndex: notificationIndex,
      notificationDateTime: notificationDateTime ?? now,
      disabled: disabled,
    );
  }

  /// Create multiple test lists with unique properties
  static List<ToDoList> createMultipleLists({
    int count = 3,
  }) {
    return List.generate(
      count,
      (index) => createTestList(
        title: 'List ${index + 1}',
        totalItems: (index + 1) * 2,
        accomplishedItems: index,
      ),
    );
  }

  /// Create multiple test items for a list
  static List<ToDoItem> createMultipleItems({
    required String listId,
    int count = 5,
  }) {
    return List.generate(
      count,
      (index) => createTestItem(
        listId: listId,
        title: 'Item ${index + 1}',
        done: index >= 2, // First 2 not done, rest done
        itemIndex: index,
      ),
    );
  }
}
