import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:powershare/services/api_config.dart';
import 'package:powershare/services/session.dart';

class RentalService {
  /// ดึงประวัติการเช่าของผู้ใช้ (จาก carts ที่ status = 'paid')
  static Future<List<Map<String, dynamic>>> getRentalHistory(String userId) async {
    try {
      final token = Session.instance.accessToken ?? ApiConfig.apiKey;
      final headers = {
        'apikey': ApiConfig.apiKey,
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      // ดึง carts ที่ status = 'paid' ของ user
      final cartUrl = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/carts?user_id=eq.$userId&status=eq.paid&order=paid_at.desc,created_at.desc'
      );
      
      if (kDebugMode) print('getRentalHistory: GET $cartUrl');
      final cartResp = await http.get(cartUrl, headers: headers);
      if (kDebugMode) print('getRentalHistory: status=${cartResp.statusCode} body=${cartResp.body}');
      
      if (cartResp.statusCode != 200) return [];

      final List<dynamic> carts = jsonDecode(cartResp.body);
      if (carts.isEmpty) return [];

      List<Map<String, dynamic>> allRentals = [];

      // วนลูปแต่ละ cart เพื่อดึง cart_items
      for (var cart in carts) {
        final cartId = cart['id'].toString();
        final paidAt = cart['paid_at']?.toString();

        // ดึง cart_items ของ cart นี้
        final itemsUrl = Uri.parse(
          '${ApiConfig.baseUrl}/rest/v1/cart_items?cart_id=eq.$cartId&select=*'
        );
        final itemsResp = await http.get(itemsUrl, headers: headers);
        
        if (itemsResp.statusCode == 200) {
          final List<dynamic> items = jsonDecode(itemsResp.body);
          
          for (var item in items) {
            final productId = item['product_id']?.toString();
            Map<String, dynamic>? product;

            // ดึงข้อมูล product
            if (productId != null && productId.isNotEmpty) {
              final prodUrl = Uri.parse('${ApiConfig.baseUrl}/rest/v1/products?id=eq.$productId');
              final prodResp = await http.get(prodUrl, headers: headers);
              if (prodResp.statusCode == 200) {
                final List<dynamic> prods = jsonDecode(prodResp.body);
                if (prods.isNotEmpty) {
                  product = prods.first as Map<String, dynamic>;
                }
              }
            }

            // กำหนดสถานะการเช่า (เช่าอยู่/คืนแล้ว)
            final rentEnd = item['rent_end']?.toString();
            final now = DateTime.now();
            DateTime? endDate;
            try {
              endDate = rentEnd != null ? DateTime.parse(rentEnd) : null;
            } catch (e) {
              endDate = null;
            }

            final isActive = endDate != null && endDate.isAfter(now);

            allRentals.add({
              'cart_id': cartId,
              'item_id': item['id']?.toString(),
              'product_id': productId,
              'name': product?['name'] ?? product?['title'] ?? 'สินค้า',
              'image': product?['image'] ?? product?['image_url'] ?? '',
              'quantity': item['quantity'] ?? 1,
              'rent_start': item['rent_start']?.toString(),
              'rent_end': rentEnd,
              'paid_at': paidAt,
              'status': isActive ? 'เช่าอยู่' : 'คืนแล้ว',
              'unit_price': item['unit_price'] ?? 0,
            });
          }
        }
      }

      return allRentals;
    } catch (e, stack) {
      if (kDebugMode) {
        print('getRentalHistory exception: $e');
        print(stack);
      }
      return [];
    }
  }
}