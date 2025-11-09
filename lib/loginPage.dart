import 'package:flutter/material.dart';
import 'package:powershare/pages/forgotPasswordPage.dart';
import 'package:powershare/mainLayout.dart';
import 'package:powershare/services/apiServices.dart';
import 'package:powershare/validates/textFieldValidate.dart';
import 'package:powershare/widgets/buttonWidget.dart';
import 'package:powershare/widgets/passwordWidget.dart';
import 'package:powershare/widgets/redirectTextButtonWidget.dart';
import 'package:powershare/widgets/textFieldWidget.dart';
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
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      CustomLoginButton(
                        text: 'เข้าสู่ระบบ',
                        onPressed: () async {
                          String validatetionMessage = '';

                          validatetionMessage =
                              TextFieldValidate.validatePassword(
                                _passwordController.text.trim(),
                              );

                          validatetionMessage = TextFieldValidate.validateEmail(
                            _usernameController.text.trim(),
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

                          var res = await ApiServices.login(
                            _usernameController.text.trim(),
                            _passwordController.text.trim(),
                          );
                          // print(res);

                          if (res['responseCode'] == 'FAIL') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res['responseMessage']),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MainLayout(),
                              ),
                            );
                          }
                        },
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
    );
  }
}
