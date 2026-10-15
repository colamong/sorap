import XCTest
import Defaults
import SwiftData
@testable import Maccy

@MainActor
final class HistoryBoardTests: XCTestCase {
  let history = History.shared
  let boards = BoardStore.shared
  let savedSize = Defaults[.size]

  override func setUp() {
    super.setUp()
    MainActor.assumeIsolated {
      History.shared.clearAll()
      try? Storage.shared.context.delete(model: Board.self)
      try? Storage.shared.context.save()
      BoardStore.shared.load()
    }
    Defaults[.size] = 3
  }

  override func tearDown() {
    super.tearDown()
    Defaults[.size] = savedSize
  }

  func testToggleFavoriteMovesIntoFavoritesAndBack() {
    let item = history.add(historyItem("foo"))
    history.toggleFavorite(item)
    XCTAssertEqual(item.item.board, boards.favorites)
    XCTAssertTrue(history.boardItems.contains(item))
    XCTAssertFalse(history.unpinnedItems.contains(item))

    history.toggleFavorite(item)
    XCTAssertNil(item.item.board)
    XCTAssertTrue(history.unpinnedItems.contains(item))
  }

  func testBoardItemsSurviveSizeLimit() {
    let kept = history.add(historyItem("keep"))
    history.toggleFavorite(kept)
    for value in ["a", "b", "c", "d", "e"] {
      history.add(historyItem(value))
    }
    XCTAssertTrue(history.boardItems.contains(kept))
    XCTAssertEqual(history.unpinnedItems.count, 3)
  }

  func testDuplicateCopyKeepsBoardAndName() {
    let first = history.add(historyItem("foo"))
    history.toggleFavorite(first)
    history.rename(first, to: "Greeting")

    let merged = history.add(historyItem("foo"))
    XCTAssertEqual(merged.item.board, boards.favorites)
    XCTAssertEqual(merged.item.name, "Greeting")
    XCTAssertEqual(history.boardItems, [merged])
  }

  func testRenameShowsNameAsTitle() {
    let item = history.add(historyItem("foo"))
    history.rename(item, to: "  Greeting ")
    XCTAssertEqual(item.item.name, "Greeting")
    XCTAssertEqual(item.title, "Greeting")
  }

  func testRenameWithWhitespaceClearsName() {
    let item = history.add(historyItem("foo"))
    history.rename(item, to: "Greeting")
    history.rename(item, to: "   ")
    XCTAssertNil(item.item.name)
    XCTAssertEqual(item.title, "foo")
  }

  func testClearKeepsBoardItems() {
    let kept = history.add(historyItem("keep"))
    history.toggleFavorite(kept)
    history.add(historyItem("drop"))
    history.clear()
    XCTAssertEqual(history.boardItems, [kept])
    XCTAssertTrue(history.unpinnedItems.isEmpty)
  }

  func testDeleteBoardReturnsItemsToHistory() throws {
    let board = try boards.create(name: "SQL", symbol: "cylinder")
    let item = history.add(historyItem("select 1"))
    history.move(item, to: board)
    try history.deleteBoard(board)
    XCTAssertNil(item.item.board)
    XCTAssertTrue(history.unpinnedItems.contains(item))
    XCTAssertFalse(boards.boards.contains(board))
  }

  func testDeleteFavoritesThrows() {
    XCTAssertThrowsError(try history.deleteBoard(boards.favorites))
  }

  func testRemovingBoardDirectlyKeepsItemsWithNilBoard() throws {
    let board = try boards.create(name: "Temp", symbol: "folder")
    let item = history.add(historyItem("kept"))
    history.move(item, to: board)
    try boards.remove(board)
    try Storage.shared.context.save()
    let all = try Storage.shared.context.fetch(FetchDescriptor<HistoryItem>())
    XCTAssertTrue(all.contains(item.item))
    XCTAssertNil(item.item.board)
  }

  func testCreateSnippetLandsInBoard() throws {
    let board = try boards.create(name: "Phrases", symbol: "text.quote")
    let snippet = history.createSnippet(in: board, text: "Thanks!")
    XCTAssertEqual(snippet.item.board, board)
    XCTAssertEqual(snippet.item.text, "Thanks!")
    XCTAssertTrue(history.boardItems.contains(snippet))
  }

  func testReloadKeepsBoardItemsSeparate() async throws {
    let kept = history.add(historyItem("keep"))
    history.toggleFavorite(kept)
    history.add(historyItem("other"))
    try await history.load()
    XCTAssertEqual(history.boardItems.map(\.item), [kept.item])
    XCTAssertEqual(history.unpinnedItems.map(\.item.title), ["other"])
  }

  private func historyItem(_ value: String) -> HistoryItem {
    let item = HistoryItem()
    Storage.shared.context.insert(item)
    item.contents = [
      HistoryItemContent(type: NSPasteboard.PasteboardType.string.rawValue, value: value.data(using: .utf8))
    ]
    item.numberOfCopies = 1
    item.title = item.generateTitle()
    return item
  }
}
