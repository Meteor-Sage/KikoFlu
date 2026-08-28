# KikoFlu Design System

This document defines the shared visual contract for KikoFlu. It is intended
for incremental migrations: existing product behavior and platform-specific
capabilities take priority over pixel-identical rendering.

## Principles

- Use semantic theme roles instead of page-local font sizes and colors.
- Use the shared tokens in `lib/src/utils/design_tokens.dart` for common
  dimensions. Add a token only when a value is reused or represents a durable
  component rule.
- Preserve feature behavior while migrating styles. In particular, do not
  change feed virtualization, masonry sizing, pagination, Mini Player/dock
  measurements, safe areas, or persisted preferences as part of a style edit.
- Native Apple Liquid Glass, fallback glass, and ordinary Material surfaces
  share dimensions and state semantics. Their blur, opacity, border, and shadow
  may differ to match platform capabilities.

## Tokens

| Role | Values |
| --- | --- |
| Spacing | `4`, `8`, `12`, `16`, `24`, `32` |
| Radius | tag `4`, control `8`, list item `12`, card `16`, capsule `24` |
| Control height | compact `40`, standard `48`, primary `52` |
| Icon size | `16`, `18`, `20`, `24` |

Settings rows use a `52` point content indent for dividers and nested options.
This aligns child content after the leading icon column.

## Typography

Material `TextTheme` is the source of ordinary application text styles.

| Content role | TextTheme role |
| --- | --- |
| Page title | `titleLarge` |
| Section title | `titleMedium` or `titleSmall` |
| List title and body content | `bodyMedium` |
| Supporting text and metadata | `bodySmall` |
| Buttons, selected filters, and normal chips | `labelLarge` |
| Compact filters, chips, and status labels | `labelMedium` |

Do not introduce a raw font size for ordinary UI text. Very small text is
allowed only for registered dense or media layouts where the normal role does
not fit. A local style may change weight, color, height, truncation, or emphasis
without replacing its semantic role.

The global application presets are:

- Standard: `1.0`
- Large: `1.12`
- Extra large: `1.24`

They scale `AppTheme`'s `TextTheme` and remain additive to the operating
system's `MediaQuery.textScaler`. Work-card text, player lyrics, floating lyrics,
and other explicit media typography keep their independent user settings.

## Components

### Settings

- Build settings groups with `SettingsSectionList` and rows with
  `SettingsListTile`, `SettingsNavigationTile`, or `SettingsSwitchTile`.
- Use the shared icon column and list padding. Nested radio/checkbox choices
  start at `AppSettingsLayout.contentIndent`.
- Keep one divider convention within a settings card.

### Search and chips

- Keyword, tag, voice actor, circle, age rating, and sales controls use
  `labelLarge` for the active value and `labelMedium` for compact conditions.
- Include/exclude/disabled state changes semantic color and weight, not size.
- Use `MetadataSearchChip` for searchable metadata and `AgeRatingChip` for age
  semantics. Age-rating colors remain intentionally distinct.

### Dialogs and menus

- Prefer `ResponsiveAlertDialog`, `ResponsiveDialog`, and
  `showResponsiveBottomSheet` when layout must adapt between portrait and
  landscape.
- Dialog titles use `titleLarge`, content uses `bodyMedium`, and actions follow
  cancel/destructive-or-confirm order consistently.
- Dropdowns on glass surfaces use `LiquidGlassDropdownButtonFormField` or
  `LiquidGlassPopupSurface`; do not build another platform-specific glass menu.
- Menu selection is represented by the shared selected/check state and semantic
  primary color.

### Feedback and state

- Use `SnackBarUtil` for success, warning, error, information, and loading
  feedback. New code must not identify state with `Colors.red`, `Colors.green`,
  or `Colors.orange`.
- Empty, loading, error, and end-of-list views use semantic theme colors and the
  standard title/body/action roles.

## Color

Use `ColorScheme` for normal UI:

- primary action: `primary` / `onPrimary`
- ordinary surface: `surface` / `onSurface`
- secondary text: `onSurfaceVariant`
- borders and dividers: `outline` / `outlineVariant`
- error: `error` / `errorContainer`
- success, warning, and information: use the shared feedback component so the
  mapping remains centralized

Explicit black/white overlays are allowed for image viewers, cover media,
contrast masks, and user-configured floating lyrics. Document new exceptions in
this file.

## Responsive and glass behavior

- Derive bottom and side protection from `MediaQuery`, safe areas, orientation,
  window geometry, and the measured dock/Mini Player extent.
- Do not add device-specific fixed bottom offsets.
- Verify native Apple Liquid Glass, adjustable fallback glass, and glass-off
  Material modes. Shared controls retain the same hit targets and layout in all
  three modes.
- Long localized text must wrap or truncate deliberately without overlapping
  icons, trailing controls, or adjacent content.

## Review checklist

- Light, dark, and system theme.
- Phone, tablet, desktop, portrait, and landscape.
- Standard, large, and extra-large app text plus system text scaling.
- Chinese, English, Japanese, and Russian long labels.
- Native Apple glass, fallback glass at low/high opacity, and glass disabled.
- Search filters, settings nesting, chips, menus, dialogs, feedback, toolbars,
  bottom dock, and Mini Player safe areas.
- Android, iOS, Windows, macOS, and Linux runtime screenshots for a migration
  that changes shared theme or layout behavior.
