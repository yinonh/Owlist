import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:to_do/Models/notification.dart';
import 'package:to_do/Utils/keys.dart';
import '../../fixtures/test_data.dart';

void main() {
  group('Notifications Model Tests', () {
    test('should create notification with all required fields', () {
      final now = DateTime.now();
      final notification = Notifications(
        id: 'notif-1',
        listId: 'list-1',
        notificationIndex: 0,
        notificationDateTime: now,
        disabled: false,
      );

      expect(notification.id, 'notif-1');
      expect(notification.listId, 'list-1');
      expect(notification.notificationIndex, 0);
      expect(notification.notificationDateTime, now);
      expect(notification.disabled, false);
    });

    test('should create notification with factory', () {
      final notification = TestDataFactory.createTestNotification(
        notificationIndex: 1,
        disabled: false,
      );

      expect(notification.notificationIndex, 1);
      expect(notification.disabled, false);
      expect(notification.id, isNotEmpty);
      expect(notification.listId, isNotEmpty);
    });

    test('should handle notification in disabled state', () {
      final notification = TestDataFactory.createTestNotification(disabled: true);
      expect(notification.disabled, true);
    });

    test('should handle notification in enabled state', () {
      final notification = TestDataFactory.createTestNotification(disabled: false);
      expect(notification.disabled, false);
    });

    test('should support all 4 notification indices (0-3)', () {
      for (int i = 0; i < 4; i++) {
        final notification = TestDataFactory.createTestNotification(
          notificationIndex: i,
        );
        expect(notification.notificationIndex, i);
      }
    });

    test('should allow arbitrary notification indices', () {
      final notification = TestDataFactory.createTestNotification(
        notificationIndex: 10,
      );
      expect(notification.notificationIndex, 10);
    });

    test('should convert to Map correctly', () {
      final now = DateTime(2026, 3, 24, 14, 30);
      final notification = Notifications(
        id: 'notif-1',
        listId: 'list-1',
        notificationIndex: 0,
        notificationDateTime: now,
        disabled: false,
      );

      final map = notification.toMap();

      expect(map['id'], 'notif-1');
      expect(map['listId'], 'list-1');
      expect(map['notificationIndex'], 0);
      expect(map['disabled'], 0); // false = 0
      expect(map.containsKey('notificationDateTime'), true);
    });

    test('should handle disabled flag conversion to int', () {
      final notifTrue = TestDataFactory.createTestNotification(disabled: true);
      final notifFalse = TestDataFactory.createTestNotification(disabled: false);

      final mapTrue = notifTrue.toMap();
      final mapFalse = notifFalse.toMap();

      expect(mapTrue['disabled'], 1);
      expect(mapFalse['disabled'], 0);
    });

    test('should create from Map correctly', () {
      final now = DateTime.now();
      final dateString = DateFormat(Keys.notificationDateTimeFormat).format(now);
      final map = {
        'id': 'notif-1',
        'listId': 'list-1',
        'notificationIndex': 2,
        'notificationDateTime': dateString,
        'disabled': 0,
      };

      final notification = Notifications.fromMap(map);

      expect(notification.id, 'notif-1');
      expect(notification.listId, 'list-1');
      expect(notification.notificationIndex, 2);
      expect(notification.disabled, false);
    });

    test('should handle disabled flag conversion from int', () {
      final mapTrue = TestDataFactory.createTestNotification(disabled: true).toMap();
      final mapFalse = TestDataFactory.createTestNotification(disabled: false).toMap();

      final notifTrue = Notifications.fromMap({...mapTrue, 'disabled': 1});
      final notifFalse = Notifications.fromMap({...mapFalse, 'disabled': 0});

      expect(notifTrue.disabled, true);
      expect(notifFalse.disabled, false);
    });

    test('should create copy with updated fields', () {
      final original = TestDataFactory.createTestNotification(
        notificationIndex: 0,
        disabled: false,
      );

      final future = original.notificationDateTime.add(Duration(hours: 2));
      final updated = original.copyWith(
        notificationDateTime: future,
        disabled: true,
      );

      expect(updated.notificationDateTime, future);
      expect(updated.disabled, true);
      expect(updated.notificationIndex, 0); // Unchanged
      expect(updated.id, original.id); // Same ID
    });

    test('should preserve all fields when using copyWith without parameters', () {
      final original = TestDataFactory.createTestNotification();
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.listId, original.listId);
      expect(copy.notificationIndex, original.notificationIndex);
      expect(copy.notificationDateTime, original.notificationDateTime);
      expect(copy.disabled, original.disabled);
    });

    test('should handle future datetime', () {
      final future = DateTime.now().add(Duration(days: 7));
      final notification = TestDataFactory.createTestNotification(
        notificationDateTime: future,
      );

      expect(notification.notificationDateTime.isAfter(DateTime.now()), true);
    });

    test('should handle past datetime (edge case)', () {
      final past = DateTime.now().subtract(Duration(days: 1));
      final notification = TestDataFactory.createTestNotification(
        notificationDateTime: past,
      );

      expect(notification.notificationDateTime.isBefore(DateTime.now()), true);
    });

    test('should handle datetime at midnight', () {
      final midnight = DateTime(2026, 3, 24, 0, 0, 0);
      final notification = TestDataFactory.createTestNotification(
        notificationDateTime: midnight,
      );

      expect(notification.notificationDateTime.hour, 0);
      expect(notification.notificationDateTime.minute, 0);
    });

    test('should handle datetime at end of day', () {
      final endOfDay = DateTime(2026, 3, 24, 23, 59, 59);
      final notification = TestDataFactory.createTestNotification(
        notificationDateTime: endOfDay,
      );

      expect(notification.notificationDateTime.hour, 23);
      expect(notification.notificationDateTime.minute, 59);
    });

    test('should have unique IDs for different notifications', () {
      final notif1 = TestDataFactory.createTestNotification();
      final notif2 = TestDataFactory.createTestNotification();

      expect(notif1.id, isNot(notif2.id));
    });

    test('should be serializable and deserializable', () {
      final original = TestDataFactory.createTestNotification(
        notificationIndex: 2,
        disabled: true,
      );

      final map = original.toMap();
      final restored = Notifications.fromMap(map);

      expect(restored.notificationIndex, original.notificationIndex);
      expect(restored.disabled, original.disabled);
      expect(restored.listId, original.listId);
    });

    test('should handle multiple notifications for same list', () {
      final listId = 'list-1';
      final notif1 = TestDataFactory.createTestNotification(
        listId: listId,
        notificationIndex: 0,
      );
      final notif2 = TestDataFactory.createTestNotification(
        listId: listId,
        notificationIndex: 1,
      );
      final notif3 = TestDataFactory.createTestNotification(
        listId: listId,
        notificationIndex: 2,
      );

      expect(notif1.listId, listId);
      expect(notif2.listId, listId);
      expect(notif3.listId, listId);

      expect(notif1.id, isNot(notif2.id));
      expect(notif2.id, isNot(notif3.id));
    });

    test('should support toggling disabled state', () {
      final notification = TestDataFactory.createTestNotification(disabled: false);

      notification.disabled = true;
      expect(notification.disabled, true);

      notification.disabled = false;
      expect(notification.disabled, false);
    });

    test('should support updating notification time', () {
      final notification = TestDataFactory.createTestNotification();
      final newTime = DateTime.now().add(Duration(hours: 5));

      notification.notificationDateTime = newTime;
      expect(notification.notificationDateTime, newTime);
    });

    test('should format datetime correctly for database', () {
      final notification = TestDataFactory.createTestNotification();
      final map = notification.toMap();
      final dateString = map['notificationDateTime'] as String;

      // Should be in format 'yyyy-MM-dd HH:mm'
      expect(dateString.length, 16); // "2026-03-24 14:30"
      expect(dateString.contains('-'), true);
      expect(dateString.contains(':'), true);
    });

    test('should parse datetime from database format correctly', () {
      final dateString = '2026-03-24 14:30';
      final map = {
        'id': 'notif-1',
        'listId': 'list-1',
        'notificationIndex': 0,
        'notificationDateTime': dateString,
        'disabled': 0,
      };

      final notification = Notifications.fromMap(map);

      expect(notification.notificationDateTime.year, 2026);
      expect(notification.notificationDateTime.month, 3);
      expect(notification.notificationDateTime.day, 24);
      expect(notification.notificationDateTime.hour, 14);
      expect(notification.notificationDateTime.minute, 30);
    });
  });
}
