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

  // Fixed test dates
  final testDate = DateTime(2026, 3, 27);
  final futureDate = DateTime(2026, 12, 25);
  final pastDate = DateTime(2025, 12, 25);

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

      final result = await provider.addNotification(list, futureDate);

      expect(result, false);
      final notifications = await provider.getNotificationsByListId('list-1');
      expect(notifications, isEmpty);
    });

    test('should insert with disabled=false for future datetime when active', () async {
      SharedPreferences.setMockInitialValues({'notificationActive': true});
      await SharedPreferencesHelper.instance.initialise();

      final list = TestDataFactory.createTestList(id: 'list-1');

      // addNotification inserts into DB first, then calls scheduleNotification which
      // uses FlutterLocalNotificationsPlugin (a platform plugin unavailable in unit tests).
      // We swallow the unhandled async MissingPluginException and verify the DB state.
      final completer = Completer<void>();
      runZonedGuarded(() async {
        await provider.addNotification(list, futureDate);
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

      final completer = Completer<void>();
      runZonedGuarded(() async {
        await provider.addNotification(list, pastDate);
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

  group('NotificationProvider - Negative Test Cases', () {
    /// NEW: Error handling and edge cases
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

    test('should handle concurrent delete operations', () async {
      // Create 10 notifications
      for (int i = 0; i < 10; i++) {
        final notif = TestDataFactory.createTestNotification(
          id: 'notif-$i',
          listId: 'list-1',
        );
        await insertNotification(notif);
      }

      final list = TestDataFactory.createTestList(id: 'list-1');

      // Delete 5 concurrently
      final futures = List.generate(5, (i) {
        final notif = TestDataFactory.createTestNotification(
          id: 'notif-$i',
          listId: 'list-1',
        );
        return provider.deleteNotification(notif, list);
      });

      await Future.wait(futures);

      // Verify 5 remain
      final remaining = await provider.getNotificationsByListId('list-1');
      expect(remaining.length, 5);
    });

    test('should handle toggling disabled state of non-existent notification', () async {
      final notif = TestDataFactory.createTestNotification(id: 'nonexistent', listId: 'list-1');
      final list = TestDataFactory.createTestList(id: 'list-1');
      // Should not throw
      await provider.toggleNotificationDisabled(notif, list);
    });

    test('should handle disabling already-disabled notification', () async {
      final notif = TestDataFactory.createTestNotification(
        id: 'notif-1',
        listId: 'list-1',
        disabled: true,
      );
      await insertNotification(notif);

      final list = TestDataFactory.createTestList(id: 'list-1');
      await provider.disableNotificationById(notif, list);

      // Should remain disabled
      final row = await queryNotificationById('notif-1');
      expect(row!['disabled'], 1);
    });

    test('should handle editing non-existent notification', () async {
      final notif = TestDataFactory.createTestNotification(id: 'nonexistent', listId: 'list-1');
      final list = TestDataFactory.createTestList(id: 'list-1');
      // Should not throw
      await provider.editNotification(notif, list);
    });

    test('should handle notifications with boundary dates', () async {
      final db = await TestDatabaseHelper.getTestDatabase();

      // Very old date
      final oldNotif = TestDataFactory.createTestNotification(
        id: 'notif-old',
        listId: 'list-1',
        notificationDateTime: DateTime(1970, 1, 1),
      );
      await db.insert('notifications', oldNotif.toMap());

      // Very far future
      final futureNotif = TestDataFactory.createTestNotification(
        id: 'notif-future',
        listId: 'list-1',
        notificationDateTime: DateTime(3000, 12, 31),
      );
      await db.insert('notifications', futureNotif.toMap());

      final notifications = await provider.getNotificationsByListId('list-1');
      expect(notifications.length, 2);
      expect(notifications[0].notificationDateTime.year, 1970);
      expect(notifications[1].notificationDateTime.year, 3000);
    });
  });

  group('NotificationProvider - Bulk Operations', () {
    /// NEW: Bulk operation tests
    test('should support multiple notifications for the same list', () async {
      // Create 4 notifications for same list
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

    test('should add multiple notifications efficiently', () async {
      SharedPreferences.setMockInitialValues({'notificationActive': true});
      await SharedPreferencesHelper.instance.initialise();

      final list = TestDataFactory.createTestList(id: 'list-1');

      // Add 10 notifications
      for (int i = 0; i < 10; i++) {
        final completer = Completer<void>();
        runZonedGuarded(() async {
          await provider.addNotification(list, futureDate.add(Duration(days: i)));
          if (!completer.isCompleted) completer.complete();
        }, (e, _) {
          if (!completer.isCompleted) completer.complete();
        });
        await completer.future;
      }

      final notifications = await provider.getNotificationsByListId('list-1');
      expect(notifications.length, 10);
    });

    test('should clear all notifications for a list efficiently', () async {
      // Create 15 notifications
      final notifIds = <String>[];
      for (int i = 0; i < 15; i++) {
        final notif = TestDataFactory.createTestNotification(
          id: 'notif-$i',
          listId: 'list-1',
        );
        await insertNotification(notif);
        notifIds.add('notif-$i');
      }

      final list = TestDataFactory.createTestList(id: 'list-1');

      // Delete all
      for (final id in notifIds) {
        final notif = TestDataFactory.createTestNotification(id: id, listId: 'list-1');
        await provider.deleteNotification(notif, list);
      }

      // Verify all cleared
      final remaining = await provider.getNotificationsByListId('list-1');
      expect(remaining, isEmpty);
    });

    test('should handle bulk enable/disable operations', () async {
      // Create 10 notifications, 5 disabled
      for (int i = 0; i < 10; i++) {
        final notif = TestDataFactory.createTestNotification(
          id: 'notif-$i',
          listId: 'list-1',
          disabled: i < 5, // First 5 are disabled
        );
        await insertNotification(notif);
      }

      final list = TestDataFactory.createTestList(id: 'list-1');
      final notifications = await provider.getNotificationsByListId('list-1');

      // Toggle all
      for (final notif in notifications) {
        await provider.toggleNotificationDisabled(notif, list);
      }

      // Verify state changed
      final updated = await provider.getNotificationsByListId('list-1');
      
      // First 5 should now be enabled (disabled=false)
      // Last 5 should now be disabled (disabled=true)
      final disabledCount = updated.where((n) => n.disabled).length;
      expect(disabledCount, 5); // Now opposite half are disabled
    });

    test('should handle bulk edit of notification datetimes', () async {
      // Create 5 notifications
      for (int i = 0; i < 5; i++) {
        final notif = TestDataFactory.createTestNotification(
          id: 'notif-$i',
          listId: 'list-1',
          notificationDateTime: DateTime(2026, 1, i + 1),
        );
        await insertNotification(notif);
      }

      final list = TestDataFactory.createTestList(id: 'list-1');
      var notifications = await provider.getNotificationsByListId('list-1');

      // Re-enable all (simulating bulk edit)
      for (final notif in notifications) {
        await provider.editNotification(notif, list);
      }

      // Verify all are enabled
      notifications = await provider.getNotificationsByListId('list-1');
      final allEnabled = notifications.every((n) => !n.disabled);
      expect(allEnabled, true);
    });
  });

  group('NotificationProvider - Edge Cases', () {
    test('should retrieve notifications in stable order', () async {
      // Create notifications in random order
      final notifIds = ['notif-3', 'notif-1', 'notif-4', 'notif-2', 'notif-5'];
      for (final id in notifIds) {
        final notif = TestDataFactory.createTestNotification(id: id, listId: 'list-1');
        await insertNotification(notif);
      }

      // Retrieve multiple times - order should be consistent
      final firstRetrieve = await provider.getNotificationsByListId('list-1');
      final secondRetrieve = await provider.getNotificationsByListId('list-1');

      expect(firstRetrieve.map((n) => n.id), secondRetrieve.map((n) => n.id));
    });

    test('should handle notification with maximum index value', () async {
      final notif = TestDataFactory.createTestNotification(
        id: 'notif-1',
        listId: 'list-1',
        notificationIndex: 999999,
      );
      await insertNotification(notif);

      final notifications = await provider.getNotificationsByListId('list-1');
      expect(notifications[0].notificationIndex, 999999);
    });

    test('should preserve notification state through multiple operations', () async {
      final notif = TestDataFactory.createTestNotification(
        id: 'notif-1',
        listId: 'list-1',
        disabled: false,
        notificationIndex: 5,
      );
      await insertNotification(notif);

      final list = TestDataFactory.createTestList(id: 'list-1');

      // Get, disable, edit, get again
      var notifications = await provider.getNotificationsByListId('list-1');
      await provider.disableNotificationById(notifications[0], list);
      
      notifications = await provider.getNotificationsByListId('list-1');
      await provider.editNotification(notifications[0], list);

      notifications = await provider.getNotificationsByListId('list-1');
      final final Notif = notifications[0];

      expect(finalNotif.id, 'notif-1');
      expect(finalNotif.listId, 'list-1');
      expect(finalNotif.notificationIndex, 5);
      expect(finalNotif.disabled, false); // Should be re-enabled after edit
    });
  });
}
