import 'package:flutter/material.dart';


class WelcomeText extends StatelessWidget {
  final String text;

  const WelcomeText({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}




