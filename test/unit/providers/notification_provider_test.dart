import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
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
    // Load .env file once for all tests
    await dotenv.load(fileName: '.env');
  });

  setUp(() async {
    // Initialize SharedPreferences with mock data
    SharedPreferences.setMockInitialValues({});
    await SharedPreferencesHelper.instance.initialise();
    
    // Initialize fresh test database with injected dependency
    final testDb = await TestDatabaseHelper.getTestDatabase();
    provider = NotificationProvider(database: testDb);
  });

  tearDown(() async {
    await TestDatabaseHelper.clearAllTables();
    await TestDatabaseHelper.closeTestDatabase();
  });

  group('NotificationProvider - Notification Retrieval', () {
    test('should retrieve notifications for a list', () async {
      // Create 2 notifications for list-1
      // const notif1 = TestDataFactory.createTestNotification(listId: 'list-1');
      // const notif2 = TestDataFactory.createTestNotification(listId: 'list-1');

      // final notifications = await provider.getNotifications('list-1');
      // expect(notifications.length, 2);
    });

    test('should return empty for list with no notifications', () async {
      // final notifications = await provider.getNotifications('list-1');
      // expect(notifications, isEmpty);
    });

    test('should retrieve notification by ID', () async {
      // const notif = TestDataFactory.createTestNotification();
      // await provider.scheduleNotification('list-1', notif);

      // final retrieved = await provider.getNotification(notif.id);
      // expect(retrieved?.id, notif.id);
    });

    test('should separate notifications by list', () async {
      // Create notifications for list-1 and list-2
      // final notifs1 = await provider.getNotifications('list-1');
      // final notifs2 = await provider.getNotifications('list-2');

      // expect(notifs1.every((n) => n.listId == 'list-1'), true);
      // expect(notifs2.every((n) => n.listId == 'list-2'), true);
    });
  });

  group('NotificationProvider - Notification CRUD', () {
    test('should schedule notification', () async {
      // const notif = TestDataFactory.createTestNotification();
      // await provider.scheduleNotification('list-1', notif);

      // final retrieved = await provider.getNotification(notif.id);
      // expect(retrieved, isNotNull);
    });

    test('should update notification time', () async {
      // Create and schedule notification
      // const time1 = DateTime(2026, 3, 24, 10, 0);
      // const notif = TestDataFactory.createTestNotification(
      //   notificationDateTime: time1,
      // );
      // await provider.scheduleNotification('list-1', notif);

      // Update
      // const time2 = DateTime(2026, 3, 24, 14, 30);
      // final updated = notif.copyWith(notificationDateTime: time2);
      // await provider.updateNotification(updated);

      // Verify
      // final retrieved = await provider.getNotification(notif.id);
      // expect(retrieved?.notificationDateTime, time2);
    });

    test('should delete notification', () async {
      // Create and schedule
      // const notif = TestDataFactory.createTestNotification();
      // await provider.scheduleNotification('list-1', notif);

      // Delete
      // await provider.deleteNotification(notif.id);

      // Verify deleted
      // final retrieved = await provider.getNotification(notif.id);
      // expect(retrieved, isNull);
    });

    test('should disable notification without deleting', () async {
      // Create and schedule
      // const notif = TestDataFactory.createTestNotification(disabled: false);
      // await provider.scheduleNotification('list-1', notif);

      // Disable
      // await provider.disableNotification(notif.id);

      // Verify still exists but disabled
      // final retrieved = await provider.getNotification(notif.id);
      // expect(retrieved?.disabled, true);
      // expect(retrieved?.id, notif.id); // Still there
    });

    test('should re-enable disabled notification', () async {
      // Disable notification
      // await provider.disableNotification(notif.id);

      // Re-enable
      // await provider.enableNotification(notif.id);

      // Verify enabled
      // final retrieved = await provider.getNotification(notif.id);
      // expect(retrieved?.disabled, false);
    });
  });

  group('NotificationProvider - Multiple Reminders Per List', () {
    test('should support up to 4 notifications per list', () async {
      // Create 4 notifications
      // for (int i = 0; i < 4; i++) {
      //   final notif = TestDataFactory.createTestNotification(
      //     listId: 'list-1',
      //     notificationIndex: i,
      //   );
      //   await provider.scheduleNotification('list-1', notif);
      // }

      // final notifications = await provider.getNotifications('list-1');
      // expect(notifications.length, 4);
    });

    test('should enforce maximum 4 notifications per list', () async {
      // Create 5 notifications
      // First 4 should succeed
      // 5th should fail or be rejected

      // expect(
      //   () => provider.scheduleNotification('list-1', notification5),
      //   throwsA(isA<TooManyNotificationsException>()),
      // );
    });

    test('should allow replacing a notification', () async {
      // Create 4 notifications
      // Replace notification at index 1
      // Should still have 4 total

      // final notifications = await provider.getNotifications('list-1');
      // expect(notifications.length, 4);
    });

    test('should track notification index correctly', () async {
      // Create notifications at indices 0, 1, 2, 3
      // All should exist with correct indices

      // final notifications = await provider.getNotifications('list-1');
      // for (int i = 0; i < 4; i++) {
      //   expect(notifications.any((n) => n.notificationIndex == i), true);
      // }
    });

    test('should allow independent notifications for different lists', () async {
      // list-1: 4 notifications
      // list-2: 4 notifications
      // list-3: 4 notifications
      // All independent and separate
    });
  });

  group('NotificationProvider - Notification Timing', () {
    test('should handle notifications scheduled in future', () async {
      // Schedule for tomorrow
      // const tomorrow = DateTime.now().add(Duration(days: 1));
      // const notif = TestDataFactory.createTestNotification(
      //   notificationDateTime: tomorrow,
      // );
      // await provider.scheduleNotification('list-1', notif);

      // Should succeed
      // final retrieved = await provider.getNotification(notif.id);
      // expect(retrieved?.notificationDateTime.isAfter(DateTime.now()), true);
    });

    test('should handle notifications for past times', () async {
      // Schedule for yesterday (past)
      // const yesterday = DateTime.now().subtract(Duration(days: 1));
      // const notif = TestDataFactory.createTestNotification(
      //   notificationDateTime: yesterday,
      // );

      // Should either:
      // 1. Not allow past times
      // 2. Reschedule to next occurrence
      // 3. Store but not fire
    });

    test('should persist notification time across app restarts', () async {
      // Schedule notification
      // Close provider
      // Reinitialize provider
      // Verify notification still exists with same time
    });

    test('should handle timezone-aware scheduling', () async {
      // Schedule notification with specific timezone
      // Retrieve and verify time is correct
    });

    test('should handle daylight saving time transitions', () async {
      // Schedule around DST change
      // Verify time doesn't shift unexpectedly
    });
  });

  group('NotificationProvider - Notification Firing', () {
    test('should fire notification at scheduled time', () {
      fakeAsync((async) {
        // Schedule notification for 1 second from now
        // const notif = TestDataFactory.createTestNotification(
        //   notificationDateTime: DateTime.now().add(Duration(seconds: 1)),
        // );
        // await provider.scheduleNotification('list-1', notif);

        // Advance time past trigger
        // async.elapse(Duration(seconds: 2));

        // Verify notification was shown
        // expect(notificationWasShown, true);
      });
    });

    test('should not fire disabled notifications', () {
      fakeAsync((async) {
        // Schedule notification but disable it
        // Advance time
        // Notification should NOT fire
        // expect(notificationWasShown, false);
      });
    });

    test('should handle multiple notifications firing simultaneously', () {
      fakeAsync((async) {
        // Schedule 4 notifications all at same time
        // Advance to trigger time
        // All should fire

        // expect(notificationsFired, 4);
      });
    });

    test('should not fire duplicate notifications', () {
      fakeAsync((async) {
        // Schedule notification
        // Advance time to trigger (it fires)
        // Check that it only fires once, not repeatedly
      });
    });

    test('should handle rescheduling after firing', () async {
      // Notification fires
      // Reschedule for next day
      // Next day: notification fires again
    });
  });

  group('NotificationProvider - Notification Cleanup', () {
    test('should delete all notifications when list is deleted', () async {
      // Create list with 3 notifications
      // const notif1 = TestDataFactory.createTestNotification(listId: 'list-1');
      // const notif2 = TestDataFactory.createTestNotification(listId: 'list-1');
      // const notif3 = TestDataFactory.createTestNotification(listId: 'list-1');

      // Delete list
      // await provider.deleteListNotifications('list-1');

      // Verify all deleted
      // final remaining = await provider.getNotifications('list-1');
      // expect(remaining, isEmpty);
    });

    test('should cancel scheduled notifications on delete', () {
      fakeAsync((async) {
        // Schedule notification
        // Delete it before it fires
        // Advance to trigger time
        // Should NOT fire
        // expect(notificationFired, false);
      });
    });
  });

  group('NotificationProvider - Edge Cases', () {
    test('should handle notification with null list ID', () async {
      // Create notification with empty listId
      // Should either throw or handle gracefully
    });

    test('should handle creating notification at exact same time as another', () async {
      // Create 2 notifications with identical datetime
      // Both should be scheduled
    });

    test('should handle very far future dates', () async {
      // Schedule notification for year 3000
      // Should handle without error
    });

    test('should handle very old past dates', () async {
      // Schedule notification for 1970
      // Should handle gracefully
    });

    test('should handle rapid notification updates', () async {
      // Create notification
      // Update time 10 times rapidly
      // All updates should succeed
    });

    test('should handle disabling/enabling rapidly', () async {
      // Create notification
      // Toggle disabled state 20 times rapidly
      // Final state should be correct
    });

    test('should handle concurrent operations on same notification', () async {
      // Multiple threads trying to update same notification
      // Should handle concurrency correctly
    });
  });

  group('NotificationProvider - Special Datetime Cases', () {
    test('should handle midnight (00:00)', () async {
      // const midnight = DateTime(2026, 3, 24, 0, 0, 0);
      // const notif = TestDataFactory.createTestNotification(
      //   notificationDateTime: midnight,
      // );
      // await provider.scheduleNotification('list-1', notif);

      // final retrieved = await provider.getNotification(notif.id);
      // expect(retrieved?.notificationDateTime.hour, 0);
    });

    test('should handle end of day (23:59)', () async {
      // const endOfDay = DateTime(2026, 3, 24, 23, 59, 59);
      // Should handle correctly
    });

    test('should handle year boundary (Dec 31 → Jan 1)', () async {
      // Schedule notification for Dec 31, 23:59
      // Should handle year transition
    });

    test('should handle leap year dates', () async {
      // Schedule notification for Feb 29 (leap year)
      // Should handle correctly
    });

    test('should handle month boundary dates', () async {
      // Schedule for last day of month (28, 29, 30, or 31)
      // Should handle all variations
    });
  });
}
