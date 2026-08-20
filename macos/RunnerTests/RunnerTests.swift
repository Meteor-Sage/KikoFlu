import Cocoa
import FlutterMacOS
import XCTest
@testable import real_liquid_glass

class RunnerTests: XCTestCase {

  func testLiquidGlassHostClipsRoundedRectangleBoundary() {
    let host = GlassHostView(args: [
      "capsule": false,
      "cornerRadius": 24,
    ])
    host.frame = NSRect(x: 0, y: 0, width: 200, height: 80)
    host.layoutSubtreeIfNeeded()

    XCTAssertEqual(host.layer?.cornerRadius, 24)
    XCTAssertEqual(host.layer?.masksToBounds, true)
  }

  func testLiquidGlassHostClipsCapsuleBoundary() {
    let host = GlassHostView(args: [
      "capsule": true,
      "cornerRadius": 0,
    ])
    host.frame = NSRect(x: 0, y: 0, width: 200, height: 80)
    host.layoutSubtreeIfNeeded()

    XCTAssertEqual(host.layer?.cornerRadius, 40)
    XCTAssertEqual(host.layer?.masksToBounds, true)
  }

}
