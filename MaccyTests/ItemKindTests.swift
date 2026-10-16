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

  func testNonImageFileIsFile() {
    let pdf = URL(fileURLWithPath: "/tmp/a.pdf")
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: "/tmp/a.pdf", fileURLs: [pdf]), .file)
  }

  func testMixedImageAndNonImageFilesAreFile() {
    let urls = [URL(fileURLWithPath: "/tmp/a.png"), URL(fileURLWithPath: "/tmp/a.pdf")]
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: nil, fileURLs: urls), .file)
  }

  func testAbsolutePathTextIsFile() {
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: "/Users/me/a.txt", fileURLs: []), .file)
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: "  /Users/me/My Docs/a.txt\n", fileURLs: []), .file)
  }

  func testHomePathTextIsFile() {
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: "~/Desktop/x", fileURLs: []), .file)
  }

  func testFileSchemeTextIsFile() {
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: "file:///tmp/a", fileURLs: []), .file)
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: "File:///tmp/a", fileURLs: []), .file)
  }

  func testMultilineFileSchemeTextIsNotFile() {
    XCTAssertNotEqual(ItemKind.classify(hasImage: false, text: "file://x is a scheme\nmore text", fileURLs: []), .file)
  }

  func testMultiSegmentPathsAreFile() {
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: "/tmp/a", fileURLs: []), .file)
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: "/Users/me/My Folder/a.txt", fileURLs: []), .file)
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: "~/x", fileURLs: []), .file)
  }

  func testSlashCommandsAndBareSlashesAreText() {
    for text in ["/", "//", "/compact", "/help me", "//x/y"] {
      XCTAssertEqual(ItemKind.classify(hasImage: false, text: text, fileURLs: []), .text, text)
    }
  }

  func testPathInsideSentenceIsText() {
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: "see /tmp/a now", fileURLs: []), .text)
  }

  func testMultiLineTextWithPathIsText() {
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: "/tmp/a\n/tmp/b", fileURLs: []), .text)
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: "cd:\n/tmp/a", fileURLs: []), .text)
  }

  func testOverlongPathTextIsText() {
    let long = "/" + String(repeating: "a", count: 1024)
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: long, fileURLs: []), .text)
  }

  func testFiltersOrder() {
    XCTAssertEqual(ItemKind.filters, [.text, .link, .file, .image])
  }

  func testEmptyIsOther() {
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: "   ", fileURLs: []), .other)
    XCTAssertEqual(ItemKind.classify(hasImage: false, text: nil, fileURLs: []), .other)
  }
}
