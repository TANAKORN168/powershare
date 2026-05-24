import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:powershare/services/api_config.dart';
import 'package:powershare/services/session.dart';
import 'package:powershare/models/responseModel.dart';
import 'package:powershare/models/singupModel.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final authUrl = Uri.parse(
        '${ApiConfig.baseUrl}/auth/v1/token?grant_type=password',
      );
      final authHeaders = {
        'apikey': ApiConfig.apiKey,
        'Content-Type': 'application/json',
      };
      final authBody = jsonEncode({'email': email, 'password': password});

      if (kDebugMode) print('🔵 login: POST $authUrl');
      final authResp = await http.post(
        authUrl,
        headers: authHeaders,
        body: authBody,
      );
      if (kDebugMode)
        print(
          '🔵 login auth: status=${authResp.statusCode} body=${authResp.body}',
        );

      if (authResp.statusCode != 200) {
        if (kDebugMode) {
          print(
            'login auth error: status=${authResp.statusCode} body=${authResp.body}',
          );
        }
        return {
          'responseCode': 'FAIL',
          'responseMessage':
              'อีเมลหรือรหัสผ่านไม่ถูกต้อง (${authResp.statusCode}): ${authResp.body}',
        };
      }

      final authData = jsonDecode(authResp.body);
      final accessToken = authData['access_token'];

      final usersUrl = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/users?email=eq.$email',
      );
      final usersHeaders = {
        'apikey': ApiConfig.apiKey,
        'Authorization': 'Bearer $accessToken',
      };

      if (kDebugMode) print('🔵 login users: GET $usersUrl');
      final usersResp = await http.get(usersUrl, headers: usersHeaders);
      if (kDebugMode)
        print(
          '🔵 login users: status=${usersResp.statusCode} body=${usersResp.body}',
        );

      if (usersResp.statusCode != 200) {
        return {
          'responseCode': 'FAIL',
          'responseMessage':
              'ไม่พบข้อมูลผู้ใช้ (${usersResp.statusCode}): ${usersResp.body}',
        };
      }

      final usersData = jsonDecode(usersResp.body) as List<dynamic>;
      if (usersData.isEmpty) {
        return {'responseCode': 'FAIL', 'responseMessage': 'ไม่พบข้อมูลผู้ใช้'};
      }

      final user = usersData[0];
      if (user['role'] == 'Pending') {
        return {
          'responseCode': 'FAIL',
          'responseMessage': 'บัญชีของคุณรออนุมัติ',
        };
      }

      return {
        'responseCode': 'SUCCESS',
        'responseMessage': 'เข้าสู่ระบบสำเร็จ',
        'user': usersData,
        'access_token': accessToken,
      };
    } catch (e) {
      if (kDebugMode) print('login error: $e');
      return {'responseCode': 'FAIL', 'responseMessage': 'เกิดข้อผิดพลาด: $e'};
    }
  }

  static Future<ResponseModel> signup(SignupModel signupModel) async {
    try {
      final signupUrl = Uri.parse('${ApiConfig.baseUrl}/auth/v1/signup');
      final signupHeaders = {
        'apikey': ApiConfig.apiKey,
        'Content-Type': 'application/json',
      };
      final signupBody = jsonEncode({
        'email': signupModel.email,
        'password': signupModel.password,
      });

      final signupResp = await http.post(
        signupUrl,
        headers: signupHeaders,
        body: signupBody,
      );
      if (!(signupResp.statusCode == 200 || signupResp.statusCode == 201)) {
        if (kDebugMode) {
          print(
            'signup auth: status=${signupResp.statusCode} body=${signupResp.body}',
          );
        }
        return ResponseModel(
          responseCode: 'FAIL',
          responseMessage:
              'ไม่สามารถสร้างบัญชีได้ (${signupResp.statusCode}): ${signupResp.body}',
        );
      }

      final signupData = jsonDecode(signupResp.body);
      final userId = signupData['user']?['id'];
      final accessToken = signupData['access_token'];

      if (userId == null || userId.toString().isEmpty) {
        return ResponseModel(
          responseCode: 'FAIL',
          responseMessage: 'ไม่สามารถดึง user id จากผลสมัครได้',
        );
      }

      if (accessToken == null || accessToken.toString().isEmpty) {
        return ResponseModel(
          responseCode: 'FAIL',
          responseMessage:
              'สมัครสมาชิกสำเร็จ แต่ไม่สามารถสร้างโปรไฟล์ได้ (ไม่พบ access token)',
          user: userId,
        );
      }

      final usersUrl = Uri.parse('${ApiConfig.baseUrl}/rest/v1/users');
      final usersHeaders = {
        'apikey': ApiConfig.apiKey,
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };
      final usersBody = jsonEncode(signupModel.toJson(userId.toString()));

      final usersResp = await http.post(
        usersUrl,
        headers: usersHeaders,
        body: usersBody,
      );

      if (!(usersResp.statusCode == 200 || usersResp.statusCode == 201)) {
        if (kDebugMode) {
          print(
            'signup users: status=${usersResp.statusCode} body=${usersResp.body}',
          );
        }
        return ResponseModel(
          responseCode: 'FAIL',
          responseMessage: 'สร้างโปรไฟล์ผู้ใช้ไม่สำเร็จ',
          user: userId,
        );
      }

      return ResponseModel(
        responseCode: 'SUCCESS',
        responseMessage: 'สมัครสมาชิกสำเร็จ',
        user: userId,
      );
    } catch (e) {
      if (kDebugMode) print('signup error: $e');
      return ResponseModel(
        responseCode: 'FAIL',
        responseMessage: 'เกิดข้อผิดพลาด: $e',
      );
    }
  }

  static bool isTokenExpired() {
    final token = Session.instance.accessToken;
    if (token == null || token.isEmpty) return true;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> data = jsonDecode(decoded);

      final exp = data['exp'] as int?;
      if (exp == null) return true;

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();

      if (kDebugMode) {
        print('Token expiry: $expiryDate');
        print('Current time: $now');
        print('Token expired: ${now.isAfter(expiryDate)}');
      }

      return now.isAfter(expiryDate);
    } catch (e) {
      if (kDebugMode) print('isTokenExpired error: $e');
      return true;
    }
  }

  static Future<bool> checkAndRefreshToken() async {
    if (!isTokenExpired()) return true;

    if (kDebugMode) print('⚠️ Token expired - clearing session');

    Session.instance.clear();
    await Session.instance.saveToPrefs();

    return false;
  }

  static Future<String> generatePasswordResetOTP(String email) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/rest/v1/rpc/generate_password_reset_otp',
    );
    final body = jsonEncode({'user_email': email});

    final resp = await http.post(url, headers: ApiConfig.headers, body: body);

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as String;
    }
    throw Exception(
      'generatePasswordResetOTP failed: ${resp.statusCode} ${resp.body}',
    );
  }

  static Future<bool> verifyOTPAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/rest/v1/rpc/verify_otp_and_reset_password',
    );
    final body = jsonEncode({
      'user_email': email,
      'input_otp': otp,
      'new_password': newPassword,
    });

    final resp = await http.post(url, headers: ApiConfig.headers, body: body);

    if (resp.statusCode == 200) {
      final result = jsonDecode(resp.body);
      return result == true;
    }
    return false;
  }
}
