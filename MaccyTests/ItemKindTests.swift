import XCTest
@testable import Maccy

@MainActor
final class ItemKindTests: XCTestCase {
  func testImageWins() {
    XCTAssertEqual(ItemKind.classify(hasImage: true, text: "https://a.com", fileURLs: []), .image)
  }

  func testSingleURLIsLink() {
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: "https://github.com/p0deje/Maccy", fileURLs: []), .link)
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: "  https://a.com/x?y=1\n", fileURLs: []), .link)
  }

  func testURLInsideSentenceIsText() {
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: "see https://a.com now", fileURLs: []), .text)
  }

  func testPlainTextAndSQLAreText() {
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: "hello", fileURLs: []), .text)
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: "SELECT 1 FROM dual", fileURLs: []), .text)
  }

  func testImageFileIsImage() {
    let png = URL(fileURLWithPath: "/tmp/a.png")
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: nil, fileURLs: [png]), .image)
  }

  func testOtherFileIsOther() {
    let pdf = URL(fileURLWithPath: "/tmp/a.pdf")
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: "/tmp/a.pdf", fileURLs: [pdf]), .other)
  }

  func testEmptyIsOther() {
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: "   ", fileURLs: []), .other)
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: nil, fileURLs: []), .other)
  }
}
