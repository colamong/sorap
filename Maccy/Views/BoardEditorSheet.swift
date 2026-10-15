import SwiftData
import SwiftUI

enum BoardEditorRequest: Identifiable {
  case create
  case edit(Board)

  var id: String {
    switch self {
    case .create: "create"
    case .edit(let board): "edit-\(board.persistentModelID.hashValue)"
    }
  }
}

struct BoardEditorSheet: View {
  let request: BoardEditorRequest

  @Environment(\.dismiss) private var dismiss
  @State private var name: String
  @State private var symbol: String

  init(request: BoardEditorRequest) {
    self.request = request
    switch request {
    case .create:
      _name = State(initialValue: "")
      _symbol = State(initialValue: "folder")
    case .edit(let board):
      _name = State(initialValue: board.name)
      _symbol = State(initialValue: board.symbol)
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      TextField(BoardStore.defaultName, text: $name)
        .textFieldStyle(.roundedBorder)
        .onSubmit(save)

      LazyVGrid(columns: Array(repeating: GridItem(.fixed(32)), count: 6), spacing: 8) {
        ForEach(BoardStore.symbolChoices, id: \.self) { choice in
          Button {
            symbol = choice
          } label: {
            Image(systemName: choice)
              .frame(width: 30, height: 30)
              .background(
                symbol == choice ? AnyShapeStyle(Color.accentColor.opacity(0.2)) : AnyShapeStyle(.clear),
                in: RoundedRectangle(cornerRadius: 6)
              )
          }
          .buttonStyle(.plain)
          .accessibilityLabel(choice)
        }
      }

      HStack {
        Spacer()
        Button(String(localized: "common.cancel", table: "Sorap"), role: .cancel) { dismiss() }
          .keyboardShortcut(.cancelAction)
        Button(String(localized: "common.save", table: "Sorap"), action: save)
          .keyboardShortcut(.defaultAction)
      }
    }
    .padding(16)
    .frame(width: 300)
  }

  private func save() {
    switch request {
    case .create:
      let board = BoardStore.shared.create(name: name, symbol: symbol)
      AppState.shared.history.scope = .board(board)
    case .edit(let board):
      BoardStore.shared.rename(board, to: name)
      BoardStore.shared.setSymbol(board, to: symbol)
    }
    dismiss()
  }
}
