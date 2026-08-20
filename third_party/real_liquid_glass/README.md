# real_liquid_glass

Real Liquid Glass for Flutter — not a shader imitation.

<img src="https://raw.githubusercontent.com/kiddo4/real_liquid_glass/main/doc/demo.gif" width="320" alt="Demo recorded on an iPhone 17: a music app with glass cards, a glass mini-player, and the native Liquid Glass tab bar morphing between tabs" />

On iOS 26+ and macOS 26+ these widgets host Apple's native glass material
(`UIGlassEffect` / `NSGlassEffectView`) in a platform view beneath your
Flutter content, so you get **actual refractive Liquid Glass**: it samples
and bends what's behind it, shimmers on touch, merges like droplets, and —
because it's the system material — automatically follows every system
appearance setting, including:

- the **iOS 27 transparency slider** (ultra-clear → fully tinted),
- **Reduce Transparency** and **Increase Contrast**,
- iOS 27's refined edges, highlights, and content diffusion.

Elsewhere it degrades gracefully behind the same API: a native system blur
on iOS/macOS < 26, and a Flutter-drawn frosted material on Android, web,
Windows, and Linux (with high-contrast support and an intensity dial).

## Widgets

### `LiquidGlassContainer`

The primitive. Use it like a `Container` and build whatever you want —
cards, pills, headers, floating panels:

```dart
LiquidGlassContainer(
  shape: const LiquidGlassShape.roundedRectangle(16),
  padding: const EdgeInsets.all(20),
  onTap: () => play(),
  child: const Text('Now playing'),
)
```

Options: `style` (`LiquidGlassStyle.regular` for legibility, `.clear` over
media), `shape` (`.capsule()` or `.roundedRectangle(r)`), `tint`,
`interactive` (Apple's touch shimmer), and `Container`-style `padding`,
`margin`, `width`, `height`, `alignment`. Supplying `onTap` automatically
enables the native interactive material on iOS and requires no Swift setup.

### `LiquidGlassGroup` — true liquid merging

The signature behavior from Apple's demos: glass shapes that fuse like
droplets when they approach each other. Wrap any subtree and every
`LiquidGlassContainer` inside it shares one native glass container
(`UIGlassContainerEffect` / `NSGlassEffectContainerView`):

```dart
LiquidGlassGroup(
  spacing: 32, // distance at which shapes begin to merge
  child: Stack(
    children: [
      Align(child: LiquidGlassContainer(
        shape: const LiquidGlassShape.capsule(), width: 200, height: 64)),
      Positioned(
        left: _x, top: _y, // animate or drag this — the glass morphs along
        child: LiquidGlassContainer(
          shape: const LiquidGlassShape.capsule(), width: 64, height: 64)),
    ],
  ),
)
```

Bonus: N containers in a group cost **one** platform view, not N.

### `LiquidGlassBottomBar`

A floating capsule tab bar in the iOS 26/27 idiom, built on the container:

```dart
LiquidGlassBottomBar(
  items: const [
    LiquidGlassBarItem(
      icon: CupertinoIcons.house,
      sfSymbol: 'house',
      label: 'Home',
    ),
    LiquidGlassBarItem(
      icon: CupertinoIcons.search,
      sfSymbol: 'magnifyingglass',
      label: 'Search',
    ),
    LiquidGlassBarItem(
      icon: CupertinoIcons.person,
      sfSymbol: 'person',
      label: 'Profile',
    ),
  ],
  currentIndex: _index,
  onTap: (i) => setState(() => _index = i),
)
```

Place it above your content (e.g. bottom-aligned in a `Stack`) so the glass
has something to refract. On iOS this widget is a complete native `UITabBar`,
not a Flutter recreation: iOS owns the Liquid Glass surface, selection lens,
touch response, accessibility, and system morphing animation. `sfSymbol` and
`selectedSfSymbol` configure its native icons. Other platforms keep the
Flutter-rendered fallback behind the same API.

### `LiquidGlass.capabilities()`

Runtime introspection when you need it:

```dart
final caps = await LiquidGlass.capabilities();
if (caps.nativeGlass) { /* real UIGlassEffect (iOS 26+) */ }
if (caps.reduceTransparency) { /* user prefers opaque surfaces */ }
```

## Design notes

- **Glass needs content.** Apple's material only reads as glass over rich,
  scrolling content. Don't stack glass on glass; don't put it on a flat
  background and expect magic.
- **`regular` vs `clear`:** default to `regular` — it keeps text legible.
  Reserve `clear` for controls over photos/video.
- **Tinting:** supported, but Apple's guidance is that glass reads best
  untinted. The bar's selected color is the ambient Cupertino primary.
- **Touch handling:** non-`interactive` glass never intercepts touches;
  your widgets behind and above it keep working.
- The fallback's `fallbackIntensity` (0–1) is the in-app analogue of the
  iOS 27 slider for platforms that don't have one.

## Requirements

- iOS / macOS: builds with Xcode 26+ (iOS/macOS 26 SDK). Runs on any OS
  version the app supports — glass on 26+, system blur before that.
- Other platforms: no setup; the Dart fallback is dependency-free.

## Alternatives

Honest map of the space: [native_liquid_glass](https://pub.dev/packages/native_liquid_glass)
wraps ~20 native iOS controls (buttons, pickers, sheets…) if you want a
whole widget suite; [cupertino_native](https://pub.dev/packages/cupertino_native)
embeds complete native bars; shader packages like
[liquid_glass_renderer](https://pub.dev/packages/liquid_glass_renderer)
imitate the look anywhere without native views. This package instead stays
deliberately small: one glass **container primitive** you compose into
anything, plus a bottom bar, with **liquid merging for arbitrary
containers** and **macOS support** — and zero Dart dependencies.

## Example

`example/` contains the four-tab music app shown above: glass cards and a
mini-player over rich artwork, driven by the native Liquid Glass tab bar.
