import 'package:flutter/material.dart';
import 'package:powershare/pages/forgotPasswordPage.dart';
import 'package:powershare/mainLayout.dart';
import 'package:powershare/services/apiServices.dart';
import 'package:powershare/services/session.dart'; // <-- เพิ่มบรรทัดนี้
import 'package:powershare/validates/textFieldValidate.dart';
import 'package:powershare/widgets/passwordWidget.dart';
import 'package:powershare/widgets/redirectTextButtonWidget.dart';
import 'package:powershare/widgets/textFieldWidget.dart';
import 'package:powershare/widgets/buttonWidget.dart'; // <-- เพิ่ม import นี้
import 'pages/registerPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return LoginPageState();
  }
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // ตรวจ email ก่อน password
    String validationMessage =
        TextFieldValidate.validateEmail(_usernameController.text.trim());
    if (validationMessage != '') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationMessage),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    validationMessage =
        TextFieldValidate.validatePassword(_passwordController.text.trim());
    if (validationMessage != '') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationMessage),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _loading = true);

    // ให้เวลาให้เฟรมวาด spinner ก่อนเรียก API
    await Future.delayed(const Duration(milliseconds: 80));

    try {
      var res = await ApiServices.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (res['responseCode'] == 'FAIL') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['responseMessage']),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      } else {
        // --- เพิ่มการเก็บข้อมูล user แบบ global ---
        // ตัวอย่าง: ApiServices.login คืนข้อมูล users ใน key 'user' เป็น list
        final users = res['user'] as List<dynamic>? ?? [];
        final email = _usernameController.text.trim();
        final matchedUser = users.firstWhere(
          (u) => (u['email'] as String?)?.toLowerCase() == email.toLowerCase(),
          orElse: () => null,
        );

        if (matchedUser != null) {
          Session.instance.setUser(Map<String, dynamic>.from(matchedUser),
              token: res['access_token'] as String?);
          // ถ้าต้องการเก็บลง SharedPreferences ให้เรียก
          await Session.instance.saveToPrefs();
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainLayout(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เกิดข้อผิดพลาด'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(height: 30),
                          Container(
                            padding: EdgeInsets.all(15),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 200,
                            ),
                          ),
                          SizedBox(height: 20),

                          TextFieldWidget.buildEmailField(
                            _usernameController,
                            hint: 'อีเมล',
                          ),
                          PasswordField(controller: _passwordController),

                          const SizedBox(height: 16),

                          // --- เปลี่ยนกลับไปใช้ CustomLoginButton แต่รองรับ loading (spinner บนปุ่ม) ---
                          // ใช้ Stack เพื่อวาง spinner กลางปุ่มเมื่อ _loading = true
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // ปุ่มแบบเดิม (appearance มาจาก CustomLoginButton)
                                CustomLoginButton(
                                  text: 'เข้าสู่ระบบ',
                                  // ส่ง closure ที่คืนค่า void แทนการส่ง Future<void> โดยตรง
                                  onPressed: () {
                                    if (_loading) return;
                                    _handleLogin();
                                  },
                                ),

                                // spinner บนปุ่ม (แสดงเมื่อ loading)
                                if (_loading)
                                  Positioned.fill(
                                    child: Container(
                                      alignment: Alignment.center,
                                      color: Colors.transparent,
                                      child: const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3ABDC5)),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: EdgeInsets.only(right: 30),
                              child: RedirectTextButtonWidget(
                                text: 'ลืมรหัสผ่าน?',
                                pageToNavigate: const ForgotPasswordPage(),
                              ),
                            ),
                          ),
                          SizedBox(height: 15),
                          RedirectTextButtonWidget(
                            text: 'ยังไม่มีบัญชี? สมัครสมาชิก',
                            pageToNavigate: const RegisterPage(),
                          ),
                          SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // overlay loading แบบเต็มหน้าจอ (ป้องกันการกดซ้ำ)
        if (_loading)
          Positioned.fill(
            child: Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3ABDC5)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
