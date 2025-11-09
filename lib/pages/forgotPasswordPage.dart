import 'package:flutter/material.dart';
import 'package:powershare/services/emailServices.dart';
import 'package:powershare/validates/textFieldValidate.dart';
import 'package:powershare/widgets/buttonWidget.dart';
import 'package:powershare/widgets/redirectTextButtonWidget.dart';
import 'package:powershare/widgets/textFieldWidget.dart';
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
        <title>รหัสผ่าน PowerShare</title>
      </head>
      <body style="font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 30px;">
        <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 600px; margin: auto; background-color: #ffffff; border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.05);">
          <tr>
            <td style="padding: 30px;">
              <h2 style="color: #3e96c6; margin-top: 0;">🔐 รหัสผ่านสำหรับใช้งาน PowerShare ของคุณคือ</h2>

              <table style="background-color: #f9f9f9; border: 1px solid #ddd; border-radius: 8px; padding: 15px; margin: 20px 0;">
                <tr>
                  <td><b>👤 Username:</b></td>
                  <td>{{username}}</td>
                </tr>
                <tr>
                  <td><b>🔑 รหัสผ่านใหม่:</b></td>
                  <td>{{new_password}}</td>
                </tr>
              </table>

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
              text: 'เข้าสู่ระบบ',
              onPressed: () {
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

                EmailServices.sendEmailViaEdgeFunction(
                  to: 'jack.buffer@gmail.com',
                  subject: 'APP PowerShare!',
                  html: htmlForgotPassword,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ระบบได้ส่งคำขอลืมรหัสผ่านไปยังอีเมลแล้ว'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            SizedBox(height: 10),
            RedirectTextButtonWidget(
              text: 'กลับไปหน้าเข้าสู่ระบบ',
              pageToNavigate: const LoginPage(),
            ),
          ],
        ),
      ),
    );
  }
}
