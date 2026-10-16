import SwiftUI

struct ConfirmationView<Content: View>: View {
  @Bindable var item: FooterItem
  @ViewBuilder let content: () -> Content

  var body: some View {
    if let confirmation = item.confirmation, let suppressConfirmation = item.suppressConfirmation {
      content()
        .buttonAction {
          item.trigger()
        }
        .confirmationDialog(confirmation.message, isPresented: $item.showConfirmation, titleVisibility: .visible) {
          Text(confirmation.comment)
          Button(confirmation.confirm, role: .destructive) {
            item.action()
          }
          .accessibilityIdentifier("confirmation-confirm")
          Button(confirmation.cancel, role: .cancel) {}
        }
        .dialogSuppressionToggle(isSuppressed: suppressConfirmation)
    } else {
      content()
        .buttonAction {
          item.trigger()
        }
    }
  }
}
