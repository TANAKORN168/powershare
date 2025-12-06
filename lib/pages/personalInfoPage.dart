import 'package:flutter/material.dart';
import 'package:powershare/mainLayout.dart';
import 'package:powershare/services/session.dart';

class PersonalInfoPage extends StatelessWidget {
  const PersonalInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ดึงข้อมูลจาก session แทนค่าคงที่
    final user = Session.instance.user ?? <String, dynamic>{};
    final String name = '${(user['name'] ?? '').toString().trim()} ${(user['surname'] ?? '').toString().trim()}'.trim();
    final String idCard = (user['id_card_number'] ?? user['citizen_id  '] ?? '').toString();
    final String email = (user['email'] ?? user['email_address'] ?? '').toString();
    final String phone = (user['phone_number'] ?? user['tel'] ?? user['mobile'] ?? '').toString();
    final String address = '${(user['address'] ?? '').toString().trim()} ${(user['subdistrict'] ?? '').toString().trim()} ${(user['district'] ?? '').toString().trim()} ${(user['province'] ?? '').toString().trim()} ${(user['postalCode'] ?? '').toString().trim()}'.trim();
    final String avatarPath = (user['face_image_path'] ?? user['face_image'] ?? '').toString();
    final ImageProvider avatarProvider = avatarPath.isNotEmpty
        ? NetworkImage(avatarPath)
        : const AssetImage('assets/images/avatar.png');

    return Scaffold(
      appBar: AppBar(
        title: Text('ข้อมูลส่วนตัว'),
        backgroundColor: Color(0xFF3ABDC5),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            final currentUser = Session.instance.user;
            final isAdmin = currentUser != null &&
                (((currentUser['role'] as String?) ?? '').toLowerCase() == 'admin');

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                // ใช้ชื่อหน้าแทนเลข index
                builder: (context) => MainLayout(currentIndex: MainLayout.tabIndex('profile', isAdmin: isAdmin)),
              ),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: avatarProvider,
            ),
            SizedBox(height: 16),
            Text(
              name.isNotEmpty ? name : 'ผู้ใช้',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),

            _buildInfoTile('เลขประจำตัวประชาชน', idCard),
            _buildInfoTile('อีเมล', email),
            _buildInfoTile('เบอร์โทรศัพท์', phone),
            _buildInfoTile('ที่อยู่', address),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          margin: EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value, style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
