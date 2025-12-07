import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:powershare/services/api_config.dart';

class ProductService {
  static Future<Map<String, dynamic>> createProduct(
    Map<String, dynamic> productData,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/products');
    final headers = {...ApiConfig.headers, 'Prefer': 'return=representation'};
    final resp = await http.post(url, headers: headers, body: jsonEncode(productData));
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return (data.first as Map).cast<String, dynamic>();
    }
    throw Exception('createProduct failed: ${resp.statusCode} ${resp.body}');
  }

  static Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> updates) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/products?id=eq.$id');
    final headers = {...ApiConfig.headers, 'Prefer': 'return=representation'};
    final resp = await http.patch(url, headers: headers, body: jsonEncode(updates));
    if (resp.statusCode == 200 || resp.statusCode == 204) {
      if (resp.body.isNotEmpty) {
        final data = jsonDecode(resp.body) as List<dynamic>;
        return (data.first as Map).cast<String, dynamic>();
      }
      return {};
    }
    throw Exception('updateProduct failed: ${resp.statusCode} ${resp.body}');
  }

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

  static Future<bool> deleteProduct(String id, {String? userUpdates}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/products?id=eq.$id');
    final body = {
      'delete_flag': 'Y',
      if (userUpdates != null) 'user_updates': userUpdates,
      'updated_at': DateTime.now().toIso8601String(),
    };
    final resp = await http.patch(url, headers: ApiConfig.headers, body: jsonEncode(body));
    return resp.statusCode == 204 || resp.statusCode == 200;
  }

  static Future<List<Map<String, dynamic>>> getPopularProducts({
    int limit = 10,
    bool onlyActive = false,
  }) async {
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
}