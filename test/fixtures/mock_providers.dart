import 'package:mocktail/mocktail.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_do/Providers/lists_provider.dart';
import 'package:to_do/Providers/notification_provider.dart';
import 'package:to_do/Providers/item_provider.dart';
import 'package:to_do/Models/to_do_list.dart';
import 'package:to_do/Models/to_do_item.dart';
import 'package:to_do/Models/notification.dart';
import 'package:to_do/Utils/sort_by.dart';

/// Mock ListsProvider for widget and integration tests
class MockListsProvider extends Mock implements ListsProvider {
  final List<ToDoList> _lists = [];
  late SortBy _selectedOption;

  @override
  Future<List<ToDoList>> getActiveItems() async => _lists;

  @override
  Future<List<ToDoList>> getAchievedItems() async {
    return _lists.where((list) => list.isAchieved).toList();
  }

  @override
  Future<List<ToDoList>> getWithoutDeadlineItems() async {
    return _lists.where((list) => !list.hasDeadline).toList();
  }

  @override
  SortBy get selectedOptionVal => _selectedOption;

  @override
  set selectedOptionVal(SortBy value) {
    _selectedOption = value;
  }

  void addList(ToDoList list) {
    _lists.add(list);
  }

  void clear() => _lists.clear();
}

/// Mock ItemProvider for widget and integration tests
class MockItemProvider extends Mock implements ItemProvider {
  final Map<String, List<ToDoItem>> _items = {};

  @override
  Future<List<ToDoItem>> getItems(String listId) async {
    return _items[listId] ?? [];
  }

  void addItem(String listId, ToDoItem item) {
    _items.putIfAbsent(listId, () => []);
    _items[listId]!.add(item);
  }

  void clear() => _items.clear();
}

/// Mock NotificationProvider for widget and integration tests
class MockNotificationProvider extends Mock implements NotificationProvider {
  final Map<String, List<Notifications>> _notifications = {};

  @override
  Future<List<Notifications>> getNotifications(String listId) async {
    return _notifications[listId] ?? [];
  }

  void addTestNotification(String listId, Notifications notification) {
    _notifications.putIfAbsent(listId, () => []);
    _notifications[listId]!.add(notification);
  }

  @override
  Future<bool> addNotification(ToDoList list, DateTime notificationDateTime,
      [String? notificationText]) async {
    return true;
  }

  @override
  Future<List<Notifications>> getNotificationsByListId(String listId) async {
    return _notifications[listId] ?? [];
  }

  @override
  Future<bool> cancelNotification(int notificationID) async {
    return true;
  }

  @override
  Future<void> requestPermissions([bool? toActive]) async {}

  @override
  Future<bool> isAndroidPermissionGranted() async {
    return false; // return false so createNewList skips scheduling
  }

  @override
  Future<bool> scheduleNotification(ToDoList list,
      [String? notificationText]) async {
    return true;
  }

  @override
  Future<bool> deleteNotification(
      Notifications notification, ToDoList list) async {
    return true;
  }

  @override
  Future<void> setUpNotifications() async {}

  void clear() => _notifications.clear();
}

/// Helper to create test widget with providers
class TestProviderWrapper extends StatelessWidget {
  final Widget child;
  final ListsProvider? listsProvider;
  final ItemProvider? itemProvider;
  final NotificationProvider? notificationProvider;

  const TestProviderWrapper({
    required this.child,
    this.listsProvider,
    this.itemProvider,
    this.notificationProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ListsProvider>(
          create: (_) => listsProvider ?? MockListsProvider(),
        ),
        ChangeNotifierProvider<ItemProvider>(
          create: (_) => itemProvider ?? MockItemProvider(),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => notificationProvider ?? MockNotificationProvider(),
        ),
      ],
      child: child,
    );
  }
}

// Fallback registrations for mocktail to handle complex types
void setupMocktailFallbacks() {
  registerFallbackValue(ToDoList(
    id: 'fallback-id',
    userID: 'fallback-user',
    title: 'fallback',
    hasDeadline: false,
    creationDate: DateTime.now(),
    deadline: DateTime.now(),
    totalItems: 0,
    accomplishedItems: 0,
  ));

  registerFallbackValue(ToDoItem(
    id: 'fallback-id',
    listId: 'fallback-list',
    title: 'fallback',
    content: 'fallback',
    done: false,
    itemIndex: 0,
  ));

  registerFallbackValue(Notifications(
    id: 'fallback-id',
    listId: 'fallback-list',
    notificationIndex: 0,
    notificationDateTime: DateTime.now(),
    disabled: false,
  ));
}
