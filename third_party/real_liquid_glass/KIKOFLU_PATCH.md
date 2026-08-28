# KikoFlu patches

This directory mirrors `real_liquid_glass` 0.3.0 from pub.dev
(`sha256: 07f97c760eb1593ff050fd79b58e91e4e1e0d9135c89b1dcf0ee1941e4e22f11`).

KikoFlu includes these local adjustments:

- macOS native glass platform views reserve a small transparent perimeter for
  the native shadow. The host remains unclipped while the visible effect view
  is inset, avoiding the square AppKitView clip boundary. Grouped regions use
  the same inset coordinate space.
- Calibrate the non-Apple Flutter fallback with a wider transparency range,
  clearer fill, and restrained blur. Native iOS materials remain unchanged;
  macOS uses the platform-view shadow buffer described above.

The local mirror can be removed after an upstream release includes equivalent
behavior.
