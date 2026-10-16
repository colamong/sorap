import SwiftUI

struct BoardChipsView: View {
  @Environment(AppState.self) private var appState
  private var boardStore = BoardStore.shared
  @State private var boardToDelete: Board?

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
            Divider()
            Button(String(localized: "board.empty", table: "Sorap"), role: .destructive) {
              appState.requestEmptyBoard(board)
            }
            .disabled(appState.history.boardItemCount(in: board) == 0)
            if !board.isFavorites {
              Button(String(localized: "board.delete", table: "Sorap"), role: .destructive) {
                appState.isEditingItem = true
                boardToDelete = board
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
        .help(String(localized: "board.new.tooltip", table: "Sorap"))
        .accessibilityLabel(String(localized: "board.new.tooltip", table: "Sorap"))
      }
      .padding(.vertical, 2)
    }
    .confirmationDialog(
      dialogTitle,
      isPresented: Binding(
        get: { boardToDelete != nil },
        set: { if !$0 { dismissDialog() } }
      ),
      titleVisibility: .visible,
      presenting: boardToDelete
    ) { board in
      Button(String(localized: "item.delete", table: "Sorap"), role: .destructive) {
        // A failed delete leaves the board and its items untouched.
        try? appState.history.deleteBoard(board)
        dismissDialog()
      }
      Button(String(localized: "common.cancel", table: "Sorap"), role: .cancel) {
        dismissDialog()
      }
      .keyboardShortcut(.defaultAction)
    } message: { board in
      Text(String(localized: "board.delete.message \(appState.history.boardItemCount(in: board))", table: "Sorap"))
    }
  }

  private var dialogTitle: String {
    guard let board = boardToDelete else { return "" }
    return String(format: String(localized: "board.delete.title", table: "Sorap"), board.name)
  }

  private func dismissDialog() {
    boardToDelete = nil
    appState.isEditingItem = false
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
