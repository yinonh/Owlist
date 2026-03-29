import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:to_do/Providers/notification_provider.dart';
import 'package:to_do/Utils/keys.dart';
import 'package:to_do/Utils/notification_time.dart';
import 'package:to_do/Utils/shared_preferences_helper.dart';
import '../../fixtures/mock_database.dart';
import '../../fixtures/test_data.dart';

void main() {
  late NotificationProvider provider;

  final futureDate = DateTime(2026, 12, 25);

  // Helper: run action and swallow MissingPluginException from platform channel
  Future<void> runSwallowingPlugin(Future<void> Function() action) async {
    final completer = Completer<void>();
    runZonedGuarded(() async {
      await action();
      if (!completer.isCompleted) completer.complete();
    }, (e, _) {
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
  }

  // Helper: set up provider with both guards ON (happy path).
  // Also explicitly sets _notificationTime via saveNotificationTimeToPrefs to
  // avoid a LateInitializationError from the async _initSharedPreferences().
  Future<void> setUpActiveProvider({int notificationTime = 120000}) async {
    SharedPreferences.setMockInitialValues({
      Keys.notificationActive: true,
      Keys.autoNotification: true,
      Keys.notificationTime: notificationTime,
    });
    await SharedPreferencesHelper.instance.initialise();

    // Initialize timezone data so tz.TZDateTime(tz.local, ...) doesn't throw.
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));

    final testDb = await TestDatabaseHelper.getTestDatabase();
    provider = NotificationProvider(database: testDb);
    provider.autoNotification = true;
    // Directly initialize _notificationTime so the late field is ready before
    // addNotificationDayBeforeDeadline accesses it.
    await provider.saveNotificationTimeToPrefs(NotificationTime.fromInt(notificationTime));
  }

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
  });

  setUp(() async {
    // Default: both guards OFF — safe baseline
    SharedPreferences.setMockInitialValues({
      Keys.notificationActive: false,
      Keys.autoNotification: false,
    });
    await SharedPreferencesHelper.instance.initialise();

    final testDb = await TestDatabaseHelper.getTestDatabase();
    provider = NotificationProvider(database: testDb);
    provider.autoNotification = false;
  });

  tearDown(() async {
    await TestDatabaseHelper.clearAllTables();
    await TestDatabaseHelper.closeTestDatabase();
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('NotificationProvider - addNotificationDayBeforeDeadline - guards', () {
    test('returns false and inserts nothing when notificationsActive=false', () async {
      final list = TestDataFactory.createTestList(
        id: 'list-1', hasDeadline: true, deadline: futureDate,
      );

      final result =
          await provider.addNotificationDayBeforeDeadline(list, 'Reminder');

      expect(result, false);
      final notifs = await provider.getNotificationsByListId('list-1');
      expect(notifs, isEmpty);
    });

    test('returns false and inserts nothing when autoNotification=false', () async {
      // notificationsActive=true but autoNotification=false
      SharedPreferences.setMockInitialValues({Keys.notificationActive: true});
      await SharedPreferencesHelper.instance.initialise();
      final testDb = await TestDatabaseHelper.getTestDatabase();
      provider = NotificationProvider(database: testDb);
      provider.autoNotification = false;

      final list = TestDataFactory.createTestList(
        id: 'list-1', hasDeadline: true, deadline: futureDate,
      );

      final result =
          await provider.addNotificationDayBeforeDeadline(list, 'Reminder');

      expect(result, false);
      final notifs = await provider.getNotificationsByListId('list-1');
      expect(notifs, isEmpty);
    });

    test('returns false and inserts nothing when both guards are off', () async {
      final list = TestDataFactory.createTestList(
        id: 'list-1', hasDeadline: true, deadline: futureDate,
      );

      final result =
          await provider.addNotificationDayBeforeDeadline(list, 'Reminder');

      expect(result, false);
      final notifs = await provider.getNotificationsByListId('list-1');
      expect(notifs, isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('NotificationProvider - addNotificationDayBeforeDeadline - happy path', () {
    test('inserts a notification scheduled one day before the deadline', () async {
      await setUpActiveProvider();
      final list = TestDataFactory.createTestList(
        id: 'list-1', hasDeadline: true, deadline: futureDate, // 2026-12-25
      );

      await runSwallowingPlugin(() async {
        await provider.addNotificationDayBeforeDeadline(list, 'Reminder');
      });

      final notifs = await provider.getNotificationsByListId('list-1');
      expect(notifs.length, 1);
      // Scheduled for Dec 24 (deadline - 1 day)
      expect(notifs.first.notificationDateTime.year, 2026);
      expect(notifs.first.notificationDateTime.month, 12);
      expect(notifs.first.notificationDateTime.day, 24);
      expect(notifs.first.listId, 'list-1');
    });

    test('notification is disabled=false when scheduled time is in the future', () async {
      await setUpActiveProvider();
      final list = TestDataFactory.createTestList(
        id: 'list-1', hasDeadline: true, deadline: futureDate, // 2026-12-25 → scheduled 2026-12-24
      );

      await runSwallowingPlugin(() async {
        await provider.addNotificationDayBeforeDeadline(list, 'Reminder');
      });

      final notifs = await provider.getNotificationsByListId('list-1');
      expect(notifs.first.disabled, false);
    });

    test('notification is disabled=true when scheduled time is in the past', () async {
      await setUpActiveProvider();
      // deadline=2026-03-27 → scheduled for 2026-03-26, which is before today (2026-03-28)
      final list = TestDataFactory.createTestList(
        id: 'list-1', hasDeadline: true, deadline: DateTime(2026, 3, 27),
      );

      await runSwallowingPlugin(() async {
        await provider.addNotificationDayBeforeDeadline(list, 'Reminder');
      });

      final notifs = await provider.getNotificationsByListId('list-1');
      expect(notifs.first.disabled, true);
    });

    test('notification time reflects stored notificationTime preference', () async {
      // 90000 encodes 09:00 (9 * 10000 = 90000)
      await setUpActiveProvider(notificationTime: 90000);
      final list = TestDataFactory.createTestList(
        id: 'list-1', hasDeadline: true, deadline: futureDate,
      );

      await runSwallowingPlugin(() async {
        await provider.addNotificationDayBeforeDeadline(list, 'Reminder');
      });

      final notifs = await provider.getNotificationsByListId('list-1');
      expect(notifs.first.notificationDateTime.hour, 9);
      expect(notifs.first.notificationDateTime.minute, 0);
    });

    test('second call creates a second row with a unique notification index', () async {
      await setUpActiveProvider();
      final list = TestDataFactory.createTestList(
        id: 'list-1', hasDeadline: true, deadline: futureDate,
      );

      await runSwallowingPlugin(() async {
        await provider.addNotificationDayBeforeDeadline(list, 'First');
      });
      await runSwallowingPlugin(() async {
        await provider.addNotificationDayBeforeDeadline(list, 'Second');
      });

      final notifs = await provider.getNotificationsByListId('list-1');
      expect(notifs.length, 2);
      final indices = notifs.map((n) => n.notificationIndex).toSet();
      expect(indices.length, 2); // All notification indices are unique
    });
  });
}
