import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:powershare/services/api_config.dart';

class PaymentService {
  /// ดึงการตั้งค่าการชำระเงิน (promptpay QR)
  static Future<Map<String, dynamic>?> getPaymentSettings() async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/payment_settings?setting_key=eq.promptpay_qr&limit=1',
      );
      final resp = await http.get(url, headers: ApiConfig.headers);
      
      if (kDebugMode) {
        print('═══════════════════════════════════════');
        print('getPaymentSettings: GET $url');
        print('getPaymentSettings: status=${resp.statusCode}');
        print('getPaymentSettings: body=${resp.body}');
        print('═══════════════════════════════════════');
      }
      
      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        if (data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        }
      } else {
        if (kDebugMode) print('❌ GET failed with status ${resp.statusCode}: ${resp.body}');
      }
      return null;
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ getPaymentSettings error: $e');
        print('Stack: $stack');
      }
      return null;
    }
  }

  /// อัปเดตการตั้งค่าการชำระเงิน
  static Future<bool> updatePaymentSettings(Map<String, dynamic> payload) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/payment_settings?setting_key=eq.promptpay_qr',
      );
      
      if (kDebugMode) {
        print('═══════════════════════════════════════');
        print('🔄 UPDATE Payment Settings');
        print('URL: $url');
        print('Payload: ${jsonEncode(payload)}');
        print('Headers: ${ApiConfig.headers}');
      }
      
      final resp = await http.patch(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode(payload),
      );
      
      if (kDebugMode) {
        print('Response Status: ${resp.statusCode}');
        print('Response Body: ${resp.body}');
        print('Response Headers: ${resp.headers}');
        
        if (resp.statusCode == 200 || resp.statusCode == 204) {
          print('✅ UPDATE SUCCESS');
        } else {
          print('❌ UPDATE FAILED!');
          print('   Status: ${resp.statusCode}');
          print('   Error: ${resp.body}');
        }
        print('═══════════════════════════════════════');
      }
      
      return resp.statusCode == 200 || resp.statusCode == 204;
    } catch (e, stack) {
      if (kDebugMode) {
        print('═══════════════════════════════════════');
        print('❌ updatePaymentSettings EXCEPTION: $e');
        print('Stack: $stack');
        print('═══════════════════════════════════════');
      }
      return false;
    }
  }

  /// สร้างการตั้งค่าการชำระเงินใหม่ (ถ้ายังไม่มี)
  static Future<Map<String, dynamic>?> createPaymentSettings({
    required String promptpayNumber,
    required String promptpayName,
    String? qrImageUrl,
    String? createdBy,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/rest/v1/payment_settings');
      
      // ไม่ส่ง created_by เพราะ Foreign Key constraint ไม่ตรงกับ users table
      final body = {
        'setting_key': 'promptpay_qr',
        'promptpay_number': promptpayNumber,
        'promptpay_name': promptpayName,
        'qr_image_url': qrImageUrl ?? '',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        // ไม่ส่ง created_by เพื่อให้ database ใช้ค่า default หรือ null
      };
      
      final headers = {...ApiConfig.headers, 'Prefer': 'return=representation'};
      
      if (kDebugMode) {
        print('═══════════════════════════════════════');
        print('➕ CREATE Payment Settings');
        print('URL: $url');
        print('Body: ${jsonEncode(body)}');
        print('Headers: $headers');
      }
      
      final resp = await http.post(url, headers: headers, body: jsonEncode(body));
      
      if (kDebugMode) {
        print('Response Status: ${resp.statusCode}');
        print('Response Body: ${resp.body}');
        print('Response Headers: ${resp.headers}');
        
        if (resp.statusCode == 201 || resp.statusCode == 200) {
          print('✅ CREATE SUCCESS');
        } else {
          print('❌ CREATE FAILED!');
          print('   Status: ${resp.statusCode}');
          print('   Error: ${resp.body}');
        }
        print('═══════════════════════════════════════');
      }
      
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List<dynamic>;
        if (data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e, stack) {
      if (kDebugMode) {
        print('═══════════════════════════════════════');
        print('❌ createPaymentSettings EXCEPTION: $e');
        print('Stack: $stack');
        print('═══════════════════════════════════════');
      }
      return null;
    }
  }

  /// ตั้งค่าสถานะการใช้งาน (เปิด/ปิด)
  static Future<bool> setPaymentSettingsActive(bool isActive) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/rest/v1/payment_settings?setting_key=eq.promptpay_qr',
      );
      final body = {
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final resp = await http.patch(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode(body),
      );
      
      if (kDebugMode) {
        print('setPaymentSettingsActive: status=${resp.statusCode} body=${resp.body}');
      }
      
      return resp.statusCode == 200 || resp.statusCode == 204;
    } catch (e) {
      if (kDebugMode) print('setPaymentSettingsActive error: $e');
      return false;
    }
  }
}