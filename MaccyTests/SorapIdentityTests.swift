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

  func testWaitForOtherInstancesReturnsAtOnceWhenAlone() async {
    // No process runs under this identifier, so there is nothing to wait for.
    let alone = await AppDelegate.waitForOtherInstances(
      bundleIdentifier: "io.github.colamong.sorap.no-such-instance", timeout: .seconds(5)
    )
    XCTAssertTrue(alone)
  }

  func testWaitForOtherInstancesTimesOutWhileAnotherInstanceRuns() async {
    // Excluding a pid that is not ours makes this process look like "the other instance".
    let alone = await AppDelegate.waitForOtherInstances(
      processIdentifier: 0, timeout: .milliseconds(300), pollInterval: .milliseconds(50)
    )
    XCTAssertFalse(alone)
  }
}
