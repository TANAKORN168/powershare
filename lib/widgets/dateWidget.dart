import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Color backgroundColor = Color.fromARGB(255, 240, 240, 240);
Color borderColor = Color.fromARGB(255, 200, 200, 200);

class DateWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(DateTime)? onDateSelected;

  const DateWidget({
    Key? key,
    required this.controller,
    this.hintText = 'วันเดือนปีเกิด',
    this.onDateSelected,
  }) : super(key: key);

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('th', 'TH'),
    );

    if (picked != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(picked);
      if (onDateSelected != null) {
        onDateSelected!(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: GestureDetector(
        onTap: () => _pickDate(context),
        child: AbsorbPointer(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              contentPadding: EdgeInsets.all(10.0),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}
