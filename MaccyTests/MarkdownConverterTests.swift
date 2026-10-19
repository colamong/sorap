import XCTest
@testable import Maccy

@MainActor
final class MarkdownConverterTests: XCTestCase {
  func testPlainParagraphsAreSeparatedByBlankLine() {
    XCTAssertEqual(markdown("<p>one</p><p>two</p>"), "one\n\ntwo")
  }

  func testBoldItalicAndCode() {
    XCTAssertEqual(
      markdown("<p>a <b>bold</b> and <i>italic</i> and <code>x = 1</code></p>"),
      "a **bold** and *italic* and `x = 1`"
    )
  }

  func testLink() {
    XCTAssertEqual(
      markdown(#"<p>see <a href="https://example.com/a">the docs</a></p>"#),
      "see [the docs](https://example.com/a)"
    )
  }

  func testBulletList() {
    XCTAssertEqual(markdown("<ul><li>one</li><li>two</li></ul>"), "- one\n- two")
  }

  func testOrderedList() {
    XCTAssertEqual(markdown("<ol><li>one</li><li>two</li></ol>"), "1. one\n2. two")
  }

  func testWhitespaceStaysOutsideEmphasis() {
    XCTAssertEqual(markdown("<p>a<b> bold </b>b</p>"), "a **bold** b")
  }

  private func markdown(_ html: String) -> String {
    let text = NSAttributedString(html: Data("<meta charset=\"utf-8\">\(html)".utf8), documentAttributes: nil)!
    return MarkdownConverter.markdown(from: text)
  }
}
