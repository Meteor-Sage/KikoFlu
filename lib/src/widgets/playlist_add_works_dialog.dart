import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../services/work_id_parser.dart';
import 'responsive_dialog.dart';
import 'settings_option_dialog.dart';

class PlaylistAddWorksDialog extends StatefulWidget {
  const PlaylistAddWorksDialog({
    super.key,
    required this.onAddWorks,
  });

  final ValueChanged<List<String>> onAddWorks;

  @override
  State<PlaylistAddWorksDialog> createState() => _PlaylistAddWorksDialogState();
}

class _PlaylistAddWorksDialogState extends State<PlaylistAddWorksDialog> {
  final TextEditingController _textController = TextEditingController();
  List<String> _parsedWorkIds = [];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ResponsiveDialog(
      maxWidth: 600,
      titlePadding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      title: Row(
        children: [
          Icon(Icons.playlist_add, size: 22, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              S.of(context).addWorks,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).addWorksInputHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            decoration: settingsDialogInputDecoration(
              context,
              labelText: S.of(context).workId,
              hintText: S.of(context).workIdHint,
              prefixIcon: const Icon(Icons.music_note),
            ),
            maxLines: 5,
            autofocus: true,
            onChanged: _handleInputChanged,
          ),
          if (_parsedWorkIds.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ParsedWorkIdsPreview(ids: _parsedWorkIds),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).cancel),
        ),
        FilledButton(
          onPressed: _parsedWorkIds.isEmpty ? null : _submitParsedIds,
          child: Text(
            _parsedWorkIds.isEmpty
                ? S.of(context).add
                : S.of(context).addNWorks(_parsedWorkIds.length),
          ),
        ),
      ],
    );
  }

  void _handleInputChanged(String text) {
    setState(() {
      _parsedWorkIds = WorkIdParser.extractRJIds(text);
    });
  }

  void _submitParsedIds() {
    final ids = List<String>.unmodifiable(_parsedWorkIds);
    Navigator.of(context).pop();
    widget.onAddWorks(ids);
  }
}

class _ParsedWorkIdsPreview extends StatelessWidget {
  const _ParsedWorkIdsPreview({required this.ids});

  final List<String> ids;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                S.of(context).detectedNWorkIds(ids.length),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ids.map((id) {
              return Chip(
                label: Text(id, style: Theme.of(context).textTheme.bodySmall),
                visualDensity: VisualDensity.compact,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
