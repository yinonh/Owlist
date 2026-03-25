import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do/Providers/notification_provider.dart';
import 'package:to_do/Models/notification.dart';
import 'package:to_do/Utils/shared_preferences_helper.dart';
import '../../fixtures/mock_database.dart';
import '../../fixtures/test_data.dart';

void main() {
  late NotificationProvider provider;

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
  });

  setUp(() async {
    // Disable notifications so scheduleNotification() returns early (skips platform plugin)
    SharedPreferences.setMockInitialValues({'notificationActive': false});
    await SharedPreferencesHelper.instance.initialise();

    final testDb = await TestDatabaseHelper.getTestDatabase();
    provider = NotificationProvider(database: testDb);
  });

  tearDown(() async {
    await TestDatabaseHelper.clearAllTables();
    await TestDatabaseHelper.closeTestDatabase();
  });

  // Helper: insert a notification directly into the DB (bypasses scheduleNotification)
  Future<void> insertNotification(Notifications notif) async {
    final db = await TestDatabaseHelper.getTestDatabase();
    await db.insert('notifications', notif.toMap());
  }

  // Helper: query a notification by ID from DB
  Future<Map<String, dynamic>?> queryNotificationById(String id) async {
    final db = await TestDatabaseHelper.getTestDatabase();
    final rows = await db.query('notifications', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  group('NotificationProvider - Retrieval', () {
    test('should return empty list when no notifications exist', () async {
      final notifications = await provider.getNotificationsByListId('list-1');
      expect(notifications, isEmpty);
    });

    test('should retrieve notifications by list ID', () async {
      final notif1 = TestDataFactory.createTestNotification(id: 'notif-1', listId: 'list-1');
      final notif2 = TestDataFactory.createTestNotification(id: 'notif-2', listId: 'list-1');
      await insertNotification(notif1);
      await insertNotification(notif2);

      final notifications = await provider.getNotificationsByListId('list-1');
      expect(notifications.length, 2);
      expect(notifications.every((n) => n.listId == 'list-1'), true);
    });

    test('should separate notifications by list ID', () async {
      final notif1 = TestDataFactory.createTestNotification(id: 'notif-1', listId: 'list-1');
      final notif2 = TestDataFactory.createTestNotification(id: 'notif-2', listId: 'list-2');
      await insertNotification(notif1);
      await insertNotification(notif2);

      final notifications1 = await provider.getNotificationsByListId('list-1');
      final notifications2 = await provider.getNotificationsByListId('list-2');

      expect(notifications1.length, 1);
      expect(notifications2.length, 1);
      expect(notifications1.first.listId, 'list-1');
      expect(notifications2.first.listId, 'list-2');
    });
  });

  group('NotificationProvider - Disable/Enable', () {
    test('should disable notification by ID', () async {
      final notif = TestDataFactory.createTestNotification(
        id: 'notif-1',
        listId: 'list-1',
        disabled: false,
      );
      await insertNotification(notif);

      final list = TestDataFactory.createTestList(id: 'list-1');
      await provider.disableNotificationById(notif, list);

      final row = await queryNotificationById('notif-1');
      expect(row, isNotNull);
      expect(row!['disabled'], 1);
    });

    test('should toggle enabled notification to disabled', () async {
      final notif = TestDataFactory.createTestNotification(
        id: 'notif-1',
        listId: 'list-1',
        disabled: false,
      );
      await insertNotification(notif);

      final list = TestDataFactory.createTestList(id: 'list-1');
      await provider.toggleNotificationDisabled(notif, list);

      final row = await queryNotificationById('notif-1');
      expect(row!['disabled'], 1);
    });

    test('should not toggle disabled notification when notificationsActive is false', () async {
      // When notificationsActive=false and notification is disabled,
      // toggleNotificationDisabled is a no-op (guard at top of method)
      final notif = TestDataFactory.createTestNotification(
        id: 'notif-1',
        listId: 'list-1',
        disabled: true,
      );
      await insertNotification(notif);

      final list = TestDataFactory.createTestList(id: 'list-1');
      await provider.toggleNotificationDisabled(notif, list);

      // Should remain disabled since notificationsActive=false and notification.disabled=true
      final row = await queryNotificationById('notif-1');
      expect(row!['disabled'], 1);
    });
  });

  group('NotificationProvider - Deletion', () {
    test('should delete notification from DB', () async {
      final notif = TestDataFactory.createTestNotification(id: 'notif-1', listId: 'list-1');
      await insertNotification(notif);

      final list = TestDataFactory.createTestList(id: 'list-1');
      await provider.deleteNotification(notif, list);

      final row = await queryNotificationById('notif-1');
      expect(row, isNull);
    });

    test('should only delete the specified notification', () async {
      final notif1 = TestDataFactory.createTestNotification(id: 'notif-1', listId: 'list-1');
      final notif2 = TestDataFactory.createTestNotification(id: 'notif-2', listId: 'list-1');
      await insertNotification(notif1);
      await insertNotification(notif2);

      final list = TestDataFactory.createTestList(id: 'list-1');
      await provider.deleteNotification(notif1, list);

      final remaining = await provider.getNotificationsByListId('list-1');
      expect(remaining.length, 1);
      expect(remaining.first.id, 'notif-2');
    });
  });

  group('NotificationProvider - Edit', () {
    test('should re-enable disabled notification via editNotification', () async {
      final notif = TestDataFactory.createTestNotification(
        id: 'notif-1',
        listId: 'list-1',
        disabled: true,
      );
      await insertNotification(notif);

      final list = TestDataFactory.createTestList(id: 'list-1');
      await provider.editNotification(notif, list);

      final row = await queryNotificationById('notif-1');
      expect(row!['disabled'], 0);
    });
  });

  group('NotificationProvider - addNotification', () {
    test('should not insert when notificationsActive is false', () async {
      // notificationsActive defaults to false in this test suite
      final list = TestDataFactory.createTestList(id: 'list-1');
      final futureTime = DateTime.now().add(const Duration(hours: 1));

      final result = await provider.addNotification(list, futureTime);

      expect(result, false);
      final notifications = await provider.getNotificationsByListId('list-1');
      expect(notifications, isEmpty);
    });

    test('should insert with disabled=false for future datetime when active', () async {
      SharedPreferences.setMockInitialValues({'notificationActive': true});
      await SharedPreferencesHelper.instance.initialise();

      final list = TestDataFactory.createTestList(id: 'list-1');
      final futureTime = DateTime.now().add(const Duration(hours: 2));

      // addNotification inserts into DB first, then calls scheduleNotification which
      // uses FlutterLocalNotificationsPlugin (a platform plugin unavailable in unit tests).
      // We swallow the unhandled async MissingPluginException and verify the DB state.
      final completer = Completer<void>();
      runZonedGuarded(() async {
        await provider.addNotification(list, futureTime);
        if (!completer.isCompleted) completer.complete();
      }, (e, _) {
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future;

      final notifications = await provider.getNotificationsByListId('list-1');
      expect(notifications.length, 1);
      expect(notifications.first.disabled, false);
    });

    test('should insert with disabled=true for past datetime when active', () async {
      SharedPreferences.setMockInitialValues({'notificationActive': true});
      await SharedPreferencesHelper.instance.initialise();

      final list = TestDataFactory.createTestList(id: 'list-1');
      final pastTime = DateTime.now().subtract(const Duration(hours: 2));

      final completer = Completer<void>();
      runZonedGuarded(() async {
        await provider.addNotification(list, pastTime);
        if (!completer.isCompleted) completer.complete();
      }, (e, _) {
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future;

      final notifications = await provider.getNotificationsByListId('list-1');
      expect(notifications.length, 1);
      expect(notifications.first.disabled, true);
    });
  });

  group('NotificationProvider - Edge Cases', () {
    test('should handle deleting non-existent notification gracefully', () async {
      final notif = TestDataFactory.createTestNotification(id: 'nonexistent', listId: 'list-1');
      final list = TestDataFactory.createTestList(id: 'list-1');
      // Should not throw
      await provider.deleteNotification(notif, list);
    });

    test('should handle retrieving notifications for non-existent list', () async {
      final notifications = await provider.getNotificationsByListId('nonexistent-list');
      expect(notifications, isEmpty);
    });

    test('should support multiple notifications for the same list', () async {
      for (int i = 0; i < 4; i++) {
        final notif = TestDataFactory.createTestNotification(
          id: 'notif-$i',
          listId: 'list-1',
          notificationIndex: i,
        );
        await insertNotification(notif);
      }

      final notifications = await provider.getNotificationsByListId('list-1');
      expect(notifications.length, 4);
    });
  });
}
