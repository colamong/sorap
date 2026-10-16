import Defaults
import SwiftUI

@Observable
class Footer: ItemsContainer {
  var items: [FooterItem] = []

  var selectedItem: FooterItem? {
    willSet {
      selectedItem?.isSelected = false
      newValue?.isSelected = true
    }
  }

  var suppressClearAlert = Binding<Bool>(
    get: { Defaults[.suppressClearAlert] },
    set: { Defaults[.suppressClearAlert] = $0 }
  )

  private var showFooter: Bool {
    return Defaults[.showFooter]
  }
  var containerVisible: Bool {
    return showFooter
  }

  init() { // swiftlint:disable:this function_body_length
    items = [
      FooterItem(
        title: "clear",
        shortcuts: [KeyShortcut(key: .delete, modifierFlags: [.command, .option])],
        help: "clear_tooltip",
        confirmation: .init(
          message: "clear_alert_message",
          comment: "clear_alert_comment",
          confirm: "clear_alert_confirm",
          cancel: "clear_alert_cancel"
        ),
        suppressConfirmation: suppressClearAlert
      ) {
        Task { @MainActor in
          let history = AppState.shared.history
          if case .board(let board) = history.scope {
            AppState.shared.requestEmptyBoard(board)
          } else {
            history.clearCurrentScope()
          }
        }
      },
      FooterItem(
        title: "preferences",
        shortcuts: [KeyShortcut(key: .comma)]
      ) {
        Task { @MainActor in
          AppState.shared.openPreferences()
        }
      },
      FooterItem(
        title: "about",
        help: "about_tooltip"
      ) {
        AppState.shared.openAbout()
      },
      FooterItem(
        title: "quit",
        shortcuts: [KeyShortcut(key: .q)],
        help: "quit_tooltip"
      ) {
        AppState.shared.quit()
      }
    ]
    configureClearItem(items[0])
  }

  /// The clear item follows the view: wipes history there, empties the board in a board view.
  private func configureClearItem(_ clear: FooterItem) {
    clear.titleOverride = {
      guard case .board(let board) = AppState.shared.history.scope else { return nil }
      return String(format: String(localized: "board.empty.named", table: "Sorap"), board.name)
    }
    clear.isEnabled = {
      let history = AppState.shared.history
      guard case .board(let board) = history.scope else { return true }
      return history.boardItemCount(in: board) > 0
    }
    // A board always asks, with its own count, so the "don't ask again" history toggle does not apply.
    clear.confirmsItself = {
      if case .board = AppState.shared.history.scope { return true }
      return false
    }
  }
}
