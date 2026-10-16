import SwiftUI

struct FooterItemView: View {
  @Bindable var item: FooterItem
  @Environment(AppState.self) private var appState

  var body: some View {
    ConfirmationView(item: item) {
      ListItemView(
        id: item.id,
        selectionId: item.id,
        shortcuts: item.shortcuts,
        isSelected: item.isSelected,
        accessibilityLabel: item.titleOverride() ?? NSLocalizedString(item.title, comment: "")
      ) {
        if let title = item.titleOverride() {
          Text(verbatim: title)
        } else {
          Text(LocalizedStringKey(item.title))
        }
      }
      .opacity(item.isEnabled() ? 1 : 0.4)
    }
    .onHover { hovering in
      if hovering && appState.preview.state.isOpen {
        appState.preview.togglePreview()
      }
    }
  }
}
