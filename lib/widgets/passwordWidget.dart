import 'package:flutter/material.dart';

Color backgroundColor = Color.fromARGB(255, 240, 240, 240);
Color borderColor = Color.fromARGB(255, 200, 200, 200);

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;

  const PasswordField({
    Key? key,
    required this.controller,
    this.hint = 'รหัสผ่าน',
  }) : super(key: key);

  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          hintText: widget.hint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 14.0,
          ),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
      ),
    );
  }
}
