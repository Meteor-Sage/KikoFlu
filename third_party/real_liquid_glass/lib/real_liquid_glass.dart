/// Real Liquid Glass containers and bars for Flutter.
///
/// On iOS 26+ these widgets host Apple's native UIGlassEffect material —
/// actual refractive Liquid Glass that automatically adapts to iOS 27's
/// transparency slider and the Reduce Transparency / Increase Contrast
/// accessibility settings. On older iOS versions they degrade to a native
/// system blur, and on Android/web/desktop to a Flutter-drawn frosted
/// fallback, all behind one API.
library;

export 'src/bottom_bar.dart';
export 'src/capabilities.dart';
export 'src/glass_container.dart';
export 'src/glass_group.dart'
    show LiquidGlassGroup, LiquidGlassGroupState, GlassRegion;
export 'src/glass_style.dart';
