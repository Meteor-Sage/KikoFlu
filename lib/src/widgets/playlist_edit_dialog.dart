import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../utils/snackbar_util.dart';
import 'responsive_dialog.dart';
import 'settings_option_dialog.dart';

class PlaylistMetadataDraft {
  const PlaylistMetadataDraft({
    required this.name,
    required this.privacy,
    required this.description,
  });

  final String name;
  final int privacy;
  final String description;
}

class PlaylistEditDialog extends StatefulWidget {
  const PlaylistEditDialog({
    super.key,
    required this.initialName,
    required this.initialPrivacy,
    required this.initialDescription,
    required this.onSave,
  });

  final String initialName;
  final int initialPrivacy;
  final String initialDescription;
  final ValueChanged<PlaylistMetadataDraft> onSave;

  @override
  State<PlaylistEditDialog> createState() => _PlaylistEditDialogState();
}

class _PlaylistEditDialogState extends State<PlaylistEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late int _selectedPrivacy;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController =
        TextEditingController(text: widget.initialDescription);
    _selectedPrivacy = widget.initialPrivacy;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
          Icon(Icons.edit_note, size: 22, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              S.of(context).editPlaylist,
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
          TextField(
            key: const ValueKey('playlist-edit-name'),
            controller: _nameController,
            decoration: settingsDialogInputDecoration(
              context,
              labelText: S.of(context).playlistName,
              hintText: S.of(context).enterPlaylistName,
              prefixIcon: const Icon(Icons.title),
            ),
            autofocus: true,
            maxLength: 50,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: const ValueKey('playlist-edit-privacy'),
            initialValue: _selectedPrivacy,
            decoration: settingsDialogInputDecoration(
              context,
              labelText: S.of(context).privacySetting,
              prefixIcon: const Icon(Icons.lock_outline),
              helperText: _privacyDescription(context),
              helperMaxLines: 2,
            ),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text(S.of(context).playlistPrivacyPrivate),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text(S.of(context).playlistPrivacyUnlisted),
              ),
              DropdownMenuItem(
                value: 2,
                child: Text(S.of(context).playlistPrivacyPublic),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedPrivacy = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('playlist-edit-description'),
            controller: _descriptionController,
            decoration: settingsDialogInputDecoration(
              context,
              labelText: S.of(context).playlistDescription,
              hintText: S.of(context).addDescription,
              prefixIcon: const Icon(Icons.description),
            ),
            maxLines: 1,
            maxLength: 200,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(S.of(context).save)),
      ],
    );
  }

  String _privacyDescription(BuildContext context) {
    switch (_selectedPrivacy) {
      case 0:
        return S.of(context).privacyDescPrivate;
      case 1:
        return S.of(context).privacyDescUnlisted;
      case 2:
        return S.of(context).privacyDescPublic;
      default:
        return '';
    }
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      SnackBarUtil.showWarning(context, S.of(context).playlistNameRequired);
      return;
    }

    Navigator.of(context).pop();
    widget.onSave(
      PlaylistMetadataDraft(
        name: name,
        privacy: _selectedPrivacy,
        description: _descriptionController.text.trim(),
      ),
    );
  }
}
