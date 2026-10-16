import XCTest
import Defaults
@testable import Maccy

// swiftlint:disable force_try
@MainActor
class HistoryItemTests: XCTestCase {
  func testSortedPinsPlacesLettersBeforeSymbols() {
    XCTAssertEqual(
      HistoryItem.sortedPins(["/", "c", "[", "b", "-", "\\", "y"]),
      ["b", "c", "y", "-", "/", "[", "\\"]
    )
  }

  func testTitleForString() {
    let title = "foo"
    let item = historyItem(title)
    XCTAssertEqual(item.title, title)
  }

  func testTitleWithWhitespaces() {
    let title = "   foo bar   "
    let item = historyItem(title)
    XCTAssertEqual(item.title, "···foo bar···")
  }

  func testTitleWithNewlines() {
    let title = "\nfoo\nbar\n"
    let item = historyItem(title)
    XCTAssertEqual(item.title, "⏎foo⏎bar⏎")
  }

  func testTitleWithTabs() {
    let title = "\tfoo\tbar\t"
    let item = historyItem(title)
    XCTAssertEqual(item.title, "⇥foo⇥bar⇥")
  }

  // U+FFFC arrives from rich text with inline attachments and hangs CoreText
  // on macOS 26. See https://github.com/p0deje/Maccy/issues/1520.
  func testTitleWithObjectReplacementCharacters() {
    let item = historyItem("\u{FFFC}foo\u{FFFC}bar\u{FFFC}")
    XCTAssertEqual(item.title, "foobar")
  }

  func testTitleWithOnlyObjectReplacementCharacters() {
    let item = historyItem("\u{FFFC}\u{FFFC}")
    XCTAssertEqual(item.title, "")
  }

  func testTitleWithRTF() {
    let rtf = NSAttributedString(string: "foo").rtf(
      from: NSRange(0...2),
      documentAttributes: [:]
    )
    let item = historyItem(rtf, .rtf)
    XCTAssertEqual(item.title, "foo")
  }

  func testTitleWithHTML() {
    let html = "<a href='#'>foo</a>".data(using: .utf8)
    let item = historyItem(html, .html)
    XCTAssertEqual(item.title, "foo")
  }

  func testImage() {
    let image = NSImage(named: "NSBluetoothTemplate")!
    let item = historyItem(image)
    XCTAssertEqual(item.title, "")
  }

  func testFile() {
    let url = URL(fileURLWithPath: "/tmp/foo.bar")
    let item = historyItem(url)
    XCTAssertEqual(item.title, "file:///tmp/foo.bar")
  }

  func testFileWithEscapedChars() {
    let url = URL(fileURLWithPath: "/tmp/产品培训/产品培训.txt")
    let item = historyItem(url)
    XCTAssertEqual(item.title, "file:///tmp/产品培训/产品培训.txt")
  }

  func testTextFromUniversalClipboard() {
    let url = URL(fileURLWithPath: "/tmp/foo.bar")
    let fileURLContent = HistoryItemContent(
      type: NSPasteboard.PasteboardType.fileURL.rawValue,
      value: url.dataRepresentation
    )
    let textContent = HistoryItemContent(
      type: NSPasteboard.PasteboardType.string.rawValue,
      value: url.lastPathComponent.data(using: .utf8)
    )
    let universalClipboardContent = HistoryItemContent(
      type: NSPasteboard.PasteboardType.universalClipboard.rawValue,
      value: "".data(using: .utf8)
    )
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = [fileURLContent, textContent, universalClipboardContent]
    item.title = item.generateTitle()
    XCTAssertEqual(item.title, "foo.bar")
  }

  func testImageFromUniversalClipboard() {
    let url = Bundle(for: type(of: self)).url(forResource: "guy", withExtension: "jpeg")!
    let fileURLContent = HistoryItemContent(
      type: NSPasteboard.PasteboardType.fileURL.rawValue,
      value: url.dataRepresentation
    )
    let universalClipboardContent = HistoryItemContent(
      type: NSPasteboard.PasteboardType.universalClipboard.rawValue,
      value: "".data(using: .utf8)
    )
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = [fileURLContent, universalClipboardContent]
    XCTAssertEqual(item.image!.tiffRepresentation, NSImage(data: try! Data(contentsOf: url))!.tiffRepresentation)
  }

  func testFileFromUniversalClipboard() {
    let url = URL(fileURLWithPath: "/tmp/foo.bar")
    let fileURLContent = HistoryItemContent(
      type: NSPasteboard.PasteboardType.fileURL.rawValue,
      value: url.dataRepresentation
    )
    let universalClipboardContent = HistoryItemContent(
      type: NSPasteboard.PasteboardType.universalClipboard.rawValue,
      value: "".data(using: .utf8)
    )
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = [fileURLContent, universalClipboardContent]
    item.title = item.generateTitle()
    XCTAssertEqual(item.title, "file:///tmp/foo.bar")
  }

  func testItemWithoutData() {
    let item = historyItem(nil)
    XCTAssertEqual(item.title, "")
  }

  func testSeveralItemsCanHaveEmptyPin() {
    let item1 = historyItem("foo")
    item1.pin = ""
    let item2 = historyItem("bar")
    item2.pin = ""
    XCTAssertNoThrow(try Storage.shared.context.save())
    XCTAssertEqual(item1.pin, "")
    XCTAssertEqual(item2.pin, "")
  }

  func testReplacingTextRegeneratesTitle() {
    let item = historyItem("old text")
    item.replaceText(with: "new text".data(using: .utf8)!)
    XCTAssertEqual(item.title, "new text")
    XCTAssertEqual(item.text, "new text")
  }

  func testPNGDataFromTIFFBackedItem() throws {
    let source = NSImage(size: NSSize(width: 7, height: 5), flipped: false) { rect in
      NSColor.red.setFill()
      rect.fill()
      return true
    }
    let item = historyItem(source)
    let png = try XCTUnwrap(item.pngData())
    XCTAssertEqual(Array(png.prefix(4)), [0x89, 0x50, 0x4E, 0x47])
    let rep = try XCTUnwrap(NSBitmapImageRep(data: png))
    XCTAssertEqual(rep.pixelsWide, 7)
    XCTAssertEqual(rep.pixelsHigh, 5)
  }

  func testPNGDataIsNilForTextItem() {
    XCTAssertNil(historyItem("foo").pngData())
  }

  func testSuggestedImageFileNameUsesName() {
    let item = historyItem("foo")
    item.name = "a/b:c"
    XCTAssertEqual(item.suggestedImageFileName(), "abc.png")
  }

  func testSuggestedImageFileNameFallsBackToTimestamp() {
    let item = historyItem("foo")
    var components = DateComponents()
    components.year = 2026
    components.month = 10
    components.day = 16
    components.hour = 9
    components.minute = 5
    components.second = 3
    let date = Calendar.current.date(from: components)!
    XCTAssertEqual(item.suggestedImageFileName(now: date), "Sorap 2026-10-16 09.05.03.png")
  }

  func testFilePathsTextSingleFile() {
    let item = fileItem(["file:///tmp/a.pdf"])
    XCTAssertEqual(item.filePathsText, "/tmp/a.pdf")
  }

  func testFilePathsTextJoinsSeveralFilesWithNewline() {
    let item = fileItem(["file:///tmp/a.pdf", "file:///tmp/My%20Docs/b.txt"])
    XCTAssertEqual(item.filePathsText, "/tmp/a.pdf\n/tmp/My Docs/b.txt")
  }

  func testFilePathsTextIsNilWithoutFiles() {
    XCTAssertNil(historyItem("just text").filePathsText)
  }

  private func fileItem(_ urls: [String]) -> HistoryItem {
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = urls.map {
      HistoryItemContent(type: NSPasteboard.PasteboardType.fileURL.rawValue, value: $0.data(using: .utf8))
    }
    return item
  }

  private func historyItem(_ value: String?) -> HistoryItem {
    let contents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.string.rawValue,
        value: value?.data(using: .utf8)
      )
    ]
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = contents
    item.title = item.generateTitle()

    return item
  }

  private func historyItem(_ data: Data?, _ type: NSPasteboard.PasteboardType) -> HistoryItem {
    let contents = [
      HistoryItemContent(
        type: type.rawValue,
        value: data
      )
    ]
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = contents
    item.title = item.generateTitle()

    return item
  }

  private func historyItem(_ value: NSImage) -> HistoryItem {
    let contents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.tiff.rawValue,
        value: value.tiffRepresentation!
      )
    ]
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = contents
    item.title = item.generateTitle()

    return item
  }

  private func historyItem(_ value: URL) -> HistoryItem {
    let contents = [
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.fileURL.rawValue,
        value: value.dataRepresentation
      ),
      HistoryItemContent(
        type: NSPasteboard.PasteboardType.string.rawValue,
        value: value.lastPathComponent.data(using: .utf8)
      )
    ]
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = contents
    item.title = item.generateTitle()

    return item
  }
}
// swiftlint:enable force_try
