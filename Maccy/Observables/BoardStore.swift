import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class BoardStore {
  static let shared = BoardStore()

  static let symbolChoices = [
    "star", "folder", "text.quote", "cylinder", "chevron.left.forwardslash.chevron.right",
    "link", "photo", "envelope", "person", "briefcase", "tag", "bookmark"
  ]

  private(set) var boards: [Board] = []

  var favorites: Board {
    if let board = boards.first(where: \.isFavorites) { return board }
    load()
    return boards.first(where: \.isFavorites)!
  }

  private var context: ModelContext { Storage.shared.context }

  func load() {
    let descriptor = FetchDescriptor<Board>(sortBy: [SortDescriptor(\.order)])
    boards = (try? context.fetch(descriptor)) ?? []
    if !boards.contains(where: \.isFavorites) {
      let favorites = Board(
        name: String(localized: "board.favorites", table: "Sorap"),
        symbol: "star",
        order: 0,
        isFavorites: true
      )
      context.insert(favorites)
      boards.insert(favorites, at: 0)
      renumber()
    }
  }

  @discardableResult
  func create(name: String, symbol: String) throws -> Board {
    let trimmed = try validated(name)
    let board = Board(name: trimmed, symbol: symbol, order: boards.count)
    context.insert(board)
    boards.append(board)
    save()
    return board
  }

  func rename(_ board: Board, to name: String) throws {
    board.name = try validated(name)
    save()
  }

  func setSymbol(_ board: Board, to symbol: String) {
    board.symbol = symbol
    save()
  }

  func move(fromOffsets source: IndexSet, toOffset destination: Int) {
    boards.move(fromOffsets: source, toOffset: destination)
    renumber()
  }

  func remove(_ board: Board) throws {
    guard !board.isFavorites else { throw BoardError.cannotDeleteFavorites }
    boards.removeAll { $0 == board }
    context.delete(board)
    renumber()
  }

  private func validated(_ name: String) throws -> String {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { throw BoardError.emptyName }
    return trimmed
  }

  private func renumber() {
    for (index, board) in boards.enumerated() {
      board.order = index
    }
    save()
  }

  private func save() {
    context.processPendingChanges()
    try? context.save()
  }
}
