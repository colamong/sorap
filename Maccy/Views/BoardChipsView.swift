import SwiftUI

struct BoardChipsView: View {
  @Environment(AppState.self) private var appState
  private var boardStore = BoardStore.shared
  @State private var pendingDeletion: Board?

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
                // The panel closes on resign-key, so keep it open while the dialog is up.
                appState.isEditingItem = true
                pendingDeletion = board
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
    .confirmationDialog(
      deletionTitle,
      isPresented: Binding(
        get: { pendingDeletion != nil },
        set: { if !$0 { dismissDeletionDialog() } }
      ),
      titleVisibility: .visible,
      presenting: pendingDeletion
    ) { board in
      Button(String(localized: "item.delete", table: "Sorap"), role: .destructive) {
        // A failed delete leaves the board and its items untouched.
        try? appState.history.deleteBoard(board)
        dismissDeletionDialog()
      }
      Button(String(localized: "common.cancel", table: "Sorap"), role: .cancel) {
        dismissDeletionDialog()
      }
    } message: { board in
      let count = appState.history.boardItems.filter { $0.item.board == board }.count
      Text(String(format: String(localized: "board.delete.message", table: "Sorap"), count))
    }
  }

  private var deletionTitle: String {
    String(format: String(localized: "board.delete.title", table: "Sorap"), pendingDeletion?.name ?? "")
  }

  private func dismissDeletionDialog() {
    pendingDeletion = nil
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
