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

    return addNotification(list, scheduledTime, notificationText);
  }

  Future<bool> addNotification(ToDoList list, DateTime notificationDateTime,
      [String? notificationText]) async {
    if (!SharedPreferencesHelper.instance.notificationsActive) return false;

    final disabled = notificationDateTime.isBefore(DateTime.now());
    final Database db = await database;

    final List<Map<String, dynamic>> snapshot = await db.rawQuery(
        'SELECT MAX(notificationIndex) as maxIndex FROM notifications');

    int notificationIndex = (snapshot[0]['maxIndex'] as int? ?? 0) + 1;

    final Notifications notification = Notifications(
      id: Uuid().v4(),
      listId: list.id,
      notificationIndex: notificationIndex,
      notificationDateTime: notificationDateTime,
      disabled: disabled,
    );

    await db.insert(
      'notifications',
      notification.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return scheduleNotification(list, notificationText);
  }

  Future<bool> editNotification(
      Notifications notification, ToDoList list) async {
    final db = await database;
    notification.disabled = false;

    await db.update(
      'notifications',
      notification.toMap(),
      where: 'id = ?',
      whereArgs: [notification.id],
    );
    return scheduleNotification(list);
  }

  Future<bool> deleteNotification(
      Notifications notification, ToDoList list) async {
    final db = await database;

    await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [notification.id],
    );
    return scheduleNotification(list);
  }

  Future<List<Notifications>> getNotificationsByListId(String listId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db
        .query('notifications', where: 'listId = ?', whereArgs: [listId]);
    return List.generate(maps.length, (i) {
      return Notifications.fromMap(maps[i]);
    });
  }

  Future<void> toggleNotificationDisabled(
      Notifications notification, ToDoList list) async {
    if (!SharedPreferencesHelper.instance.notificationsActive &&
        notification.disabled) return;
    final db = await database;

    // Toggle the 'disabled' field
    final int newDisabledValue = notification.disabled ? 0 : 1;

    await db.update(
      'notifications',
      {'disabled': newDisabledValue},
      where: 'id = ?',
      whereArgs: [notification.id],
    );

    // Schedule notifications for the list
    if (list != null) {
      await scheduleNotification(list);
    }
  }

  Future<void> disableNotificationById(
      Notifications notification, ToDoList list) async {
    final db = await database;
    await db.update(
      'notifications',
      {'disabled': 1},
      where: 'id = ?',
      whereArgs: [notification.id],
    );
    scheduleNotification(list);
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
  }

  Future<bool> scheduleNotification(ToDoList list,
      [String? notificationText]) async {
    if (!SharedPreferencesHelper.instance.notificationsActive) return false;

    // Retrieve notifications with the same listId
    List<Notifications> notifications = await getNotificationsByListId(list.id);

    notifications.forEach((notification) {
      cancelNotification(notification.notificationIndex);
    });
    bool notificationScheduled = false;
    for (var notification in notifications) {
      final scheduledDateTime = notification.notificationDateTime;

      if (scheduledDateTime.isBefore(DateTime.now()) || notification.disabled) {
        continue;
      }
      if (!list.hasDeadline) {
        notificationText = '';
      }

      final tzDateTime = tz.TZDateTime.from(scheduledDateTime, tz.local);

      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          notification.notificationIndex,
          list.title,
          notificationText,
          tzDateTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              Keys.mainChannelId,
              Keys.mainChannelName,
              channelDescription: Keys.mainChannelDescription,
              channelShowBadge: false,
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: list.id,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        notificationScheduled = true;
      } catch (e) {
        print('Error scheduling notification: $e');
      }
    }
    notifyListeners();
    return notificationScheduled;
  }
}
