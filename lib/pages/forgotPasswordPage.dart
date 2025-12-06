import 'package:flutter/material.dart';
import 'dart:math';
import 'package:powershare/services/emailServices.dart';
import 'package:powershare/validates/textFieldValidate.dart';
import 'package:powershare/widgets/buttonWidget.dart';
import 'package:powershare/widgets/textFieldWidget.dart';
import 'package:powershare/services/apiServices.dart';
import 'package:powershare/pages/resetPasswordPage.dart';
import '../loginPage.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  String htmlForgotPassword = '''
    <!DOCTYPE html>
    <html lang="th">
      <head>
        <meta charset="UTF-8" />
        <title>รหัส OTP PowerShare</title>
      </head>
      <body style="font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 30px;">
        <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 600px; margin: auto; background-color: #ffffff; border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.05);">
          <tr>
            <td style="padding: 30px;">
              <h2 style="color: #3e96c6; margin-top: 0;">🔐 รหัส OTP สำหรับรีเซ็ตรหัสผ่าน PowerShare</h2>

              <table style="background-color: #f9f9f9; border: 1px solid #ddd; border-radius: 8px; padding: 15px; margin: 20px 0;">
                <tr>
                  <td><b>👤 Username:</b></td>
                  <td>{{username}}</td>
                </tr>
                <tr>
                  <td><b>🔑 รหัส OTP:</b></td>
                  <td style="font-size: 24px; font-weight: bold; color: #3e96c6;">{{otp}}</td>
                </tr>
                <tr>
                  <td colspan="2" style="padding-top: 10px; color: #e74c3c;">
                    ⏰ <b>รหัส OTP นี้ใช้ได้ภายใน 15 นาที</b>
                  </td>
                </tr>
              </table>

              <p><b>วิธีใช้:</b></p>
              <ol>
                <li>คัดลอกรหัส OTP ด้านบน</li>
                <li>กลับไปที่แอป PowerShare</li>
                <li>กรอก OTP และตั้งรหัสผ่านใหม่</li>
              </ol>

              <p>หากคุณไม่ได้เป็นคนทำรายการนี้ โปรดติดต่อฝ่ายสนับสนุนของเราทันทีที่ <a href="mailto:support@powershare.app">support@powershare.app</a></p>

              <p style="margin-top: 40px;">ด้วยความเคารพ,<br />
              ทีมงาน PowerShare</p>
            </td>
          </tr>
        </table>
      </body>
    </html>
  ''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ลืมรหัสผ่าน'),
        backgroundColor: Color(0xFF1E4F70),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 40),

            TextFieldWidget.buildEmailField(_emailController, hint: 'อีเมล'),

            SizedBox(height: 30),

            CustomLoginButton(
              text: 'ส่ง OTP',
              onPressed: () async {
                String validatetionMessage = '';

                validatetionMessage = TextFieldValidate.validateEmail(
                  _emailController.text.trim(),
                );

                if (validatetionMessage != '') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(validatetionMessage),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // แสดง loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  // สร้าง OTP และบันทึกใน DB
                  final otp = await ApiServices.generatePasswordResetOTP(_emailController.text.trim());

                  // แทนที่ค่าจริงใน HTML template
                  final htmlContent = htmlForgotPassword
                      .replaceAll('{{username}}', _emailController.text.trim())
                      .replaceAll('{{otp}}', otp);

                  // ส่งอีเมล
                  await EmailServices.sendEmailViaEdgeFunction(
                    to: _emailController.text.trim(),
                    subject: 'OTP รีเซ็ตรหัสผ่าน - PowerShare',
                    html: htmlContent,
                  );

                  Navigator.of(context, rootNavigator: true).pop(); // ปิด loading

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('ระบบได้ส่ง OTP ไปยังอีเมล ${_emailController.text.trim()} แล้ว (ใช้ได้ภายใน 15 นาที)'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // ไปหน้ากรอก OTP และรหัสผ่านใหม่
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResetPasswordPage(email: _emailController.text.trim()),
                    ),
                  );
                } catch (e) {
                  Navigator.of(context, rootNavigator: true).pop(); // ปิด loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('เกิดข้อผิดพลาด: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text(
                'กลับไปหน้าเข้าสู่ระบบ',
                style: TextStyle(color: Color(0xFF3ABDC5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
