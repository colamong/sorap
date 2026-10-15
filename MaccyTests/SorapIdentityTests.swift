import XCTest
@testable import Maccy

final class SorapIdentityTests: XCTestCase {
  func testPasteboardMarkerIsSorap() {
    XCTAssertEqual(NSPasteboard.PasteboardType.fromMaccy.rawValue, "io.github.colamong.sorap")
  }

  @MainActor
  func testStoreLivesInSorapFolder() {
    XCTAssertEqual(Storage.storeURL.deletingLastPathComponent().lastPathComponent, "Sorap")
  }

  func testBundleIdentifierIsSorap() {
    XCTAssertEqual(Bundle(for: History.self).bundleIdentifier, "io.github.colamong.sorap")
  }
}
