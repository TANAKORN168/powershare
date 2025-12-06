import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:powershare/models/responseModel.dart';
import 'package:powershare/models/singupModel.dart';
import 'package:flutter/foundation.dart'; // ✅ เพิ่มบรรทัดนี้
import 'package:powershare/services/session.dart';

class ApiServices {
  static const String baseUrl = 'https://lizyjuvbyuygsezyhpwr.supabase.co';
  static const String apiKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxpenlqdXZieXV5Z3NlenlocHdyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIxNTUyMzksImV4cCI6MjA2NzczMTIzOX0.91fgESB0_0P_9X7qDd-YfCGYgBywcE5hWYd6aX6kIRg';

  // headers helper (ใช้ apiKey ที่มีอยู่ในไฟล์)
  static Map<String, String> get _headers {
    // ถ้ามี accessToken จาก session ให้ใช้ token ของผู้ใช้
    final token = Session.instance.accessToken;
    final bearer = token != null && token.isNotEmpty ? token : apiKey;
    return {
      'apikey': apiKey,
      'Authorization': 'Bearer $bearer',
      'Content-Type': 'application/json',
    };
  }

  /// ดึงรายการหมวดหมู่จากตาราง `categories`
  /// จะไม่ส่งคืนรายการที่ delete_flag = 'Y'
  static Future<List<Map<String, dynamic>>> getCategories({bool onlyActive = false}) async {
    final activeFilter = onlyActive ? '&is_active=eq.true' : '';
    // รวมเงื่อนไขเพื่อเอาเฉพาะที่ delete_flag = 'N' หรือ delete_flag IS NULL
    // ใช้ or=(delete_flag.eq.N,delete_flag.is.null)
    final url = Uri.parse('$baseUrl/rest/v1/categories?select=*&order=created_at.desc$activeFilter&or=(delete_flag.eq.N,delete_flag.is.null)');
    final resp = await http.get(url, headers: _headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('getCategories failed: ${resp.statusCode} ${resp.body}');
  }

  /// สร้างหมวดหมู่ใหม่ (ตั้ง delete_flag เป็น 'N' โดยปริยาย)
  static Future<Map<String, dynamic>> createCategory({
    required String name,
    String? description,
    bool isActive = true,
    String? userCreated,
  }) async {
    final url = Uri.parse('$baseUrl/rest/v1/categories');
    final body = {
      'name': name,
      'description': description ?? '',
      'is_active': isActive,
      'delete_flag': 'N',
      'created_at': DateTime.now().toIso8601String(),
      if (userCreated != null) 'user_created': userCreated,
    };
    final headers = {..._headers, 'Prefer': 'return=representation'};
    final resp = await http.post(url, headers: headers, body: jsonEncode(body));
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return (data.first as Map).cast<String, dynamic>();
    }
    throw Exception('createCategory failed: ${resp.statusCode} ${resp.body}');
  }

  /// อัพเดตหมวดหมู่ (คืนค่า representation ถ้ามี)
  static Future<Map<String, dynamic>> updateCategory(
    String id, {
    String? name,
    String? description,
    bool? isActive,
    String? userUpdates,
  }) async {
    final url = Uri.parse('$baseUrl/rest/v1/categories?id=eq.$id');
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (isActive != null) body['is_active'] = isActive;
    if (userUpdates != null) body['user_updates'] = userUpdates;
    body['updated_at'] = DateTime.now().toIso8601String();

    final headers = {..._headers, 'Prefer': 'return=representation'};
    final resp = await http.patch(url, headers: headers, body: jsonEncode(body));
    if (resp.statusCode == 200 || resp.statusCode == 204) {
      if (resp.body.isNotEmpty) {
        final data = jsonDecode(resp.body) as List<dynamic>;
        return (data.first as Map).cast<String, dynamic>();
      }
      return {};
    }
    throw Exception('updateCategory failed: ${resp.statusCode} ${resp.body}');
  }

  /// Soft-delete: ตั้ง delete_flag = 'Y' แทนการลบจริง
  static Future<bool> deleteCategory(String id, {String? userUpdates}) async {
    final url = Uri.parse('$baseUrl/rest/v1/categories?id=eq.$id');
    final body = {
      'delete_flag': 'Y',
      'updated_at': DateTime.now().toIso8601String(),
      if (userUpdates != null) 'user_updates': userUpdates,
    };
    final resp = await http.patch(url, headers: _headers, body: jsonEncode(body));
    // Supabase จะคืน 204 หรือ 200
    return resp.statusCode == 200 || resp.statusCode == 204;
  }

  /// เปลี่ยนสถานะ is_active
  static Future<bool> setCategoryActive(String id, bool active) async {
    final url = Uri.parse('$baseUrl/rest/v1/categories?id=eq.$id');
    final body = jsonEncode({'is_active': active, 'updated_at': DateTime.now().toIso8601String()});
    final resp = await http.patch(url, headers: _headers, body: body);
    return resp.statusCode == 200 || resp.statusCode == 204;
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/auth/v1/token?grant_type=password');

    // ใช้ header ชัดเจนสำหรับ login (apikey + content-type)
    final headersForLogin = {
      'apikey': apiKey,
      'Content-Type': 'application/json',
    };

    if (kDebugMode) {
      print('login: POST $url');
      print('login: headersForLogin keys=${headersForLogin.keys.toList()}');
      print('login: body={"email":"$email","password":"(redacted)"}');
    }

    final response = await http.post(
      url,
      headers: headersForLogin,
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (kDebugMode) {
      print('login: status=${response.statusCode}');
      print('login: body=${response.body}');
    }

    if (response.statusCode == 200) {
      final data = await compute(_parseJson, response.body);

      // เก็บ access token ใน Session เพื่อใช้ต่อ
      final accessToken = data['access_token'] as String?;
      if (accessToken != null && accessToken.isNotEmpty) {
        Session.instance.accessToken = accessToken;
      }

      // ดึงข้อมูลผู้ใช้โดยส่ง access token ที่ได้
      final users = await getUsers(accessToken ?? '');

      return {
        'responseCode': 'SUCCESS',
        'access_token': data['access_token'],
        'refresh_token': data['refresh_token'],
        'user': users,
      };
    } else {
      // แสดงรายละเอียด error ใน debug
      if (kDebugMode) {
        try {
          final err = jsonDecode(response.body);
          print('login error detail: $err');
        } catch (_) {}
      }
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

  /// อัพโหลดไฟล์ไปยัง Supabase Storage
  /// - bucket: ชื่อ bucket
  /// - folder: โฟลเดอร์ภายใน bucket (เช่น 'products') — จะถูกต่อเป็น path/file.ext
  static Future<String> uploadFile(
    File file, {
    required String bucket,
    String? filename,
    String folder = 'products',
  }) async {
    final name = filename ?? basename(file.path);
    final encodedName = Uri.encodeComponent(name);
    final cleanFolder = folder.replaceAll(RegExp(r'^/+|/+$'), ''); // remove leading/trailing slashes
    final objectPath = '$cleanFolder/$encodedName';
    final url = Uri.parse('$baseUrl/storage/v1/object/$bucket/$objectPath');

    final bytes = await file.readAsBytes();
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'apikey': apiKey,
      'Content-Type': mimeType,
    };

    final resp = await http.put(url, headers: headers, body: bytes);

    debugPrint('uploadFile: PUT $url -> status=${resp.statusCode}');
    debugPrint('uploadFile body: ${resp.body}');

    if (resp.statusCode == 200) {
      // public URL ของ object (path ต้องเหมือน objectPath)
      return '$baseUrl/storage/v1/object/public/$bucket/$objectPath';
    }

    throw Exception('uploadFile failed: status=${resp.statusCode}, body=${resp.body}. '
        'Check bucket name "$bucket", baseUrl and your API key. Ensure bucket exists and is accessible.');
  }

  /// สำหรับ debug: ดึงรายการ buckets (ต้องใช้ service_role key ถ้าเป็น private)
  static Future<List<dynamic>> listBuckets() async {
    final url = Uri.parse('$baseUrl/storage/v1/bucket');
    final resp = await http.get(url, headers: {'apikey': apiKey, 'Authorization': 'Bearer $apiKey'});
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as List<dynamic>;
    }
    throw Exception('listBuckets failed: ${resp.statusCode} ${resp.body}');
  }

  /// สร้าง product ในตาราง products (คืน representation)
  static Future<Map<String, dynamic>> createProduct(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/rest/v1/products');
    final headers = {..._headers, 'Prefer': 'return=representation'};
    final resp = await http.post(url, headers: headers, body: jsonEncode(payload));
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return (data.first as Map).cast<String, dynamic>();
    }
    throw Exception('createProduct failed: ${resp.statusCode} ${resp.body}');
  }

  /// อัพเดต product ตาม id (คืน representation ถ้ามี)
  static Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/rest/v1/products?id=eq.$id');
    final headers = {..._headers, 'Prefer': 'return=representation'};
    final resp = await http.patch(url, headers: headers, body: jsonEncode(payload));
    if (resp.statusCode == 200 || resp.statusCode == 204) {
      if (resp.body.isNotEmpty) {
        final data = jsonDecode(resp.body) as List<dynamic>;
        return (data.first as Map).cast<String, dynamic>();
      }
      return payload;
    }
    throw Exception('updateProduct failed: ${resp.statusCode} ${resp.body}');
  }

  // uploadUserFiles: อัพโหลดไฟล์ของผู้ใช้ (สามารถระบุ subfolder ได้)
  static Future<String> uploadUserFiles(File file, {String subfolder = 'users'}) async {
    const bucketName = 'powershare-files';

    final fileName = '${DateTime.now().millisecondsSinceEpoch}${extension(file.path)}';
    final folder = subfolder.replaceAll(RegExp(r'^/+|/+$'), ''); // trim slashes
    final filePath = '$folder/$fileName';

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
      final publicUrl = '$baseUrl/storage/v1/object/public/$bucketName/$filePath';
      return publicUrl;
    } else {
      debugPrint('Upload failed: ${response.statusCode} ${response.body}');
      return '';
    }
  }

  // helper สำหรับอัพโหลดรูปสินค้าไปที่ powershare-files/products
  static Future<String> uploadProductFile(File file) async {
    return uploadUserFiles(file, subfolder: 'products');
  }

  // ✅ ดึงข้อมูลจากตาราง users ด้วย access_token ที่ส่งมา
  static Future<List<dynamic>> getUsers(String accessToken) async {
    final url = Uri.parse('$baseUrl/rest/v1/users');

    // สร้าง headers แบบชั่วคราวโดยใช้ accessToken ที่ส่งมา (fallback เป็น apiKey ถ้า empty)
    final tokenToUse = (accessToken != null && accessToken.isNotEmpty) ? accessToken : Session.instance.accessToken ?? apiKey;
    final headers = {
      'apikey': apiKey,
      'Authorization': 'Bearer $tokenToUse',
      'Content-Type': 'application/json',
    };

    if (kDebugMode) print('getUsers: GET $url (using token length ${tokenToUse.length})');

    final response = await http.get(url, headers: headers);

    if (kDebugMode) print('getUsers: status=${response.statusCode} body=${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Load users failed: ${response.statusCode} ${response.body}');
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

  // ✅ ดึงเฉพาะผู้ใช้ที่ยังไม่ได้อนุมัติ (is_approve = false)
  static Future<List<Map<String, dynamic>>?> getPendingUsers() async {
    // ใช้ RPC function แทน (กรองเฉพาะ is_approve=false และ rejected_at IS NULL)
    final url = Uri.parse('$baseUrl/rest/v1/rpc/get_pending_users');
    
    final response = await http.post(url, headers: _headers); // RPC ใช้ POST

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    return null;
  }

  // อนุมัติ/ปฏิเสธผู้ใช้ (อัพเดต is_approve และ optional role)
  static Future<bool> setUserApproval(String id, {required bool approve, String? role}) async {
    final url = Uri.parse('$baseUrl/rest/v1/users?id=eq.$id');
    final payload = <String, dynamic>{'is_approve': approve};
    if (role != null) payload['role'] = role;

    final response = await http.patch(url, headers: _headers, body: jsonEncode(payload));

    // Supabase REST คืน 204 No Content เมื่อสำเร็จ (บางครั้งอาจเป็น 200)
    return response.statusCode == 204 || response.statusCode == 200;
  }

  /// ดึงรายการสินค้า (จะไม่คืนรายการที่ delete_flag = 'Y')
  /// ถ้าต้องการเฉพาะที่ is_active = true ให้กำหนด onlyActive: true
  static Future<List<Map<String, dynamic>>> getProducts({bool onlyActive = false}) async {
    final activeFilter = onlyActive ? '&is_active=eq.true' : '';
    final url = Uri.parse(
      '$baseUrl/rest/v1/products?select=*&order=created_at.desc$activeFilter&or=(delete_flag.eq.N,delete_flag.is.null)',
    );

    final resp = await http.get(url, headers: _headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }

    throw Exception('getProducts failed: ${resp.statusCode} ${resp.body}');
  }

  /// Soft-delete product: ตั้ง delete_flag = 'Y'
  static Future<bool> deleteProduct(String id, {String? userUpdates}) async {
    final url = Uri.parse('$baseUrl/rest/v1/products?id=eq.$id');
    final body = {
      'delete_flag': 'Y',
      'updated_at': DateTime.now().toIso8601String(),
      if (userUpdates != null) 'user_updates': userUpdates,
    };
    final resp = await http.patch(url, headers: _headers, body: jsonEncode(body));
    return resp.statusCode == 200 || resp.statusCode == 204;
  }

  /// ดึงรายการ promotions (ไม่เอาที่ delete_flag='Y')
  static Future<List<Map<String, dynamic>>> getPromotions({bool onlyActive = false}) async {
    final activeFilter = onlyActive ? '&is_active=eq.true' : '';
    final url = Uri.parse(
      '$baseUrl/rest/v1/promotions?select=*&order="order".asc,created_at.desc$activeFilter&or=(delete_flag.eq.N,delete_flag.is.null)',
    );
    final resp = await http.get(url, headers: _headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('getPromotions failed: ${resp.statusCode} ${resp.body}');
  }

  /// สร้าง promotion
  static Future<Map<String, dynamic>> createPromotion({
    required String text,
    bool isActive = true,
    int order = 999,
    String? userCreated,
  }) async {
    final url = Uri.parse('$baseUrl/rest/v1/promotions');
    final body = {
      'text': text,
      'is_active': isActive,
      'order': order,
      'delete_flag': 'N',
      'created_at': DateTime.now().toIso8601String(),
      if (userCreated != null) 'user_created': userCreated,
    };
    final headers = {..._headers, 'Prefer': 'return=representation'};
    final resp = await http.post(url, headers: headers, body: jsonEncode(body));
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return (data.first as Map).cast<String, dynamic>();
    }
    throw Exception('createPromotion failed: ${resp.statusCode} ${resp.body}');
  }

  /// อัพเดต promotion
  static Future<Map<String, dynamic>> updatePromotion(
    String id, {
    String? text,
    bool? isActive,
    int? order,
    String? userUpdates,
  }) async {
    final url = Uri.parse('$baseUrl/rest/v1/promotions?id=eq.$id');
    final body = <String, dynamic>{};
    if (text != null) body['text'] = text;
    if (isActive != null) body['is_active'] = isActive;
    if (order != null) body['order'] = order;
    if (userUpdates != null) body['user_updates'] = userUpdates;
    body['updated_at'] = DateTime.now().toIso8601String();

    final headers = {..._headers, 'Prefer': 'return=representation'};
    final resp = await http.patch(url, headers: headers, body: jsonEncode(body));
    if (resp.statusCode == 200 || resp.statusCode == 204) {
      if (resp.body.isNotEmpty) {
        final data = jsonDecode(resp.body) as List<dynamic>;
        return (data.first as Map).cast<String, dynamic>();
      }
      return {};
    }
    throw Exception('updatePromotion failed: ${resp.statusCode} ${resp.body}');
  }

  /// soft-delete promotion (ตั้ง delete_flag='Y')
  static Future<bool> deletePromotion(String id, {String? userUpdates}) async {
    final url = Uri.parse('$baseUrl/rest/v1/promotions?id=eq.$id');
    final body = {
      'delete_flag': 'Y',
      'updated_at': DateTime.now().toIso8601String(),
      if (userUpdates != null) 'user_updates': userUpdates,
    };
    final resp = await http.patch(url, headers: _headers, body: jsonEncode(body));
    return resp.statusCode == 200 || resp.statusCode == 204;
  }

  /// สร้าง OTP (6 หลัก) และบันทึกใน DB พร้อมกำหนดเวลาหมดอายุ
  static Future<String> generatePasswordResetOTP(String email) async {
    // สร้าง OTP 6 หลัก
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString(); // 6 digits
    
    // กำหนดเวลาหมดอายุ (15 นาที)
    final expiresAt = DateTime.now().add(Duration(minutes: 15)).toIso8601String();
    
    final url = Uri.parse('$baseUrl/rest/v1/users?email=eq.$email');
    final body = jsonEncode({
      'reset_otp': otp,
      'reset_otp_expires_at': expiresAt,
    });
    
    final resp = await http.patch(url, headers: _headers, body: body);
    
    if (resp.statusCode == 200 || resp.statusCode == 204) {
      return otp;
    }
    
    throw Exception('generatePasswordResetOTP failed: ${resp.statusCode} ${resp.body}');
  }

  /// ตรวจสอบ OTP และรีเซ็ตรหัสผ่าน (ใช้ RPC function)
  static Future<bool> verifyOTPAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/rest/v1/rpc/reset_user_password');
    final body = jsonEncode({
      'user_email': email,
      'user_otp': otp,
      'new_password': newPassword,
    });
    
    final resp = await http.post(url, headers: _headers, body: body);
    
    if (resp.statusCode == 200) {
      final result = jsonDecode(resp.body);
      if (result['success'] == true) {
        return true;
      } else {
        throw Exception(result['message'] ?? 'เกิดข้อผิดพลาด');
      }
    }
    
    throw Exception('verifyOTPAndResetPassword failed: ${resp.statusCode} ${resp.body}');
  }

  /// ปฏิเสธผู้ใช้ (ตั้งค่า is_approve = false แทน null)
  static Future<void> rejectUser(String userId) async {
    final url = Uri.parse('$baseUrl/rest/v1/users?id=eq.$userId');
    
    final body = jsonEncode({
      'is_approve': false,
      'rejected_at': DateTime.now().toIso8601String(),
    });
    
    if (kDebugMode) {
      print('🔴 rejectUser - URL: $url');
      print('🔴 rejectUser - userId: $userId');
      print('🔴 rejectUser - body: $body');
    }
    
    final resp = await http.patch(url, headers: _headers, body: body);
    
    if (kDebugMode) {
      print('🔴 rejectUser - status: ${resp.statusCode}');
      print('🔴 rejectUser - response: ${resp.body}');
    }
    
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('rejectUser failed: ${resp.statusCode} ${resp.body}');
    }
  }

  /// ดึง top N สินค้าตาม rent_amount (มาก -> น้อย)
  static Future<List<Map<String, dynamic>>> getPopularProducts({int limit = 10, bool onlyActive = false}) async {
    final activeFilter = onlyActive ? '&is_active=eq.true' : '';
    final url = Uri.parse(
      '$baseUrl/rest/v1/products?select=*&order=rent_amount.desc&limit=$limit&last_status=eq.Available$activeFilter&or=(delete_flag.eq.N,delete_flag.is.null)',
    );

    final resp = await http.get(url, headers: _headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('getPopularProducts failed: ${resp.statusCode} ${resp.body}');
  }

  /// ดึงสินค้าที่มี last_status = 'Available' (เรียงล่าสุดเข้ามาก่อน)
  static Future<List<Map<String, dynamic>>> getAvailableProducts({int limit = 20}) async {
    final url = Uri.parse(
      '$baseUrl/rest/v1/products?select=*&order=created_at.desc&limit=$limit&last_status=eq.Available&or=(delete_flag.eq.N,delete_flag.is.null)',
    );

    final resp = await http.get(url, headers: _headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('getAvailableProducts failed: ${resp.statusCode} ${resp.body}');
  }

  /// ดึง product_id ที่ผู้ใช้กดถูกใจแล้ว (คืนเป็น List<String>)
  static Future<List<String>> getUserLikedProductIds(String userId) async {
    final url = Uri.parse('$baseUrl/rest/v1/product_likes?select=product_id&user_id=eq.$userId');
    if (kDebugMode) print('getUserLikedProductIds: GET $url');
    final resp = await http.get(url, headers: _headers);
    if (kDebugMode) print('getUserLikedProductIds: status=${resp.statusCode} body=${resp.body}');
    if (resp.statusCode == 200) {
      final List<dynamic> data = jsonDecode(resp.body);
      return data.map<String>((e) => (e['product_id'] ?? '').toString()).where((s) => s.isNotEmpty).toList();
    }
    throw Exception('getUserLikedProductIds failed: ${resp.statusCode} ${resp.body}');
  }

  /// สร้าง like ระหว่าง user กับ product
  static Future<bool> createLike(String userId, String productId) async {
    final url = Uri.parse('$baseUrl/rest/v1/product_likes');
    final body = {
      'user_id': userId,
      'product_id': productId,
      'created_at': DateTime.now().toIso8601String(),
    };
    final headers = {..._headers, 'Prefer': 'return=representation'};
    if (kDebugMode) {
      print('createLike: POST $url');
      print('createLike: headers=${headers.keys.toList()}');
      print('createLike: body=${jsonEncode(body)}');
      print('createLike: token length=${Session.instance.accessToken?.length ?? 0}');
    }
    final resp = await http.post(url, headers: headers, body: jsonEncode(body));
    if (kDebugMode) print('createLike: status=${resp.statusCode} body=${resp.body}');

    // ถ้าสำเร็จ (201/200/204) -> true
    if (resp.statusCode == 201 || resp.statusCode == 200 || resp.statusCode == 204) {
      return true;
    }

    // ถ้าเป็น 409 (duplicate key) ให้ถือว่าเป็น success (เพราะอาจถูกกดซ้ำ)
    if (resp.statusCode == 409) {
      if (kDebugMode) print('createLike: got 409 (duplicate) — treat as success');
      return true;
    }

    // Log ข้อความ error เพิ่มเติมสำหรับการดีบัก
    if (kDebugMode) {
      try {
        final err = jsonDecode(resp.body);
        print('createLike error body parsed: $err');
      } catch (_) {
        print('createLike error body (raw): ${resp.body}');
      }
    }

    return false;
  }

  /// ลบ like ของ user สำหรับ product (unlike)
  static Future<bool> deleteLike(String userId, String productId) async {
    final url = Uri.parse('$baseUrl/rest/v1/product_likes?user_id=eq.$userId&product_id=eq.$productId');
    if (kDebugMode) print('deleteLike: DELETE $url');
    final resp = await http.delete(url, headers: _headers);
    if (kDebugMode) print('deleteLike: status=${resp.statusCode} body=${resp.body}');
    return resp.statusCode == 204 || resp.statusCode == 200;
  }

  /// สร้าง cart + cart_items แบบ REST (non-transactional)
  /// ก่อนสร้างจะตรวจว่า user profile มีอยู่ใน `public.users` (ถ้าไม่มีก็พยายามสร้าง)
  /// จำเป็นต้องมี Session.instance.accessToken (JWT) เพื่อผ่าน RLS
  static Future<bool> addToCart(String userId, List<Map<String, dynamic>> items) async {
    try {
      if (kDebugMode) print('addToCart: start for userId=$userId items=${jsonEncode(items)} tokenLen=${Session.instance.accessToken?.length ?? 0}');

      // ต้องมี access token ของผู้ใช้ (JWT) เพื่อเรียก REST ที่มี RLS
      final userToken = Session.instance.accessToken;
      if (userToken == null || userToken.isEmpty) {
        if (kDebugMode) print('addToCart: missing user access token, aborting');
        return false;
      }

      // สร้าง headers ที่ใช้ JWT ของผู้ใช้ (ไม่ใช้ service role ใน client)
      final authHeaders = {
        'apikey': apiKey,
        'Authorization': 'Bearer $userToken',
        'Content-Type': 'application/json',
      };

      // 0) ตรวจว่ามีแถว profile ใน public.users ไหม (ใช้ headers ที่มี JWT)
      final checkUrl = Uri.parse('$baseUrl/rest/v1/users?id=eq.$userId');
      final checkResp = await http.get(checkUrl, headers: authHeaders);
      if (kDebugMode) print('addToCart.checkUser: status=${checkResp.statusCode} body=${checkResp.body}');
      if (checkResp.statusCode == 200) {
        final List<dynamic> existing = jsonDecode(checkResp.body) as List<dynamic>;
        if (existing.isEmpty) {
          // สร้าง profile เบื้องต้น (fields ปรับตาม schema ของคุณ)
          final profile = {
            'id': userId,
            'email': Session.instance.user?['email'] ?? '',
            'created_at': DateTime.now().toIso8601String(),
          };
          if (kDebugMode) print('addToCart: creating profile $profile');

          final createResp = await http.post(
            Uri.parse('$baseUrl/rest/v1/users'),
            headers: {...authHeaders, 'Prefer': 'return=representation'},
            body: jsonEncode(profile),
          );
          if (kDebugMode) print('addToCart.createProfile: status=${createResp.statusCode} body=${createResp.body}');
          if (!(createResp.statusCode == 201 || createResp.statusCode == 200)) {
            if (kDebugMode) print('addToCart: failed to create profile, aborting');
            return false;
          }
        }
      } else {
        if (kDebugMode) print('addToCart: failed to check user existence: ${checkResp.statusCode} ${checkResp.body}');
        return false;
      }

      // 1) สร้าง cart (ใช้ authHeaders)
      final urlCart = Uri.parse('$baseUrl/rest/v1/carts');
      final cartBody = {
        'user_id': userId,
        'status': 'pending',
        'total_amount': 0,
        'currency': 'THB',
        'created_at': DateTime.now().toIso8601String(),
      };
      final headersCart = {...authHeaders, 'Prefer': 'return=representation'};
      if (kDebugMode) print('addToCart: POST $urlCart body=${jsonEncode(cartBody)}');
      var respCart = await http.post(urlCart, headers: headersCart, body: jsonEncode(cartBody));
      if (kDebugMode) print('addToCart.createCart: status=${respCart.statusCode} body=${respCart.body}');

      // If success, continue. If 409 -> try to create profile then retry cart insertion once.
      if (respCart.statusCode == 201 || respCart.statusCode == 200) {
        // ok, continue
      } else if (respCart.statusCode == 409) {
        if (kDebugMode) {
          print('addToCart.createCart: got 409 Conflict, reason=${respCart.reasonPhrase}, body=${respCart.body}');
        }

        final respBody = respCart.body ?? '';

        // Case A: foreign key to users missing -> try create profile then retry
        final isFkToUsers = respBody.contains('is not present in table') && respBody.contains('users') ||
                            respBody.contains('foreign key') && respBody.contains('users');

        if (isFkToUsers) {
          if (kDebugMode) print('addToCart: detected FK -> users missing. Attempting to create profile.');

          final profile = {
            'id': userId,
            'email': Session.instance.user?['email'] ?? '',
            'full_name': Session.instance.user?['full_name'] ?? Session.instance.user?['name'] ?? '',
            'display_name': Session.instance.user?['display_name'] ?? '',
            'phone': Session.instance.user?['phone'] ?? '',
            'created_at': DateTime.now().toIso8601String(),
          };

          if (kDebugMode) print('addToCart: attempting to create missing profile (best-effort) -> $profile');

          final createResp = await http.post(
            Uri.parse('$baseUrl/rest/v1/users'),
            headers: {...authHeaders, 'Prefer': 'return=representation'},
            body: jsonEncode(profile),
          );

          if (kDebugMode) print('addToCart.createProfile-after-409: status=${createResp.statusCode} reason=${createResp.reasonPhrase} body=${createResp.body}');

          if (createResp.statusCode == 201 || createResp.statusCode == 200) {
            if (kDebugMode) print('addToCart: profile created after 409, retrying cart creation');
            respCart = await http.post(urlCart, headers: headersCart, body: jsonEncode(cartBody));
            if (kDebugMode) print('addToCart.createCart.retry: status=${respCart.statusCode} reason=${respCart.reasonPhrase} body=${respCart.body}');
            if (!(respCart.statusCode == 201 || respCart.statusCode == 200)) {
              if (kDebugMode) print('addToCart: retry still failed, aborting');
              return false;
            }
          } else {
            if (kDebugMode) {
              print('addToCart: failed to create profile after 409 — response indicates DB constraint or missing required fields');
              try {
                final parsed = jsonDecode(createResp.body);
                print('addToCart.createProfile-after-409 details: $parsed');
              } catch (_) {
                print('addToCart.createProfile-after-409 raw body: ${createResp.body}');
              }
            }
            return false;
          }

          // continue below (cart created on retry)
        } else {
          // Case B: duplicate/unique constraint on carts (or other duplicate) -> try reuse existing pending cart
          final isDuplicate = respBody.toLowerCase().contains('duplicate') ||
                              respBody.toLowerCase().contains('unique constraint') ||
                              respBody.toLowerCase().contains('already exists');

          if (isDuplicate) {
            if (kDebugMode) print('addToCart: detected duplicate/unique constraint. Trying to find existing pending cart for user.');

            // try to find an existing pending cart for this user
            final findCartUrl = Uri.parse('$baseUrl/rest/v1/carts?user_id=eq.$userId&status=eq.pending&select=*&order=created_at.desc&limit=1');
            final findResp = await http.get(findCartUrl, headers: authHeaders);
            if (kDebugMode) print('addToCart.findExistingCart: status=${findResp.statusCode} reason=${findResp.reasonPhrase} body=${findResp.body}');
            if (findResp.statusCode == 200) {
              final List<dynamic> found = jsonDecode(findResp.body) as List<dynamic>;
              if (found.isNotEmpty) {
                final existingCart = found.first as Map<String, dynamic>;
                final cartIdExisting = existingCart['id'].toString();
                if (kDebugMode) print('addToCart: using existing cart id=$cartIdExisting');
                // set respCart to a faux-success response containing the existing cart representation
                respCart = http.Response(jsonEncode([existingCart]), 200, request: respCart.request);
              } else {
                if (kDebugMode) print('addToCart: no existing pending cart found for user; cannot resolve 409 automatically.');
                return false;
              }
            } else {
              if (kDebugMode) print('addToCart: failed to query existing carts: ${findResp.statusCode} ${findResp.body}');
              return false;
            }
          } else {
            // Unknown 409 cause -> surface body and abort
            if (kDebugMode) {
              print('addToCart: received 409 but could not classify it. resp body: ${respBody}');
            }
            return false;
          }
        }
      } else {
        // other error codes (401/403/4xx/5xx) -> abort
        if (kDebugMode) print('addToCart: create cart failed with status ${respCart.statusCode}');
        return false;
      }

      final cartData = jsonDecode(respCart.body) as List<dynamic>;
      final cartId = (cartData.first as Map)['id'].toString();

      double total = 0.0;

      // 2) เพิ่ม cart_items ทีละรายการ (ใช้ authHeaders)
      for (final it in items) {
        final productId = it['product_id'];
        final quantity = (it['quantity'] ?? 1) is int ? (it['quantity'] as int) : int.tryParse(it['quantity'].toString()) ?? 1;
        final unitPrice = (it['unit_price'] is num) ? (it['unit_price'] as num).toDouble() : double.tryParse(it['unit_price'].toString()) ?? 0.0;
        final itemBody = {
          'cart_id': cartId,
          'product_id': productId,
          'quantity': quantity,
          'unit_price': unitPrice,
          'rent_start': it['rent_start'],
          'rent_end': it['rent_end'],
          'created_at': DateTime.now().toIso8601String(),
          'status': 'reserved',
        };
        final urlItem = Uri.parse('$baseUrl/rest/v1/cart_items');
        if (kDebugMode) print('addToCart: POST $urlItem body=${jsonEncode(itemBody)}');
        final respItem = await http.post(urlItem, headers: {...authHeaders, 'Prefer': 'return=representation'}, body: jsonEncode(itemBody));
        if (kDebugMode) print('addToCart.addItem: status=${respItem.statusCode} body=${respItem.body}');
        if (!(respItem.statusCode == 201 || respItem.statusCode == 200)) {
          if (kDebugMode) print('addToCart: failed to add item, aborting');
          return false;
        }

        // 3) อัพเดตสถานะสินค้าเป็น Reserved (ใช้ authHeaders)
        final urlProd = Uri.parse('$baseUrl/rest/v1/products?id=eq.$productId');
        final respProd = await http.patch(urlProd, headers: authHeaders, body: jsonEncode({'last_status': 'Reserved', 'updated_at': DateTime.now().toIso8601String()}));
        if (kDebugMode) print('addToCart.reserveProd $productId: status=${respProd.statusCode} body=${respProd.body}');
        total += quantity * unitPrice;
      }

      // 4) อัปเดต total ใน cart (ใช้ authHeaders)
      final urlUpdate = Uri.parse('$baseUrl/rest/v1/carts?id=eq.$cartId');
      final respUpd = await http.patch(urlUpdate, headers: authHeaders, body: jsonEncode({'total_amount': total, 'updated_at': DateTime.now().toIso8601String()}));
      if (kDebugMode) print('addToCart.updateCartTotal: status=${respUpd.statusCode} body=${respUpd.body}');

      return true;
    } catch (e) {
      if (kDebugMode) print('addToCart exception: $e');
      return false;
    }
  }

  /// ดึง cart_items ของผู้ใช้ (จะเลือก cart ล่าสุดที่ status = 'pending')
  /// คืนค่า List ของ item แต่ละชิ้นที่มีข้อมูล product (ถ้ามี)
  static Future<List<Map<String, dynamic>>> getCartItemsForUser(String userId) async {
    try {
      // ใช้ JWT ของ session ถ้ามี (fallback เป็น apiKey)
      final token = Session.instance.accessToken ?? apiKey;
      final headers = {
        'apikey': apiKey,
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      // 1) หา cart ล่าสุดของผู้ใช้ที่ status = pending
      final cartUrl = Uri.parse('$baseUrl/rest/v1/carts?user_id=eq.$userId&status=eq.pending&order=created_at.desc&limit=1');
      if (kDebugMode) {
        print('getCartItemsForUser: GET $cartUrl');
        print('getCartItemsForUser.headers: $headers');
      }
      final cartResp = await http.get(cartUrl, headers: headers);
      if (kDebugMode) print('getCartItemsForUser.carts: status=${cartResp.statusCode} body=${cartResp.body}');
      if (cartResp.statusCode != 200) {
        if (kDebugMode) print('getCartItemsForUser: carts request failed -> ${cartResp.statusCode}');
        return [];
      }

      final List<dynamic> carts = jsonDecode(cartResp.body) as List<dynamic>;
      if (carts.isEmpty) return [];

      final cartId = (carts.first as Map)['id'].toString();

      // 2) ดึง cart_items ของ cartId
      final itemsUrl = Uri.parse('$baseUrl/rest/v1/cart_items?cart_id=eq.$cartId');
      if (kDebugMode) print('getCartItemsForUser: GET $itemsUrl');
      final itemsResp = await http.get(itemsUrl, headers: headers);
      if (kDebugMode) print('getCartItemsForUser.cart_items: status=${itemsResp.statusCode} body=${itemsResp.body}');
      if (itemsResp.statusCode != 200) {
        if (kDebugMode) print('getCartItemsForUser: cart_items request failed -> ${itemsResp.statusCode}');
        return [];
      }

      final List<dynamic> items = jsonDecode(itemsResp.body) as List<dynamic>;
      if (items.isEmpty) return [];

      // 3) รวบ product ids และดึงข้อมูล product แบบเป็นชุด
      final productIds = items
          .map((e) => (e['product_id'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();

      List<Map<String, dynamic>> products = [];
      if (productIds.isNotEmpty) {
        // Supabase expects id=in.(id1,id2). Ensure ids are safe (no spaces) and separated by commas.
        final joined = productIds.map((id) => id.trim()).join(',');
        final prodUrl = Uri.parse('$baseUrl/rest/v1/products?id=in.($joined)');
        if (kDebugMode) print('getCartItemsForUser: GET $prodUrl');
        final prodResp = await http.get(prodUrl, headers: headers);
        if (kDebugMode) print('getCartItemsForUser.products: status=${prodResp.statusCode} body=${prodResp.body}');
        if (prodResp.statusCode == 200) {
          try {
            products = (jsonDecode(prodResp.body) as List<dynamic>).cast<Map<String, dynamic>>();
          } catch (e) {
            if (kDebugMode) print('getCartItemsForUser: failed to parse products body: $e');
          }
        }
      }

      // 4) สร้าง map product_id -> product
      final Map<String, Map<String, dynamic>> prodMap = {};
      for (final p in products) {
        if (p['id'] != null) prodMap[p['id'].toString()] = p;
      }

      // 5) รวมข้อมูลกลับเป็นรายการที่ UI คาดหวัง
      final result = items.map<Map<String, dynamic>>((it) {
        final pid = (it['product_id'] ?? '').toString();
        final prod = prodMap[pid];
        return {
          'cart_id': cartId,
          'item_id': it['id']?.toString() ?? '',
          'product_id': pid,
          'name': prod != null ? (prod['name'] ?? prod['title'] ?? 'สินค้า') : (it['name'] ?? 'สินค้า'),
          'price': (it['unit_price'] ?? prod?['rent_amount'] ?? 0),
          'image': prod != null ? (prod['image'] ?? prod['image_url'] ?? '') : '',
          'quantity': it['quantity'] ?? 1,
          'rent_start': it['rent_start'],
          'rent_end': it['rent_end'],
        };
      }).toList();

      return result;
    } catch (e, st) {
      if (kDebugMode) {
        print('getCartItemsForUser exception: $e');
        print(st);
      }
      return [];
    }
  }

  /// ลบ cart_item และอัพเดตสถานะสินค้า + ยอดรวมของ cart
  static Future<bool> deleteCartItem(String itemId, {String? productId, String? cartId}) async {
    try {
      final userToken = Session.instance.accessToken;
      if (userToken == null || userToken.isEmpty) {
        if (kDebugMode) print('deleteCartItem: missing user token');
        return false;
      }

      final headers = {
        'apikey': apiKey,
        'Authorization': 'Bearer $userToken',
        'Content-Type': 'application/json',
      };

      // 1) ลบ cart_item
      final urlDel = Uri.parse('$baseUrl/rest/v1/cart_items?id=eq.$itemId');
      final delResp = await http.delete(urlDel, headers: headers);
      if (kDebugMode) print('deleteCartItem.delete: status=${delResp.statusCode} body=${delResp.body}');
      if (!(delResp.statusCode == 200 || delResp.statusCode == 204)) {
        return false;
      }

      // 2) ถ้ามี productId -> อัพเดตสถานะ product กลับเป็น Available
      if (productId != null && productId.isNotEmpty) {
        final urlProd = Uri.parse('$baseUrl/rest/v1/products?id=eq.$productId');
        final prodResp = await http.patch(
          urlProd,
          headers: headers,
          body: jsonEncode({'last_status': 'Available', 'updated_at': DateTime.now().toIso8601String()}),
        );
        if (kDebugMode) print('deleteCartItem.updateProduct: status=${prodResp.statusCode} body=${prodResp.body}');
      }

      // 3) ถ้ามี cartId -> คำนวณยอดรวมใหม่และอัพเดต carts.total_amount
      if (cartId != null && cartId.isNotEmpty) {
        final itemsUrl = Uri.parse('$baseUrl/rest/v1/cart_items?cart_id=eq.$cartId');
        final itemsResp = await http.get(itemsUrl, headers: headers);
        if (kDebugMode) print('deleteCartItem.fetchItems: status=${itemsResp.statusCode} body=${itemsResp.body}');
        if (itemsResp.statusCode == 200) {
          final List<dynamic> items = jsonDecode(itemsResp.body) as List<dynamic>;
          double total = 0.0;
          for (final it in items) {
            final unit = (it['unit_price'] is num) ? (it['unit_price'] as num).toDouble() : double.tryParse(it['unit_price']?.toString() ?? '0') ?? 0.0;
            final qty = (it['quantity'] is num) ? (it['quantity'] as num).toDouble() : double.tryParse(it['quantity']?.toString() ?? '0') ?? 0.0;
            total += unit * qty;
          }
          final urlUpdate = Uri.parse('$baseUrl/rest/v1/carts?id=eq.$cartId');
          final respUpd = await http.patch(urlUpdate, headers: headers, body: jsonEncode({'total_amount': total, 'updated_at': DateTime.now().toIso8601String()}));
          if (kDebugMode) print('deleteCartItem.updateCartTotal: status=${respUpd.statusCode} body=${respUpd.body}');

          return true;
        } else {
          if (kDebugMode) print('deleteCartItem: failed to fetch remaining items: ${itemsResp.statusCode}');
        }
      }

      return true;
    } catch (e, st) {
      if (kDebugMode) {
        print('deleteCartItem exception: $e');
        print(st);
      }
      return false;
    }
  }

  /// คืนจำนวน cart_items ของ cart ล่าสุดของ user (fallback โดยไม่กรอง status)
  static Future<int> getCartItemCountForUser(String userId) async {
    try {
      final token = Session.instance.accessToken ?? apiKey;
      final headers = {
        'apikey': apiKey,
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      // 1) พยายามหา cart ล่าสุดของผู้ใช้ (ไม่จำกัด status)
      final cartUrl = Uri.parse('$baseUrl/rest/v1/carts?user_id=eq.$userId&order=created_at.desc&limit=1');
      if (kDebugMode) print('getCartItemCountForUser: GET $cartUrl');
      final cartResp = await http.get(cartUrl, headers: headers);
      if (kDebugMode) print('getCartItemCountForUser.carts: status=${cartResp.statusCode} body=${cartResp.body}');
      if (cartResp.statusCode == 200) {
        final List<dynamic> carts = jsonDecode(cartResp.body) as List<dynamic>;
        if (carts.isNotEmpty) {
          final cartId = (carts.first as Map)['id'].toString();
          // ดึงจำนวน cart_items สำหรับ cartId
          final itemsUrl = Uri.parse('$baseUrl/rest/v1/cart_items?cart_id=eq.$cartId&select=id');
          if (kDebugMode) print('getCartItemCountForUser: GET $itemsUrl');
          final itemsResp = await http.get(itemsUrl, headers: headers);
          if (kDebugMode) print('getCartItemCountForUser.cart_items: status=${itemsResp.statusCode} body=${itemsResp.body}');
          if (itemsResp.statusCode == 200) {
            final List<dynamic> items = jsonDecode(itemsResp.body) as List<dynamic>;
            if (kDebugMode) print('getCartItemCountForUser: cartId=$cartId count=${items.length}');
            return items.length;
          } else {
            if (kDebugMode) print('getCartItemCountForUser: failed to fetch cart_items for cartId=$cartId');
          }
        } else {
          if (kDebugMode) print('getCartItemCountForUser: no carts found for userId=$userId');
        }
      } else {
        if (kDebugMode) print('getCartItemCountForUser: carts request failed with ${cartResp.statusCode}');
      }

      // 2) FALLBACK: ดึง cart_items โดย join กับ cart และกรอง cart.user_id
      // Supabase REST สามารถ embed ความสัมพันธ์: select=id,cart(user_id)
      final fallbackUrl = Uri.parse('$baseUrl/rest/v1/cart_items?select=id,cart(user_id)&cart.user_id=eq.$userId');
      if (kDebugMode) print('getCartItemCountForUser: FALLBACK GET $fallbackUrl');
      final fallbackResp = await http.get(fallbackUrl, headers: headers);
      if (kDebugMode) print('getCartItemCountForUser.fallback: status=${fallbackResp.statusCode} body=${fallbackResp.body}');
      if (fallbackResp.statusCode == 200) {
        final List<dynamic> items = jsonDecode(fallbackResp.body) as List<dynamic>;
        if (kDebugMode) print('getCartItemCountForUser: fallback count=${items.length}');
        return items.length;
      } else {
        if (kDebugMode) print('getCartItemCountForUser: fallback request failed ${fallbackResp.statusCode}');
      }

      return 0;
    } catch (e, st) {
      if (kDebugMode) {
        print('getCartItemCountForUser exception: $e');
        print(st);
      }
      return 0;
    }
  }
}

// helper top-level เพื่อใช้ compute
dynamic _parseJson(String body) => jsonDecode(body);
