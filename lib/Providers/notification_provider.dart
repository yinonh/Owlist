import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do/Models/to_do_list.dart';
import 'dart:math';

import '../Widgets/notification_time.dart';

class NotificationProvider with ChangeNotifier {
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _notificationsEnabled = false;
  late SharedPreferences _prefs;
  late NotificationTime _notificationTime;
  late bool isActive;

  FlutterLocalNotificationsPlugin get flutterLocalNotificationsPlugin =>
      _flutterLocalNotificationsPlugin;

  bool get notificationsEnabled => _notificationsEnabled;

  NotificationTime get notificationTime => _notificationTime;

  NotificationProvider() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    int storedTime = _prefs.getInt('notification_time') ?? 120000;
    _notificationTime = NotificationTime.fromInt(storedTime);
    isActive = _prefs.getBool('notification_active') ?? true;
    notifyListeners();
  }

  Future<void> saveNotificationTimeToPrefs(NotificationTime time) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _notificationTime = time;
    await prefs.setInt('notification_time', time.toInt());
    notifyListeners();
  }

  Future<void> saveActive(bool isActive) async {
    this.isActive = isActive;
    await _prefs.setBool('notification_active', isActive);
    notifyListeners();
  }

  Future<void> setUpNotifications() async {
    await _configureLocalTimeZone();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String? timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName!));
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

  Future<bool> cancelNotification(int id, [DateTime? deadline]) async {
    bool notificationExists = true;
    if (deadline != null) {
      final pendingNotifications =
          await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      notificationExists =
          pendingNotifications.any((notification) => notification.id == id);
      final notificationTime = DateTime(
          deadline.year,
          deadline.month,
          deadline.subtract(Duration(days: 1)).day,
          _notificationTime.hour,
          _notificationTime.minute,
          0);
      if (notificationTime.isBefore(DateTime.now())) return false;
    }

    if (notificationExists) {
      await flutterLocalNotificationsPlugin.cancel(id);
      return true;
    }
    return false;
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<String> getRandomNotificationText() async {
    String languageCode = _prefs.getString('selectedLanguage') ?? 'en';
    String jsonString =
        await rootBundle.loadString('Assets/languages/${languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    List<String> notificationOptions = [
      jsonMap["Hurry up! Tomorrow's Deadline!"],
      jsonMap["⏰ Reminder: Tomorrow's the Deadline!"],
      jsonMap["Final Call: Task Due Tomorrow!"],
      jsonMap["Deadline Alert: Due Tomorrow!"],
      jsonMap["Time's Running Out: Due Tomorrow!"],
      jsonMap["Don't Forget: Due Tomorrow!"],
      jsonMap["Last Day Reminder: Due Tomorrow!"],
      jsonMap["Act Now: Tomorrow's Deadline!"],
      jsonMap["Urgent Reminder: Due Tomorrow!"],
      jsonMap["Just One Day Left: Deadline Tomorrow!"]
    ];
    final random = Random();
    final index = random.nextInt(notificationOptions.length);
    return notificationOptions[index];
  }

  Future<String?> scheduleNotification(ToDoList list) async {
    if (!isActive) return null;
    cancelNotification(list.notificationIndex);
    final deadline = list.deadline.subtract(Duration(days: 1));
    final tz.TZDateTime scheduledTime = tz.TZDateTime(
      tz.local,
      deadline.year,
      deadline.month,
      deadline.day,
      _notificationTime.hour, // Hour
      _notificationTime.minute, // Minute
      _notificationTime.second, // Second
    );
    if (scheduledTime.isBefore(DateTime.now())) return null;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      list.notificationIndex,
      list.title,
      await getRandomNotificationText(),
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'main_channel_id',
          'Deadline notifications',
          channelDescription:
              'Notification scheduled for one day before the deadline',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );

    return DateFormat('dd/MM/yyyy HH:mm').format(scheduledTime);
  }
}
