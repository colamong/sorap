import SwiftData
import SwiftUI

struct ItemContextMenu: ViewModifier {
  let item: HistoryItemDecorator
  @Environment(AppState.self) private var appState

  func body(content: Content) -> some View {
    content.contextMenu {
      Button(String(localized: "item.name", table: "Sorap")) {
        appState.requestEdit(item)
      }
      Menu(String(localized: "item.move", table: "Sorap")) {
        Button(String(localized: "board.history", table: "Sorap")) {
          appState.history.move(item, to: nil)
        }
        .disabled(item.item.board == nil)
        ForEach(BoardStore.shared.boards, id: \.persistentModelID) { board in
          Button(board.name) {
            appState.history.move(item, to: board)
          }
          .disabled(item.item.board == board)
        }
      }
      Divider()
      Button(String(localized: "item.delete", table: "Sorap"), role: .destructive) {
        appState.history.delete(item)
      }
    }
  }
}

extension View {
  func itemContextMenu(_ item: HistoryItemDecorator) -> some View {
    modifier(ItemContextMenu(item: item))
  }
}
