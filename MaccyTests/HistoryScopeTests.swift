import XCTest
import SwiftData
@testable import Maccy

@MainActor
final class HistoryScopeTests: XCTestCase {
  let history = History.shared
  let boards = BoardStore.shared

  override func setUp() {
    super.setUp()
    MainActor.assumeIsolated {
      History.shared.clearAll()
      History.shared.scope = .history
      History.shared.kindFilter = nil
      History.shared.searchQuery = ""
      try? Storage.shared.context.delete(model: Board.self)
      try? Storage.shared.context.save()
      BoardStore.shared.load()
    }
  }

  override func tearDown() {
    MainActor.assumeIsolated {
      History.shared.scope = .history
      History.shared.kindFilter = nil
      History.shared.searchQuery = ""
    }
    super.tearDown()
  }

  func testHistoryScopeShowsOnlyNonBoardItems() {
    let loose = history.add(historyItem("loose"))
    let fav = history.add(historyItem("fav"))
    history.toggleFavorite(fav)
    XCTAssertEqual(history.items.toArray(), [loose])
  }

  func testBoardScopeShowsOnlyThatBoard() throws {
    let sql = boards.create(name: "SQL", symbol: "cylinder")
    let query = history.add(historyItem("select 1"))
    let fav = history.add(historyItem("fav"))
    history.move(query, to: sql)
    history.toggleFavorite(fav)

    history.scope = .board(sql)
    XCTAssertEqual(history.items.toArray(), [query])
    history.scope = .board(boards.favorites)
    XCTAssertEqual(history.items.toArray(), [fav])
  }

  func testKindFilterInHistoryScope() {
    let link = history.add(historyItem("https://github.com"))
    history.add(historyItem("plain words"))
    history.kindFilter = .link
    XCTAssertEqual(history.items.toArray(), [link])
  }

  // searchQuery 는 0.2초 throttle 뒤에 결과를 갱신하므로 기다린다.
  func testSearchAndKindFilterCombineInBoard() async throws {
    let board = boards.create(name: "Mixed", symbol: "folder")
    let target = history.add(historyItem("https://apple.com"))
    let otherLink = history.add(historyItem("https://github.com"))
    let text = history.add(historyItem("apple pie"))
    [target, otherLink, text].forEach { history.move($0, to: board) }

    history.scope = .board(board)
    history.kindFilter = .link
    history.searchQuery = "apple"
    try await Task.sleep(for: .milliseconds(500))
    XCTAssertEqual(history.items.toArray(), [target])
  }

  func testSearchMatchesName() async throws {
    let item = history.add(historyItem("zzz"))
    history.rename(item, to: "Signature")
    history.add(historyItem("other"))
    history.searchQuery = "Signa"
    try await Task.sleep(for: .milliseconds(500))
    XCTAssertEqual(history.items.toArray().map(\.item), [item.item])
  }

  func testSearchMatchesContentOfRenamedItem() async throws {
    let item = history.add(historyItem("SELECT * FROM users"))
    history.rename(item, to: "유저 쿼리")
    history.add(historyItem("other"))
    history.searchQuery = "users"
    try await Task.sleep(for: .milliseconds(500))
    XCTAssertEqual(history.items.toArray().map(\.item), [item.item])
  }

  func testHistoryItemsIgnoresScopeAndFilter() throws {
    let board = boards.create(name: "Intent", symbol: "folder")
    let plain = history.add(historyItem("plain words"))
    let inBoard = history.add(historyItem("in board"))
    history.move(inBoard, to: board)

    history.scope = .board(board)
    history.kindFilter = .link
    XCTAssertEqual(history.historyItems, [plain])
  }

  func testDeletingSelectedBoardFallsBackToHistory() throws {
    let board = boards.create(name: "Temp", symbol: "folder")
    let item = history.add(historyItem("x"))
    history.move(item, to: board)
    history.scope = .board(board)
    try history.deleteBoard(board)
    XCTAssertEqual(history.scope, .history)
    XCTAssertEqual(history.items.toArray(), [item])
  }

  func testSelectNextBoardFromHistoryGoesToFavorites() {
    history.selectNextBoard()
    XCTAssertEqual(history.scope, .board(boards.favorites))
  }

  func testSelectPreviousBoardFromHistoryWrapsToLastBoard() throws {
    let last = boards.create(name: "Last", symbol: "folder")
    history.selectPreviousBoard()
    XCTAssertEqual(history.scope, .board(last))
  }

  func testSelectNextBoardFromLastBoardWrapsToHistory() throws {
    let last = boards.create(name: "Last", symbol: "folder")
    history.scope = .board(last)
    history.selectNextBoard()
    XCTAssertEqual(history.scope, .history)
  }

  func testCycleKindFilterForward() {
    var seen: [ItemKind?] = []
    for _ in 0..<5 {
      history.cycleKindFilter(forward: true)
      seen.append(history.kindFilter)
    }
    XCTAssertEqual(seen, [.text, .link, .file, .image, nil])
  }

  func testCycleKindFilterBackwardFromAllGoesToImage() {
    history.cycleKindFilter(forward: false)
    XCTAssertEqual(history.kindFilter, .image)
    history.cycleKindFilter(forward: false)
    XCTAssertEqual(history.kindFilter, .file)
  }

  func testIntentItemIndexBounds() {
    XCTAssertNil(History.index(forNumber: 0, count: 3))
    XCTAssertNil(History.index(forNumber: -1, count: 3))
    XCTAssertEqual(History.index(forNumber: 1, count: 3), 0)
    XCTAssertEqual(History.index(forNumber: 3, count: 3), 2)
    XCTAssertNil(History.index(forNumber: 4, count: 3))
    XCTAssertNil(History.index(forNumber: 1, count: 0))
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
