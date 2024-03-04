import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';
import 'package:path/path.dart' as path;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:uuid/uuid.dart';
import 'dart:math';

import '../Models/notification.dart';
import '../Utils/shared_preferences_helper.dart';
import '../Utils/strings.dart';
import '../Utils/notification_time.dart';
import '../Models/to_do_list.dart';

class NotificationProvider with ChangeNotifier {
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _notificationsEnabled = false;

  // late SharedPreferences _prefs;
  late NotificationTime _notificationTime;
  late bool isActive;
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  initDB() async {
    return await sql.openDatabase(
      path.join(await sql.getDatabasesPath(), 'to_do.db'),
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
    isActive = await SharedPreferencesHelper.instance.isNotificationActive();

    notifyListeners();
  }

  Future<void> saveNotificationTimeToPrefs(NotificationTime time) async {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    _notificationTime = time;
    await SharedPreferencesHelper.instance.setNotificationTime(time.toInt());
    notifyListeners();
  }

  Future<void> saveActive(bool isActive) async {
    this.isActive = isActive;
    await SharedPreferencesHelper.instance.setNotificationStatus(isActive);
    notifyListeners();
  }

  Future<void> setUpNotifications() async {
    await _configureLocalTimeZone();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  Future<void> isAndroidPermissionGranted() async {
    final bool granted = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled() ??
        false;

    _notificationsEnabled = granted;
    notifyListeners();
  }

  Future<void> requestPermissions() async {
    if (isActive) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedNotificationPermission =
          await androidImplementation?.requestPermission();

      _notificationsEnabled = grantedNotificationPermission ?? false;
      notifyListeners();
    }
  }

  Future<bool> addNotificationDayBeforeDeadline(
      ToDoList list, String languageCode) async {
    if (!isActive) return false;
    final deadline = list.deadline.subtract(const Duration(days: 1));
    final tz.TZDateTime scheduledTime = tz.TZDateTime(
      tz.local,
      deadline.year,
      deadline.month,
      deadline.day,
      _notificationTime.hour,
      // Hour
      _notificationTime.minute,
      // Minute
    );
    final disabled = scheduledTime.isBefore(DateTime.now());
    final Database db = await database;
    final List<Map<String, dynamic>> snapshot = await db.rawQuery(
        'SELECT MAX(notificationIndex) as maxIndex FROM notifications');

    int notificationIndex = (snapshot[0]['maxIndex'] as int? ?? 0) + 1;
    return addNotification(
        list,
        Notifications(
            id: Uuid().v4(),
            listId: list.id,
            notificationIndex: notificationIndex,
            notificationDateTime: scheduledTime,
            disabled: disabled),
        languageCode);
  }

  Future<bool> addNotification(
      ToDoList list, Notifications notification, String languageCode) async {
    final db = await database;

    await db.insert(
      'notifications',
      notification.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
    return scheduleNotification(list, languageCode);
  }

  Future<List<Notifications>> getNotificationsByListId(String listId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db
        .query('notifications', where: 'listId = ?', whereArgs: [listId]);
    return List.generate(maps.length, (i) {
      return Notifications.fromMap(maps[i]);
    });
  }

  Future<void> disableNotificationById(String notificationId) async {
    final db = await database;
    await db.update(
      'notifications',
      {'disabled': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  Future<bool> cancelNotification(int notificationID) async {
    await flutterLocalNotificationsPlugin.cancel(notificationID);
    return true;
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<String> getRandomNotificationText(String languageCode) async {
    languageCode = languageCode != 'he' ? 'en' : 'he';
    String jsonString =
        await rootBundle.loadString('Assets/languages/$languageCode.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    List<String> notificationOptions = [
      jsonMap[Strings.hurryUpTomorrowsDeadline],
      jsonMap[Strings.reminderTomorrowsTheDeadline],
      jsonMap[Strings.finalCallTaskDueTomorrow],
      jsonMap[Strings.deadlineAlertDueTomorrow],
      jsonMap[Strings.timesRunningOutDueTomorrow],
      jsonMap[Strings.dontForgetDueTomorrow],
      jsonMap[Strings.lastDayReminderDueTomorrow],
      jsonMap[Strings.actNowTomorrowsDeadline],
      jsonMap[Strings.urgentReminderDueTomorrow],
      jsonMap[Strings.justOneDayLeftDeadlineTomorrow]
    ];
    final random = Random();
    final index = random.nextInt(notificationOptions.length);
    return notificationOptions[index];
  }

  Future<bool> scheduleNotification(ToDoList list, String languageCode) async {
    if (!isActive) return false;

    // Retrieve notifications with the same listId
    List<Notifications> notifications = await getNotificationsByListId(list.id);

    notifications.forEach((notification) {
      cancelNotification(notification.notificationIndex);
    });
    bool notificationScheduled = false;
    // Schedule new notifications based on notification date and time
    for (var notification in notifications) {
      final scheduledDateTime = notification.notificationDateTime;

      if (scheduledDateTime.isBefore(DateTime.now()) || notification.disabled)
        continue;

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notification.notificationIndex,
        list.title,
        await getRandomNotificationText(languageCode),
        tz.TZDateTime.from(scheduledDateTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'main_channel_id',
            'Deadline notifications',
            channelDescription:
                'Notification scheduled for one day before the deadline',
            channelShowBadge: false,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      notificationScheduled = true;
    }
    return notificationScheduled;
  }

// Future<String?> scheduleNotification(
//     ToDoList list, String languageCode) async {
//   if (!isActive) return null;
//   cancelNotification(list.notificationIndex);
//   final deadline = list.deadline.subtract(const Duration(days: 1));
//   final tz.TZDateTime scheduledTime = tz.TZDateTime(
//     tz.local,
//     deadline.year,
//     deadline.month,
//     deadline.day,
//     _notificationTime.hour, // Hour
//     _notificationTime.minute, // Minute
//     _notificationTime.second, // Second
//   );
//   if (scheduledTime.isBefore(DateTime.now())) return null;
//
//   await flutterLocalNotificationsPlugin.zonedSchedule(
//     list.notificationIndex,
//     list.title,
//     await getRandomNotificationText(languageCode),
//     scheduledTime,
//     const NotificationDetails(
//       android: AndroidNotificationDetails(
//         'main_channel_id',
//         'Deadline notifications',
//         channelDescription:
//             'Notification scheduled for one day before the deadline',
//         channelShowBadge: false,
//       ),
//     ),
//     androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//     uiLocalNotificationDateInterpretation:
//         UILocalNotificationDateInterpretation.absoluteTime,
//   );
//
//   return DateFormat('dd/MM/yyyy HH:mm').format(scheduledTime);
// }
}
