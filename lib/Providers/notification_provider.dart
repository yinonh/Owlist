import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:to_do/Screens/single_list_screen.dart';
import 'package:uuid/uuid.dart';

import '../Models/notification.dart';
import '../Models/to_do_list.dart';
import '../Utils/notification_time.dart';
import '../Utils/shared_preferences_helper.dart';
import '../Utils/strings.dart';
import '../Providers/lists_provider.dart';

class NotificationProvider with ChangeNotifier {
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _notificationsEnabled = false;
  late NotificationTime _notificationTime;
  late bool isActive;
  late bool autoNotification;
  Database? _database;
  late BuildContext context;

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
    isActive = SharedPreferencesHelper.instance.notificationActive;
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
    this.isActive = isActive;
    SharedPreferencesHelper.instance.notificationsActive = isActive;
    notifyListeners();
  }

  Future<void> saveAutoNotification(bool autoNotification) async {
    this.autoNotification = autoNotification;
    await SharedPreferencesHelper.instance
        .setAutoNotification(autoNotification);
    notifyListeners();
  }

  Future<void> setUpNotifications(BuildContext context) async {
    this.context = context;
    await _configureLocalTimeZone();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveBackgroundNotificationResponse: (response) {
      Navigator.of(context).popUntil((route) => true);
      Navigator.pushNamed(context, SingleListScreen.routeName,
          arguments: response.payload);
    }, onDidReceiveNotificationResponse: (response) {
      Navigator.of(context).popUntil((route) => true);
      Navigator.pushNamed(context, SingleListScreen.routeName,
          arguments: response.payload);
    });
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

  Future<bool> addNotificationDayBeforeDeadline(ToDoList list) async {
    if (!isActive || !autoNotification) return false;
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

    return addNotification(list, scheduledTime);
  }

  Future<bool> addNotification(
      ToDoList list, DateTime notificationDateTime) async {
    if (!isActive) return false;

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

    return scheduleNotification(list);
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

  Future<void> toggleNotificationDisabled(Notifications notification) async {
    if (!isActive && notification.disabled) return;
    final db = await database;

    // Toggle the 'disabled' field
    final int newDisabledValue = notification.disabled ? 0 : 1;

    await db.update(
      'notifications',
      {'disabled': newDisabledValue},
      where: 'id = ?',
      whereArgs: [notification.id],
    );

    // Retrieve the corresponding ToDoList
    ToDoList? list = await Provider.of<ListsProvider>(context, listen: false)
        .getListById(notification.listId);

    // Schedule notifications for the list
    if (list != null) {
      await scheduleNotification(list);
    }
  }

  Future<void> disableNotificationById(Notifications notification) async {
    final db = await database;
    await db.update(
      'notifications',
      {'disabled': 1},
      where: 'id = ?',
      whereArgs: [notification.id],
    );
    ToDoList? list = await Provider.of<ListsProvider>(context, listen: false)
        .getListById(notification.listId);
    scheduleNotification(list!);
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

  Future<String> getRandomNotificationText() async {
    String languageCode = (SharedPreferencesHelper.instance.selectedLanguage ??
                Localizations.localeOf(context).languageCode) !=
            'he'
        ? 'en'
        : 'he';
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

  Future<bool> scheduleNotification(ToDoList list) async {
    if (!isActive) return false;

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

      DateTime dayBefore = list.deadline.subtract(Duration(days: 1));
      String? notificationText = null;
      if (list.hasDeadline &&
          dayBefore.year == scheduledDateTime.year &&
          dayBefore.month == scheduledDateTime.month &&
          dayBefore.day == scheduledDateTime.day) {
        notificationText = await getRandomNotificationText();
      }

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notification.notificationIndex,
        list.title,
        notificationText,
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
        payload: list.id,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      notificationScheduled = true;
    }
    notifyListeners();
    return notificationScheduled;
  }
}
