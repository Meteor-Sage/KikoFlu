# KikoFlu patches

This directory mirrors `real_liquid_glass` 0.3.0 from pub.dev
(`sha256: 07f97c760eb1593ff050fd79b58e91e4e1e0d9135c89b1dcf0ee1941e4e22f11`).

KikoFlu includes these local adjustments:

- `GlassHostView` applies rounded clipping to the legacy AppKit blur fallback.
  On macOS 26+, clipping stays on `NSGlassEffectView` so its outer shadow can
  extend beyond the Flutter host without being cut off.
- Calibrate the non-Apple Flutter fallback with a wider transparency range,
  clearer fill, and restrained blur. Native iOS/macOS materials are unchanged.

The local mirror can be removed after an upstream release includes equivalent
behavior.
