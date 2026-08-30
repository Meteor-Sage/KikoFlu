import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';

import '../providers/settings_provider.dart';

/// A dropdown field that keeps Material's form-field behavior while using a
/// glass-backed menu when the app's liquid-glass navigation is enabled.
class LiquidGlassDropdownButtonFormField<T> extends ConsumerWidget {
  const LiquidGlassDropdownButtonFormField({
    super.key,
    required this.initialValue,
    required this.items,
    required this.onChanged,
    required this.decoration,
    this.style,
    this.menuMaxHeight = 300,
  });

  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration decoration;
  final TextStyle? style;
  final double menuMaxHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useLiquidGlass = ref.watch(liquidGlassNavigationProvider);
    if (!useLiquidGlass) {
      return DropdownButtonFormField<T>(
        initialValue: initialValue,
        decoration: decoration,
        style: style,
        menuMaxHeight: menuMaxHeight,
        items: items,
        onChanged: onChanged,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final selected = items.cast<DropdownMenuItem<T>?>().firstWhere(
          (item) => item?.value == initialValue,
          orElse: () => null,
        );
        final selectedChild = selected?.child ?? const SizedBox.shrink();
        final colorScheme = Theme.of(context).colorScheme;
        final controller = MenuController();

        return MenuAnchor(
          controller: controller,
          consumeOutsideTap: true,
          alignmentOffset: const Offset(0, 4),
          style: MenuStyle(
            backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            shadowColor: const WidgetStatePropertyAll(Colors.transparent),
            elevation: const WidgetStatePropertyAll(0),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
          menuChildren: [
            LiquidGlassPopupSurface(
              maxHeight: menuMaxHeight,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth.isFinite
                      ? constraints.maxWidth
                      : 0,
                ),
                child: SingleChildScrollView(
                  primary: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in items)
                        MenuItemButton(
                          onPressed: item.enabled
                              ? () {
                                  controller.close();
                                  item.onTap?.call();
                                  if (item.onTap == null) {
                                    onChanged?.call(item.value);
                                  }
                                }
                              : null,
                          style: ButtonStyle(
                            foregroundColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.disabled)
                                  ? colorScheme.onSurface.withValues(
                                      alpha: 0.38,
                                    )
                                  : colorScheme.onSurface,
                            ),
                            iconColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.disabled)
                                  ? colorScheme.onSurfaceVariant.withValues(
                                      alpha: 0.38,
                                    )
                                  : colorScheme.onSurfaceVariant,
                            ),
                            padding: const WidgetStatePropertyAll(
                              EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: item.child),
                              if (item.value == initialValue) ...[
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          builder: (context, controller, child) {
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              child: InputDecorator(
                decoration: decoration,
                isFocused: controller.isOpen,
                isEmpty: false,
                child: Row(
                  children: [
                    Expanded(
                      child: DefaultTextStyle(
                        style: style ?? Theme.of(context).textTheme.bodyMedium!,
                        child: selectedChild,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Wraps an overlay surface so Autocomplete menus follow the same material as
/// other app dropdowns without changing their existing option interaction.
class LiquidGlassPopupSurface extends ConsumerWidget {
  const LiquidGlassPopupSurface({
    super.key,
    required this.child,
    this.maxHeight,
  });

  final Widget child;
  final double? maxHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useLiquidGlass = ref.watch(liquidGlassNavigationProvider);
    final fallbackIntensity = ref.watch(fallbackGlassTransparencyProvider);
    final content = maxHeight == null
        ? child
        : ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight!),
            child: child,
          );

    if (!useLiquidGlass) {
      return Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(4),
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    }

    // Native glass is a platform view. When it is mounted inside a menu
    // overlay, iOS/macOS can composite that view above Flutter descendants,
    // which hides the menu labels and icons. Keep popup content in Flutter's
    // compositing tree while retaining the same blur/material appearance.
    if (LiquidGlass.isNativePlatform) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final fillOpacity = theme.brightness == Brightness.dark ? 0.72 : 0.82;
      final radius = BorderRadius.circular(18);
      return ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: fillOpacity,
              ),
              borderRadius: radius,
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.32),
                width: 0.8,
              ),
            ),
            child: Material(type: MaterialType.transparency, child: content),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: LiquidGlassContainer(
        shape: const LiquidGlassShape.roundedRectangle(18),
        style: LiquidGlassStyle.regular,
        fallbackIntensity: fallbackIntensity,
        child: Material(type: MaterialType.transparency, child: content),
      ),
    );
  }
}
