import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  static const String _baseUrlKey = 'baseUrl';
  static const String _sessionTokenKey = 'sessionToken';
  static const String _odooSessionKey = 'odooSession';

  Future<dynamic> readObject(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return json.decode(prefs.getString(key) ?? '{}');
  }

  Future<void> saveObject(String key, value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(value));
  }

  Future<String?> readString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  Future<String> get baseUrl async {
    return await readString(_baseUrlKey) ?? '';
  }

  Future<void> setBaseUrl(String url) async {
    await saveString(_baseUrlKey, url);
  }

  Future<String?> get sessionToken async {
    return await readString(_sessionTokenKey);
  }

  Future<void> setSessionToken(String token) async {
    await saveString(_sessionTokenKey, token);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
