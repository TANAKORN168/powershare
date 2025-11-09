import 'package:intl/intl.dart';

class TextFieldValidate {
  static String validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกอีเมล';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'รูปแบบอีเมลไม่ถูกต้อง';
    }
    return "";
  }

  static String validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกรหัสผ่าน';
    }

    if (!isValidPassword(value)) {
      return 'รหัสผ่านต้องมีความยาวอย่างน้อย 8 ตัว และมีอักขระพิเศษ ตัวเลข ตัวใหญ่-เล็ก';
    }

    if (!isInputSafe(value)) {
      return 'ห้ามใช้คำ SQL หรืออักขระต้องห้ามในรหัสผ่าน';
    }

    return "";
  }

  static bool isValidPassword(String password) {
    final passwordRegex = RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$&*~_])[A-Za-z\d!@#\$&*~_]{8,}$',
    );
    return passwordRegex.hasMatch(password);
  }

  static bool isInputSafe(String input) {
    final injectionPattern = RegExp(
      r"(--)|[';]|(\b(OR|AND|SELECT|INSERT|DELETE|UPDATE|DROP|UNION|WHERE)\b)",
      caseSensitive: false,
    );
    return !injectionPattern.hasMatch(input);
  }

  static String validateIdCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกเลขบัตรประชาชน';
    }
    if (value.length != 13) {
      return 'เลขบัตรประชาชนต้องมี 13 ตัวอักษร';
    }
    return "";
  }

  static String validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอก$fieldName';
    }
    return "";
  }

  static String validateDate(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอก$fieldName';
    }

    try {
      DateFormat('dd/MM/yyyy').parseStrict(value);
    } catch (e) {
      return 'รูปแบบ$fieldNameไม่ถูกต้อง';
    }
    return "";
  }

  static String validateMobileNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'กรุณากรอกมือถือ';
    }

    final phoneRegex = RegExp(r'^\d{9,10}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'รูปแบบเบอร์มือถือไม่ถูกต้อง';
    }

    return "";
  }
}
