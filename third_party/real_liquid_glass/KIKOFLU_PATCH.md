# KikoFlu patches

This directory mirrors `real_liquid_glass` 0.3.0 from pub.dev
(`sha256: 07f97c760eb1593ff050fd79b58e91e4e1e0d9135c89b1dcf0ee1941e4e22f11`).

KikoFlu includes these local adjustments:

- `GlassHostView` clips its composited AppKit layer to the same rounded boundary
  as the native glass view, so native shadows cannot leak into rectangular
  corners.
- Calibrate the non-Apple Flutter fallback with a wider transparency range,
  clearer fill, and restrained blur. Native iOS/macOS materials are unchanged.

The local mirror can be removed after an upstream release includes equivalent
behavior.
