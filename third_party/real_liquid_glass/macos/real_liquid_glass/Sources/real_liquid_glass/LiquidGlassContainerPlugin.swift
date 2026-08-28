import Cocoa
import CoreGraphics
import FlutterMacOS

public class LiquidGlassContainerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "real_liquid_glass",
      binaryMessenger: registrar.messenger)
    let instance = LiquidGlassContainerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.register(
      GlassViewFactory(messenger: registrar.messenger),
      withId: "real_liquid_glass/glass_view")
    registrar.register(
      GlassGroupViewFactory(messenger: registrar.messenger),
      withId: "real_liquid_glass/glass_group")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getCapabilities":
      var nativeGlass = false
      if #available(macOS 26.0, *) { nativeGlass = true }
      result([
        "nativeGlass": nativeGlass,
        "reduceTransparency":
          NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency,
        "osMajorVersion": ProcessInfo.processInfo.operatingSystemVersion.majorVersion,
      ])
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  static func color(argb: Int64) -> NSColor {
    NSColor(
      srgbRed: CGFloat((argb >> 16) & 0xFF) / 255,
      green: CGFloat((argb >> 8) & 0xFF) / 255,
      blue: CGFloat(argb & 0xFF) / 255,
      alpha: CGFloat((argb >> 24) & 0xFF) / 255)
  }
}

final class GlassViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
    let host = GlassHostView(args: args as? [String: Any] ?? [:])
    let channel = FlutterMethodChannel(
      name: "real_liquid_glass/glass_view_\(viewId)",
      binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak host] call, result in
      switch call.method {
      case "update":
        host?.apply(args: call.arguments as? [String: Any] ?? [:])
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    host.retainedChannel = channel
    return host
  }
}

/// Hosts NSGlassEffectView (macOS 26+) or an NSVisualEffectView blur
/// fallback, mirroring the iOS implementation.
final class GlassHostView: NSView {
  private var glassView: NSView?
  private var capsule = false
  private var cornerRadius: CGFloat = 0
  private var shadowExtent: CGFloat = 0
  private var shadowFadeMask: CALayer?
  private var shadowFadeMaskBounds = CGRect.zero
  private var shadowFadeMaskGlassFrame = CGRect.zero
  private var shadowFadeMaskInset: CGFloat = -1
  private var shadowFadeMaskRadius: CGFloat = -1
  private var shadowFadeMaskScale: CGFloat = -1
  var retainedChannel: FlutterMethodChannel?

  init(args: [String: Any]) {
    super.init(frame: .zero)
    wantsLayer = true
    apply(args: args)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  func apply(args: [String: Any]) {
    if let dark = args["dark"] as? Bool {
      appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
    }
    capsule = args["capsule"] as? Bool ?? false
    cornerRadius = CGFloat((args["cornerRadius"] as? NSNumber)?.doubleValue ?? 0)
    shadowExtent = max(
      0,
      CGFloat((args["shadowExtent"] as? NSNumber)?.doubleValue ?? 0))
    let tint = (args["tint"] as? NSNumber)
      .map { LiquidGlassContainerPlugin.color(argb: $0.int64Value) }

    glassView?.removeFromSuperview()
    if #available(macOS 26.0, *) {
      let glass = NSGlassEffectView()
      if (args["style"] as? String) == "clear" {
        glass.style = .clear
      } else {
        glass.style = .regular
      }
      glass.tintColor = tint
      glassView = glass
    } else {
      let blur = NSVisualEffectView()
      blur.material = .hudWindow
      blur.blendingMode = .withinWindow
      blur.state = .active
      blur.wantsLayer = true
      glassView = blur
    }
    if let glassView {
      updateGlassFrame(of: glassView)
      glassView.autoresizingMask = []
      addSubview(glassView)
    }
    updateCorners()
  }

  override func layout() {
    super.layout()
    if let glassView { updateGlassFrame(of: glassView) }
    updateCorners()
  }

  private func currentShadowInset() -> CGFloat {
    guard bounds.width > 0, bounds.height > 0 else { return 0 }
    return min(shadowExtent, min(bounds.width, bounds.height) / 2)
  }

  private func updateGlassFrame(of view: NSView) {
    view.frame = bounds.insetBy(dx: currentShadowInset(), dy: currentShadowInset())
  }

  private func updateCorners() {
    guard let glassView else { return }
    let inset = currentShadowInset()
    let radius = capsule
      ? min(glassView.bounds.width, glassView.bounds.height) / 2
      : cornerRadius
    // The platform-view host is expanded to hold the native shadow. Round
    // that buffer too, otherwise its rectangular edge clips the shadow.
    layer?.cornerRadius = radius + inset
    if #available(macOS 10.15, *) {
      layer?.cornerCurve = .continuous
    }
    layer?.masksToBounds = true
    updateShadowFadeMask(inset: inset, radius: radius, glassFrame: glassView.frame)
    if #available(macOS 26.0, *), let glass = glassView as? NSGlassEffectView {
      glass.cornerRadius = radius
    } else if let layer = glassView.layer {
      layer.cornerRadius = radius
      if #available(macOS 10.15, *) {
        layer.cornerCurve = .continuous
      }
      layer.masksToBounds = true
    }
  }

  private func updateShadowFadeMask(
    inset: CGFloat,
    radius: CGFloat,
    glassFrame: CGRect
  ) {
    guard let hostLayer = layer, inset > 0 else {
      layer?.mask = nil
      shadowFadeMask = nil
      return
    }

    let scale = max(
      window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2,
      1)
    if shadowFadeMask != nil,
      shadowFadeMaskBounds == bounds,
      shadowFadeMaskGlassFrame == glassFrame,
      shadowFadeMaskInset == inset,
      shadowFadeMaskRadius == radius,
      shadowFadeMaskScale == scale {
      return
    }

    let pixelWidth = max(1, Int(ceil(bounds.width * scale)))
    let pixelHeight = max(1, Int(ceil(bounds.height * scale)))
    guard let context = CGContext(
      data: nil,
      width: pixelWidth,
      height: pixelHeight,
      bitsPerComponent: 8,
      bytesPerRow: pixelWidth * 4,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
      let image = makeShadowFadeMaskImage(
        context: context,
        scale: scale,
        glassFrame: glassFrame,
        radius: radius,
        inset: inset)
    else { return }

    let mask = CALayer()
    mask.frame = bounds
    mask.contents = image
    mask.contentsScale = scale
    mask.contentsGravity = .resize
    hostLayer.mask = mask
    shadowFadeMask = mask
    shadowFadeMaskBounds = bounds
    shadowFadeMaskGlassFrame = glassFrame
    shadowFadeMaskInset = inset
    shadowFadeMaskRadius = radius
    shadowFadeMaskScale = scale
  }

  private func makeShadowFadeMaskImage(
    context: CGContext,
    scale: CGFloat,
    glassFrame: CGRect,
    radius: CGFloat,
    inset: CGFloat
  ) -> CGImage? {
    context.clear(
      CGRect(
        x: 0,
        y: 0,
        width: bounds.width * scale,
        height: bounds.height * scale))
    context.scaleBy(x: scale, y: scale)
    context.setFillColor(NSColor.white.cgColor)
    // Draw the mask's own rounded shadow into an alpha image. This makes the
    // buffer fade continuously instead of relying on a hard layer boundary.
    context.setShadow(
      offset: .zero,
      blur: max(0.5, inset / 3),
      color: NSColor.white.cgColor)
    let localFrame = glassFrame.offsetBy(dx: -bounds.minX, dy: -bounds.minY)
    let path = CGPath(
      roundedRect: localFrame,
      cornerWidth: radius,
      cornerHeight: radius,
      transform: nil)
    context.addPath(path)
    context.fillPath()
    return context.makeImage()
  }
}

final class GlassGroupViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
    GlassGroupHostView(
      viewId: viewId,
      messenger: messenger,
      args: args as? [String: Any] ?? [:])
  }
}

/// One native view hosting many glass shapes so they can merge, via
/// NSGlassEffectContainerView on macOS 26+.
final class GlassGroupHostView: NSView {
  private struct ShapeMaterial: Equatable {
    let style: String
    let tint: Int64?
    let capsule: Bool
    let cornerRadius: Double
  }

  private var containerView: NSView?
  private var shapes: [Int: NSView] = [:]
  private var materials: [Int: ShapeMaterial] = [:]
  private var spacing: CGFloat = -1
  private var shadowExtent: CGFloat = 0
  private var channel: FlutterMethodChannel?

  init(viewId: Int64, messenger: FlutterBinaryMessenger, args: [String: Any]) {
    super.init(frame: .zero)
    wantsLayer = true
    shadowExtent = max(
      0,
      CGFloat((args["shadowExtent"] as? NSNumber)?.doubleValue ?? 0))
    let channel = FlutterMethodChannel(
      name: "real_liquid_glass/glass_group_\(viewId)",
      binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(FlutterMethodNotImplemented) }
      switch call.method {
      case "setRegions":
        self.setRegions(call.arguments as? [String: Any] ?? [:])
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  private func hostContainer() -> NSView {
    if let containerView { return containerView }
    let view: NSView
    if #available(macOS 26.0, *) {
      let group = NSGlassEffectContainerView()
      let content = FlippedView(frame: bounds)
      content.autoresizingMask = [.width, .height]
      group.contentView = content
      view = group
    } else {
      view = FlippedView()
    }
    view.frame = bounds
    view.autoresizingMask = [.width, .height]
    addSubview(view)
    containerView = view
    return view
  }

  private var shapeParent: NSView? {
    if #available(macOS 26.0, *),
      let group = containerView as? NSGlassEffectContainerView {
      return group.contentView
    }
    return containerView
  }

  private func setRegions(_ args: [String: Any]) {
    if let dark = args["dark"] as? Bool {
      appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
    }
    let container = hostContainer()
    if let extent = args["shadowExtent"] as? NSNumber {
      shadowExtent = max(0, CGFloat(extent.doubleValue))
    }
    let newSpacing = CGFloat((args["spacing"] as? NSNumber)?.doubleValue ?? 24)
    if #available(macOS 26.0, *), newSpacing != spacing,
      let group = container as? NSGlassEffectContainerView {
      spacing = newSpacing
      group.spacing = newSpacing
    }

    let regions = args["regions"] as? [[String: Any]] ?? []
    var seen = Set<Int>()
    for region in regions {
      guard let id = (region["id"] as? NSNumber)?.intValue else { continue }
      seen.insert(id)
      apply(region: region, id: id)
    }
    for (id, shape) in shapes where !seen.contains(id) {
      shape.removeFromSuperview()
      shapes[id] = nil
      materials[id] = nil
    }
  }

  private func apply(region: [String: Any], id: Int) {
    let frame = CGRect(
      x: (region["x"] as? NSNumber)?.doubleValue ?? 0,
      y: (region["y"] as? NSNumber)?.doubleValue ?? 0,
      width: (region["width"] as? NSNumber)?.doubleValue ?? 0,
      height: (region["height"] as? NSNumber)?.doubleValue ?? 0)
      .offsetBy(dx: shadowExtent, dy: shadowExtent)
    let material = ShapeMaterial(
      style: region["style"] as? String ?? "regular",
      tint: (region["tint"] as? NSNumber)?.int64Value,
      capsule: region["capsule"] as? Bool ?? false,
      cornerRadius: (region["cornerRadius"] as? NSNumber)?.doubleValue ?? 0)

    var shape = shapes[id]
    if shape == nil || materials[id] != material {
      shape?.removeFromSuperview()
      let built = makeShape(material: material, size: frame.size)
      shapeParent?.addSubview(built)
      shapes[id] = built
      materials[id] = material
      shape = built
    }
    shape?.frame = frame
    updateCorners(of: shape, material: material)
  }

  private func makeShape(material: ShapeMaterial, size: CGSize) -> NSView {
    let tint = material.tint.map { LiquidGlassContainerPlugin.color(argb: $0) }
    if #available(macOS 26.0, *) {
      let glass = NSGlassEffectView()
      glass.style = material.style == "clear" ? .clear : .regular
      glass.tintColor = tint
      return glass
    }
    let blur = NSVisualEffectView()
    blur.material = .hudWindow
    blur.blendingMode = .withinWindow
    blur.state = .active
    blur.wantsLayer = true
    return blur
  }

  private func updateCorners(of shape: NSView?, material: ShapeMaterial) {
    guard let shape else { return }
    let radius = material.capsule
      ? min(shape.bounds.width, shape.bounds.height) / 2
      : CGFloat(material.cornerRadius)
    if #available(macOS 26.0, *), let glass = shape as? NSGlassEffectView {
      glass.cornerRadius = radius
    } else if let layer = shape.layer {
      layer.cornerRadius = radius
      layer.masksToBounds = true
    }
  }
}

/// AppKit's default coordinate system is bottom-left; Flutter sends
/// top-left rects. Flipping the container makes the math match.
final class FlippedView: NSView {
  override var isFlipped: Bool { true }
}
