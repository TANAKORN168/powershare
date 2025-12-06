import 'package:flutter/material.dart';
import 'package:powershare/services/apiServices.dart';
import 'package:powershare/validates/textFieldValidate.dart';
import 'package:powershare/widgets/buttonWidget.dart';
import 'package:powershare/widgets/textFieldWidget.dart';
import '../loginPage.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รีเซ็ตรหัสผ่าน'),
        backgroundColor: const Color(0xFF1E4F70),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              'กรอก OTP ที่ส่งไปยังอีเมล:\n${widget.email}',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            TextFormField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'รหัส OTP (6 หลัก)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pin),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'รหัสผ่านใหม่',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'ยืนยันรหัสผ่านใหม่',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 30),

            CustomLoginButton(
              text: 'ยืนยันรีเซ็ตรหัสผ่าน',
              onPressed: () async {
                // Validate
                if (_otpController.text.trim().length != 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กรุณากรอก OTP 6 หลัก'), backgroundColor: Colors.red),
                  );
                  return;
                }

                final passwordError = TextFieldValidate.validatePassword(_passwordController.text.trim());
                if (passwordError.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(passwordError), backgroundColor: Colors.red),
                  );
                  return;
                }

                if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('รหัสผ่านไม่ตรงกัน'), backgroundColor: Colors.red),
                  );
                  return;
                }

                // Loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  await ApiServices.verifyOTPAndResetPassword(
                    email: widget.email,
                    otp: _otpController.text.trim(),
                    newPassword: _passwordController.text.trim(),
                  );

                  Navigator.of(context, rootNavigator: true).pop(); // ปิด loading

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('รีเซ็ตรหัสผ่านสำเร็จ'), backgroundColor: Colors.green),
                  );

                  // กลับไปหน้า login
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                } catch (e) {
                  Navigator.of(context, rootNavigator: true).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}