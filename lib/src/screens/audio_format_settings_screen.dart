import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../utils/snackbar_util.dart';
import '../widgets/settings_section.dart';

class AudioFormatSettingsScreen extends ConsumerWidget {
  const AudioFormatSettingsScreen({super.key});

  Future<void> _resetToDefault(BuildContext context, WidgetRef ref) async {
    final confirmed = await showSettingsResetConfirmation(
      context: context,
      message: S.of(context).confirmRestoreAudioFormat,
    );

    if (confirmed && context.mounted) {
      await ref.read(audioFormatPreferenceProvider.notifier).resetToDefault();
      if (context.mounted) {
        SnackBarUtil.showSuccess(context, S.of(context).restoredToDefault);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(audioFormatPreferenceProvider);
    final notifier = ref.read(audioFormatPreferenceProvider.notifier);

    return SettingsReorderablePage<AudioFormat>(
      title: S.of(context).audioFormatPriority,
      infoTitle: S.of(context).priorityDescription,
      infoDescription: S.of(context).audioFormatPriorityDesc,
      items: preference.priority,
      itemKey: (format) => format,
      onOrderChanged: notifier.updatePriority,
      onRestoreDefaults: () => _resetToDefault(context, ref),
      itemBuilder: (context, format, index) => ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        title: Text(
          format.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          '.${format.extension}',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: ReorderableDragStartListener(
          index: index,
          child: Icon(
            Icons.drag_handle,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
