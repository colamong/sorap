import Defaults
import SwiftData
import SwiftUI

struct HistoryItemView: View {
  @Bindable var item: HistoryItemDecorator
  var previous: HistoryItemDecorator?
  var next: HistoryItemDecorator?
  var index: Int

  private var selectionAppearance: SelectionAppearance {
    let previousSelected = previous?.isSelected ?? false
    let nextSelected = next?.isSelected ?? false
    switch (previousSelected, nextSelected) {
    case (true, false):
      return .topConnection
    case (false, true):
      return .bottomConnection
    case (true, true):
      return .topBottomConnection
    default:
      return .none
    }
  }

  @Default(.showHexColorSwatch) private var showHexColorSwatch
  @Environment(AppState.self) private var appState

  private var colorSwatchImage: NSImage? {
    guard showHexColorSwatch else { return nil }
    return ColorImage.from(item.title)
  }

  private var isFavorite: Bool { item.item.board?.isFavorites == true }

  private var favoriteButton: some View {
    Button {
      appState.history.toggleFavorite(item)
    } label: {
      Image(systemName: isFavorite ? "star.fill" : "star")
        .foregroundStyle(isFavorite ? Color.yellow : (item.isSelected ? Color.white : .secondary))
    }
    .buttonStyle(.plain)
    .help(String(localized: isFavorite ? "history_item_unfavorite_action" : "history_item_favorite_action", table: "Sorap"))
  }

  private func performSelect() {
    if NSEvent.modifierFlags.contains(.command) && appState.multiSelectionEnabled {
      appState.navigator.addToSelection(item: item)
    } else {
      let flags = NSEvent.ModifierFlags.currentModifierFlags
      Task {
        appState.history.select(item, flags: flags)
      }
    }
  }

  var body: some View {
    ListItemView(
      id: item.id,
      selectionId: item.id,
      appIcon: item.applicationImage,
      image: item.thumbnailImage,
      accessoryImage: item.thumbnailImage != nil ? nil : colorSwatchImage,
      attributedTitle: item.attributedTitle,
      shortcuts: item.shortcuts,
      isSelected: item.isSelected,
      selectionIndex: item.multiSelectionIndex,
      selectionAppearance: selectionAppearance,
      accessibilityLabel: item.accessibilityLabel,
      leadingSymbol: item.kind.symbol,
      trailingAccessory: AnyView(favoriteButton)
    ) {
      Text(verbatim: item.title)
    }
    .accessibilityIdentifier("copy-history-item")
    .contextMenu {
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
    .buttonAction(performSelect)
    .onAppear {
      item.ensureThumbnailImage()
    }
    .accessibilityAction(named: Text(item.item.board == nil ? "history_item_favorite_action" : "history_item_unfavorite_action", tableName: "Sorap")) {
      appState.history.toggleFavorite(item)
    }
    .accessibilityAction(named: Text("history_item_delete_action")) {
      appState.history.delete(item)
    }
  }
}
