import 'package:flutter/material.dart';
import '../models/work.dart';

class VaChip extends StatelessWidget {
  final Va va;
  final VoidCallback? onDeleted;
  final VoidCallback? onTap;

  const VaChip({
    super.key,
    required this.va,
    this.onDeleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(va.name),
      onDeleted: onDeleted,
      deleteIcon: onDeleted != null ? const Icon(Icons.close, size: 18) : null,
      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onTertiaryContainer,
      ),
    );
  }
}
