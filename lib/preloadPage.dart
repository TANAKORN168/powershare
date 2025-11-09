import 'package:flutter/material.dart';
import 'loginPage.dart';

class PreloadPage extends StatefulWidget {
  const PreloadPage({super.key});
  @override
  PreloadPageState createState() => PreloadPageState();
}

class PreloadPageState extends State<PreloadPage> {
  @override
  void initState() {
    super.initState();

    // รอ 3 วินาทีแล้วไปหน้า Login
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // พื้นหลังสีขาว
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // โลโก้ + กรอบ
            Container(
              padding: EdgeInsets.all(15), // ช่องว่างรอบโลโก้
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12), // มุมโค้ง
              ),
              child: Image.asset(
                'assets/images/logo.png', // เปลี่ยน path ตามโลโก้ของคุณ
                width: 300,
              ),
            ),
            Text(
              'เครื่องใช้ไฟฟ้า ไม่ต้องซื้อ ก็ใช้ได้',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Prompt',
                fontWeight: FontWeight.bold,
                color: Color(0xFF3ABDC5), // สี #3abdc5
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
