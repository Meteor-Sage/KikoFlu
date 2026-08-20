import Flutter
import UIKit

public class LiquidGlassContainerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "real_liquid_glass",
      binaryMessenger: registrar.messenger())
    let instance = LiquidGlassContainerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.register(
      GlassViewFactory(messenger: registrar.messenger()),
      withId: "real_liquid_glass/glass_view")
    registrar.register(
      GlassGroupViewFactory(messenger: registrar.messenger()),
      withId: "real_liquid_glass/glass_group")
    registrar.register(
      NativeTabBarViewFactory(messenger: registrar.messenger()),
      withId: "real_liquid_glass/tab_bar")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getCapabilities":
      var nativeGlass = false
      if #available(iOS 26.0, *) { nativeGlass = true }
      result([
        "nativeGlass": nativeGlass,
        "reduceTransparency": UIAccessibility.isReduceTransparencyEnabled,
        "osMajorVersion": ProcessInfo.processInfo.operatingSystemVersion.majorVersion,
      ])
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

final class NativeTabBarViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    NativeTabBarPlatformView(
      frame: frame,
      viewId: viewId,
      args: args as? [String: Any] ?? [:],
      messenger: messenger)
  }
}

/// A complete system UITabBar. On iOS 26+ UIKit supplies the Liquid Glass
/// surface, selection lens, touch response, and morphing transition.
final class NativeTabBarPlatformView: NSObject, FlutterPlatformView, UITabBarDelegate {
  private let container: UIView
  private let tabBar: UITabBar
  private let channel: FlutterMethodChannel
  private var labels: [String] = []
  private var symbols: [String] = []
  private var selectedSymbols: [String] = []

  init(
    frame: CGRect,
    viewId: Int64,
    args: [String: Any],
    messenger: FlutterBinaryMessenger
  ) {
    container = UIView(frame: frame)
    tabBar = UITabBar(frame: .zero)
    channel = FlutterMethodChannel(
      name: "real_liquid_glass/tab_bar_\(viewId)",
      binaryMessenger: messenger)
    super.init()

    container.backgroundColor = .clear
    tabBar.translatesAutoresizingMaskIntoConstraints = false
    tabBar.delegate = self
    container.addSubview(tabBar)
    NSLayoutConstraint.activate([
      tabBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      tabBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      tabBar.topAnchor.constraint(equalTo: container.topAnchor),
      tabBar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])

    apply(args)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(FlutterMethodNotImplemented) }
      switch call.method {
      case "update":
        self.apply(call.arguments as? [String: Any] ?? [:])
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func view() -> UIView { container }

  private func apply(_ args: [String: Any]) {
    let nextLabels = args["labels"] as? [String] ?? labels
    let nextSymbols = args["symbols"] as? [String] ?? symbols
    let nextSelectedSymbols = args["selectedSymbols"] as? [String] ?? selectedSymbols
    let itemsChanged = nextLabels != labels || nextSymbols != symbols
      || nextSelectedSymbols != selectedSymbols
    labels = nextLabels
    symbols = nextSymbols
    selectedSymbols = nextSelectedSymbols

    if itemsChanged || tabBar.items == nil {
      tabBar.items = labels.indices.map { index in
        let image = UIImage(systemName: symbol(at: index, in: symbols))
        let selectedImage = UIImage(
          systemName: symbol(at: index, in: selectedSymbols, fallback: symbols))
        return UITabBarItem(
          title: labels[index], image: image, selectedImage: selectedImage)
      }
    }

    if let tint = args["tint"] as? NSNumber {
      tabBar.tintColor = GlassHostView.color(argb: tint.int64Value)
    }
    if let dark = args["dark"] as? Bool, #available(iOS 13.0, *) {
      container.overrideUserInterfaceStyle = dark ? .dark : .light
    }
    let index = (args["currentIndex"] as? NSNumber)?.intValue ?? 0
    if let items = tabBar.items, items.indices.contains(index), tabBar.selectedItem !== items[index] {
      tabBar.selectedItem = items[index]
    }
  }

  private func symbol(
    at index: Int,
    in names: [String],
    fallback: [String] = []
  ) -> String {
    if names.indices.contains(index), !names[index].isEmpty { return names[index] }
    if fallback.indices.contains(index), !fallback[index].isEmpty { return fallback[index] }
    return "circle"
  }

  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    guard let items = tabBar.items, let index = items.firstIndex(of: item) else { return }
    channel.invokeMethod("selected", arguments: ["index": index])
  }
}

final class GlassViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    GlassPlatformView(
      frame: frame,
      viewId: viewId,
      args: args as? [String: Any],
      messenger: messenger)
  }
}

/// Hosts a UIVisualEffectView carrying UIGlassEffect (iOS 26+) or a
/// UIBlurEffect material fallback on older systems. The effect samples
/// whatever renders beneath it in the native hierarchy — including the
/// Flutter view — so glass over Flutter content behaves exactly like
/// glass in a native app, and inherits system appearance settings
/// (iOS 27 transparency slider, Reduce Transparency, Increase Contrast).
final class GlassPlatformView: NSObject, FlutterPlatformView {
  private let container: GlassHostView
  private let channel: FlutterMethodChannel

  init(
    frame: CGRect,
    viewId: Int64,
    args: [String: Any]?,
    messenger: FlutterBinaryMessenger
  ) {
    container = GlassHostView(frame: frame, args: args ?? [:])
    channel = FlutterMethodChannel(
      name: "real_liquid_glass/glass_view_\(viewId)",
      binaryMessenger: messenger)
    super.init()
    container.onTap = { [weak channel] in
      channel?.invokeMethod("tap", arguments: nil)
    }
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(FlutterMethodNotImplemented) }
      switch call.method {
      case "update":
        self.container.apply(args: call.arguments as? [String: Any] ?? [:])
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func view() -> UIView { container }
}

final class GlassHostView: UIView {
  private let effectView = UIVisualEffectView()
  private lazy var tapRecognizer = UITapGestureRecognizer(
    target: self, action: #selector(didTap))
  private var capsule = false
  private var cornerRadius: CGFloat = 0
  var onTap: (() -> Void)?

  init(frame: CGRect, args: [String: Any]) {
    super.init(frame: frame)
    backgroundColor = .clear
    effectView.frame = bounds
    effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addSubview(effectView)
    apply(args: args)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

  func apply(args: [String: Any]) {
    let style = args["style"] as? String ?? "regular"
    let interactive = args["interactive"] as? Bool ?? false
    let tint = (args["tint"] as? NSNumber).map { Self.color(argb: $0.int64Value) }
    if let dark = args["dark"] as? Bool, #available(iOS 13.0, *) {
      overrideUserInterfaceStyle = dark ? .dark : .light
    }
    capsule = args["capsule"] as? Bool ?? false
    cornerRadius = CGFloat((args["cornerRadius"] as? NSNumber)?.doubleValue ?? 0)
    isUserInteractionEnabled = interactive
    effectView.isUserInteractionEnabled = interactive
    if interactive && tapRecognizer.view == nil {
      addGestureRecognizer(tapRecognizer)
    } else if !interactive && tapRecognizer.view != nil {
      removeGestureRecognizer(tapRecognizer)
    }

    if #available(iOS 26.0, *) {
      let glass: UIGlassEffect
      if style == "clear" {
        glass = UIGlassEffect(style: .clear)
      } else {
        glass = UIGlassEffect(style: .regular)
      }
      glass.isInteractive = interactive
      if let tint { glass.tintColor = tint }
      effectView.effect = glass
      effectView.cornerConfiguration =
        capsule
        ? .capsule()
        : .uniformCorners(radius: .fixed(cornerRadius))
    } else {
      effectView.effect = UIBlurEffect(style: .systemMaterial)
      if let tint {
        effectView.contentView.backgroundColor = tint.withAlphaComponent(0.25)
      } else {
        effectView.contentView.backgroundColor = nil
      }
      effectView.clipsToBounds = true
      effectView.layer.cornerCurve = .continuous
      updateLegacyCorners()
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    if #unavailable(iOS 26.0) { updateLegacyCorners() }
  }

  private func updateLegacyCorners() {
    effectView.layer.cornerRadius =
      capsule ? min(bounds.width, bounds.height) / 2 : cornerRadius
  }

  @objc private func didTap() { onTap?() }

  static func color(argb: Int64) -> UIColor {
    UIColor(
      red: CGFloat((argb >> 16) & 0xFF) / 255,
      green: CGFloat((argb >> 8) & 0xFF) / 255,
      blue: CGFloat(argb & 0xFF) / 255,
      alpha: CGFloat((argb >> 24) & 0xFF) / 255)
  }
}

final class GlassGroupViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    GlassGroupPlatformView(frame: frame, viewId: viewId, messenger: messenger)
  }
}

/// One native view hosting many glass shapes so they can merge.
///
/// On iOS 26+ the outer UIVisualEffectView carries UIGlassContainerEffect:
/// child glass shapes within `spacing` points of each other fuse into one
/// continuous form, with the morph animated by the system material. Flutter
/// streams shape geometry every frame via the `setRegions` channel call.
final class GlassGroupPlatformView: NSObject, FlutterPlatformView {
  private struct ShapeMaterial: Equatable {
    let style: String
    let tint: Int64?
  }

  private let container = UIVisualEffectView()
  private let channel: FlutterMethodChannel
  private var shapes: [Int: UIVisualEffectView] = [:]
  private var materials: [Int: ShapeMaterial] = [:]
  private var spacing: CGFloat = -1

  init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger) {
    container.frame = frame
    container.isUserInteractionEnabled = false
    channel = FlutterMethodChannel(
      name: "real_liquid_glass/glass_group_\(viewId)",
      binaryMessenger: messenger)
    super.init()
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
  }

  func view() -> UIView { container }

  private func setRegions(_ args: [String: Any]) {
    let newSpacing = CGFloat((args["spacing"] as? NSNumber)?.doubleValue ?? 24)
    if #available(iOS 26.0, *), newSpacing != spacing {
      spacing = newSpacing
      let effect = UIGlassContainerEffect()
      effect.spacing = newSpacing
      container.effect = effect
    }

    let regions = args["regions"] as? [[String: Any]] ?? []
    var seen = Set<Int>()
    for region in regions {
      guard let id = (region["id"] as? NSNumber)?.intValue else { continue }
      seen.insert(id)
      let shape = shapes[id] ?? makeShape(id: id)
      apply(region: region, id: id, to: shape)
    }
    for (id, shape) in shapes where !seen.contains(id) {
      shape.removeFromSuperview()
      shapes[id] = nil
      materials[id] = nil
    }
  }

  private func makeShape(id: Int) -> UIVisualEffectView {
    let shape = UIVisualEffectView()
    shape.isUserInteractionEnabled = false
    shapes[id] = shape
    container.contentView.addSubview(shape)
    return shape
  }

  private func apply(region: [String: Any], id: Int, to shape: UIVisualEffectView) {
    shape.frame = CGRect(
      x: (region["x"] as? NSNumber)?.doubleValue ?? 0,
      y: (region["y"] as? NSNumber)?.doubleValue ?? 0,
      width: (region["width"] as? NSNumber)?.doubleValue ?? 0,
      height: (region["height"] as? NSNumber)?.doubleValue ?? 0)
    let capsule = region["capsule"] as? Bool ?? false
    let radius = CGFloat((region["cornerRadius"] as? NSNumber)?.doubleValue ?? 0)
    let material = ShapeMaterial(
      style: region["style"] as? String ?? "regular",
      tint: (region["tint"] as? NSNumber)?.int64Value)
    let tint = material.tint.map { GlassHostView.color(argb: $0) }

    if #available(iOS 26.0, *) {
      // Rebuild the effect only when the material changes; frames stream in
      // every animation tick and replacing the effect each time would
      // defeat the system's merge animation.
      if materials[id] != material {
        materials[id] = material
        let glass: UIGlassEffect
        if material.style == "clear" {
          glass = UIGlassEffect(style: .clear)
        } else {
          glass = UIGlassEffect(style: .regular)
        }
        if let tint { glass.tintColor = tint }
        shape.effect = glass
      }
      shape.cornerConfiguration =
        capsule ? .capsule() : .uniformCorners(radius: .fixed(radius))
    } else {
      if materials[id] != material {
        materials[id] = material
        shape.effect = UIBlurEffect(style: .systemMaterial)
        shape.contentView.backgroundColor = tint?.withAlphaComponent(0.25)
      }
      shape.clipsToBounds = true
      shape.layer.cornerCurve = .continuous
      shape.layer.cornerRadius =
        capsule ? min(shape.bounds.width, shape.bounds.height) / 2 : radius
    }
  }
}
