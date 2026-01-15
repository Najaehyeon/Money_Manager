import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences를 관리하는 서비스 클래스
class StorageService {
  static StorageService? _instance;
  SharedPreferences? _prefs;

  StorageService._();

  /// 싱글톤 인스턴스 가져오기
  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _instance!._prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  /// SharedPreferences 인스턴스 가져오기
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call getInstance() first.');
    }
    return _prefs!;
  }

  // String List Operations
  Future<List<String>> getStringList(String key) async {
    return prefs.getStringList(key) ?? [];
  }

  Future<void> setStringList(String key, List<String> value) async {
    await prefs.setStringList(key, value);
  }

  // String Operations
  Future<String?> getString(String key) async {
    return prefs.getString(key);
  }

  Future<void> setString(String key, String value) async {
    await prefs.setString(key, value);
  }

  // Double Operations
  Future<double> getDouble(String key, {double defaultValue = 0.0}) async {
    return prefs.getDouble(key) ?? defaultValue;
  }

  Future<void> setDouble(String key, double value) async {
    await prefs.setDouble(key, value);
  }

  // Bool Operations
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    return prefs.getBool(key) ?? defaultValue;
  }

  Future<void> setBool(String key, bool value) async {
    await prefs.setBool(key, value);
  }

  // Clear all data
  Future<void> clear() async {
    await prefs.clear();
  }
}
