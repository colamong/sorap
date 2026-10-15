import XCTest
import SwiftData
@testable import Maccy

@MainActor
final class BoardStoreTests: XCTestCase {
  let store = BoardStore.shared
  let defaultName = String(localized: "board.defaultName", table: "Sorap")

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
    let sql = store.create(name: "SQL", symbol: "cylinder")
    let phrases = store.create(name: "Phrases", symbol: "text.quote")
    XCTAssertEqual(store.boards.map(\.name), [store.favorites.name, "SQL", "Phrases"])
    XCTAssertLessThan(sql.order, phrases.order)
  }

  func testCreateWithBlankNameUsesDefault() {
    let board = store.create(name: "  ", symbol: "folder")
    XCTAssertEqual(board.name, defaultName)
  }

  func testCreateDefaultNameIsUniquified() {
    let first = store.create(name: "", symbol: "folder")
    let second = store.create(name: " ", symbol: "folder")
    let third = store.create(name: "", symbol: "folder")
    XCTAssertEqual(first.name, defaultName)
    XCTAssertEqual(second.name, "\(defaultName) 2")
    XCTAssertEqual(third.name, "\(defaultName) 3")
  }

  func testRenameTrimsName() {
    let board = store.create(name: "SQL", symbol: "cylinder")
    store.rename(board, to: "  Queries ")
    XCTAssertEqual(board.name, "Queries")
  }

  func testRenameWithBlankKeepsName() {
    let board = store.create(name: "SQL", symbol: "cylinder")
    store.rename(board, to: "  ")
    XCTAssertEqual(board.name, "SQL")
  }

  func testFavoritesCannotBeRemoved() {
    XCTAssertThrowsError(try store.remove(store.favorites)) { error in
      XCTAssertEqual(error as? BoardError, .cannotDeleteFavorites)
    }
  }

  func testRemoveDeletesBoard() throws {
    let board = store.create(name: "SQL", symbol: "cylinder")
    try store.remove(board)
    XCTAssertFalse(store.boards.contains(board))
  }

  func testMoveReordersAndRenumbers() throws {
    _ = store.create(name: "A", symbol: "folder")
    _ = store.create(name: "B", symbol: "folder")
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
