import Defaults
import SwiftUI

enum SelectionAppearance {
  case none
  case topConnection
  case bottomConnection
  case topBottomConnection

  func rect(cornerRadius: CGFloat) -> some Shape {
    var cornerRadii = RectangleCornerRadii()
    switch self {
    case .none:
      cornerRadii.topLeading = cornerRadius
      cornerRadii.topTrailing = cornerRadius
      cornerRadii.bottomLeading = cornerRadius
      cornerRadii.bottomTrailing = cornerRadius
    case .topConnection:
      cornerRadii.bottomLeading = cornerRadius
      cornerRadii.bottomTrailing = cornerRadius
    case .bottomConnection:
      cornerRadii.topLeading = cornerRadius
      cornerRadii.topTrailing = cornerRadius
    case .topBottomConnection:
      break
    }
    return .rect(cornerRadii: cornerRadii)
  }
}

struct ListItemView<Title: View, ID: Hashable>: View {
  var id: ID
  var selectionId: UUID
  var appIcon: ApplicationImage?
  var image: NSImage?
  var accessoryImage: NSImage?
  var attributedTitle: AttributedString?
  var shortcuts: [KeyShortcut]
  var isSelected: Bool
  var selectionIndex: Int?
  var help: LocalizedStringKey?
  var selectionAppearance: SelectionAppearance = .none
  // Complete description used when the row's visual content is hidden from accessibility.
  var accessibilityLabel: String = ""
  var leadingSymbol: String?
  var trailingAccessory: AnyView?
  // Colors the text, and swaps the selection fill for a light wash of the same color.
  var tint: Color?
  @ViewBuilder var title: () -> Title

  @Default(.showApplicationIcons) private var showIcons
  @Environment(AppState.self) private var appState
  @Environment(ModifierFlags.self) private var modifierFlags

  // Use the same selection number for the visible badge and accessibility value.
  private var displaySelectionIndex: String? {
    selectionIndex.map { "\($0 + 1)" }
  }

  private var selectionFill: Color {
    tint?.opacity(0.18) ?? Color.accentColor.opacity(0.8)
  }

  var body: some View {
    HStack(spacing: 0) {
      if showIcons, let appIcon {
        VStack {
          Spacer(minLength: 0)
          AppImageView(appImage: appIcon, size: NSSize(width: 15, height: 15))
          Spacer(minLength: 0)
        }
        .padding(.leading, 4)
        .padding(.vertical, 5)
      }

      Spacer()
        .frame(width: showIcons ? 5 : 10)

      if let accessoryImage {
        Image(nsImage: accessoryImage)
          .accessibilityIdentifier("copy-history-item")
          .accessibilityHidden(true)
          .padding(.trailing, 5)
          .padding(.vertical, 5)
      }

      if image == nil, let leadingSymbol {
        Image(systemName: leadingSymbol)
          .font(.system(size: 12))
          .frame(width: 24, height: 24)
          .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
          .foregroundStyle(isSelected ? Color.white : .secondary)
          .accessibilityHidden(true)
          .padding(.trailing, 8)
      }

      if let image {
        Image(nsImage: image)
          .accessibilityIdentifier("copy-history-item")
          .accessibilityHidden(true)
          .padding(.trailing, 5)
          .padding(.vertical, 5)
      } else {
        ListItemTitleView(attributedTitle: attributedTitle, title: title)
          .accessibilityHidden(true)
          .padding(.trailing, 5)
      }

      Spacer()

      HStack(spacing: 5) {
        if let displaySelectionIndex {
          Text(displaySelectionIndex)
            .font(.caption)
            .frame(minWidth: 10, alignment: .center)
            .padding(3)
            .background(
              Color.secondary.opacity(isSelected ? 0.5 : 0.8),
              in: Capsule()
            )
            .foregroundStyle(Color.white)
            .accessibilityHidden(true)
        }

        if !shortcuts.isEmpty {
          ZStack(alignment: .trailing) {
            ForEach(shortcuts) { shortcut in
              let visible = shortcut.isVisible(shortcuts, modifierFlags.flags)
              KeyboardShortcutView(shortcut: shortcut)
                .opacity(visible ? 1 : 0)
                .accessibilityHidden(true)
                .frame(width: visible ? nil : 0)
            }
          }
        }

        if let trailingAccessory {
          trailingAccessory
        }
      }
      .padding(.trailing, 10)
    }
    .frame(minHeight: Popup.itemHeight)
    .padding(.vertical, 2)
    .id(id)
    .frame(maxWidth: .infinity, alignment: .leading)
    .foregroundStyle(tint ?? (isSelected ? Color.white : .primary))
    // macOS 26 broke hovering if no background is present.
    // The slight opcaity white background is a workaround
    .background(
      isSelected ? selectionFill : Color.primary.opacity(0.04),
      in: selectionAppearance.rect(cornerRadius: Popup.cornerRadius)
    )
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(accessibilityLabel))
    .accessibilityAddTraits(isSelected ? .isSelected : [])
    .accessibilityValue(Text(displaySelectionIndex ?? ""))
    .hoverSelectionId(selectionId)
    .help(help ?? "")
  }
}
