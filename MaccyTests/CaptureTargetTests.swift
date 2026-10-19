import XCTest
@testable import Maccy

@MainActor
final class CaptureTargetTests: XCTestCase {
  private let noFiles: (String) -> Bool = { _ in false }
  private let allFiles: (String) -> Bool = { _ in true }

  func testBlankTextIsNothing() {
    XCTAssertNil(CaptureTarget.detect(in: "  \n ", fileExists: noFiles))
  }

  func testPlainTextIsText() {
    XCTAssertEqual(CaptureTarget.detect(in: " hello\n", fileExists: noFiles), .text("hello"))
  }

  func testURLIsLink() {
    XCTAssertEqual(
      CaptureTarget.detect(in: "https://example.com/a?b=1", fileExists: noFiles),
      .link(URL(string: "https://example.com/a?b=1")!)
    )
  }

  func testLinkInsideSentenceIsLink() {
    XCTAssertEqual(
      CaptureTarget.detect(in: "주소는 www.naver.com 입니다", fileExists: noFiles),
      .link(URL(string: "http://www.naver.com")!)
    )
  }

  func testEmailIsNotLink() {
    XCTAssertEqual(CaptureTarget.detect(in: "me@example.com", fileExists: noFiles), .text("me@example.com"))
  }

  func testExistingPathIsPath() {
    XCTAssertEqual(
      CaptureTarget.detect(in: "/Users/me/doc.txt", fileExists: allFiles),
      .path(URL(fileURLWithPath: "/Users/me/doc.txt"))
    )
  }

  func testMissingPathIsText() {
    XCTAssertEqual(CaptureTarget.detect(in: "/Users/me/doc.txt", fileExists: noFiles), .text("/Users/me/doc.txt"))
  }

  func testTildePathExpands() {
    XCTAssertEqual(
      CaptureTarget.detect(in: "~/Downloads", fileExists: allFiles),
      .path(URL(fileURLWithPath: NSHomeDirectory() + "/Downloads"))
    )
  }

  func testPathOnAnyLineIsPath() {
    XCTAssertEqual(
      CaptureTarget.detect(in: "$ ls\n  /Users/me/a b.txt  ", fileExists: allFiles),
      .path(URL(fileURLWithPath: "/Users/me/a b.txt"))
    )
  }

  func testExistingPathWinsOverLinkInsideIt() {
    XCTAssertEqual(
      CaptureTarget.detect(in: "/Users/me/site.com/index.html", fileExists: allFiles),
      .path(URL(fileURLWithPath: "/Users/me/site.com/index.html"))
    )
  }

  func testPathAfterLabelIsPath() {
    let text = "설정 파일: /Users/me/LICENSE\n참고 링크: https://example.com/docs"
    XCTAssertEqual(
      CaptureTarget.detect(in: text, fileExists: { $0 == "/Users/me/LICENSE" }),
      .path(URL(fileURLWithPath: "/Users/me/LICENSE"))
    )
  }

  func testDomainInsideWrappedPathIsNotLink() {
    let text = "/private/tmp/abc-\ndef/site/site.com/index.html"
    XCTAssertEqual(CaptureTarget.detect(in: text, fileExists: noFiles), .text(text))
  }

  func testWebLinksListsEveryLinkOnceInOrder() {
    let text = "문서 https://github.com/colamong 그리고 https://example.org/second\n다시 https://github.com/colamong"
    XCTAssertEqual(
      CaptureTarget.webLinks(in: text),
      [URL(string: "https://github.com/colamong")!, URL(string: "https://example.org/second")!]
    )
  }

  func testWebLinksSkipEmailAndPathSegments() {
    XCTAssertEqual(CaptureTarget.webLinks(in: "me@example.com /Users/me/site.com/a"), [])
  }

  func testValueIsWhatGetsCopied() {
    XCTAssertEqual(CaptureTarget.link(URL(string: "https://a.com")!).value, "https://a.com")
    XCTAssertEqual(CaptureTarget.path(URL(fileURLWithPath: "/tmp/a")).value, "/tmp/a")
    XCTAssertEqual(CaptureTarget.text("hi").value, "hi")
  }
}
