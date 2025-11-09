import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:powershare/models/responseModel.dart';
import 'package:powershare/models/singupModel.dart';

class ApiServices {
  static const String baseUrl = 'https://lizyjuvbyuygsezyhpwr.supabase.co';
  static const String apiKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxpenlqdXZieXV5Z3NlenlocHdyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNTUyMzksImV4cCI6MjA2NzczMTIzOX0.91fgESB0_0P_9X7qDd-YfCGYgBywcE5hWYd6aX6kIRg';

  static Map<String, String> get _headers => {
    'apikey': apiKey,
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/auth/v1/token?grant_type=password');
    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // ดึงข้อมูลผู้ใช้จากตาราง users
      final users = await getUsers(data['access_token']);

      return {
        'responseCode': 'SUCCESS',
        'access_token': data['access_token'],
        'refresh_token': data['refresh_token'],
        'user': users,
      };
    } else {
      return {'responseCode': 'FAIL', 'responseMessage': 'เข้าสู่ระบบล้มเหลว'};
    }
  }

  // register: สมัครสมาชิก
  static Future<ResponseModel> signup(SignupModel signupModel) async {
    final url = Uri.parse('$baseUrl/auth/v1/signup');

    final response = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'email': signupModel.email,
        'password': signupModel.password,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final uid = data['user']['id'];

      var res = await addUsers('users', signupModel.toJson(uid));
      return ResponseModel(
        responseCode: res.responseCode,
        responseMessage: res.responseMessage,
      );
    } else {
      String errorMessage = 'เพิ่มข้อมูลไม่สำเร็จ';
      String errorCode = data['error_code'] ?? '';

      if (errorCode == 'user_already_exists') {
        errorMessage = 'อีเมล ${signupModel.email} ถูกใช้ไปแล้ว';
      } else {
        errorMessage = data['msg'] ?? errorMessage;
      }

      return ResponseModel(responseCode: 'FAIL', responseMessage: errorMessage);
    }
  }

  // POST: เพิ่มข้อมูล Users
  static Future<ResponseModel> addUsers(
    String table,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/rest/v1/$table');
    final json = jsonEncode(data);
    final response = await http.post(url, headers: _headers, body: json);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return ResponseModel(
        responseCode: 'SUCCESS',
        responseMessage: 'เพิ่มข้อมูลสำเร็จ',
      );
    } else {
      String errorMessage = 'เพิ่มข้อมูลไม่สำเร็จ';
      if (!response.body.isEmpty) {
        final responseData = jsonDecode(response.body);
        errorMessage = responseData['message'];
      }

      return ResponseModel(responseCode: 'FAIL', responseMessage: errorMessage);
    }
  }

  // uploadUserFiles: อัพโหลดไฟล์ของผู้ใช้
  static Future<String> uploadUserFiles(File file) async {
    const bucketName = 'powershare-files';

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}${extension(file.path)}';
    final filePath = 'users/$fileName';

    final uri = Uri.parse('$baseUrl/storage/v1/object/$bucketName/$filePath');
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

    final request = http.Request('POST', uri)
      ..headers.addAll({
        'Authorization': 'Bearer $apiKey',
        'Content-Type': mimeType,
      })
      ..bodyBytes = await file.readAsBytes();

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final publicUrl =
          '$baseUrl/storage/v1/object/public/$bucketName/$filePath';
      return publicUrl;
    } else {
      print('Upload failed: ${response.statusCode} ${response.body}');
      return "";
    }
  }

  // ✅ ดึงข้อมูลจากตาราง users ด้วย access_token
  static Future<List<dynamic>> getUsers(String accessToken) async {
    final url = Uri.parse('$baseUrl/rest/v1/users');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Load users failed: ${response.body}');
    }
  }

  // GET: ดึงข้อมูล
  static Future<List<dynamic>> getItems(String table) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$table'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('โหลดข้อมูลไม่สำเร็จ: ${response.statusCode}');
    }
  }

  // PUT: แก้ไขข้อมูล
  // Supabase REST API ต้องใช้ query string เพื่อกรองข้อมูล (เช่น id)
  // ตัวอย่าง update โดยต้องส่ง id ด้วย
  static Future<bool> updateItem(
    String table,
    String idField,
    dynamic idValue,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/$table?$idField=eq.$idValue');
    final response = await http.patch(
      url,
      headers: _headers,
      body: jsonEncode(data),
    );

    return response.statusCode ==
        204; // Supabase PATCH คืน 204 No Content ถ้าสำเร็จ
  }

  // DELETE: ลบข้อมูล
  // เช่น ลบ user ที่ id เท่ากับ 1
  static Future<bool> deleteItem(
    String table,
    String idField,
    dynamic idValue,
  ) async {
    final url = Uri.parse('$baseUrl/$table?$idField=eq.$idValue');
    final response = await http.delete(url, headers: _headers);

    return response.statusCode == 204;
  }
}
