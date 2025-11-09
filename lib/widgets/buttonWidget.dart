import 'package:flutter/material.dart';

class CustomLoginButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomLoginButton({
    Key? key,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(15.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                backgroundColor: const Color(0xFF1E4F70),
                foregroundColor: Colors.white,
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 20.0,
                  fontFamily: 'Prompt',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
