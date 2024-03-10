import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  SharedPreferencesHelper._();

  late SharedPreferences prefs;
  late String? language;
  late String? themePref;
  late bool notificationActive;

  Future<void> initialise() async {
    prefs = await SharedPreferences.getInstance();
    language = prefs.getString('selectedLanguage');
    themePref = prefs.getString('selectedTheme');
    notificationActive = prefs.getBool('notification_active') ?? true;
  }

  static final SharedPreferencesHelper instance = SharedPreferencesHelper._();

  String? get selectedLanguage => language;

  set selectedLanguage(String? value) {
    language = value;
    prefs.setString('selectedLanguage', value ?? '');
  }

  String? get selectedTheme => themePref;

  set selectedTheme(String? value) {
    themePref = value;
    prefs.setString('selectedTheme', value ?? '');
  }

  bool get notificationsActive => notificationActive;

  set notificationsActive(bool active) {
    notificationActive = active;
    prefs.setBool('notification_active', active);
  }

  Future<void> removeSelectedTheme() async {
    await prefs.remove('selectedTheme');
  }

  Future<int> getNotificationTime() async {
    return prefs.getInt('notification_time') ?? 120000;
  }

  Future<void> setNotificationTime(int time) async {
    await prefs.setInt('notification_time', time);
  }

  Future<bool> isAutoNotification() async {
    return prefs.getBool('auto_notification') ?? true;
  }

  Future<void> setAutoNotification(bool status) async {
    await prefs.setBool('auto_notification', status);
  }

  Future<int> sortByIndex() async {
    return prefs.getInt('sortByIndex') ?? 0;
  }

  Future<void> setSortByIndex(int index) async {
    await prefs.setInt('sortByIndex', index);
  }
}
