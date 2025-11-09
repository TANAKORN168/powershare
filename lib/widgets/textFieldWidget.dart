import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Color backgroundColor = Color.fromARGB(255, 240, 240, 240);
Color borderColor = Color.fromARGB(255, 200, 200, 200);

class TextFieldWidget {
  static Widget buildTextField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
  }) {
    return Container(
      margin: EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        readOnly: readOnly,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: EdgeInsets.all(10.0),
          border: InputBorder.none,
        ),
      ),
    );
  }

  static Widget buildEmailField(
    TextEditingController _emailController, {
    String hint = 'อีเมล',
  }) {
    return Container(
      margin: EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: EdgeInsets.all(10.0),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
