import 'package:flutter/material.dart';

import '../translation_toggle_button.dart';

class WorkTitleHeader extends StatelessWidget {
  const WorkTitleHeader({
    super.key,
    required this.title,
    this.translatedTitle,
    this.showTranslation = false,
    this.showTranslateButton = true,
    this.isTranslating = false,
    this.showExternalLink = false,
    this.onTranslate,
    this.onOpenExternalLink,
    this.onCopy,
    this.style,
  });

  final String title;
  final String? translatedTitle;
  final bool showTranslation;
  final bool showTranslateButton;
  final bool isTranslating;
  final bool showExternalLink;
  final VoidCallback? onTranslate;
  final VoidCallback? onOpenExternalLink;
  final ValueChanged<String>? onCopy;
  final TextStyle? style;

  String get displayTitle =>
      showTranslation && translatedTitle != null ? translatedTitle! : title;

  @override
  Widget build(BuildContext context) {
    final titleStyle = style ??
        Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            );

    return GestureDetector(
      onLongPress: onCopy == null ? null : () => onCopy!(displayTitle),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: displayTitle),
            if (showExternalLink && onOpenExternalLink != null)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onOpenExternalLink,
                      child: Icon(
                        Icons.open_in_new,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            if (showTranslateButton)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: InlineTranslationButton(
                  isTranslated: showTranslation,
                  isLoading: isTranslating,
                  onPressed: onTranslate,
                ),
              ),
          ],
        ),
        style: titleStyle,
        textAlign: TextAlign.start,
        softWrap: true,
      ),
    );
  }
}
