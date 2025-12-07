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
  // Auth
  static final login = AuthService.login;
  static final signup = AuthService.signup;
  static final checkAndRefreshToken = AuthService.checkAndRefreshToken;
  static final generatePasswordResetOTP = AuthService.generatePasswordResetOTP;
  static final verifyOTPAndResetPassword = AuthService.verifyOTPAndResetPassword;
  
  // Categories
  static final getCategories = CategoryService.getCategories;
  static final createCategory = CategoryService.createCategory;
  static final updateCategory = CategoryService.updateCategory;
  static final deleteCategory = CategoryService.deleteCategory;
  
  // Products - ยังไม่ได้แยก ใช้จาก ApiServicesLegacy ก่อน
  static Future<List<Map<String, dynamic>>> getProducts({bool onlyActive = false}) async {
    final activeFilter = onlyActive ? '&is_active=eq.true' : '';
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/rest/v1/products?select=*&order=created_at.desc$activeFilter&or=(delete_flag.eq.N,delete_flag.is.null)',
    );
    final resp = await http.get(url, headers: ApiConfig.headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('getProducts failed: ${resp.statusCode} ${resp.body}');
  }

  static Future<Map<String, dynamic>> createProduct(Map<String, dynamic> payload) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/products');
    final headers = {...ApiConfig.headers, 'Prefer': 'return=representation'};
    final resp = await http.post(url, headers: headers, body: jsonEncode(payload));
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return (data.first as Map).cast<String, dynamic>();
    }
    throw Exception('createProduct failed: ${resp.statusCode} ${resp.body}');
  }

  static Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> payload) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/products?id=eq.$id');
    final headers = {...ApiConfig.headers, 'Prefer': 'return=representation'};
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

  static Future<bool> deleteProduct(String id, {String? userUpdates}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/products?id=eq.$id');
    final body = {
      'delete_flag': 'Y',
      'updated_at': DateTime.now().toIso8601String(),
      if (userUpdates != null) 'user_updates': userUpdates,
    };
    final resp = await http.patch(url, headers: ApiConfig.headers, body: jsonEncode(body));
    return resp.statusCode == 200 || resp.statusCode == 204;
  }

  static Future<List<Map<String, dynamic>>> getPopularProducts({int limit = 10, bool onlyActive = false}) async {
    final activeFilter = onlyActive ? '&is_active=eq.true' : '';
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/rest/v1/products?select=*&order=rent_amount.desc&limit=$limit&last_status=eq.Available$activeFilter&or=(delete_flag.eq.N,delete_flag.is.null)',
    );
    final resp = await http.get(url, headers: ApiConfig.headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('getPopularProducts failed: ${resp.statusCode} ${resp.body}');
  }

  static Future<List<Map<String, dynamic>>> getAvailableProducts({int limit = 20}) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/rest/v1/products?select=*&order=created_at.desc&limit=$limit&last_status=eq.Available&or=(delete_flag.eq.N,delete_flag.is.null)',
    );
    final resp = await http.get(url, headers: ApiConfig.headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('getAvailableProducts failed: ${resp.statusCode} ${resp.body}');
  }

  // Upload
  static Future<String> uploadUserFiles(File file, {String subfolder = 'users'}) async {
    const bucketName = 'powershare-files';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}${extension(file.path)}';
    final folder = subfolder.replaceAll(RegExp(r'^/+|/+$'), '');
    final filePath = '$folder/$fileName';
    final uri = Uri.parse('${ApiConfig.baseUrl}/storage/v1/object/$bucketName/$filePath');
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

  static Future<String> uploadFile(File file, {required String bucket, String? filename, String folder = 'products'}) async {
    final name = filename ?? basename(file.path);
    final encodedName = Uri.encodeComponent(name);
    final cleanFolder = folder.replaceAll(RegExp(r'^/+|/+$'), '');
    final objectPath = '$cleanFolder/$encodedName';
    final url = Uri.parse('${ApiConfig.baseUrl}/storage/v1/object/$bucket/$objectPath');

    final bytes = await file.readAsBytes();
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final headers = {
      'Authorization': 'Bearer ${ApiConfig.apiKey}',
      'apikey': ApiConfig.apiKey,
      'Content-Type': mimeType,
    };

    final resp = await http.put(url, headers: headers, body: bytes);

    if (resp.statusCode == 200) {
      return '${ApiConfig.baseUrl}/storage/v1/object/public/$bucket/$objectPath';
    }
    throw Exception('uploadFile failed: status=${resp.statusCode}, body=${resp.body}');
  }

  // Users
  static Future<List<dynamic>> getUsers(String accessToken) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/users');
    final tokenToUse = accessToken.isNotEmpty ? accessToken : Session.instance.accessToken ?? ApiConfig.apiKey;
    final headers = {
      'apikey': ApiConfig.apiKey,
      'Authorization': 'Bearer $tokenToUse',
      'Content-Type': 'application/json',
    };
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('getUsers failed: ${response.statusCode} ${response.body}');
  }

  static Future<ResponseModel> addUsers(String table, Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/$table');
    final json = jsonEncode(data);
    final response = await http.post(url, headers: ApiConfig.headers, body: json);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return ResponseModel(responseCode: 'SUCCESS', responseMessage: 'เพิ่มข้อมูลสำเร็จ');
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
    final response = await http.post(url, headers: ApiConfig.headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return null;
  }

  static Future<bool> setUserApproval(String id, {required bool approve, String? role}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/users?id=eq.$id');
    final payload = <String, dynamic>{'is_approve': approve};
    if (role != null) payload['role'] = role;
    final response = await http.patch(url, headers: ApiConfig.headers, body: jsonEncode(payload));
    return response.statusCode == 204 || response.statusCode == 200;
  }

  static Future<void> rejectUser(String userId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/users?id=eq.$userId');
    final body = jsonEncode({
      'is_approve': false,
      'rejected_at': DateTime.now().toIso8601String(),
    });
    final resp = await http.patch(url, headers: ApiConfig.headers, body: body);
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception('rejectUser failed: ${resp.statusCode} ${resp.body}');
    }
  }

  // Likes
  static Future<List<String>> getUserLikedProductIds(String userId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/product_likes?select=product_id&user_id=eq.$userId');
    final resp = await http.get(url, headers: ApiConfig.headers);
    if (resp.statusCode == 200) {
      final List<dynamic> data = jsonDecode(resp.body);
      return data.map<String>((e) => (e['product_id'] ?? '').toString()).where((s) => s.isNotEmpty).toList();
    }
    throw Exception('getUserLikedProductIds failed: ${resp.statusCode} ${resp.body}');
  }

  static Future<bool> createLike(String userId, String productId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/product_likes');
    final body = {
      'user_id': userId,
      'product_id': productId,
      'created_at': DateTime.now().toIso8601String(),
    };
    final headers = {...ApiConfig.headers, 'Prefer': 'return=representation'};
    final resp = await http.post(url, headers: headers, body: jsonEncode(body));
    if (resp.statusCode == 201 || resp.statusCode == 200 || resp.statusCode == 204 || resp.statusCode == 409) {
      return true;
    }
    return false;
  }

  static Future<bool> deleteLike(String userId, String productId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/product_likes?user_id=eq.$userId&product_id=eq.$productId');
    final resp = await http.delete(url, headers: ApiConfig.headers);
    return resp.statusCode == 204 || resp.statusCode == 200;
  }

  // Promotions
  static Future<List<Map<String, dynamic>>> getPromotions({bool onlyActive = false}) async {
    final activeFilter = onlyActive ? '&is_active=eq.true' : '';
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/rest/v1/promotions?select=*&order="order".asc,created_at.desc$activeFilter&or=(delete_flag.eq.N,delete_flag.is.null)',
    );
    final resp = await http.get(url, headers: ApiConfig.headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('getPromotions failed: ${resp.statusCode} ${resp.body}');
  }

  static Future<Map<String, dynamic>> createPromotion({required String text, bool isActive = true, int order = 999, String? userCreated}) async {
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
    final resp = await http.post(url, headers: headers, body: jsonEncode(body));
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return (data.first as Map).cast<String, dynamic>();
    }
    throw Exception('createPromotion failed: ${resp.statusCode} ${resp.body}');
  }

  static Future<Map<String, dynamic>> updatePromotion(String id, {String? text, bool? isActive, int? order, String? userUpdates}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/promotions?id=eq.$id');
    final body = <String, dynamic>{};
    if (text != null) body['text'] = text;
    if (isActive != null) body['is_active'] = isActive;
    if (order != null) body['order'] = order;
    if (userUpdates != null) body['user_updates'] = userUpdates;
    body['updated_at'] = DateTime.now().toIso8601String();

    final headers = {...ApiConfig.headers, 'Prefer': 'return=representation'};
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

  static Future<bool> deletePromotion(String id, {String? userUpdates}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/promotions?id=eq.$id');
    final body = {
      'delete_flag': 'Y',
      'updated_at': DateTime.now().toIso8601String(),
      if (userUpdates != null) 'user_updates': userUpdates,
    };
    final resp = await http.patch(url, headers: ApiConfig.headers, body: jsonEncode(body));
    return resp.statusCode == 200 || resp.statusCode == 204;
  }

  // Payment Settings ← เพิ่มส่วนนี้
  static final getPaymentSettings = PaymentService.getPaymentSettings;
  static final updatePaymentSettings = PaymentService.updatePaymentSettings;
  static final createPaymentSettings = PaymentService.createPaymentSettings;
  static final setPaymentSettingsActive = PaymentService.setPaymentSettingsActive;

  // Cart (ย้ายมาจาก ApiServicesV2)
  static Future<bool> addToCart(String userId, List<Map<String, dynamic>> items) async {
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
      final checkUrl = Uri.parse('${ApiConfig.baseUrl}/rest/v1/users?id=eq.$userId');
      final checkResp = await http.get(checkUrl, headers: authHeaders);
      if (checkResp.statusCode == 200) {
        final List<dynamic> existing = jsonDecode(checkResp.body);
        if (existing.isEmpty) {
          final profile = {
            'id': userId,
            'email': Session.instance.user?['email'] ?? '',
            'created_at': DateTime.now().toIso8601String(),
          };
          final createResp = await http.post(
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
        '${ApiConfig.baseUrl}/rest/v1/carts?user_id=eq.$userId&status=eq.pending&order=created_at.desc&limit=1',
      );
      final checkCartResp = await http.get(checkCartUrl, headers: authHeaders);
      
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
            'status': 'pending',
            'total_amount': 0,
            'currency': 'THB',
            'created_at': DateTime.now().toIso8601String(),
          };
          final respCart = await http.post(urlCart, headers: {...authHeaders, 'Prefer': 'return=representation'}, body: jsonEncode(cartBody));
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
        final quantity = (it['quantity'] ?? 1) is int ? (it['quantity'] as int) : int.tryParse(it['quantity'].toString()) ?? 1;
        final unitPrice = (it['unit_price'] is num) ? (it['unit_price'] as num).toDouble() : double.tryParse(it['unit_price'].toString()) ?? 0.0;
        final itemBody = {
          'cart_id': cartId,
          'product_id': productId,
          'quantity': quantity,
          'unit_price': unitPrice,
          'created_at': DateTime.now().toIso8601String(),
          'status': 'reserved',
          if (it.containsKey('rent_start')) 'rent_start': it['rent_start'],
          if (it.containsKey('rent_end')) 'rent_end': it['rent_end'],
          if (it.containsKey('rental_days')) 'rental_days': it['rental_days'],
        };
        final urlItem = Uri.parse('${ApiConfig.baseUrl}/rest/v1/cart_items');
        final respItem = await http.post(urlItem, headers: {...authHeaders, 'Prefer': 'return=representation'}, body: jsonEncode(itemBody));
        if (!(respItem.statusCode == 201 || respItem.statusCode == 200)) {
          return false;
        }

        // Update product status
        final urlProd = Uri.parse('${ApiConfig.baseUrl}/rest/v1/products?id=eq.$productId');
        await http.patch(urlProd, headers: authHeaders, body: jsonEncode({'last_status': 'Reserved', 'updated_at': DateTime.now().toIso8601String()}));
        total += quantity * unitPrice;
      }

      // Update cart total
      final urlUpdate = Uri.parse('${ApiConfig.baseUrl}/rest/v1/carts?id=eq.$cartId');
      await http.patch(urlUpdate, headers: authHeaders, body: jsonEncode({'total_amount': total, 'updated_at': DateTime.now().toIso8601String()}));

      return true;
    } catch (e) {
      if (kDebugMode) print('addToCart exception: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getCartItemsForUser(String userId) async {
    try {
      final token = Session.instance.accessToken ?? ApiConfig.apiKey;
      final headers = {
        'apikey': ApiConfig.apiKey,
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final cartUrl = Uri.parse('${ApiConfig.baseUrl}/rest/v1/carts?user_id=eq.$userId&status=eq.pending&order=created_at.desc&limit=1');
      final cartResp = await http.get(cartUrl, headers: headers);
      if (cartResp.statusCode != 200) return [];

      final List<dynamic> carts = jsonDecode(cartResp.body);
      if (carts.isEmpty) return [];

      final cartId = (carts.first as Map)['id'].toString();

      final itemsUrl = Uri.parse('${ApiConfig.baseUrl}/rest/v1/cart_items?cart_id=eq.$cartId');
      final itemsResp = await http.get(itemsUrl, headers: headers);
      if (itemsResp.statusCode != 200) return [];

      final List<dynamic> items = jsonDecode(itemsResp.body);
      if (items.isEmpty) return [];

      final productIds = items.map((e) => (e['product_id'] ?? '').toString()).where((s) => s.isNotEmpty).toSet().toList();

      List<Map<String, dynamic>> products = [];
      if (productIds.isNotEmpty) {
        final joined = productIds.map((id) => id.trim()).join(',');
        final prodUrl = Uri.parse('${ApiConfig.baseUrl}/rest/v1/products?id=in.($joined)');
        final prodResp = await http.get(prodUrl, headers: headers);
        if (prodResp.statusCode == 200) {
          products = (jsonDecode(prodResp.body) as List<dynamic>).cast<Map<String, dynamic>>();
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

  static Future<bool> deleteCartItem(String itemId, {String? productId, String? cartId}) async {
    try {
      final userToken = Session.instance.accessToken;
      if (userToken == null || userToken.isEmpty) return false;

      final headers = {
        'apikey': ApiConfig.apiKey,
        'Authorization': 'Bearer $userToken',
        'Content-Type': 'application/json',
      };

      final urlDel = Uri.parse('${ApiConfig.baseUrl}/rest/v1/cart_items?id=eq.$itemId');
      final delResp = await http.delete(urlDel, headers: headers);
      if (!(delResp.statusCode == 200 || delResp.statusCode == 204)) return false;

      if (productId != null && productId.isNotEmpty) {
        final urlProd = Uri.parse('${ApiConfig.baseUrl}/rest/v1/products?id=eq.$productId');
        await http.patch(urlProd, headers: headers, body: jsonEncode({'last_status': 'Available', 'updated_at': DateTime.now().toIso8601String()}));
      }

      if (cartId != null && cartId.isNotEmpty) {
        final itemsUrl = Uri.parse('${ApiConfig.baseUrl}/rest/v1/cart_items?cart_id=eq.$cartId');
        final itemsResp = await http.get(itemsUrl, headers: headers);
        if (itemsResp.statusCode == 200) {
          final List<dynamic> items = jsonDecode(itemsResp.body);
          double total = 0.0;
          for (final it in items) {
            final unit = (it['unit_price'] is num) ? (it['unit_price'] as num).toDouble() : double.tryParse(it['unit_price']?.toString() ?? '0') ?? 0.0;
            final qty = (it['quantity'] is num) ? (it['quantity'] as num).toDouble() : double.tryParse(it['quantity']?.toString() ?? '0') ?? 0.0;
            total += unit * qty;
          }
          final urlUpdate = Uri.parse('${ApiConfig.baseUrl}/rest/v1/carts?id=eq.$cartId');
          await http.patch(urlUpdate, headers: headers, body: jsonEncode({'total_amount': total, 'updated_at': DateTime.now().toIso8601String()}));
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

      // ✅ เปลี่ยนจาก: ดึง cart ล่าสุด → เป็น: ดึง cart ที่ status != 'paid'
      final cartUrl = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/carts?user_id=eq.$userId&status=neq.paid&order=created_at.desc&limit=1'
    );
    
      final cartResp = await http.get(cartUrl, headers: headers);
      if (cartResp.statusCode == 200) {
        final List<dynamic> carts = jsonDecode(cartResp.body);
        if (carts.isNotEmpty) {
          final cartId = (carts.first as Map)['id'].toString();
          final itemsUrl = Uri.parse('${ApiConfig.baseUrl}/rest/v1/cart_items?cart_id=eq.$cartId&select=id');
          final itemsResp = await http.get(itemsUrl, headers: headers);
          if (itemsResp.statusCode == 200) {
            final List<dynamic> items = jsonDecode(itemsResp.body);
            if (kDebugMode) print('✅ Cart items count (unpaid only): ${items.length}');
            return items.length;
          }
        }
      }

      // Fallback: นับรายการจาก cart ที่ยังไม่ได้จ่ายเงิน
      final fallbackUrl = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/cart_items?select=id,cart(user_id,status)&cart.user_id=eq.$userId&cart.status=neq.paid'
    );
      final fallbackResp = await http.get(fallbackUrl, headers: headers);
      if (fallbackResp.statusCode == 200) {
        final List<dynamic> items = jsonDecode(fallbackResp.body);
        if (kDebugMode) print('✅ Cart items count (fallback, unpaid only): ${items.length}');
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

      final headers = {
        'apikey': ApiConfig.apiKey,
        'Authorization': 'Bearer $userToken',
        'Content-Type': 'application/json',
      };

      final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/carts?id=eq.$cartId');
      final body = {
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
        if (newStatus == 'paid') 'paid_at': DateTime.now().toIso8601String(),
      };

      final resp = await http.patch(url, headers: headers, body: jsonEncode(body));
      return resp.statusCode == 200 || resp.statusCode == 204;
    } catch (e) {
      if (kDebugMode) print('updateCartStatus exception: $e');
      return false;
    }
  }

  // Misc
  static Future<List<dynamic>> getItems(String table) async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/$table'), headers: ApiConfig.headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('getItems failed: ${response.statusCode}');
  }

  static Future<bool> updateItem(String table, String idField, dynamic idValue, Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/$table?$idField=eq.$idValue');
    final response = await http.patch(url, headers: ApiConfig.headers, body: jsonEncode(data));
    return response.statusCode == 204;
  }

  static Future<bool> deleteItem(String table, String idField, dynamic idValue) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/$table?$idField=eq.$idValue');
    final response = await http.delete(url, headers: ApiConfig.headers);
    return response.statusCode == 204;
  }

  static Future<List<dynamic>> listBuckets() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/storage/v1/bucket');
    final resp = await http.get(url, headers: {'apikey': ApiConfig.apiKey, 'Authorization': 'Bearer ${ApiConfig.apiKey}'});
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
      final resp = await http.get(url, headers: ApiConfig.headers);
      
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
}
