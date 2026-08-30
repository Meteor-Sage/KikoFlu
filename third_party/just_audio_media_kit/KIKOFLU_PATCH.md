# KikoFlu patch notes

This directory vendors `just_audio_media_kit` 2.1.0 under its upstream
license.

## Pending load error propagation

Upstream reports libmpv media-open failures through `Player.stream.error`, but
does not complete the pending `AudioPlayerPlatform.load()` operation. As a
result, `just_audio` callers can wait indefinitely and application-level error
handling never receives the playback failure.

The KikoFlu patch connects the error stream to the pending load operation with
a numeric `PlatformException`, which `just_audio` converts to its normal
`PlayerException`. Successful loads and all playback/session behavior remain
unchanged across Windows, Linux, and macOS.

Keep this patch until the same behavior is available in an upstream release.
