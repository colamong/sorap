import XCTest
import SwiftData
@testable import Maccy

@MainActor
final class BoardStoreTests: XCTestCase {
  let store = BoardStore.shared

  override func setUp() {
    super.setUp()
    MainActor.assumeIsolated {
      History.shared.clearAll()
      try? Storage.shared.context.delete(model: Board.self)
      try? Storage.shared.context.save()
      BoardStore.shared.load()
    }
  }

  func testLoadCreatesSingleFavoritesBoard() {
    store.load()
    XCTAssertEqual(store.boards.filter(\.isFavorites).count, 1)
    XCTAssertEqual(store.favorites.order, 0)
  }

  func testCreateAppendsInOrder() throws {
    let sql = try store.create(name: "SQL", symbol: "cylinder")
    let phrases = try store.create(name: "Phrases", symbol: "text.quote")
    XCTAssertEqual(store.boards.map(\.name), [store.favorites.name, "SQL", "Phrases"])
    XCTAssertLessThan(sql.order, phrases.order)
  }

  func testCreateRejectsBlankName() {
    XCTAssertThrowsError(try store.create(name: "  ", symbol: "folder")) { error in
      XCTAssertEqual(error as? BoardError, .emptyName)
    }
  }

  func testRenameTrimsAndRejectsBlank() throws {
    let board = try store.create(name: "SQL", symbol: "cylinder")
    try store.rename(board, to: "  Queries ")
    XCTAssertEqual(board.name, "Queries")
    XCTAssertThrowsError(try store.rename(board, to: ""))
  }

  func testFavoritesCannotBeRemoved() {
    XCTAssertThrowsError(try store.remove(store.favorites)) { error in
      XCTAssertEqual(error as? BoardError, .cannotDeleteFavorites)
    }
  }

  func testRemoveDeletesBoard() throws {
    let board = try store.create(name: "SQL", symbol: "cylinder")
    try store.remove(board)
    XCTAssertFalse(store.boards.contains(board))
  }

  func testMoveReordersAndRenumbers() throws {
    _ = try store.create(name: "A", symbol: "folder")
    _ = try store.create(name: "B", symbol: "folder")
    store.move(fromOffsets: IndexSet(integer: 2), toOffset: 1)
    XCTAssertEqual(store.boards.map(\.name).suffix(2), ["B", "A"])
    XCTAssertEqual(store.boards.map(\.order), Array(0..<store.boards.count))
  }

  func testDisplayTitlePrefersName() {
    let item = HistoryItem()
    item.title = "content"
    XCTAssertEqual(item.displayTitle, "content")
    item.name = "My name"
    XCTAssertEqual(item.displayTitle, "My name")
  }
}
