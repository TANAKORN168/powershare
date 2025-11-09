import 'package:flutter/material.dart';

class RedirectTextButtonWidget extends StatefulWidget {
  final String text;
  final Widget pageToNavigate;

  const RedirectTextButtonWidget({
    super.key,
    required this.text,
    required this.pageToNavigate,
  });

  @override
  State<RedirectTextButtonWidget> createState() =>
      _RedirectTextButtonWidgetState();
}

class _RedirectTextButtonWidgetState extends State<RedirectTextButtonWidget> {
  void _navigate() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => widget.pageToNavigate),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _navigate,
      child: Text(
        widget.text,
        style: const TextStyle(
          color: Color(0xFF3ABDC5),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
