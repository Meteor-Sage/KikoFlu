import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import 'responsive_dialog.dart';
import 'settings_option_dialog.dart';

typedef CommonInputValidator = String? Function(String value);

/// Shared single-value input dialog used by settings and utility flows.
///
/// It follows the same responsive title, spacing and action treatment as the
/// shared option and confirmation dialogs while keeping validation inline.
class CommonTextInputDialog extends StatefulWidget {
  const CommonTextInputDialog({
    super.key,
    required this.title,
    required this.labelText,
    required this.confirmLabel,
    this.initialValue = '',
    this.icon = Icons.edit_outlined,
    this.hintText,
    this.helperText,
    this.cancelLabel,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = true,
    this.validator,
    this.maxWidth = 420,
  });

  final String title;
  final String labelText;
  final String confirmLabel;
  final String initialValue;
  final IconData? icon;
  final String? hintText;
  final String? helperText;
  final String? cancelLabel;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;
  final bool autofocus;
  final CommonInputValidator? validator;
  final double maxWidth;

  @override
  State<CommonTextInputDialog> createState() => _CommonTextInputDialogState();
}

class _CommonTextInputDialogState extends State<CommonTextInputDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    final errorText = widget.validator?.call(value);
    if (errorText != null) {
      setState(() => _errorText = errorText);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = S.of(context);

    return ResponsiveDialog(
      maxWidth: widget.maxWidth,
      titlePadding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      title: Row(
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 22, color: colorScheme.primary),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              widget.title,
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
      content: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        textInputAction: widget.maxLines == 1
            ? TextInputAction.done
            : TextInputAction.newline,
        decoration: settingsDialogInputDecoration(
          context,
          labelText: widget.labelText,
          hintText: widget.hintText,
          helperText: widget.helperText,
          errorText: _errorText,
          prefixIcon: widget.icon == null ? null : Icon(widget.icon),
        ),
        onChanged: (_) {
          if (_errorText != null) setState(() => _errorText = null);
        },
        onSubmitted: widget.maxLines == 1 ? (_) => _submit() : null,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel ?? l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

Future<String?> showCommonTextInputDialog(
  BuildContext context, {
  required String title,
  required String labelText,
  required String confirmLabel,
  String initialValue = '',
  IconData? icon = Icons.edit_outlined,
  String? hintText,
  String? helperText,
  String? cancelLabel,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  int maxLines = 1,
  int? maxLength,
  bool autofocus = true,
  CommonInputValidator? validator,
  double maxWidth = 420,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => CommonTextInputDialog(
      title: title,
      labelText: labelText,
      confirmLabel: confirmLabel,
      initialValue: initialValue,
      icon: icon,
      hintText: hintText,
      helperText: helperText,
      cancelLabel: cancelLabel,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      maxLength: maxLength,
      autofocus: autofocus,
      validator: validator,
      maxWidth: maxWidth,
    ),
  );
}
