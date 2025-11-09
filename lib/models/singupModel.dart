import 'package:powershare/helps/utils.dart';

class SignupModel {
  final String name; // ✅ ชื่อจริงของผู้ใช้
  final String surname; // ✅ นามสกุลของผู้ใช้
  final String
  birthDate; // ✅ วันเกิดของผู้ใช้ในรูปแบบ ISO 8601 (YYYY-MM-DDTHH:MM:SS)
  final String phoneNumber; // ✅ หมายเลขโทรศัพท์ของผู้ใช้
  final String email; // ✅ อีเมลของผู้ใช้
  final String idCardImagePath; // ✅ path ของรูปบัตรประชาชน
  final String faceImagePath; // ✅ path ของรูปหน้าตรง
  final String idCardNumber; // ✅ หมายเลขบัตรประชาชน
  final String address; // ✅ ที่อยู่ของผู้ใช้
  final String subdistrict; // ✅ ตำบลของที่อยู่
  final String district; // ✅ อำเภอของที่อยู่
  final String province; // ✅ จังหวัดของที่อยู่
  final String postalCode; // ✅ รหัสไปรษณีย์ของที่อยู่
  final String avatarUrl; // ✅ URL ของรูปโปรไฟล์
  final String password;

  SignupModel({
    required this.name,
    required this.surname,
    required this.birthDate,
    required this.phoneNumber,
    required this.email,
    required this.idCardImagePath,
    required this.faceImagePath,
    required this.idCardNumber,
    required this.address,
    required this.subdistrict,
    required this.district,
    required this.province,
    required this.postalCode,
    required this.avatarUrl,
    required this.password,
  });

  Map<String, dynamic> toJson(String uid) {
    return {
      "users_uid": uid,
      "name": name,
      "surname": surname,
      "birth_date": Utils.ConvertToIso8601(birthDate),
      "phone_number": phoneNumber,
      "email": email,
      "id_card_image_path": idCardImagePath,
      "face_image_path": faceImagePath,
      "id_card_number": idCardNumber,
      "address": address,
      "subdistrict": subdistrict,
      "district": district,
      "province": province,
      "postalCode": postalCode,
      "avatar_url": avatarUrl,
      "role": "USER",
      "is_active": true,
      "created_at": DateTime.now().toIso8601String().split('.').first,
    };
  }
}
