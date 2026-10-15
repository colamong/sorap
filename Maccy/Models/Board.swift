import Foundation
import SwiftData

@Model
final class Board {
  var name: String = ""
  var symbol: String = "folder"
  var order: Int = 0
  var isFavorites: Bool = false

  @Relationship(deleteRule: .nullify, inverse: \HistoryItem.board)
  var items: [HistoryItem] = []

  init(name: String, symbol: String, order: Int, isFavorites: Bool = false) {
    self.name = name
    self.symbol = symbol
    self.order = order
    self.isFavorites = isFavorites
  }
}

enum BoardError: Error, Equatable {
  case emptyName
  case cannotDeleteFavorites
}
