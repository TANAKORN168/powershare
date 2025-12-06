import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Session {
  Session._private();
  static final Session _instance = Session._private();
  factory Session() => _instance;
  static Session get instance => _instance;

  Map<String, dynamic>? user;
  String? accessToken;

  void setUser(Map<String, dynamic> u, {String? token}) {
    user = u;
    accessToken = token;
  }

  void clear() {
    user = null;
    accessToken = null;
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (user != null) {
      prefs.setString('session_user', jsonEncode(user));
    } else {
      prefs.remove('session_user');
    }
    if (accessToken != null) {
      prefs.setString('session_token', accessToken!);
    } else {
      prefs.remove('session_token');
    }
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final su = prefs.getString('session_user');
    final st = prefs.getString('session_token');
    if (su != null) {
      user = Map<String, dynamic>.from(jsonDecode(su));
    }
    accessToken = st;
  }
}