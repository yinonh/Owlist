// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/mockito.dart';
// import 'package:mockito/annotations.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:flutter_timezone/flutter_timezone.dart';
// import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
// import 'package:shared_preferences/shared_preferences.dart'; // Needed for SharedPreferencesHelper mock
//
// // App classes
// // IMPORTANT: Replace 'task_master' with your actual app name found in pubspec.yaml
// import 'package:task_master/Providers/notification_provider.dart';
// import 'package:task_master/Models/to_do_list.dart';
// import 'package:task_master/Models/notification.dart';
// import 'package:task_master/Utils/keys.dart';
// import 'package:task_master/Utils/notification_time.dart';
// import 'package:task_master/Utils/shared_preferences_helper.dart';
//
// // Mocks generation
// @GenerateMocks([
//   FlutterLocalNotificationsPlugin,
//   AndroidFlutterLocalNotificationsPlugin,
//   Database,
//   SharedPreferences,
// ], customMocks: [
//   MockSpec<SharedPreferencesHelper>(as: #MockSharedPreferencesHelperRelaxed, returnNullOnMissingStub: true),
// ])
// import 'notification_provider_test.mocks.dart'; // Generated file
//
// // Testable version of NotificationProvider (add this to your NotificationProvider class or a test helper)
// // This is a common pattern to allow injecting mocks for testing.
// // Example:
// // class NotificationProvider with ChangeNotifier {
// //   late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
// //   Database? _database;
// //   SharedPreferencesHelper? _sharedPreferencesHelper; // Allow nullable for testing
// //
// //   NotificationProvider() {
// //     _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
// //     _sharedPreferencesHelper = SharedPreferencesHelper.instance;
// //     _initSharedPreferences();
// //   }
// //
// //   // Testable constructor or factory
// //   NotificationProvider.testable({
// //     required FlutterLocalNotificationsPlugin localNotificationsPlugin,
// //     required Database db,
// //     required SharedPreferencesHelper sharedPreferencesHelper,
// //   }) {
// //     _flutterLocalNotificationsPlugin = localNotificationsPlugin;
// //     _database = db;
// //     _sharedPreferencesHelper = sharedPreferencesHelper;
// //     // Call _initSharedPreferences or manually set what it does for tests
// //     _notificationTime = NotificationTime.fromInt(sharedPreferencesHelper.getNotificationTimeBlocking()); // Sync version for test setup
// //     autoNotification = sharedPreferencesHelper.isAutoNotificationBlocking(); // Sync version for test setup
// //   }
// //  // ... rest of your provider
// // }
// // You'll also need sync versions of getNotificationTime() and isAutoNotification() in SharedPreferencesHelper for this example.
//
//
// void main() {
//   late NotificationProvider notificationProvider;
//   late MockFlutterLocalNotificationsPlugin mockLocalNotificationsPlugin;
//   late MockDatabase mockDatabase;
//   late MockSharedPreferencesHelperRelaxed mockSharedPreferencesHelper;
//
//   // Removed MAX_PERIODIC_INSTANCES and PERIODIC_ID_MULTIPLIER
//
//   setUpAll(() async {
//     tz.initializeTimeZones();
//     try {
//       final String timeZoneName = await FlutterTimezone.getLocalTimezone();
//       tz.setLocalLocation(tz.getLocation(timeZoneName));
//     } catch (e) {
//       // Default to a common timezone if platform channels fail in test
//       print("Failed to get local timezone for test, defaulting to UTC: $e");
//       tz.setLocalLocation(tz.getLocation('UTC'));
//     }
//   });
//
//   setUp(() async {
//     mockLocalNotificationsPlugin = MockFlutterLocalNotificationsPlugin();
//     mockDatabase = MockDatabase();
//     // Use the relaxed mock for SharedPreferencesHelper
//     // This assumes SharedPreferencesHelper has been refactored for testability
//     // or its static instance can be manipulated, which is generally not good practice.
//     // The ideal scenario is dependency injection.
//     mockSharedPreferencesHelper = MockSharedPreferencesHelperRelaxed();
//
//     // Default stubs for SharedPreferencesHelper methods
//     // These need to be synchronous for use in the NotificationProvider constructor or initial setup.
//     // This highlights a potential need for refactoring SharedPreferencesHelper or NotificationProvider
//     // to better support synchronous initialization in tests or fully async setup.
//     when(mockSharedPreferencesHelper.getNotificationTime()).thenAnswer((_) async => NotificationTime(hour: 9, minute: 0).toInt());
//     when(mockSharedPreferencesHelper.isAutoNotification()).thenAnswer((_) async => false);
//     when(mockSharedPreferencesHelper.notificationsActive).thenReturn(true); // Getter
//
//     // Simulating the behavior of _initSharedPreferences if called in constructor
//     // For the testable constructor, we'd pass these values directly or mock sync getters in SP Helper
//
//     notificationProvider = NotificationProvider(); // Standard constructor
//     // Manually inject mocks AFTER construction for properties that allow it, or use a testable constructor.
//     // This is less ideal than constructor injection.
//     notificationProvider.flutterLocalNotificationsPlugin = mockLocalNotificationsPlugin; // Assuming public setter or test-only access
//     notificationProvider.databaseTestOverride = mockDatabase; // Assuming a test-only setter for the database
//     notificationProvider.sharedPreferencesHelperTestOverride = mockSharedPreferencesHelper; // Assuming a test-only setter
//
//     // Initialize what _initSharedPreferences would do, now using mocks
//     // This is a workaround if the constructor directly calls async methods on singletons.
//     await notificationProvider.testInitWithMocks( // Create this method in NotificationProvider
//         NotificationTime(hour: 9, minute: 0),
//         false
//     );
//
//
//     when(mockDatabase.query(any, where: anyNamed('where'), whereArgs: anyNamed('whereArgs'), orderBy: anyNamed('orderBy')))
//         .thenAnswer((_) async => []);
//     when(mockDatabase.insert(any, any, conflictAlgorithm: anyNamed('conflictAlgorithm')))
//         .thenAnswer((_) async => 1);
//     when(mockDatabase.update(any, any, where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
//         .thenAnswer((_) async => 1);
//     when(mockDatabase.delete(any, where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
//         .thenAnswer((_) async => 1);
//     when(mockDatabase.rawQuery(any)).thenAnswer((_) async => [{'maxIndex': 0}]);
//
//     when(mockLocalNotificationsPlugin.cancel(any)).thenAnswer((_) async {});
//     when(mockLocalNotificationsPlugin.zonedSchedule(any, any, any, any, any,
//             androidScheduleMode: anyNamed('androidScheduleMode'),
//             uiLocalNotificationDateInterpretation: anyNamed('uiLocalNotificationDateInterpretation'),
//             payload: anyNamed('payload')))
//         .thenAnswer((_) async {});
//     when(mockLocalNotificationsPlugin.periodicallyShow(any, any, any, any, any,
//             androidScheduleMode: anyNamed('androidScheduleMode'),
//             payload: anyNamed('payload')))
//         .thenAnswer((_) async {});
//
//     final mockAndroidImplementation = MockAndroidFlutterLocalNotificationsPlugin();
//     when(mockLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>())
//        .thenReturn(mockAndroidImplementation);
//     when(mockAndroidImplementation.areNotificationsEnabled()).thenAnswer((_) async => true);
//     // No need to call notificationProvider.setUpNotifications() if it's part of testInitWithMocks or constructor
//
//   });
//
//   group('scheduleNotification', () {
//     test('schedules daily periodic notification using periodicallyShow', () async {
//       final list = ToDoList(id: 'list1', title: 'Daily Test List', creationDate: DateTime.now(), deadline: DateTime.now().add(Duration(days: 5)), hasDeadline: true);
//       final notification = Notifications(
//         id: 'notif1',
//         listId: 'list1',
//         notificationIndex: 1,
//         notificationDateTime: DateTime.now(),
//         disabled: false,
//         notificationType: Keys.periodic,
//         periodicInterval: Keys.daily,
//       );
//
//       when(mockDatabase.query('notifications', where: 'listId = ?', whereArgs: [list.id], orderBy: 'notificationDateTime ASC'))
//           .thenAnswer((_) async => [notification.toMap()]);
//
//       await notificationProvider.scheduleNotification(list, 'Test Body');
//
//       // Verify cancel was called for this notification's ID first
//       verify(mockLocalNotificationsPlugin.cancel(notification.notificationIndex)).called(1);
//
//       // Verify periodicallyShow is called once
//       verify(mockLocalNotificationsPlugin.periodicallyShow(
//         notification.notificationIndex,
//         list.title,
//         "Daily reminder for ${list.title}",
//         RepeatInterval.daily,
//         any, // NotificationDetails
//         payload: list.id,
//         androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle
//       )).called(1);
//     });
//
//     test('schedules weekly periodic notification using periodicallyShow', () async {
//       final list = ToDoList(id: 'list2', title: 'Weekly Test List', creationDate: DateTime.now(), deadline: DateTime.now().add(Duration(days: 15)), hasDeadline: true);
//       final notification = Notifications(
//         id: 'notif2',
//         listId: 'list2',
//         notificationIndex: 2,
//         notificationDateTime: DateTime.now(),
//         disabled: false,
//         notificationType: Keys.periodic,
//         periodicInterval: Keys.weekly,
//       );
//
//       when(mockDatabase.query('notifications', where: 'listId = ?', whereArgs: [list.id], orderBy: 'notificationDateTime ASC'))
//           .thenAnswer((_) async => [notification.toMap()]);
//
//       await notificationProvider.scheduleNotification(list, 'Test Body');
//
//       verify(mockLocalNotificationsPlugin.cancel(notification.notificationIndex)).called(1);
//
//       verify(mockLocalNotificationsPlugin.periodicallyShow(
//         notification.notificationIndex,
//         list.title,
//         "Weekly reminder for ${list.title}",
//         RepeatInterval.weekly,
//         any,
//         payload: list.id,
//         androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle
//       )).called(1);
//     });
//
//     test('does NOT schedule periodic notification if deadline has passed', () async {
//       final list = ToDoList(id: 'list3', title: 'Past Deadline List', creationDate: DateTime.now(), deadline: DateTime.now().subtract(Duration(days: 1)), hasDeadline: true);
//       final notification = Notifications(
//         id: 'notif3',
//         listId: 'list3',
//         notificationIndex: 3,
//         notificationDateTime: DateTime.now().subtract(Duration(days:2)), // Anchor date in past
//         disabled: false, // Initially not disabled
//         notificationType: Keys.periodic,
//         periodicInterval: Keys.daily,
//       );
//
//       when(mockDatabase.query('notifications', where: 'listId = ?', whereArgs: [list.id], orderBy: 'notificationDateTime ASC'))
//           .thenAnswer((_) async => [notification.toMap()]);
//       // Mock update for toggleNotificationDisabled
//       when(mockDatabase.update('notifications', any, where: 'id = ?', whereArgs: [notification.id])).thenAnswer((_) async => 1);
//
//       await notificationProvider.scheduleNotification(list, 'Test Body');
//
//       verify(mockLocalNotificationsPlugin.cancel(notification.notificationIndex)).called(1);
//       verifyNever(mockLocalNotificationsPlugin.periodicallyShow(any, any, any, any, any, payload: anyNamed('payload'), androidScheduleMode: anyNamed('androidScheduleMode')));
//       verify(mockDatabase.update('notifications', argThat(containsPair(Keys.disabled, 1)), where: 'id = ?', whereArgs: [notification.id])).called(1);
//     });
//
//     test('schedules fixed notification using zonedSchedule', () async {
//       final fixedTime = DateTime.now().add(Duration(hours: 2));
//       final list = ToDoList(id: 'list4', title: 'Fixed Test List', creationDate: DateTime.now(), deadline: DateTime.now().add(Duration(days:1)), hasDeadline: true);
//       final notification = Notifications(
//         id: 'notif4',
//         listId: 'list4',
//         notificationIndex: 4,
//         notificationDateTime: fixedTime,
//         disabled: false,
//         notificationType: Keys.fixed,
//       );
//       when(mockDatabase.query('notifications', where: 'listId = ?', whereArgs: [list.id], orderBy: 'notificationDateTime ASC'))
//           .thenAnswer((_) async => [notification.toMap()]);
//
//       await notificationProvider.scheduleNotification(list, 'Fixed Body');
//
//       verify(mockLocalNotificationsPlugin.cancel(notification.notificationIndex)).called(1);
//       verify(mockLocalNotificationsPlugin.zonedSchedule(
//         notification.notificationIndex,
//         list.title,
//         'Fixed Body',
//         argThat(isA<tz.TZDateTime>().having((dt) => dt.proches(fixedTime, Duration(seconds:1)), 'time', true)),
//         any, // NotificationDetails
//         payload: list.id,
//         androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//         uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime
//       )).called(1);
//     });
//   });
//
//   group('addNotification', () {
//     test('adding periodic notification clears existing fixed and other periodic notifications', () async {
//       final list = ToDoList(id: 'listADD1', title: 'Add Test List', creationDate: DateTime.now(), deadline: DateTime.now().add(const Duration(days: 30)), hasDeadline: true);
//       final fixedNotif = Notifications(id: 'fixAdd', listId: list.id, notificationIndex: 100, notificationDateTime: DateTime.now().add(const Duration(days:1)), disabled: false, notificationType: Keys.fixed);
//       final existingPeriodic = Notifications(id: 'perAddOld', listId: list.id, notificationIndex: 101, notificationDateTime: DateTime.now().add(const Duration(days:2)), disabled: false, notificationType: Keys.periodic, periodicInterval: Keys.daily);
//
//       // Mock for getNotificationsByListId called inside addNotification
//       when(mockDatabase.query('notifications', where: 'listId = ?', whereArgs: [list.id], orderBy: 'notificationDateTime ASC'))
//           .thenAnswer((_) async => [fixedNotif.toMap(), existingPeriodic.toMap()]);
//
//       when(mockDatabase.rawQuery('SELECT MAX(notificationIndex) as maxIndex FROM notifications')).thenAnswer((_) async => [{'maxIndex': 101}]);
//       // Mock for scheduleNotification's call to getNotificationsByListId (should be empty after adds/deletes)
//       // For simplicity in this specific test, assume scheduleNotification won't find anything to schedule *after* these ops.
//       // A more robust mock would return the newly added notification.
//       when(notificationProvider.getNotificationsByListId(list.id)).thenAnswer((_) async => []);
//
//
//       await notificationProvider.addNotification(list, DateTime.now(), 'New Periodic Text', Keys.periodic, Keys.weekly);
//
//       // Verify fixed one was disabled (updated)
//       verify(mockDatabase.update('notifications', argThat(allOf(
//           containsPair(Keys.disabled, 1),
//           containsPair(Keys.id, fixedNotif.id)
//       )), where: 'id = ?', whereArgs: [fixedNotif.id])).called(1);
//       verify(mockLocalNotificationsPlugin.cancel(fixedNotif.notificationIndex)).called(1);
//
//       // Verify existing periodic was deleted
//       verify(mockDatabase.delete('notifications', where: 'id = ?', whereArgs: [existingPeriodic.id])).called(1);
//       verify(mockLocalNotificationsPlugin.cancel(existingPeriodic.notificationIndex)).called(1);
//
//       // Verify new periodic was inserted
//       verify(mockDatabase.insert('notifications', argThat(allOf(
//           containsPair(Keys.notificationType, Keys.periodic),
//           containsPair(Keys.periodicInterval, Keys.weekly),
//           containsPair(Keys.listId, list.id)
//       )), conflictAlgorithm: ConflictAlgorithm.replace)).called(1);
//     });
//
//      test('adding fixed notification clears existing periodic notification', () async {
//       final list = ToDoList(id: 'listADD2', title: 'Add Fixed Test', creationDate: DateTime.now(), deadline: DateTime.now().add(const Duration(days: 30)), hasDeadline: true);
//       final existingPeriodic = Notifications(id: 'perAddOld2', listId: list.id, notificationIndex: 201, notificationDateTime: DateTime.now().add(const Duration(days:2)), disabled: false, notificationType: Keys.periodic, periodicInterval: Keys.daily);
//
//       when(mockDatabase.query('notifications', where: 'listId = ?', whereArgs: [list.id], orderBy: 'notificationDateTime ASC'))
//           .thenAnswer((_) async => [existingPeriodic.toMap()]);
//       when(mockDatabase.rawQuery('SELECT MAX(notificationIndex) as maxIndex FROM notifications')).thenAnswer((_) async => [{'maxIndex': 201}]);
//       when(notificationProvider.getNotificationsByListId(list.id)).thenAnswer((_) async => []);
//
//
//       await notificationProvider.addNotification(list, DateTime.now().add(Duration(days:3)), 'New Fixed Text', Keys.fixed, null);
//
//       verify(mockDatabase.delete('notifications', where: 'id = ?', whereArgs: [existingPeriodic.id])).called(1);
//       verify(mockLocalNotificationsPlugin.cancel(existingPeriodic.notificationIndex)).called(1);
//
//       verify(mockDatabase.insert('notifications', argThat(allOf(
//           containsPair(Keys.notificationType, Keys.fixed),
//           containsPair(Keys.listId, list.id)
//       )), conflictAlgorithm: ConflictAlgorithm.replace)).called(1);
//     });
//   });
//
//   group('deleteNotification', () {
//     test('deletes notification from DB and cancels OS notification', () async {
//         final list = ToDoList(id: 'listDel1', title: 'Delete Test', creationDate: DateTime.now(), deadline: DateTime.now().add(const Duration(days: 5)), hasDeadline: true);
//         final notificationToDel = Notifications(id: 'notDel1', listId: list.id, notificationIndex: 301, notificationDateTime: DateTime.now().add(Duration(days:1)), disabled: false, notificationType: Keys.fixed);
//
//         when(notificationProvider.getNotificationsByListId(list.id)).thenAnswer((_) async => []); // Assume no other notifs for simplicity
//
//         await notificationProvider.deleteNotification(notificationToDel, list);
//
//         verify(mockDatabase.delete('notifications', where: 'id = ?', whereArgs: [notificationToDel.id])).called(1);
//         verify(mockLocalNotificationsPlugin.cancel(notificationToDel.notificationIndex)).called(1);
//         // verify scheduleNotification was called (which will find nothing to schedule in this simplified case)
//         verify(notificationProvider.scheduleNotification(list, any)).called(1);
//     });
//   });
//
//   group('toggleNotificationDisabled', () {
//     test('disabling a notification cancels OS notification', () async {
//       final list = ToDoList(id: 'listToggle1', title: 'Toggle Test', creationDate: DateTime.now(), deadline: DateTime.now().add(const Duration(days: 5)), hasDeadline: true);
//       final notifToDisable = Notifications(id: 'notToggle1', listId: list.id, notificationIndex: 401, notificationDateTime: DateTime.now().add(Duration(days:1)), disabled: false, notificationType: Keys.fixed);
//
//       await notificationProvider.toggleNotificationDisabled(notifToDisable, list); // Toggle to disabled
//
//       verify(mockDatabase.update('notifications', argThat(containsPair(Keys.disabled, 1)), where: 'id = ?', whereArgs: [notifToDisable.id])).called(1);
//       verify(mockLocalNotificationsPlugin.cancel(notifToDisable.notificationIndex)).called(1);
//       verifyNever(notificationProvider.scheduleNotification(list, any)); // scheduleNotification should not be called when only disabling
//     });
//
//     test('enabling a notification calls scheduleNotification', () async {
//       final list = ToDoList(id: 'listToggle2', title: 'Toggle Enable Test', creationDate: DateTime.now(), deadline: DateTime.now().add(const Duration(days: 5)), hasDeadline: true);
//       final notifToEnable = Notifications(id: 'notToggle2', listId: list.id, notificationIndex: 402, notificationDateTime: DateTime.now().add(Duration(days:1)), disabled: true, notificationType: Keys.fixed);
//
//       // Mock for scheduleNotification's call to getNotificationsByListId
//       when(mockDatabase.query('notifications', where: 'listId = ?', whereArgs: [list.id], orderBy: 'notificationDateTime ASC'))
//           .thenAnswer((_) async => [notifToEnable.toMap()..update(Keys.disabled, (v) => 0)]); // Reflects enabled state
//
//       await notificationProvider.toggleNotificationDisabled(notifToEnable, list); // Toggle to enabled
//
//       verify(mockDatabase.update('notifications', argThat(containsPair(Keys.disabled, 0)), where: 'id = ?', whereArgs: [notifToEnable.id])).called(1);
//       verify(notificationProvider.scheduleNotification(list, any)).called(1);
//     });
//
//      test('forceDisable a notification cancels OS notification and updates DB', () async {
//       final list = ToDoList(id: 'listToggle3', title: 'Force Disable Test', creationDate: DateTime.now(), deadline: DateTime.now().add(const Duration(days: 5)), hasDeadline: true);
//       final notifToForceDisable = Notifications(id: 'notToggle3', listId: list.id, notificationIndex: 403, notificationDateTime: DateTime.now().add(Duration(days:1)), disabled: false, notificationType: Keys.fixed);
//
//       await notificationProvider.toggleNotificationDisabled(notifToForceDisable, list, forceDisable: true);
//
//       verify(mockDatabase.update('notifications', argThat(containsPair(Keys.disabled, 1)), where: 'id = ?', whereArgs: [notifToForceDisable.id])).called(1);
//       verify(mockLocalNotificationsPlugin.cancel(notifToForceDisable.notificationIndex)).called(1);
//       verifyNever(notificationProvider.scheduleNotification(list, any));
//     });
//   });
//
// }
//
// extension TZDateTimeMatcher on tz.TZDateTime {
//   bool proches(DateTime other, Duration tolerance) {
//     final difference = this.toUtc().difference(other.toUtc()).abs();
//     return difference <= tolerance;
//   }
// }
//
// // To make NotificationProvider more easily testable, consider these refactors:
// // 1. Dependency Injection: Pass dependencies (FlutterLocalNotificationsPlugin, Database, SharedPreferencesHelper)
// //    via the constructor. This is the cleanest way.
// // 2. Service Locator: Use a service locator pattern (like `get_it`) to register mocks during tests.
// // 3. Test-specific initializers or setters:
// //    - A method like `NotificationProvider.testInitWithMocks(NotificationTime time, bool autoNotif)`
// //      that can synchronously set up the provider's internal state related to SharedPreferences.
// //    - Public setters for `_flutterLocalNotificationsPlugin` and `_database` that are only used in tests.
// //      (e.g., `notificationProvider.databaseTestOverride = mockDatabase;`)
// //
// // For SharedPreferencesHelper, if it's a true singleton (`SharedPreferencesHelper.instance = ...`),
// // you might be able to set `SharedPreferencesHelper.instance = MockSharedPreferencesHelperRelaxed()` in setUp.
// // But if `instance` is a final field initialized directly, this isn't possible without code changes.
// //
// // The current test file uses property overrides and a custom testInitWithMocks method as a pragmatic approach
// // assuming minor refactoring in NotificationProvider for testability.
// // e.g. in NotificationProvider:
// //   FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
// //   set flutterLocalNotificationsPlugin(FlutterLocalNotificationsPlugin p) => _flutterLocalNotificationsPlugin = p; // for test
// //   Database? _database;
// //   set databaseTestOverride(Database db) => _database = db; // for test
// //   SharedPreferencesHelper? _sharedPreferencesHelperInstance; // Use this instead of direct SharedPreferencesHelper.instance
// //   SharedPreferencesHelper get _spHelper => _sharedPreferencesHelperInstance ?? SharedPreferencesHelper.instance;
// //   set sharedPreferencesHelperTestOverride(SharedPreferencesHelper sph) => _sharedPreferencesHelperInstance = sph; // for test
// //
// //   Future<void> testInitWithMocks(NotificationTime time, bool isAuto) async {
// //     _notificationTime = time;
// //     autoNotification = isAuto;
// //     // No need to call SharedPreferences if values are passed in.
// //     await setUpNotifications(); // Still need this for FLN plugin setup
// //   }
// //
// // Remember to replace 'task_master' with your actual project name in the imports.
