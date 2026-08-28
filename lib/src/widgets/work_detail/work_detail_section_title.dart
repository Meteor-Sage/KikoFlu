import 'package:flutter/material.dart';

class WorkDetailSectionTitle extends StatelessWidget {
  const WorkDetailSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
    );
  }
}
