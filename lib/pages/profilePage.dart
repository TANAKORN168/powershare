import 'package:flutter/material.dart';
import 'package:powershare/loginPage.dart';
import 'package:powershare/mainLayout.dart';
import 'package:powershare/pages/personalInfoPage.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ ส่วนหัวโปรไฟล์
        Container(
          width: double.infinity, // กว้างเต็มหน้าจอ
          color: Color(0xFF3ABDC5), // สีพื้นหลังที่ต้องการ ปรับได้
          padding: EdgeInsets.symmetric(vertical: 12), // ระยะห่างบนล่าง
          child: Center(
            child: Text(
              'รายละเอียดโปรไฟล์',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          color: Colors.grey[100],
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: AssetImage(
                  'assets/images/avatar.png',
                ), // เปลี่ยนเป็นรูปจริง
              ),
              SizedBox(height: 12),
              Text(
                'สมชาย ใจดี', // ชื่อผู้ใช้
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'someone@email.com', // อีเมลหรือเบอร์
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // ✅ เมนูต่าง ๆ
        ListTile(
          leading: Icon(Icons.person),
          title: Text('ข้อมูลส่วนตัว'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => PersonalInfoPage()),
            );
          },
        ),
        Divider(height: 0),

        ListTile(
          leading: Icon(Icons.history),
          title: Text('ประวัติการเช่า'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            MainLayout.of(context)?.switchToTab(3);
          },
        ),
        Divider(height: 0),

        ListTile(
          leading: Icon(Icons.favorite),
          title: Text('สินค้าที่บันทึกไว้'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            MainLayout.of(context)?.switchToTab(4);
          },
        ),
        Divider(height: 0),

        ListTile(
          leading: Icon(Icons.logout, color: Colors.red),
          title: Text('ออกจากระบบ', style: TextStyle(color: Colors.red)),
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('ยืนยันการออกจากระบบ'),
                content: Text('คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('ยกเลิก'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: Text('ยืนยัน'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
