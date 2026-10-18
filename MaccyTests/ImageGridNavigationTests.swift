import XCTest
@testable import Maccy

@MainActor
final class ImageGridNavigationTests: XCTestCase {
  let history = History.shared
  let navigator = AppState.shared.navigator

  override func setUp() {
    super.setUp()
    MainActor.assumeIsolated {
      History.shared.clearAll()
      History.shared.scope = .history
      History.shared.searchQuery = ""
      History.shared.kindFilter = nil
    }
  }

  override func tearDown() {
    MainActor.assumeIsolated {
      History.shared.kindFilter = nil
    }
    super.tearDown()
  }

  func testDownMovesToNextImage() {
    (0..<4).forEach { history.add(imageItem($0)) }
    history.kindFilter = .image
    let cells = history.unpinnedItems
    XCTAssertEqual(cells.count, 4)
    navigator.highlightFirst()
    XCTAssertEqual(navigator.leadSelection, cells[0].id)
    navigator.highlightNext()
    XCTAssertEqual(navigator.leadSelection, cells[1].id)
  }

  func testDownMovesOneRow() {
    let cells = sevenCells()
    navigator.highlightFirst()
    navigator.highlightRow(offset: ImageGridView.columnCount)
    XCTAssertEqual(navigator.leadSelection, cells[3].id)
  }

  func testUpMovesOneRow() {
    let cells = sevenCells()
    navigator.select(item: cells[4])
    navigator.highlightRow(offset: -ImageGridView.columnCount)
    XCTAssertEqual(navigator.leadSelection, cells[1].id)
  }

  func testDownIntoShorterLastRowPicksLastCell() {
    let cells = sevenCells()
    navigator.select(item: cells[4])
    navigator.highlightRow(offset: ImageGridView.columnCount)
    XCTAssertEqual(navigator.leadSelection, cells[6].id)
  }

  func testDownFromLastFullRowStays() {
    (0..<6).forEach { history.add(imageItem($0)) }
    history.kindFilter = .image
    let cells = history.unpinnedItems
    navigator.select(item: cells[4])
    navigator.highlightRow(offset: ImageGridView.columnCount)
    XCTAssertEqual(navigator.leadSelection, cells[4].id)
  }

  func testUpFromFirstRowStays() {
    let cells = sevenCells()
    navigator.select(item: cells[1])
    navigator.highlightRow(offset: -ImageGridView.columnCount)
    XCTAssertEqual(navigator.leadSelection, cells[1].id)
  }

  /// Rows of 3: [0 1 2] [3 4 5] [6].
  private func sevenCells() -> [HistoryItemDecorator] {
    (0..<7).forEach { history.add(imageItem($0)) }
    history.kindFilter = .image
    let cells = history.unpinnedItems
    XCTAssertEqual(cells.count, 7)
    return cells
  }

  private func imageItem(_ seed: Int) -> HistoryItem {
    let image = NSImage(size: NSSize(width: 4 + seed, height: 4))
    image.lockFocus()
    NSColor(calibratedWhite: CGFloat(seed) / 10, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: 4 + seed, height: 4).fill()
    image.unlockFocus()
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = [
      HistoryItemContent(type: NSPasteboard.PasteboardType.tiff.rawValue, value: image.tiffRepresentation)
    ]
    item.numberOfCopies = 1
    return item
  }
}
