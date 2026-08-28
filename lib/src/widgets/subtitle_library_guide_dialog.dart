import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'responsive_dialog.dart';

class SubtitleLibraryGuideDialog extends StatelessWidget {
  const SubtitleLibraryGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return ResponsiveAlertDialog(
      title: Text(
        l10n.subtitleLibraryGuide,
        style: const TextStyle(fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GuideStep(
              number: '1',
              title: l10n.subtitleLibraryFunction,
              description: l10n.subtitleLibraryFunctionDesc,
            ),
            const SizedBox(height: 16),
            _GuideStep(
              number: '2',
              title: l10n.subtitleAutoLoad,
              description: l10n.subtitleAutoLoadDesc,
              children: [
                _GuideBullet(
                  child: Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(text: l10n.guideInPrefix),
                        TextSpan(
                          text: l10n.guideParsedFolder,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: l10n.guideFindWorkDesc),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _GuideBullet(
                  child: Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(text: l10n.guideInPrefix),
                        TextSpan(
                          text: l10n.guideSavedFolder,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: l10n.guideFindSubtitleDesc),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _GuideBullet(
                  child: Text(
                    l10n.guideMatchRule,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _GuideStep(
              number: '3',
              title: l10n.smartCategoryAndMark,
              children: [
                _GuideBullet(
                  child: Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(text: l10n.guideRecognizedWorkPrefix),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.closed_caption,
                              color: Colors.green,
                              size: 18.0,
                            ),
                          ),
                        ),
                        TextSpan(text: l10n.guideTagSuffix),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Stack(
                              children: [
                                const Icon(
                                  Icons.audiotrack,
                                  color: Colors.green,
                                  size: 24,
                                ),
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.subtitles,
                                      color: Colors.blue[600],
                                      size: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        TextSpan(text: l10n.guideSubtitleMatchSuffix),
                      ],
                    ),
                  ),
                ),
                _GuideBullet(
                  child: Text(
                    l10n.guideAutoRecognizeRJ,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 6),
                _GuideBullet(
                  child: Text(
                    l10n.guideAutoAddRJPrefix,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.gotIt),
        ),
      ],
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.number,
    required this.title,
    this.description,
    this.children = const [],
  });

  final String number;
  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final description = this.description;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepNumberBadge(number: number),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (children.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StepNumberBadge extends StatelessWidget {
  const _StepNumberBadge({required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          number,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _GuideBullet extends StatelessWidget {
  const _GuideBullet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '\u2022 ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Expanded(child: child),
      ],
    );
  }
}
