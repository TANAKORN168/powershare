import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:powershare/services/api_config.dart';
import 'package:powershare/services/session.dart';

class LikeService {
  /// ดึงรายการสินค้าที่ผู้ใช้กดถูกใจ (จาก product_likes)
  static Future<List<Map<String, dynamic>>> getLikedProducts(String userId) async {
    try {
      final token = Session.instance.accessToken ?? ApiConfig.apiKey;
      final headers = {
        'apikey': ApiConfig.apiKey,
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      // ดึง product_likes ของ user
      final likesUrl = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/product_likes?user_id=eq.$userId&select=product_id,created_at'
      );
      
      if (kDebugMode) print('getLikedProducts: GET $likesUrl');
      final likesResp = await http.get(likesUrl, headers: headers);
      if (kDebugMode) print('getLikedProducts: status=${likesResp.statusCode} body=${likesResp.body}');
      
      if (likesResp.statusCode != 200) return [];

      final List<dynamic> likes = jsonDecode(likesResp.body);
      if (likes.isEmpty) return [];

      List<Map<String, dynamic>> likedProducts = [];

      // ดึงข้อมูล product สำหรับแต่ละ product_id
      for (var like in likes) {
        final productId = like['product_id']?.toString();
        if (productId == null || productId.isEmpty) continue;

        final prodUrl = Uri.parse(
          '${ApiConfig.baseUrl}/rest/v1/products?id=eq.$productId&select=*'
        );
        final prodResp = await http.get(prodUrl, headers: headers);
        
        if (prodResp.statusCode == 200) {
          final List<dynamic> products = jsonDecode(prodResp.body);
          if (products.isNotEmpty) {
            final product = products.first as Map<String, dynamic>;
            
            // ลองหา price จากหลาย column (เหมือน HomePage)
            final priceVal = product['price'] ?? product['rent_amount'] ?? 0;
            double price = 0;
            if (priceVal is num) {
              price = priceVal.toDouble();
            } else {
              price = double.tryParse(priceVal.toString()) ?? 0;
            }
            
            if (kDebugMode) {
              print('Product: ${product['name']}, price field: ${product['price']}, rent_amount: ${product['rent_amount']}, final: $price');
            }
            
            likedProducts.add({
              'product_id': productId,
              'name': product['name'] ?? product['title'] ?? 'สินค้า',
              'image': product['image'] ?? product['image_url'] ?? '',
              'description': product['description'] ?? '',
              'price': price,
              'liked_at': like['created_at']?.toString(),
            });
          }
        }
      }

      return likedProducts;
    } catch (e, stack) {
      if (kDebugMode) {
        print('getLikedProducts exception: $e');
        print(stack);
      }
      return [];
    }
  }

  /// ลบสินค้าออกจากรายการที่ถูกใจ
  static Future<bool> removeLike(String userId, String productId) async {
    try {
      final token = Session.instance.accessToken ?? ApiConfig.apiKey;
      final headers = {
        'apikey': ApiConfig.apiKey,
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/product_likes?user_id=eq.$userId&product_id=eq.$productId'
      );
      
      if (kDebugMode) print('removeLike: DELETE $url');
      final resp = await http.delete(url, headers: headers);
      if (kDebugMode) print('removeLike: status=${resp.statusCode}');
      
      return resp.statusCode == 200 || resp.statusCode == 204;
    } catch (e) {
      if (kDebugMode) print('removeLike exception: $e');
      return false;
    }
  }
}