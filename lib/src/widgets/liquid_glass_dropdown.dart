import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';

import '../providers/settings_provider.dart';
import '../utils/design_tokens.dart';

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

    final fallbackIntensity = ref.watch(fallbackGlassTransparencyProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final selected = items.cast<DropdownMenuItem<T>?>().firstWhere(
          (item) => item?.value == initialValue,
          orElse: () => null,
        );
        final selectedChild = selected?.child ?? const SizedBox.shrink();
        final controller = MenuController();

        return MenuAnchor(
          controller: controller,
          consumeOutsideTap: true,
          alignmentOffset: const Offset(0, AppSpacing.xxs),
          style: MenuStyle(
            backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            shadowColor: const WidgetStatePropertyAll(Colors.transparent),
            elevation: const WidgetStatePropertyAll(0),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            shape: WidgetStatePropertyAll(roundedBorder(AppRadius.card)),
          ),
          menuChildren: [
            LiquidGlassContainer(
              shape: const LiquidGlassShape.roundedRectangle(AppRadius.card),
              style: LiquidGlassStyle.regular,
              fallbackIntensity: fallbackIntensity,
              child: Material(
                type: MaterialType.transparency,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth.isFinite
                        ? constraints.maxWidth
                        : 0,
                    maxHeight: menuMaxHeight,
                  ),
                  child: SingleChildScrollView(
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
                            style: const ButtonStyle(
                              padding: WidgetStatePropertyAll(
                                EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xxs,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: item.child),
                                if (item.value == initialValue) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  Icon(
                                    Icons.check,
                                    size: AppIconSize.compact,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
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
            ),
          ],
          builder: (context, controller, child) {
            return InkWell(
              borderRadius: BorderRadius.circular(AppRadius.card),
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
        borderRadius: BorderRadius.circular(AppRadius.tag),
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: LiquidGlassContainer(
        shape: const LiquidGlassShape.roundedRectangle(AppRadius.card),
        style: LiquidGlassStyle.regular,
        fallbackIntensity: fallbackIntensity,
        child: Material(type: MaterialType.transparency, child: content),
      ),
    );
  }
}
