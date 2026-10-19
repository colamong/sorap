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

  func testEmailIsEmail() {
    XCTAssertEqual(CaptureTarget.detect(in: "문의: me@example.com", fileExists: noFiles), .email("me@example.com"))
  }

  func testLinkWinsOverEmail() {
    XCTAssertEqual(
      CaptureTarget.detect(in: "me@example.com https://a.com", fileExists: noFiles),
      .link(URL(string: "https://a.com")!)
    )
  }

  func testKoreanPhoneNumbersArePhones() {
    XCTAssertEqual(CaptureTarget.detect(in: "문의: 010-1234-5678", fileExists: noFiles), .phone("010-1234-5678"))
    XCTAssertEqual(CaptureTarget.detect(in: "02-123-4567 로 전화", fileExists: noFiles), .phone("02-123-4567"))
    XCTAssertEqual(CaptureTarget.detect(in: "+82 10 1234 5678", fileExists: noFiles), .phone("+82 10 1234 5678"))
  }

  func testOrderNumberIsNotPhone() {
    XCTAssertEqual(
      CaptureTarget.detect(in: "주문번호 2026-1019-0001", fileExists: noFiles),
      .text("주문번호 2026-1019-0001")
    )
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
    XCTAssertEqual(CaptureTarget.email("me@a.com").value, "me@a.com")
    XCTAssertEqual(CaptureTarget.phone("010-1234-5678").value, "010-1234-5678")
  }
}
