import XCTest
@testable import Maccy

@MainActor
final class AppLanguageTests: XCTestCase {
  private var suiteName = ""
  private var defaults: UserDefaults!

  override func setUp() {
    suiteName = "AppLanguageTests-\(UUID().uuidString)"
    defaults = UserDefaults(suiteName: suiteName)
  }

  override func tearDown() {
    defaults.removePersistentDomain(forName: suiteName)
  }

  func testApplyWritesSingleLanguageCode() {
    AppLanguage.ja.apply(defaults: defaults)
    XCTAssertEqual(defaults.array(forKey: "AppleLanguages") as? [String], ["ja"])
  }

  func testApplyKeepsScriptSubtag() {
    AppLanguage.zhHant.apply(defaults: defaults)
    XCTAssertEqual(defaults.array(forKey: "AppleLanguages") as? [String], ["zh-Hant"])
  }

  func testApplySystemRemovesKey() {
    AppLanguage.ko.apply(defaults: defaults)
    AppLanguage.system.apply(defaults: defaults)
    // `object(forKey:)` would fall through to the system's own AppleLanguages, so look at this domain only.
    XCTAssertNil(defaults.persistentDomain(forName: suiteName)?["AppleLanguages"])
  }

  func testCurrentRoundTripsEveryCase() {
    for language in AppLanguage.allCases {
      language.apply(defaults: defaults)
      XCTAssertEqual(AppLanguage.current(defaults: defaults, domain: suiteName), language)
    }
  }

  func testCurrentIgnoresValuesMergedFromOtherDomains() {
    // `array(forKey:)` on a suite also sees the global domain; the app-domain read must not.
    XCTAssertNotNil(defaults.array(forKey: "AppleLanguages"))
    XCTAssertEqual(AppLanguage.current(defaults: defaults, domain: suiteName), .system)
  }

  func testCurrentWithNothingStoredIsSystem() {
    XCTAssertEqual(AppLanguage.current(defaults: defaults, domain: suiteName), .system)
  }

  func testUnknownStoredCodeFallsBackToSystem() {
    defaults.set(["xx"], forKey: "AppleLanguages")
    XCTAssertEqual(AppLanguage.current(defaults: defaults, domain: suiteName), .system)
  }
}
