import 'package:intl/intl.dart';

class FormatHelper {
  /// ฟอร์แมตตัวเลขให้มีคอมม่าคั่นหลักพัน และทศนิยม 2 ตำแหน่ง
  /// ตัวอย่าง: 1234.56 -> "1,234.56"
  static String formatCurrency(dynamic value, {int decimals = 2}) {
    if (value == null) return '0.00';
    
    double amount;
    if (value is num) {
      amount = value.toDouble();
    } else {
      amount = double.tryParse(value.toString()) ?? 0.0;
    }
    
    final formatter = NumberFormat('#,##0.${'0' * decimals}', 'en_US');
    return formatter.format(amount);
  }

  /// ฟอร์แมตเงินพร้อมสัญลักษณ์บาท
  /// ตัวอย่าง: 1234.56 -> "฿1,234.56"
  static String formatPrice(dynamic value, {int decimals = 2}) {
    return '฿${formatCurrency(value, decimals: decimals)}';
  }

  /// ฟอร์แมตราคาต่อวัน
  /// ตัวอย่าง: 1234.56 -> "฿1,234.56/วัน"
  static String formatDailyPrice(dynamic value, {int decimals = 2}) {
    return '${formatPrice(value, decimals: decimals)}/วัน';
  }

  /// ฟอร์แมตวันที่เป็น DD/MM/yyyy HH:mm:ss
  /// ตัวอย่าง: "2025-11-09T12:08:42" -> "09/11/2025 12:08:42"
  static String formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return '-';
    }
    
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
      return formatter.format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  /// ฟอร์แมตวันที่เป็น DD/MM/yyyy
  /// ตัวอย่าง: "2025-11-09T12:08:42" -> "09/11/2025"
  static String formatDate(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return '-';
    }
    
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final formatter = DateFormat('dd/MM/yyyy');
      return formatter.format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }
}