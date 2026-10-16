import SwiftUI

@Observable
class FooterItem: Equatable, Identifiable, HasVisibility {
  struct Confirmation {
    var message: LocalizedStringKey
    var comment: LocalizedStringKey
    var confirm: LocalizedStringKey
    var cancel: LocalizedStringKey
  }

  static func == (lhs: FooterItem, rhs: FooterItem) -> Bool {
    return lhs.id == rhs.id
  }

  let id = UUID()

  var title: String
  var shortcuts: [KeyShortcut] = []
  var help: LocalizedStringKey?
  var isSelected: Bool = false
  var confirmation: Confirmation?
  var showConfirmation: Bool = false
  var suppressConfirmation: Binding<Bool>?
  var isVisible: Bool = true
  var tint: Color?
  /// Replaces the localized title while the item's meaning depends on app state.
  var titleOverride: () -> String? = { nil }
  var isEnabled: () -> Bool = { true }
  /// True when the action asks for its own confirmation, so the item's dialog is skipped.
  var confirmsItself: () -> Bool = { false }
  var action: () -> Void

  init(
    title: String,
    shortcuts: [KeyShortcut] = [],
    help: LocalizedStringKey? = nil,
    confirmation: Confirmation? = nil,
    suppressConfirmation: Binding<Bool>? = nil,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.shortcuts = shortcuts
    self.help = help
    self.confirmation = confirmation
    self.suppressConfirmation = suppressConfirmation
    self.action = action
  }

  /// The one entry point for mouse, Return and the item's shortcut.
  func trigger() {
    guard isEnabled() else { return }
    if confirmation != nil, !confirmsItself(), suppressConfirmation?.wrappedValue != true {
      showConfirmation = true
    } else {
      action()
    }
  }
}
