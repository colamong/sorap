import SwiftUI

struct BoardChipsView: View {
  @Environment(AppState.self) private var appState
  private var boardStore = BoardStore.shared

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 6) {
        chip(
          title: String(localized: "board.history", table: "Sorap"),
          symbol: "clock",
          selected: appState.history.scope == .history
        ) {
          appState.history.scope = .history
        }

        ForEach(boardStore.boards) { board in
          chip(title: board.name, symbol: board.symbol, selected: appState.history.scope == .board(board)) {
            appState.history.scope = .board(board)
          }
          .contextMenu {
            Button(String(localized: "board.edit", table: "Sorap")) {
              appState.requestBoardEditor(.edit(board))
            }
            // Favorites is pinned at order 0, so it never moves and nothing moves in front of it.
            if !board.isFavorites, let index = boardStore.boards.firstIndex(of: board) {
              Button(String(localized: "board.moveLeft", table: "Sorap")) {
                boardStore.move(fromOffsets: IndexSet(integer: index), toOffset: index - 1)
              }
              .disabled(index <= 1)
              Button(String(localized: "board.moveRight", table: "Sorap")) {
                boardStore.move(fromOffsets: IndexSet(integer: index), toOffset: index + 2)
              }
              .disabled(index == boardStore.boards.count - 1)
            }
            if !board.isFavorites {
              Button(String(localized: "board.delete", table: "Sorap"), role: .destructive) {
                try? appState.history.deleteBoard(board)
              }
            }
          }
        }

        Button {
          appState.requestBoardEditor(.create)
        } label: {
          Image(systemName: "plus")
            .font(.system(size: 11, weight: .semibold))
            .frame(width: 22, height: 22)
            .background(.quaternary.opacity(0.6), in: Circle())
        }
        .buttonStyle(.plain)
        .help(String(localized: "board.new", table: "Sorap"))
        .accessibilityLabel(String(localized: "board.new", table: "Sorap"))
      }
      .padding(.vertical, 2)
    }
  }

  private func chip(title: String, symbol: String, selected: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Label(title, systemImage: symbol)
        .font(.system(size: 12, weight: selected ? .semibold : .regular))
        .lineLimit(1)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .foregroundStyle(selected ? Color.accentColor : .secondary)
        .background(
          selected ? AnyShapeStyle(Color.accentColor.opacity(0.15)) : AnyShapeStyle(.quaternary.opacity(0.4)),
          in: Capsule()
        )
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(selected ? .isSelected : [])
  }
}
