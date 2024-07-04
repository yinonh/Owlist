import 'package:shared_preferences/shared_preferences.dart';

import '../Utils/keys.dart';

class SharedPreferencesHelper {
  SharedPreferencesHelper._();

  late SharedPreferences prefs;
  late String? language;
  late String? themePref;
  late bool _notificationActive;

  Future<void> initialise() async {
    prefs = await SharedPreferences.getInstance();
    language = prefs.getString(Keys.selectedLanguage);
    themePref = prefs.getString(Keys.selectedTheme);
    _notificationActive = prefs.getBool(Keys.notificationActive) ?? true;
  }

  static final SharedPreferencesHelper instance = SharedPreferencesHelper._();

  String? get selectedLanguage => language;

  set selectedLanguage(String? value) {
    language = value;
    prefs.setString(Keys.selectedLanguage, value ?? Keys.emptyChar);
  }

  String? get selectedTheme => themePref;

  set selectedTheme(String? value) {
    themePref = value;
    prefs.setString(Keys.selectedTheme, value ?? Keys.emptyChar);
  }

  bool get notificationsActive => _notificationActive;

  set notificationsActive(bool active) {
    _notificationActive = active;
    prefs.setBool(Keys.notificationActive, active);
  }

  Future<void> removeSelectedTheme() async {
    await prefs.remove(Keys.selectedTheme);
  }

  Future<int> getNotificationTime() async {
    return prefs.getInt(Keys.notificationTime) ?? 120000;
  }

  Future<void> setNotificationTime(int time) async {
    await prefs.setInt(Keys.notificationTime, time);
  }

  Future<bool> isAutoNotification() async {
    return prefs.getBool(Keys.autoNotification) ?? true;
  }

  Future<void> setAutoNotification(bool status) async {
    await prefs.setBool(Keys.autoNotification, status);
  }

  Future<int> sortByIndex() async {
    return prefs.getInt(Keys.sortByIndex) ?? 0;
  }

  Future<void> setSortByIndex(int index) async {
    await prefs.setInt(Keys.sortByIndex, index);
  }
}
