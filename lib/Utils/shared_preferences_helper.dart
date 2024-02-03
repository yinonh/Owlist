import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  SharedPreferencesHelper._();

  late SharedPreferences prefs;
  late String? language;
  late String? themePref;

  Future<void> initialise() async {
    prefs = await SharedPreferences.getInstance();
    language = prefs.getString('selectedLanguage');
    themePref = prefs.getString('selectedTheme');
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

  Future<void> removeSelectedTheme() async {
    await prefs.remove('selectedTheme');
  }

  Future<int> getNotificationTime() async {
    return prefs.getInt('notification_time') ?? 120000;
  }

  Future<void> setNotificationTime(int time) async {
    await prefs.setInt('notification_time', time);
  }

  Future<bool> isNotificationActive() async {
    return prefs.getBool('notification_active') ?? true;
  }

  Future<void> setNotificationStatus(bool status) async {
    await prefs.setBool('notification_active', status);
  }

  Future<int> sortByIndex() async {
    return prefs.getInt('sortByIndex') ?? 0;
  }

  Future<void> setSortByIndex(int index) async {
    await prefs.setInt('sortByIndex', index);
  }
}
