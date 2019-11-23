import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class SharePreferenceUtil {
  static SharePreferenceUtil _instance;
  SharedPreferences shareSave;

  factory SharePreferenceUtil() => _instance ?? new SharePreferenceUtil._();

  SharePreferenceUtil._();

  void instance() async {
    shareSave = await SharedPreferences.getInstance();
  }

  Future<bool> setString(key, value) async {
    return shareSave.setString(key, value);
  }

  Future<String> getString(key) async {
    return shareSave.getString(key) == null ? "" : shareSave.getString(key);
  }

  Future<bool> setInteger(key, value) async {
    return shareSave.setInt(key, value);
  }

  Future<int> getInteger(key) async {
    return shareSave.getInt(key);
  }
}
