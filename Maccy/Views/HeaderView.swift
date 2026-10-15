import Defaults
import SwiftUI

struct HeaderView: View {
  @State private var appState = AppState.shared

  let controller: SlideoutController
  @FocusState.Binding var searchFocused: Bool

  var previewPlacement: SlideoutPlacement {
    return controller.placement
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top, spacing: 0) {
        HStack(alignment: .center, spacing: 0) {
          ListHeaderView(
            searchFocused: $searchFocused,
            searchQuery: $appState.history.searchQuery
          )
          .padding(.horizontal, Popup.horizontalPadding)

          KindFilterView()
            .padding(.trailing, 6)

          ToolbarButton {
            controller.togglePreview()
          } label: {
            Image(
              systemName: previewPlacement == .right
                ? "sidebar.left" : "sidebar.right"
            )
          }
          .shortcutKeyHelp(
            name: .togglePreview,
            key: controller.state.isOpen ? "ClosePreview" : "OpenPreview",
            tableName: "PreviewItemView",
            replacementKey: "previewKey"
          )
          .padding(.trailing, Popup.horizontalPadding)
        }
        .opacity(appState.searchVisible ? 1 : 0)
        .allowsHitTesting(appState.searchVisible)
        .accessibilityHidden(!appState.searchVisible)
        .layoutPriority(1)
      }
      // Only the search row collapses; the chip row stays and is counted in popup.headerHeight.
      .frame(maxHeight: !appState.searchVisible ? 0 : nil, alignment: .top)

      BoardChipsView()
        .padding(.top, appState.searchVisible ? 6 : 0)
        .padding(.horizontal, Popup.horizontalPadding)
    }
    .padding(.top, Popup.verticalPadding)
    .padding(.horizontal, 10)
    .animation(.default.speed(3), value: appState.navigator.leadSelection)
    .background(.clear)
    .readHeight(appState, into: \.popup.headerHeight)
  }
}
