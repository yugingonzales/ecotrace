import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF7A9185),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: .5,
      ),
    ),
  );
}
