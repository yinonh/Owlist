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
import 'dart:math';

import '../Utils/shared_preferences_helper.dart';
import '../Widgets/notification_time.dart';
import '../Models/to_do_list.dart';

class NotificationProvider with ChangeNotifier {
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _notificationsEnabled = false;
  // late SharedPreferences _prefs;
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
          deadline.subtract(const Duration(days: 1)).day,
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

  Future<String> getRandomNotificationText(String languageCode) async {
    languageCode = languageCode != 'he' ? 'en' : 'he';
    String jsonString =
        await rootBundle.loadString('Assets/languages/$languageCode.json');
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

  Future<String?> scheduleNotification(
      ToDoList list, String languageCode) async {
    if (!isActive) return null;
    cancelNotification(list.notificationIndex);
    final deadline = list.deadline.subtract(const Duration(days: 1));
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
      await getRandomNotificationText(languageCode),
      scheduledTime,
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

    return DateFormat('dd/MM/yyyy HH:mm').format(scheduledTime);
  }
}
