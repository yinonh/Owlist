import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import '../Models/notification.dart';
import '../Models/to_do_list.dart';
import '../Screens/single_list_screen.dart';
import '../Utils/keys.dart';
import '../Utils/notification_time.dart';
import '../Utils/shared_preferences_helper.dart';
import '../main.dart';

class NotificationProvider with ChangeNotifier {
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _notificationsEnabled = false;
  late NotificationTime _notificationTime;
  late bool autoNotification;
  Database? _database;

  // late BuildContext context;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  initDB() async {
    return await sql.openDatabase(
      path.join(await sql.getDatabasesPath(), Keys.toDoTable),
      version: int.parse(dotenv.env['DBVERSION']!),
    );
  }

  FlutterLocalNotificationsPlugin get flutterLocalNotificationsPlugin =>
      _flutterLocalNotificationsPlugin;

  bool get notificationsEnabled => _notificationsEnabled;

  NotificationTime get notificationTime => _notificationTime;

  NotificationProvider() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    int storedTime =
        await SharedPreferencesHelper.instance.getNotificationTime();
    _notificationTime = NotificationTime.fromInt(storedTime);
    autoNotification =
        await SharedPreferencesHelper.instance.isAutoNotification();
    notifyListeners();
  }

  Future<void> saveNotificationTimeToPrefs(NotificationTime time) async {
    _notificationTime = time;
    await SharedPreferencesHelper.instance.setNotificationTime(time.toInt());
    notifyListeners();
  }

  Future<void> saveActive(bool isActive) async {
    if (!isActive) {
      cancelAllNotifications();
    }
    SharedPreferencesHelper.instance.notificationsActive = isActive;
    notifyListeners();
  }

  Future<void> saveAutoNotification(bool autoNotification) async {
    this.autoNotification = autoNotification;
    await SharedPreferencesHelper.instance
        .setAutoNotification(autoNotification);
    notifyListeners();
  }

  static onDidReceiveBackgroundNotificationResponse(
      NotificationResponse response) {
    navigatorKey.currentState?.popUntil((route) => true);
    navigatorKey.currentState
        ?.pushNamed(SingleListScreen.routeName, arguments: response.payload);
  }

  static onDidReceiveNotificationResponse(NotificationResponse response) {
    navigatorKey.currentState?.popUntil((route) => true);
    navigatorKey.currentState
        ?.pushNamed(SingleListScreen.routeName, arguments: response.payload);
  }

  Future<void> setUpNotifications() async {
    // this.context = context;
    await _configureLocalTimeZone();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(Keys.appIcon);

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveBackgroundNotificationResponse,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  Future<bool> isAndroidPermissionGranted() async {
    _notificationsEnabled = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled() ??
        false;
    notifyListeners();

    return _notificationsEnabled;
  }

  Future<void> requestPermissions([bool? toActive]) async {
    if (SharedPreferencesHelper.instance.notificationsActive ||
        (toActive ?? false)) {
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
      notifyListeners();
    }
  }

  Future<bool> addNotificationDayBeforeDeadline(
      ToDoList list, String notificationText) async {
    if (!SharedPreferencesHelper.instance.notificationsActive ||
        !autoNotification) return false;
    final deadline = list.deadline.subtract(const Duration(days: 1));
    final tz.TZDateTime scheduledTime = tz.TZDateTime(
      tz.local,
      deadline.year,
      deadline.month,
      deadline.day,
      // Hour
      _notificationTime.hour,
      // Minute
      _notificationTime.minute,
    );

    // For auto-deadline notifications, they are always 'fixed'.
    return addNotification(
        list, scheduledTime, notificationText, Keys.fixed, null);
  }

  Future<bool> addNotification(ToDoList list, DateTime notificationDateTime,
      [String? notificationText,
      String notificationType = Keys.fixed,
      String? periodicInterval]) async {
    if (!SharedPreferencesHelper.instance.notificationsActive) return false;

    final Database db = await database;
    List<Notifications> existingNotifications =
        await getNotificationsByListId(list.id);

    if (notificationType == Keys.periodic) {
      // Handle periodic notification - remove existing periodic and disable fixed
      for (var existingNotification in existingNotifications) {
        // Cancel OS notification regardless of type before DB changes
        await _flutterLocalNotificationsPlugin
            .cancel(existingNotification.notificationIndex);

        if (existingNotification.notificationType == Keys.periodic) {
          // Delete any old periodic notification
          await db.delete('notifications',
              where: 'id = ?', whereArgs: [existingNotification.id]);
        } else {
          // Disable fixed notifications (don't delete them)
          existingNotification.disabled = true;
          await db.update('notifications', existingNotification.toMap(),
              where: 'id = ?', whereArgs: [existingNotification.id]);
        }
      }
    } else if (notificationType == Keys.fixed) {
      // Handle fixed notification - remove periodic and check fixed limit

      // First, check if we're at the limit for fixed notifications
      List<Notifications> fixedNotifications = existingNotifications
          .where((n) => n.notificationType != Keys.periodic)
          .toList();

      if (fixedNotifications.length >= 4) {
        // Return false or throw an exception to indicate limit reached
        throw Exception("Fixed notifications limit reached (4 max)");
      }

      // Find and remove periodic notification if it exists
      Notifications? periodicNotification;
      try {
        periodicNotification = existingNotifications.firstWhere(
          (n) => n.notificationType == Keys.periodic,
        );
      } catch (e) {
        // No periodic notification found, which is fine
        periodicNotification = null;
      }

      if (periodicNotification != null) {
        await _flutterLocalNotificationsPlugin
            .cancel(periodicNotification.notificationIndex);
        await db.delete('notifications',
            where: 'id = ?', whereArgs: [periodicNotification.id]);
      }
    }

    // Determine if the notification should be immediately disabled
    bool disabled = false;
    if (notificationType == Keys.fixed) {
      disabled = notificationDateTime.isBefore(DateTime.now());
    }

    final List<Map<String, dynamic>> snapshot = await db.rawQuery(
        'SELECT MAX(notificationIndex) as maxIndex FROM notifications');

    int notificationIndex = (snapshot[0]['maxIndex'] as int? ?? 0) + 1;

    final Notifications notification = Notifications(
      id: const Uuid().v4(),
      listId: list.id,
      notificationIndex: notificationIndex,
      notificationDateTime: notificationDateTime,
      disabled: disabled,
      notificationType: notificationType,
      periodicInterval: periodicInterval,
    );

    await db.insert(
      'notifications',
      notification.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return scheduleNotification(list, notificationText);
  }

  Future<bool> editNotification(Notifications notification, ToDoList list,
      [String? notificationText]) async {
    final db = await database;

    // If it's a fixed notification, and date is changed to past, it should be disabled.
    if (notification.notificationType == Keys.fixed ||
        notification.notificationType == null) {
      notification.disabled =
          notification.notificationDateTime.isBefore(DateTime.now());
    } else {
      // For periodic notifications, 'disabled' might be toggled directly via toggleNotificationDisabled.
      // Editing date for periodic is more like changing its anchor, not typically making it "disabled" unless explicitly set.
    }

    await db.update(
      'notifications',
      notification.toMap(),
      where: 'id = ?',
      whereArgs: [notification.id],
    );
    return await scheduleNotification(
        list, notificationText); // Ensure await here
  }

  Future<bool> deleteNotification(
      Notifications notification, ToDoList list) async {
    final db = await database;
    await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [notification.id],
    );
    // Explicitly cancel the OS notification.
    await _flutterLocalNotificationsPlugin
        .cancel(notification.notificationIndex);
    // Reschedule remaining notifications for the list (if any)
    return await scheduleNotification(list); // Ensure await here
  }

  Future<List<Notifications>> getNotificationsByListId(String listId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notifications',
      where: 'listId = ?',
      whereArgs: [listId],
      orderBy: 'notificationDateTime ASC', // Added for consistency
    );
    return List.generate(maps.length, (i) {
      // This fromMap will now correctly populate notificationType and periodicInterval
      return Notifications.fromMap(maps[i]);
    });
  }

  Future<void> toggleNotificationDisabled(
      Notifications notification, ToDoList list,
      {bool forceDisable = false}) async {
    final db = await database;
    bool originalDisabledState = notification.disabled;

    if (forceDisable) {
      notification.disabled = true;
    } else {
      // Regular toggle, but don't allow enabling if global notifications are off
      if (notification
              .disabled && // If trying to enable (current state is disabled)
          !SharedPreferencesHelper.instance.notificationsActive) {
        // Show user feedback that global notifications are disabled
        return;
      }
      notification.disabled = !notification.disabled;
    }

    if (originalDisabledState == notification.disabled && !forceDisable) {
      // No change in state, and not forced, so no need to update DB or reschedule.
      return;
    }

    // Update ONLY the disabled field to avoid changing other properties
    await db.update(
      'notifications',
      {'disabled': notification.disabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [notification.id],
    );

    if (notification.disabled) {
      // If it's now disabled, cancel its OS notification.
      await _flutterLocalNotificationsPlugin
          .cancel(notification.notificationIndex);
    }

    // Always reschedule all notifications for the list to ensure consistency
    // This prevents notifications from "moving" between types
    await scheduleNotification(list);

    notifyListeners();
  }

  // disableNotificationById can be removed if toggleNotificationDisabled with forceDisable=true covers its use case.
  // For now, let's assume it's still used or keep it.
  Future<void> disableNotificationById(
      Notifications notification, ToDoList list) async {
    await toggleNotificationDisabled(notification, list, forceDisable: true);
  }

  Future<bool> cancelNotification(int notificationID) async {
    await flutterLocalNotificationsPlugin.cancel(notificationID);
    return true;
  }

  Future<void> cancelAllNotifications() async {
    final db = await database;
    await db.update(
      'notifications',
      {'disabled': true},
    );
    await flutterLocalNotificationsPlugin.cancelAll();
    notifyListeners(); // Added notifyListeners here as it was in the original prompt for cancelAllNotifications
  }

  Future<bool> scheduleNotification(ToDoList list,
      [String? notificationText]) async {
    if (!SharedPreferencesHelper.instance.notificationsActive) return false;

    List<Notifications> dbNotifications =
        await getNotificationsByListId(list.id);
    bool notificationScheduled = false;

    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    final tz.Location heritageLocation =
        tz.getLocation(currentTimeZone); // Ensure tz is initialized

    for (var notification in dbNotifications) {
      // Always cancel previous OS notification before potentially rescheduling
      await _flutterLocalNotificationsPlugin
          .cancel(notification.notificationIndex);

      if (notification.disabled) {
        continue;
      }

      // Deadline check for all active notifications
      if (list.hasDeadline && list.deadline.isBefore(DateTime.now())) {
        // If deadline has passed, ensure notification is marked as disabled in DB and skip scheduling
        if (!notification.disabled) {
          // Avoid redundant DB updates
          await toggleNotificationDisabled(notification, list,
              forceDisable: true); // Add a way to force disable
        }
        continue;
      }

      String title = list.title;
      String body = notificationText ??
          ''; // Default body, might need adjustment per type

      if (notification.notificationType == Keys.periodic) {
        RepeatInterval? interval;
        if (notification.periodicInterval == Keys.daily) {
          interval = RepeatInterval.daily;
          body = "Daily reminder for ${list.title}";
        } else if (notification.periodicInterval == Keys.weekly) {
          interval = RepeatInterval.weekly;
          body = "Weekly reminder for ${list.title}";
        } else {
          // Monthly or other unsupported periodic types are no longer actively scheduled here
          continue;
        }

        // For periodicallyShow, the time component of notification.notificationDateTime is used.
        // The date part is less critical as it just needs to be a valid TZDateTime.
        // We'll use the user's preferred time for consistency, applied to today's date for the anchor.
        final scheduledTime = tz.TZDateTime(
            heritageLocation,
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            _notificationTime.hour, // User's preferred hour
            _notificationTime.minute // User's preferred minute
            );

        // If list has a deadline, and that deadline is BEFORE the first scheduled time, don't schedule.
        // This specific check might be redundant if the general deadline check above works,
        // but good for an edge case where preferred time today is already past deadline today.
        if (list.hasDeadline && list.deadline.isBefore(scheduledTime)) {
          if (!notification.disabled) {
            await toggleNotificationDisabled(notification, list,
                forceDisable: true);
          }
          continue;
        }

        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
          Keys.mainChannelId, // Use a consistent channel ID
          Keys.mainChannelName,
          channelDescription: Keys
              .mainChannelDescription, // Optional: can be simpler for periodic
          channelShowBadge: false,
        );
        const NotificationDetails platformDetails =
            NotificationDetails(android: androidDetails);

        try {
          await _flutterLocalNotificationsPlugin.periodicallyShow(
            notification.notificationIndex,
            title,
            body,
            interval,
            platformDetails,
            payload: list.id,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
          notificationScheduled = true;
        } catch (e) {
          print(
              "Error scheduling periodic notification with periodicallyShow: $e");
        }
      } else {
        // Fixed notification (notification.notificationType == Keys.fixed or null)
        if (notification.notificationDateTime.isBefore(DateTime.now())) {
          // Fixed notification is in the past
          if (!notification.disabled) {
            // Avoid redundant DB updates
            await toggleNotificationDisabled(notification, list,
                forceDisable: true);
          }
          continue;
        }

        body = notificationText ?? ''; // Use provided text or default for fixed
        if (!list.hasDeadline) {
          body = '';
        } // Original logic for fixed

        try {
          await _flutterLocalNotificationsPlugin.zonedSchedule(
            notification.notificationIndex,
            title,
            body,
            tz.TZDateTime.from(
                notification.notificationDateTime, heritageLocation),
            const NotificationDetails(
              android: AndroidNotificationDetails(
                Keys.mainChannelId,
                Keys.mainChannelName,
                channelDescription: Keys.mainChannelDescription,
                channelShowBadge: false,
              ),
            ),
            payload: list.id,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          notificationScheduled = true;
        } catch (e) {
          print("Error scheduling fixed notification: $e");
        }
      }
    }
    notifyListeners();
    return notificationScheduled;
  }
}
