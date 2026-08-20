# KikoFlu patch

This directory mirrors `real_liquid_glass` 0.3.0 from pub.dev
(`sha256: 07f97c760eb1593ff050fd79b58e91e4e1e0d9135c89b1dcf0ee1941e4e22f11`).

KikoFlu adds one macOS fix: `GlassHostView` clips its composited AppKit layer
to the same rounded boundary as the native glass view. Without that host-layer
clip, native shadows are cut at the rectangular `AppKitView` boundary.

The local mirror can be removed after an upstream release includes equivalent
host-layer clipping for both rounded rectangles and capsules.
