import 'package:flutter/material.dart';
import '../models/work.dart';

class TagChip extends StatelessWidget {
  final Tag tag;
  final VoidCallback? onDeleted;
  final VoidCallback? onTap;

  const TagChip({
    super.key,
    required this.tag,
    this.onDeleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(tag.name),
      onDeleted: onDeleted,
      deleteIcon: onDeleted != null ? const Icon(Icons.close, size: 18) : null,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    );
  }
}
