import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mock SharedPreferences for testing
/// Provides in-memory storage without persistence
class MockSharedPreferences extends Mock implements SharedPreferences {
  final Map<String, dynamic> _storage = {};

  @override
  dynamic get(String key) => _storage[key];

  @override
  bool? getBool(String key) => _storage[key] as bool?;

  @override
  double? getDouble(String key) => _storage[key] as double?;

  @override
  int? getInt(String key) => _storage[key] as int?;

  @override
  String? getString(String key) => _storage[key] as String?;

  @override
  List<String>? getStringList(String key) => _storage[key] as List<String>?;

  @override
  Set<String> getKeys() => _storage.keys.toSet();

  @override
  Future<bool> setBool(String key, bool value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _storage.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _storage.clear();
    return true;
  }

  @override
  Future<bool> reload() async => true;

  /// Helper method to reset preferences for fresh test state
  void reset() {
    _storage.clear();
  }

  /// Helper to verify stored values
  bool contains(String key) => _storage.containsKey(key);

  /// Helper to get all stored data
  Map<String, dynamic> getAllData() => Map.from(_storage);
}
