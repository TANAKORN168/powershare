import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:powershare/services/api_config.dart';

class CategoryService {
  static Future<List<Map<String, dynamic>>> getCategories({bool onlyActive = false}) async {
    final activeFilter = onlyActive ? '&is_active=eq.true' : '';
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/rest/v1/categories?select=*&order=created_at.desc$activeFilter&or=(delete_flag.eq.N,delete_flag.is.null)',
    );
    final resp = await http.get(url, headers: ApiConfig.headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('getCategories failed: ${resp.statusCode} ${resp.body}');
  }

  static Future<Map<String, dynamic>> createCategory({
    required String name,
    String? description,
    String? imageUrl,
    bool isActive = true,
    String? userCreated,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/categories');
    final body = {
      'name': name,
      'description': description ?? '',
      'image_url': imageUrl ?? '',
      'is_active': isActive,
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
    throw Exception('createCategory failed: ${resp.statusCode} ${resp.body}');
  }

  static Future<Map<String, dynamic>> updateCategory(
    String id, {
    String? name,
    String? description,
    String? imageUrl,
    bool? isActive,
    String? userUpdates,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/categories?id=eq.$id');
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (imageUrl != null) body['image_url'] = imageUrl;
    if (isActive != null) body['is_active'] = isActive;
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
    throw Exception('updateCategory failed: ${resp.statusCode} ${resp.body}');
  }

  static Future<bool> deleteCategory(String id, {String? userUpdates}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/categories?id=eq.$id');
    final body = {
      'delete_flag': 'Y',
      if (userUpdates != null) 'user_updates': userUpdates,
      'updated_at': DateTime.now().toIso8601String(),
    };
    final resp = await http.patch(url, headers: ApiConfig.headers, body: jsonEncode(body));
    return resp.statusCode == 204 || resp.statusCode == 200;
  }

  static Future<bool> setCategoryActive(String id, bool active) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/categories?id=eq.$id');
    final body = {'is_active': active, 'updated_at': DateTime.now().toIso8601String()};
    final resp = await http.patch(url, headers: ApiConfig.headers, body: jsonEncode(body));
    return resp.statusCode == 204 || resp.statusCode == 200;
  }
}