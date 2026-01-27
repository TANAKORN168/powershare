import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:powershare/models/responseModel.dart';
import 'package:flutter/foundation.dart';
import 'package:powershare/services/auth_service.dart';
import 'package:powershare/services/category_service.dart';
import 'package:powershare/services/session.dart';
import 'api_config.dart';
import 'payment_service.dart';

// Re-export all services for convenience
export 'api_config.dart';
export 'auth_service.dart';
export 'category_service.dart';
export 'payment_service.dart';

// Alias class สำหรับ backward compatibility
class ApiServices {
  /// อัปเดตสถานะของสินค้า (Product)
  static Future<void> updateProductStatus({
    required String productId,
    required String status,
  }) async {
    final payload = {
      'last_status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    await updateProduct(productId, payload);
  }

  /// เรียก Edge Function เพื่อส่ง push notification ไปยังผู้ใช้ (FCM)
  static Future<void> sendPushNotificationToUser({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      final token = Session.instance.accessToken ?? ApiConfig.apiKey;
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/functions/v1/send-push-notification',
      );
      final headers = {
        'apikey': ApiConfig.apiKey,
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      final payload = jsonEncode({
        'user_id': userId,
        'title': title,
        'body': body,
      });
      final resp = await _post(url, headers: headers, body: payload);
      if (kDebugMode) {
        print(
          '[sendPushNotificationToUser] status=[32m${resp.statusCode}[0m body=${resp.body}',
        );
      }
    } catch (e) {
      if (kDebugMode) print('[sendPushNotificationToUser] error: $e');
    }
  }

  // Auth
  static final login = AuthService.login;
  static final signup = AuthService.signup;
  static final checkAndRefreshToken = AuthService.checkAndRefreshToken;
  static final generatePasswordResetOTP = AuthService.generatePasswordResetOTP;
  static final verifyOTPAndResetPassword =
      AuthService.verifyOTPAndResetPassword;

  // Centralized HTTP wrappers to handle 401 (force login) globally
  static Future<http.Response> _get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final resp = await http.get(url, headers: headers ?? ApiConfig.headers);
    if (resp.statusCode == 401) {
      if (kDebugMode) print('[ApiServices] Unauthorized (401) on GET $url');
      try {
        Session.instance.accessToken = null;
        Session.instance.user = null;
      } catch (_) {}
      throw Exception('UNAUTHORIZED');
    }
    return resp;
  }

  static Future<http.Response> _post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final resp = await http.post(
      url,
      headers: headers ?? ApiConfig.headers,
      body: body,
    );
    if (resp.statusCode == 401) {
      if (kDebugMode) print('[ApiServices] Unauthorized (401) on POST $url');
      try {
        Session.instance.accessToken = null;
        Session.instance.user = null;
      } catch (_) {}
      throw Exception('UNAUTHORIZED');
    }
    return resp;
  }

  static Future<http.Response> _patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final resp = await http.patch(
      url,
      headers: headers ?? ApiConfig.headers,
      body: body,
    );
    if (resp.statusCode == 401) {
      if (kDebugMode) print('[ApiServices] Unauthorized (401) on PATCH $url');
      try {
        Session.instance.accessToken = null;
        Session.instance.user = null;
      } catch (_) {}
      throw Exception('UNAUTHORIZED');
    }
    return resp;
  }

  static Future<http.Response> _delete(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final resp = await http.delete(url, headers: headers ?? ApiConfig.headers);
    if (resp.statusCode == 401) {
      if (kDebugMode) print('[ApiServices] Unauthorized (401) on DELETE $url');
      try {
        Session.instance.accessToken = null;
        Session.instance.user = null;
      } catch (_) {}
      throw Exception('UNAUTHORIZED');
    }
    return resp;
  }

  static Future<http.Response> _put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final resp = await http.put(
      url,
      headers: headers ?? ApiConfig.headers,
      body: body,
    );
    if (resp.statusCode == 401) {
      if (kDebugMode) print('[ApiServices] Unauthorized (401) on PUT $url');
      try {
        Session.instance.accessToken = null;
        Session.instance.user = null;
      } catch (_) {}
      throw Exception('UNAUTHORIZED');
    }
    return resp;
  }

  // Categories
  static final getCategories = CategoryService.getCategories;
  static final createCategory = CategoryService.createCategory;
  static final updateCategory = CategoryService.updateCategory;
  static final deleteCategory = CategoryService.deleteCategory;

  // Products - ยังไม่ได้แยก ใช้จาก ApiServicesLegacy ก่อน
  static Future<List<Map<String, dynamic>>> getProducts({
    bool onlyActive = false,
  }) async {
    final activeFilter = onlyActive ? '&is_active=eq.true' : '';
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/rest/v1/products?select=*&order=created_at.desc$activeFilter&or=(delete_flag.eq.N,delete_flag.is.null)',
    );
    final resp = await _get(url, headers: ApiConfig.headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('getProducts failed: ${resp.statusCode} ${resp.body}');
  }

  static Future<Map<String, dynamic>> createProduct(
    Map<String, dynamic> payload,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/products');
    final headers = {...ApiConfig.headers, 'Prefer': 'return=representation'};
    final resp = await _post(url, headers: headers, body: jsonEncode(payload));
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return (data.first as Map).cast<String, dynamic>();
    }
    throw Exception('createProduct failed: ${resp.statusCode} ${resp.body}');
  }

  static Future<Map<String, dynamic>> updateProduct(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/products?id=eq.$id');
    final headers = {...ApiConfig.headers, 'Prefer': 'return=representation'};
    final resp = await _patch(url, headers: headers, body: jsonEncode(payload));
    if (resp.statusCode == 200 || resp.statusCode == 204) {
      if (resp.body.isNotEmpty) {
        final data = jsonDecode(resp.body) as List<dynamic>;
        return (data.first as Map).cast<String, dynamic>();
      }
      return payload;
    }
    throw Exception('updateProduct failed: ${resp.statusCode} ${resp.body}');
  }

  static Future<bool> deleteProduct(String id, {String? userUpdates}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/products?id=eq.$id');
    final body = {
      'delete_flag': 'Y',
      'updated_at': DateTime.now().toIso8601String(),
      if (userUpdates != null) 'user_updates': userUpdates,
    };
    final resp = await _patch(
      url,
      headers: ApiConfig.headers,
      body: jsonEncode(body),
    );
    return resp.statusCode == 200 || resp.statusCode == 204;
  }

  static Future<List<Map<String, dynamic>>> getPopularProducts({
    int limit = 10,
    bool onlyActive = false,
  }) async {
    final activeFilter = onlyActive ? '&is_active=eq.true' : '';
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/rest/v1/products?select=*&order=rent_amount.desc&limit=$limit&last_status=eq.AVAILABLE$activeFilter&or=(delete_flag.eq.N,delete_flag.is.null)',
    );
    final resp = await _get(url, headers: ApiConfig.headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(
      'getPopularProducts failed: ${resp.statusCode} ${resp.body}',
    );
  }

  static Future<List<Map<String, dynamic>>> getAvailableProducts({
    int limit = 20,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/rest/v1/products?select=*&order=created_at.desc&limit=$limit&last_status=eq.AVAILABLE&or=(delete_flag.eq.N,delete_flag.is.null)',
    );
    final resp = await _get(url, headers: ApiConfig.headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(
      'getAvailableProducts failed: ${resp.statusCode} ${resp.body}',
    );
  }

  // Upload
  static Future<String> uploadUserFiles(
    File file, {
    String subfolder = 'users',
  }) async {
    const bucketName = 'powershare-files';
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}${extension(file.path)}';
    final folder = subfolder.replaceAll(RegExp(r'^/+|/+$'), '');
    final filePath = '$folder/$fileName';
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/storage/v1/object/$bucketName/$filePath',
    );
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

    final request = http.Request('POST', uri)
      ..headers.addAll({
        'Authorization': 'Bearer ${ApiConfig.apiKey}',
        'Content-Type': mimeType,
      })
      ..bodyBytes = await file.readAsBytes();

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return '${ApiConfig.baseUrl}/storage/v1/object/public/$bucketName/$filePath';
    } else {
      debugPrint('Upload failed: ${response.statusCode} ${response.body}');
      return '';
    }
  }

  static Future<String> uploadProductFile(File file) async {
    return uploadUserFiles(file, subfolder: 'products');
  }

  static Future<String> uploadFile(
    File file, {
    required String bucket,
    String? filename,
    String folder = 'products',
  }) async {
    final name = filename ?? basename(file.path);
    final encodedName = Uri.encodeComponent(name);
    final cleanFolder = folder.replaceAll(RegExp(r'^/+|/+$'), '');
    final objectPath = '$cleanFolder/$encodedName';
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/storage/v1/object/$bucket/$objectPath',
    );

    final bytes = await file.readAsBytes();
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final headers = {
      'Authorization': 'Bearer ${ApiConfig.apiKey}',
      'apikey': ApiConfig.apiKey,
      'Content-Type': mimeType,
    };

    final resp = await _put(url, headers: headers, body: bytes);

    if (resp.statusCode == 200) {
      return '${ApiConfig.baseUrl}/storage/v1/object/public/$bucket/$objectPath';
    }
    throw Exception(
      'uploadFile failed: status=${resp.statusCode}, body=${resp.body}',
    );
  }

  // Users
  static Future<List<dynamic>> getUsers(String accessToken) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/users');
    final tokenToUse = accessToken.isNotEmpty
        ? accessToken
        : Session.instance.accessToken ?? ApiConfig.apiKey;
    final headers = {
      'apikey': ApiConfig.apiKey,
      'Authorization': 'Bearer $tokenToUse',
      'Content-Type': 'application/json',
    };
    final response = await _get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('getUsers failed: ${response.statusCode} ${response.body}');
  }

  static Future<ResponseModel> addUsers(
    String table,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/$table');
    final json = jsonEncode(data);
    final response = await _post(url, headers: ApiConfig.headers, body: json);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return ResponseModel(
        responseCode: 'SUCCESS',
        responseMessage: 'เพิ่มข้อมูลสำเร็จ',
      );
    } else {
      String errorMessage = 'เพิ่มข้อมูลไม่สำเร็จ';
      if (response.body.isNotEmpty) {
        final responseData = jsonDecode(response.body);
        errorMessage = responseData['message'];
      }
      return ResponseModel(responseCode: 'FAIL', responseMessage: errorMessage);
    }
  }

  static Future<List<Map<String, dynamic>>?> getPendingUsers() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/rpc/get_pending_users');
    final response = await _post(url, headers: ApiConfig.headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return null;
  }

  static Future<int> getPendingReservationCount() async {
    try {
      final token = Session.instance.accessToken ?? ApiConfig.apiKey;
      final headers = {
        'apikey': ApiConfig.apiKey,
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      // นับรายการจองที่รออนุมัติ (RESERVED) เฉพาะ cart ที่จ่ายเงินแล้ว
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/cart_items?select=id,carts(status,paid_at)&status=eq.RESERVED',
      );

      final resp = await _get(url, headers: headers);
      if (resp.statusCode != 200) return 0;

      final data = jsonDecode(resp.body) as List<dynamic>;
      var count = 0;
      for (final row in data.cast<Map<String, dynamic>>()) {
        final carts = row['carts'];
        if (carts is! Map<String, dynamic>) continue;
        final cartStatus = (carts['status'] ?? '').toString();
        final paidAt = carts['paid_at'];
        final isPaid =
            cartStatus.trim().toUpperCase() == 'PAID' ||
            (paidAt != null && paidAt.toString().isNotEmpty);
        if (isPaid) count++;
      }
      return count;
    } catch (e) {
      if (kDebugMode) print('getPendingReservationCount error: $e');
      return 0;
    }
  }

  static Future<int> getAdminPendingCount() async {
    try {
      final pendingUsers = await getPendingUsers();
      final userCount = pendingUsers?.length ?? 0;
      final reservationCount = await getPendingReservationCount();
      return userCount + reservationCount;
    } catch (e) {
      if (kDebugMode) print('getAdminPendingCount error: $e');
      return 0;
    }
  }

  static Future<void> notifyAdminsPayment({
    required String cartId,
    required double totalAmount,
    String? slipUrl,
  }) async {
    try {
      final token = Session.instance.accessToken ?? ApiConfig.apiKey;
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/functions/v1/send-push-notification',
      );
      final headers = {
        'apikey': ApiConfig.apiKey,
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      final payload = jsonEncode({
        'cart_id': cartId,
        'total_amount': totalAmount,
        if (slipUrl != null && slipUrl.isNotEmpty) 'slip_url': slipUrl,
      });

      final resp = await _post(url, headers: headers, body: payload);
      if (kDebugMode) {
        print(
          '[notifyAdminsPayment] status=${resp.statusCode} body=${resp.body}',
        );
      }
    } catch (e) {
      if (kDebugMode) print('[notifyAdminsPayment] error: $e');
    }
  }

  static Future<void> notifyAdminsNewUser({
    required String userId,
    required String email,
    String? name,
    String? surname,
  }) async {
    try {
      final token = Session.instance.accessToken ?? ApiConfig.apiKey;
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/functions/v1/notify-admins-new-user',
      );
      final headers = {
        'apikey': ApiConfig.apiKey,
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      final payload = jsonEncode({
        'user_id': userId,
        'email': email,
        if (name != null && name.isNotEmpty) 'name': name,
        if (surname != null && surname.isNotEmpty) 'surname': surname,
      });

      final resp = await _post(url, headers: headers, body: payload);
      if (kDebugMode) {
        print(
          '[notifyAdminsNewUser] status=${resp.statusCode} body=${resp.body}',
        );
      }
    } catch (e) {
      if (kDebugMode) print('[notifyAdminsNewUser] error: $e');
    }
  }

  static Future<bool> setUserApproval(
    String id, {
    required bool approve,
    String? role,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/users?id=eq.$id');
    final payload = <String, dynamic>{'is_approve': approve};
    if (role != null) payload['role'] = role;
    final response = await _patch(
      url,
      headers: ApiConfig.headers,
      body: jsonEncode(payload),
    );
    return response.statusCode == 204 || response.statusCode == 200;
  }

  static Future<void> rejectUser(String userId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/users?id=eq.$userId');
    final body = jsonEncode({
      'is_approve': false,
      'rejected_at': DateTime.now().toIso8601String(),
    });
    final resp = await _patch(url, headers: ApiConfig.headers, body: body);
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('rejectUser failed: ${resp.statusCode} ${resp.body}');
    }
  }

  // Likes
  static Future<List<String>> getUserLikedProductIds(String userId) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/rest/v1/product_likes?select=product_id&user_id=eq.$userId',
    );
    final resp = await _get(url, headers: ApiConfig.headers);
    if (resp.statusCode == 200) {
      final List<dynamic> data = jsonDecode(resp.body);
      return data
          .map<String>((e) => (e['product_id'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    throw Exception(
      'getUserLikedProductIds failed: ${resp.statusCode} ${resp.body}',
    );
  }

  static Future<bool> createLike(String userId, String productId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/product_likes');
    final body = {
      'user_id': userId,
      'product_id': productId,
      'created_at': DateTime.now().toIso8601String(),
    };
    final headers = {...ApiConfig.headers, 'Prefer': 'return=representation'};
    final resp = await _post(url, headers: headers, body: jsonEncode(body));
    if (resp.statusCode == 201 ||
        resp.statusCode == 200 ||
        resp.statusCode == 204 ||
        resp.statusCode == 409) {
      return true;
    }
    return false;
  }

  static Future<bool> deleteLike(String userId, String productId) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/rest/v1/product_likes?user_id=eq.$userId&product_id=eq.$productId',
    );
    final resp = await _delete(url, headers: ApiConfig.headers);
    return resp.statusCode == 204 || resp.statusCode == 200;
  }

  // Promotions
  static Future<List<Map<String, dynamic>>> getPromotions({
    bool onlyActive = false,
  }) async {
    final activeFilter = onlyActive ? '&is_active=eq.true' : '';
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/rest/v1/promotions?select=*&order="order".asc,created_at.desc$activeFilter&or=(delete_flag.eq.N,delete_flag.is.null)',
    );
    final resp = await _get(url, headers: ApiConfig.headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('getPromotions failed: ${resp.statusCode} ${resp.body}');
  }

  static Future<Map<String, dynamic>> createPromotion({
    required String text,
    bool isActive = true,
    int order = 999,
    String? userCreated,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/promotions');
    final body = {
      'text': text,
      'is_active': isActive,
      'order': order,
      'delete_flag': 'N',
      'created_at': DateTime.now().toIso8601String(),
      if (userCreated != null) 'user_created': userCreated,
    };
    final headers = {...ApiConfig.headers, 'Prefer': 'return=representation'};
    final resp = await _post(url, headers: headers, body: jsonEncode(body));
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return (data.first as Map).cast<String, dynamic>();
    }
    throw Exception('createPromotion failed: ${resp.statusCode} ${resp.body}');
  }

  static Future<Map<String, dynamic>> updatePromotion(
    String id, {
    String? text,
    bool? isActive,
    int? order,
    String? userUpdates,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/promotions?id=eq.$id');
    final body = <String, dynamic>{};
    if (text != null) body['text'] = text;
    if (isActive != null) body['is_active'] = isActive;
    if (order != null) body['order'] = order;
    if (userUpdates != null) body['user_updates'] = userUpdates;
    body['updated_at'] = DateTime.now().toIso8601String();

    final headers = {...ApiConfig.headers, 'Prefer': 'return=representation'};
    final resp = await _patch(url, headers: headers, body: jsonEncode(body));
    if (resp.statusCode == 200 || resp.statusCode == 204) {
      if (resp.body.isNotEmpty) {
        final data = jsonDecode(resp.body) as List<dynamic>;
        return (data.first as Map).cast<String, dynamic>();
      }
      return {};
    }
    throw Exception('updatePromotion failed: ${resp.statusCode} ${resp.body}');
  }

  static Future<bool> deletePromotion(String id, {String? userUpdates}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/promotions?id=eq.$id');
    final body = {
      'delete_flag': 'Y',
      'updated_at': DateTime.now().toIso8601String(),
      if (userUpdates != null) 'user_updates': userUpdates,
    };
    final resp = await _patch(
      url,
      headers: ApiConfig.headers,
      body: jsonEncode(body),
    );
    return resp.statusCode == 200 || resp.statusCode == 204;
  }

  // Payment Settings ← เพิ่มส่วนนี้
  static final getPaymentSettings = PaymentService.getPaymentSettings;
  static final updatePaymentSettings = PaymentService.updatePaymentSettings;
  static final createPaymentSettings = PaymentService.createPaymentSettings;
  static final setPaymentSettingsActive =
      PaymentService.setPaymentSettingsActive;

  // Cart (ย้ายมาจาก ApiServicesV2)
  static Future<bool> addToCart(
    String userId,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final userToken = Session.instance.accessToken;
      if (userToken == null || userToken.isEmpty) {
        if (kDebugMode) print('addToCart: missing user access token');
        return false;
      }

      final authHeaders = {
        'apikey': ApiConfig.apiKey,
        'Authorization': 'Bearer $userToken',
        'Content-Type': 'application/json',
      };

      // ตรวจสอบ user profile
      final checkUrl = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/users?id=eq.$userId',
      );
      final checkResp = await _get(checkUrl, headers: authHeaders);
      if (checkResp.statusCode == 200) {
        final List<dynamic> existing = jsonDecode(checkResp.body);
        if (existing.isEmpty) {
          final profile = {
            'id': userId,
            'email': Session.instance.user?['email'] ?? '',
            'created_at': DateTime.now().toIso8601String(),
          };
          final createResp = await _post(
            Uri.parse('${ApiConfig.baseUrl}/rest/v1/users'),
            headers: {...authHeaders, 'Prefer': 'return=representation'},
            body: jsonEncode(profile),
          );
          if (!(createResp.statusCode == 201 || createResp.statusCode == 200)) {
            return false;
          }
        }
      }

      // ตรวจสอบ cart pending
      final checkCartUrl = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/carts?user_id=eq.$userId&status=eq.PENDING&order=created_at.desc&limit=1',
      );
      final checkCartResp = await _get(checkCartUrl, headers: authHeaders);

      String cartId;
      if (checkCartResp.statusCode == 200) {
        final existingCarts = jsonDecode(checkCartResp.body) as List<dynamic>;
        if (existingCarts.isNotEmpty) {
          cartId = (existingCarts.first as Map)['id'].toString();
        } else {
          // สร้าง cart ใหม่
          final urlCart = Uri.parse('${ApiConfig.baseUrl}/rest/v1/carts');
          final cartBody = {
            'user_id': userId,
            'status': 'PENDING',
            'total_amount': 0,
            'currency': 'THB',
            'created_at': DateTime.now().toIso8601String(),
          };
          final respCart = await _post(
            urlCart,
            headers: {...authHeaders, 'Prefer': 'return=representation'},
            body: jsonEncode(cartBody),
          );
          if (!(respCart.statusCode == 201 || respCart.statusCode == 200)) {
            return false;
          }
          final cartData = jsonDecode(respCart.body) as List<dynamic>;
          cartId = (cartData.first as Map)['id'].toString();
        }
      } else {
        return false;
      }

      double total = 0.0;
      for (final it in items) {
        final productId = it['product_id'];
        final quantity = (it['quantity'] ?? 1) is int
            ? (it['quantity'] as int)
            : int.tryParse(it['quantity'].toString()) ?? 1;
        final unitPrice = (it['unit_price'] is num)
            ? (it['unit_price'] as num).toDouble()
            : double.tryParse(it['unit_price'].toString()) ?? 0.0;
        final itemBody = {
          'cart_id': cartId,
          'product_id': productId,
          'quantity': quantity,
          'unit_price': unitPrice,
          'created_at': DateTime.now().toIso8601String(),
          'status': 'RESERVED',
          if (it.containsKey('rent_start')) 'rent_start': it['rent_start'],
          if (it.containsKey('rent_end')) 'rent_end': it['rent_end'],
          if (it.containsKey('rental_days')) 'rental_days': it['rental_days'],
        };
        final urlItem = Uri.parse('${ApiConfig.baseUrl}/rest/v1/cart_items');
        final respItem = await _post(
          urlItem,
          headers: {...authHeaders, 'Prefer': 'return=representation'},
          body: jsonEncode(itemBody),
        );
        if (!(respItem.statusCode == 201 || respItem.statusCode == 200)) {
          return false;
        }

        // Update product status
        final urlProd = Uri.parse(
          '${ApiConfig.baseUrl}/rest/v1/products?id=eq.$productId',
        );
        await _patch(
          urlProd,
          headers: authHeaders,
          body: jsonEncode({
            'last_status': 'RESERVED',
            'updated_at': DateTime.now().toIso8601String(),
          }),
        );
        total += quantity * unitPrice;
      }

      // Update cart total
      final urlUpdate = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/carts?id=eq.$cartId',
      );
      await _patch(
        urlUpdate,
        headers: authHeaders,
        body: jsonEncode({
          'total_amount': total,
          'updated_at': DateTime.now().toIso8601String(),
        }),
      );

      return true;
    } catch (e) {
      if (kDebugMode) print('addToCart exception: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getCartItemsForUser(
    String userId,
  ) async {
    try {
      final token = Session.instance.accessToken ?? ApiConfig.apiKey;
      final headers = {
        'apikey': ApiConfig.apiKey,
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final cartUrl = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/carts?user_id=eq.$userId&status=eq.PENDING&order=created_at.desc&limit=1',
      );
      final cartResp = await _get(cartUrl, headers: headers);
      if (cartResp.statusCode != 200) return [];

      final List<dynamic> carts = jsonDecode(cartResp.body);
      if (carts.isEmpty) return [];

      final cartId = (carts.first as Map)['id'].toString();

      final itemsUrl = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/cart_items?cart_id=eq.$cartId',
      );
      final itemsResp = await _get(itemsUrl, headers: headers);
      if (itemsResp.statusCode != 200) return [];

      final List<dynamic> items = jsonDecode(itemsResp.body);
      if (items.isEmpty) return [];

      final productIds = items
          .map((e) => (e['product_id'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();

      List<Map<String, dynamic>> products = [];
      if (productIds.isNotEmpty) {
        final joined = productIds.map((id) => id.trim()).join(',');
        final prodUrl = Uri.parse(
          '${ApiConfig.baseUrl}/rest/v1/products?id=in.($joined)',
        );
        final prodResp = await _get(prodUrl, headers: headers);
        if (prodResp.statusCode == 200) {
          products = (jsonDecode(prodResp.body) as List<dynamic>)
              .cast<Map<String, dynamic>>();
        }
      }

      final Map<String, Map<String, dynamic>> prodMap = {};
      for (final p in products) {
        if (p['id'] != null) prodMap[p['id'].toString()] = p;
      }

      return items.map<Map<String, dynamic>>((it) {
        final pid = (it['product_id'] ?? '').toString();
        final prod = prodMap[pid];
        return {
          'cart_id': cartId,
          'item_id': it['id']?.toString() ?? '',
          'product_id': pid,
          'name': prod?['name'] ?? it['name'] ?? 'สินค้า',
          'price': it['unit_price'] ?? prod?['rent_amount'] ?? 0,
          'image': prod?['image'] ?? '',
          'quantity': it['quantity'] ?? 1,
          'rent_start': it['rent_start'],
          'rent_end': it['rent_end'],
          'rental_days': it['rental_days'],
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) print('getCartItemsForUser exception: $e');
      return [];
    }
  }

  static Future<bool> deleteCartItem(
    String itemId, {
    String? productId,
    String? cartId,
  }) async {
    try {
      final userToken = Session.instance.accessToken;
      if (userToken == null || userToken.isEmpty) return false;

      final headers = {
        'apikey': ApiConfig.apiKey,
        'Authorization': 'Bearer $userToken',
        'Content-Type': 'application/json',
      };

      final urlDel = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/cart_items?id=eq.$itemId',
      );
      final delResp = await _delete(urlDel, headers: headers);
      if (!(delResp.statusCode == 200 || delResp.statusCode == 204))
        return false;

      if (productId != null && productId.isNotEmpty) {
        final urlProd = Uri.parse(
          '${ApiConfig.baseUrl}/rest/v1/products?id=eq.$productId',
        );
        await _patch(
          urlProd,
          headers: headers,
          body: jsonEncode({
            'last_status': 'AVAILABLE',
            'updated_at': DateTime.now().toIso8601String(),
          }),
        );
      }

      if (cartId != null && cartId.isNotEmpty) {
        final itemsUrl = Uri.parse(
          '${ApiConfig.baseUrl}/rest/v1/cart_items?cart_id=eq.$cartId',
        );
        final itemsResp = await _get(itemsUrl, headers: headers);
        if (itemsResp.statusCode == 200) {
          final List<dynamic> items = jsonDecode(itemsResp.body);
          double total = 0.0;
          for (final it in items) {
            final unit = (it['unit_price'] is num)
                ? (it['unit_price'] as num).toDouble()
                : double.tryParse(it['unit_price']?.toString() ?? '0') ?? 0.0;
            final qty = (it['quantity'] is num)
                ? (it['quantity'] as num).toDouble()
                : double.tryParse(it['quantity']?.toString() ?? '0') ?? 0.0;
            total += unit * qty;
          }
          final urlUpdate = Uri.parse(
            '${ApiConfig.baseUrl}/rest/v1/carts?id=eq.$cartId',
          );
          await _patch(
            urlUpdate,
            headers: headers,
            body: jsonEncode({
              'total_amount': total,
              'updated_at': DateTime.now().toIso8601String(),
            }),
          );
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) print('deleteCartItem exception: $e');
      return false;
    }
  }

  static Future<int> getCartItemCountForUser(String userId) async {
    try {
      final token = Session.instance.accessToken ?? ApiConfig.apiKey;
      final headers = {
        'apikey': ApiConfig.apiKey,
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      // ✅ ดึง cart ที่ยังไม่จ่ายเงิน (paid_at เป็น null)
      final cartUrl = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/carts?user_id=eq.$userId&paid_at=is.null&order=created_at.desc&limit=1',
      );

      final cartResp = await _get(cartUrl, headers: headers);
      if (cartResp.statusCode == 200) {
        final List<dynamic> carts = jsonDecode(cartResp.body);
        if (carts.isNotEmpty) {
          final cartId = (carts.first as Map)['id'].toString();
          final itemsUrl = Uri.parse(
            '${ApiConfig.baseUrl}/rest/v1/cart_items?cart_id=eq.$cartId&select=id',
          );
          final itemsResp = await _get(itemsUrl, headers: headers);
          if (itemsResp.statusCode == 200) {
            final List<dynamic> items = jsonDecode(itemsResp.body);
            if (kDebugMode)
              print('✅ Cart items count (unpaid): ${items.length}');
            return items.length;
          }
        }
      }

      // Fallback: นับรายการจาก cart ที่ paid_at เป็น null
      final fallbackUrl = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/cart_items?select=id,cart(user_id,paid_at)&cart.user_id=eq.$userId&cart.paid_at=is.null',
      );
      final fallbackResp = await _get(fallbackUrl, headers: headers);
      if (fallbackResp.statusCode == 200) {
        final List<dynamic> items = jsonDecode(fallbackResp.body);
        if (kDebugMode)
          print('✅ Cart items count (fallback, unpaid): ${items.length}');
        return items.length;
      }

      return 0;
    } catch (e) {
      if (kDebugMode) print('getCartItemCountForUser exception: $e');
      return 0;
    }
  }

  static Future<bool> updateCartStatus(String cartId, String newStatus) async {
    try {
      final userToken = Session.instance.accessToken;
      if (userToken == null || userToken.isEmpty) return false;

      final normalizedStatus = newStatus.trim().toUpperCase();

      final headers = {
        'apikey': ApiConfig.apiKey,
        'Authorization': 'Bearer $userToken',
        'Content-Type': 'application/json',
      };

      final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/carts?id=eq.$cartId');
      final body = {
        'status': normalizedStatus,
        'updated_at': DateTime.now().toIso8601String(),
        if (normalizedStatus == 'PAID')
          'paid_at': DateTime.now().toIso8601String(),
      };

      final resp = await _patch(url, headers: headers, body: jsonEncode(body));
      return resp.statusCode == 200 || resp.statusCode == 204;
    } catch (e) {
      if (kDebugMode) print('updateCartStatus exception: $e');
      return false;
    }
  }

  // Misc
  static Future<List<dynamic>> getItems(String table) async {
    final response = await _get(
      Uri.parse('${ApiConfig.baseUrl}/$table'),
      headers: ApiConfig.headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('getItems failed: ${response.statusCode}');
  }

  static Future<bool> updateItem(
    String table,
    String idField,
    dynamic idValue,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/$table?$idField=eq.$idValue');
    final response = await _patch(
      url,
      headers: ApiConfig.headers,
      body: jsonEncode(data),
    );
    return response.statusCode == 204;
  }

  static Future<bool> deleteItem(
    String table,
    String idField,
    dynamic idValue,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/$table?$idField=eq.$idValue');
    final response = await _delete(url, headers: ApiConfig.headers);
    return response.statusCode == 204;
  }

  static Future<List<dynamic>> listBuckets() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/storage/v1/bucket');
    final resp = await _get(
      url,
      headers: {
        'apikey': ApiConfig.apiKey,
        'Authorization': 'Bearer ${ApiConfig.apiKey}',
      },
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as List<dynamic>;
    }
    throw Exception('listBuckets failed: ${resp.statusCode} ${resp.body}');
  }

  // เพิ่ม method ใหม่
  static Future<Map<String, dynamic>?> getProductById(String productId) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/products?id=eq.$productId&select=*&limit=1',
      );
      final resp = await _get(url, headers: ApiConfig.headers);

      if (kDebugMode) {
        print('getProductById: GET $url');
        print('getProductById: status=${resp.statusCode} body=${resp.body}');
      }

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List<dynamic>;
        if (data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('getProductById error: $e');
      return null;
    }
  }

  // Reservation methods
  static Future<List<Map<String, dynamic>>> getReservations() async {
    try {
      // ดึง cart_items ที่มี status = RESERVED (รออนุมัติ), RENTED (อนุมัติแล้ว) และ REJECT/Reject (ปฏิเสธ)
      final cartItemsUrl = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/cart_items?select=*,carts(id,status,user_id,created_at,paid_at,payment_slip_url),products(id,name,image)&status=in.(RESERVED,RENTED,REJECT,Reject)&order=created_at.desc',
      );
      final cartItemsResp = await _get(
        cartItemsUrl,
        headers: ApiConfig.headers,
      );

      if (kDebugMode) {
        print(
          '[getReservations] cart_items RESERVED status: ${cartItemsResp.statusCode}',
        );
        print('[getReservations] body: ${cartItemsResp.body}');
      }

      if (cartItemsResp.statusCode != 200) {
        return [];
      }

      final cartItems = jsonDecode(cartItemsResp.body) as List<dynamic>;
      if (kDebugMode)
        print('[getReservations] Found ${cartItems.length} items');

      if (cartItems.isEmpty) {
        return [];
      }

      // สร้าง reservation list จาก cart_items
      final reservationsList = <Map<String, dynamic>>[];

      for (final item in cartItems.cast<Map<String, dynamic>>()) {
        final cartItem = item;
        final carts = cartItem['carts'] as Map<String, dynamic>?;
        final product = cartItem['products'] as Map<String, dynamic>?;

        if (carts != null && product != null) {
          final cartStatus = carts['status']?.toString() ?? '';
          final paidAt = carts['paid_at'];
          final isPaidCart =
              cartStatus.trim().toUpperCase() == 'PAID' ||
              (paidAt != null && paidAt.toString().isNotEmpty);

          // แสดงให้อนุมัติเฉพาะ cart ที่ชำระเงินแล้วเท่านั้น
          if (!isPaidCart) {
            if (kDebugMode) {
              print(
                '[getReservations] Skipping unpaid cart: cartId=${carts['id']} status=$cartStatus paid_at=$paidAt',
              );
            }
            continue;
          }

          final userId = carts['user_id']?.toString();

          // ดึง user info
          Map<String, dynamic>? userInfo;
          if (userId != null) {
            final userUrl = Uri.parse(
              '${ApiConfig.baseUrl}/rest/v1/users?id=eq.$userId&select=id,name,surname&limit=1',
            );
            final userResp = await _get(userUrl, headers: ApiConfig.headers);

            if (userResp.statusCode == 200) {
              final userList = jsonDecode(userResp.body) as List<dynamic>;
              if (userList.isNotEmpty) {
                userInfo = userList.first as Map<String, dynamic>;
              }
            }
          }

          final reservation = {
            ...carts,
            'id': carts['id'],
            'product': product,
            'cart_item': cartItem,
            'user': userInfo ?? {},
          };
          reservationsList.add(reservation);

          if (kDebugMode) {
            print(
              '[getReservations] Added reservation: product=${product['name']}, cartId=${carts['id']}',
            );
          }
        }
      }

      if (kDebugMode) {
        print('[getReservations] Final count: ${reservationsList.length}');
      }

      return reservationsList;
    } catch (e) {
      if (kDebugMode) print('[getReservations] error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getUserReservations({
    String? userId,
  }) async {
    // ดึงประวัติการเช่าของผู้ใช้จากตาราง carts
    String filter = '';
    if (userId != null) {
      filter = '&user_id=eq.$userId';
    }
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/rest/v1/carts?select=*,cart_items(*,products(*))&order=created_at.desc$filter',
    );
    final resp = await _get(url, headers: ApiConfig.headers);
    if (kDebugMode) {
      print('getUserReservations: GET $url');
      print('getUserReservations: status=${resp.statusCode}');
      print('getUserReservations: body=${resp.body}');
    }
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception(
      'getUserReservations failed: ${resp.statusCode} ${resp.body}',
    );
  }

  // Helper method to compress image
  static Future<File> _compressImage(File imageFile) async {
    try {
      final originalSize = imageFile.lengthSync();
      if (kDebugMode)
        print(
          '[updateReservationStatus] Original image size: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB',
        );

      // ถ้าไฟล์เล็กกว่า 2MB ไม่ต้องบีบอัด
      if (originalSize < 2 * 1024 * 1024) {
        return imageFile;
      }

      // สร้างชื่อไฟล์ใหม่สำหรับเก็บไฟล์บีบอัด
      final dir = Directory.systemTemp;
      final compressedFile = File(
        '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // อ่านข้อมูลรูปภาพเดิม
      final imageData = await imageFile.readAsBytes();

      // เขียนไฟล์บีบอัด (ลดขนาดโดยการเขียนจากแฟมิลี่)
      await compressedFile.writeAsBytes(imageData);

      final compressedSize = compressedFile.lengthSync();
      if (kDebugMode)
        print(
          '[updateReservationStatus] Compressed image size: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB',
        );

      return compressedFile;
    } catch (e) {
      if (kDebugMode)
        print('[updateReservationStatus] Error compressing image: $e');
      return imageFile; // Return original if compression fails
    }
  }

  static Future<void> updateReservationStatus({
    required String reservationId,
    required String status,
    String? trackingNumber,
    List<File>? images,
    String? reason,
    String? shippedBy,
    DateTime? deliveryDate,
  }) async {
    final isRejectStatus =
        status.toUpperCase() == 'REJECT' || status.toLowerCase() == 'reject';

    Map<String, dynamic> payload = {
      'status': status,
      if (reason != null) 'cancellation_reason': reason,
    };

    List<String> uploadedImageUrls = [];

    // อัพโหลดรูปพัสดุถ้ามี
    if (images != null && images.isNotEmpty) {
      if (kDebugMode)
        print(
          '[updateReservationStatus] Starting upload of ${images.length} images',
        );

      for (int i = 0; i < images.length; i++) {
        try {
          if (kDebugMode)
            print(
              '[updateReservationStatus] Processing image ${i + 1}/${images.length}',
            );

          // บีบอัดรูปภาพเพื่อลดปัญหา graphics buffer
          final compressedImage = await _compressImage(images[i]);

          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'shipment_${reservationId}_${timestamp}_$i.jpg';
          // ใช้ bucket เดิมที่มีอยู่แล้ว (powershare-files) และเก็บไว้ในโฟลเดอร์ shipment-images
          final url = Uri.parse(
            '${ApiConfig.baseUrl}/storage/v1/object/powershare-files/shipment-images/$fileName',
          );

          if (kDebugMode) print('[updateReservationStatus] Uploading to: $url');

          final request = http.MultipartRequest('PUT', url)
            ..headers.addAll(ApiConfig.headers)
            ..files.add(
              await http.MultipartFile.fromPath('file', compressedImage.path),
            );

          final response = await request.send();

          if (kDebugMode)
            print(
              '[updateReservationStatus] Upload response status: ${response.statusCode}',
            );

          if (response.statusCode == 200) {
            final publicUrl =
                '${ApiConfig.baseUrl}/storage/v1/object/public/powershare-files/shipment-images/$fileName';
            uploadedImageUrls.add(publicUrl);
            if (kDebugMode)
              print(
                '[updateReservationStatus] Image $i uploaded successfully: $publicUrl',
              );
          } else {
            final responseBody = await response.stream.bytesToString();
            if (kDebugMode) {
              print(
                '[updateReservationStatus] Failed to upload image $i: ${response.statusCode}',
              );
              print('[updateReservationStatus] Error body: $responseBody');
            }
          }
        } catch (e) {
          if (kDebugMode)
            print('[updateReservationStatus] Error uploading image $i: $e');
          // Continue with next image even if one fails
        }
      }

      if (kDebugMode)
        print(
          '[updateReservationStatus] Total uploaded images: ${uploadedImageUrls.length}',
        );

      if (uploadedImageUrls.isNotEmpty) {
        payload['shipment_images'] = uploadedImageUrls;
        if (kDebugMode)
          print(
            '[updateReservationStatus] Added shipment_images to payload: $uploadedImageUrls',
          );
      }
    } else {
      if (kDebugMode) print('[updateReservationStatus] No images to upload');
    }

    try {
      // 1. ดึงข้อมูล cart_items เพื่อหา product_id
      final cartUrl = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/carts?id=eq.$reservationId&select=*,cart_items(*)',
      );
      final cartResp = await http.get(cartUrl, headers: ApiConfig.headers);

      if (cartResp.statusCode == 200) {
        final cartData = jsonDecode(cartResp.body) as List<dynamic>;
        if (cartData.isNotEmpty) {
          final cart = cartData[0] as Map<String, dynamic>;
          final cartItems = cart['cart_items'] as List<dynamic>? ?? [];

          // 2. อัปเดต cart_items (และอัปเดต last_status ของ products เฉพาะตอนอนุมัติ)
          if ((status == 'RENTED' || isRejectStatus) && cartItems.isNotEmpty) {
            for (var item in cartItems) {
              final itemMap = item as Map<String, dynamic>;
              final productId = itemMap['product_id']?.toString();

              if (productId != null && productId.isNotEmpty) {
                try {
                  final productUrl = Uri.parse(
                    '${ApiConfig.baseUrl}/rest/v1/products?id=eq.$productId',
                  );

                  final productStatus = (status == 'RENTED')
                      ? 'RENTED'
                      : (isRejectStatus ? 'AVAILABLE' : null);

                  if (productStatus != null) {
                    await http.patch(
                      productUrl,
                      headers: ApiConfig.headers,
                      body: jsonEncode({
                        'last_status': productStatus,
                        'updated_at': DateTime.now().toIso8601String(),
                      }),
                    );
                    if (kDebugMode)
                      print(
                        '[updateReservationStatus] Updated product $productId to $productStatus',
                      );
                  }
                } catch (e) {
                  if (kDebugMode)
                    print(
                      '[updateReservationStatus] Error updating product $productId: $e',
                    );
                }
              }

              // 3. อัปเดต cart_items ให้มี status, tracking_number, shipped_by และ shipment_images
              final cartItemId = itemMap['id']?.toString();
              if (cartItemId != null) {
                try {
                  final cartItemPayload = <String, dynamic>{'status': status};

                  // ถ้า status เป็น Reject ให้เพิ่มหมายเหตุไปที่ rejection_reson (หรือ rejection_reason ถ้ามี)
                  if (isRejectStatus && reason != null) {
                    String? rejectionField;
                    if (itemMap.containsKey('rejection_reson')) {
                      rejectionField = 'rejection_reson';
                    } else if (itemMap.containsKey('rejection_reason')) {
                      rejectionField = 'rejection_reason';
                    }

                    if (rejectionField != null) {
                      cartItemPayload[rejectionField] = reason;
                      if (kDebugMode)
                        print(
                          '[updateReservationStatus] Adding $rejectionField: $reason',
                        );
                    } else {
                      if (kDebugMode)
                        print(
                          '[updateReservationStatus] No rejection field found on cart_item payload; skipping reason update',
                        );
                    }
                  }

                  if (shippedBy != null) {
                    cartItemPayload['shipped_by'] = shippedBy;
                    if (kDebugMode)
                      print(
                        '[updateReservationStatus] Adding shipped_by: $shippedBy',
                      );
                  }

                  if (trackingNumber != null) {
                    cartItemPayload['tracking_number'] = trackingNumber;
                    if (kDebugMode)
                      print(
                        '[updateReservationStatus] Adding tracking_number: $trackingNumber',
                      );
                  }

                  if (uploadedImageUrls.isNotEmpty) {
                    cartItemPayload['shipment_images'] = uploadedImageUrls;
                    if (kDebugMode)
                      print(
                        '[updateReservationStatus] Adding ${uploadedImageUrls.length} shipment_images',
                      );
                  }

                  if (deliveryDate != null) {
                    cartItemPayload['delivery_date'] = deliveryDate
                        .toIso8601String();
                  }

                  if (kDebugMode)
                    print(
                      '[updateReservationStatus] Updating cart_item $cartItemId with payload: $cartItemPayload',
                    );

                  final cartItemUrl = Uri.parse(
                    '${ApiConfig.baseUrl}/rest/v1/cart_items?id=eq.$cartItemId',
                  );
                  final cartItemResp = await http.patch(
                    cartItemUrl,
                    headers: ApiConfig.headers,
                    body: jsonEncode(cartItemPayload),
                  );

                  if (kDebugMode) {
                    print(
                      '[updateReservationStatus] Cart item update response: ${cartItemResp.statusCode}',
                    );
                    if (cartItemResp.statusCode != 200 &&
                        cartItemResp.statusCode != 204) {
                      print(
                        '[updateReservationStatus] Cart item update error: ${cartItemResp.body}',
                      );
                    }
                  }
                } catch (e) {
                  if (kDebugMode)
                    print(
                      '[updateReservationStatus] Error updating cart_item $cartItemId: $e',
                    );
                }
              }
            }
          }
        }
      }

      // 4. อัปเดตตาราง carts
      final updateUrl = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/carts?id=eq.$reservationId',
      );
      final resp = await http.patch(
        updateUrl,
        headers: ApiConfig.headers,
        body: jsonEncode(payload),
      );

      if (resp.statusCode != 200 && resp.statusCode != 204) {
        throw Exception(
          'updateReservationStatus failed: ${resp.statusCode} ${resp.body}',
        );
      }
      if (kDebugMode)
        print(
          '[updateReservationStatus] Successfully updated reservation $reservationId',
        );
    } catch (e) {
      if (kDebugMode)
        print('[updateReservationStatus] Error updating cart: $e');
      rethrow;
    }
  }

  static Future<void> updateReservationItemStatus({
    required String cartItemId,
    required String status,
    String? trackingNumber,
    List<File>? images,
    String? reason,
    String? shippedBy,
    DateTime? deliveryDate,
  }) async {
    final isRejectStatus =
        status.toUpperCase() == 'REJECT' || status.toLowerCase() == 'reject';

    final cartItemUrl = Uri.parse(
      '${ApiConfig.baseUrl}/rest/v1/cart_items?id=eq.$cartItemId&select=*',
    );
    final cartItemGetResp = await http.get(
      cartItemUrl,
      headers: ApiConfig.headers,
    );
    if (cartItemGetResp.statusCode != 200) {
      throw Exception(
        'updateReservationItemStatus failed to load cart_item: ${cartItemGetResp.statusCode} ${cartItemGetResp.body}',
      );
    }
    final cartItemData = jsonDecode(cartItemGetResp.body) as List<dynamic>;
    if (cartItemData.isEmpty) {
      throw Exception(
        'updateReservationItemStatus cart_item not found: $cartItemId',
      );
    }
    final itemMap = cartItemData.first as Map<String, dynamic>;
    final productId = itemMap['product_id']?.toString();

    // Upload shipment images if provided
    final uploadedImageUrls = <String>[];
    if (images != null && images.isNotEmpty) {
      if (kDebugMode)
        print(
          '[updateReservationItemStatus] Starting upload of ${images.length} images',
        );
      for (int i = 0; i < images.length; i++) {
        try {
          final compressedImage = await _compressImage(images[i]);
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'shipment_item_${cartItemId}_${timestamp}_$i.jpg';
          final url = Uri.parse(
            '${ApiConfig.baseUrl}/storage/v1/object/powershare-files/shipment-images/$fileName',
          );
          final request = http.MultipartRequest('PUT', url)
            ..headers.addAll(ApiConfig.headers)
            ..files.add(
              await http.MultipartFile.fromPath('file', compressedImage.path),
            );
          final response = await request.send();
          if (response.statusCode == 200) {
            uploadedImageUrls.add(
              '${ApiConfig.baseUrl}/storage/v1/object/public/powershare-files/shipment-images/$fileName',
            );
          } else {
            if (kDebugMode) {
              final responseBody = await response.stream.bytesToString();
              print(
                '[updateReservationItemStatus] Failed to upload image $i: ${response.statusCode} $responseBody',
              );
            }
          }
        } catch (e) {
          if (kDebugMode)
            print('[updateReservationItemStatus] Error uploading image $i: $e');
        }
      }
    }

    // Update product last_status based on reservation decision
    if (productId != null && productId.isNotEmpty) {
      final productStatus = (status == 'RENTED')
          ? 'RENTED'
          : (isRejectStatus ? 'AVAILABLE' : null);
      if (productStatus != null) {
        try {
          final productUrl = Uri.parse(
            '${ApiConfig.baseUrl}/rest/v1/products?id=eq.$productId',
          );
          await http.patch(
            productUrl,
            headers: ApiConfig.headers,
            body: jsonEncode({
              'last_status': productStatus,
              'updated_at': DateTime.now().toIso8601String(),
            }),
          );
          if (kDebugMode)
            print(
              '[updateReservationItemStatus] Updated product $productId to $productStatus',
            );
        } catch (e) {
          if (kDebugMode)
            print(
              '[updateReservationItemStatus] Error updating product $productId: $e',
            );
        }
      }
    }

    // Update only this cart_item
    final cartItemPayload = <String, dynamic>{'status': status};

    if (isRejectStatus && reason != null) {
      String? rejectionField;
      if (itemMap.containsKey('rejection_reson')) {
        rejectionField = 'rejection_reson';
      } else if (itemMap.containsKey('rejection_reason')) {
        rejectionField = 'rejection_reason';
      }
      if (rejectionField != null) {
        cartItemPayload[rejectionField] = reason;
      }
    }

    if (shippedBy != null) cartItemPayload['shipped_by'] = shippedBy;
    if (trackingNumber != null)
      cartItemPayload['tracking_number'] = trackingNumber;
    if (uploadedImageUrls.isNotEmpty) {
      cartItemPayload['shipment_images'] = uploadedImageUrls;
    }
    if (deliveryDate != null) {
      cartItemPayload['delivery_date'] = deliveryDate.toIso8601String();
    }

    final cartItemPatchUrl = Uri.parse(
      '${ApiConfig.baseUrl}/rest/v1/cart_items?id=eq.$cartItemId',
    );
    final patchResp = await http.patch(
      cartItemPatchUrl,
      headers: ApiConfig.headers,
      body: jsonEncode(cartItemPayload),
    );
    if (patchResp.statusCode != 200 && patchResp.statusCode != 204) {
      throw Exception(
        'updateReservationItemStatus failed: ${patchResp.statusCode} ${patchResp.body}',
      );
    }

    if (kDebugMode)
      print(
        '[updateReservationItemStatus] Successfully updated cart_item $cartItemId',
      );
  }
}
