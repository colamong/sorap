import SwiftUI

struct ImageGridView: View {
  let items: [HistoryItemDecorator]
  @Environment(AppState.self) private var appState

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

  var body: some View {
    LazyVGrid(columns: columns, spacing: 6) {
      ForEach(items) { item in
        Button {
          let flags = NSEvent.ModifierFlags.currentModifierFlags
          Task {
            appState.history.select(item, flags: flags)
          }
        } label: {
          Color.clear
            .aspectRatio(4 / 3, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary.opacity(0.5)))
            .overlay {
              if let image = item.thumbnailImage {
                Image(nsImage: image)
                  .resizable()
                  .scaledToFill()
              }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .bottomLeading) {
              if item.item.name != nil {
                Text(item.title)
                  .font(.caption2)
                  .lineLimit(1)
                  .padding(.horizontal, 5)
                  .padding(.vertical, 2)
                  .background(.thinMaterial, in: Capsule())
                  .padding(4)
              }
            }
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(item.isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.accessibilityLabel)
        .accessibilityAddTraits(item.isSelected ? .isSelected : [])
        .itemContextMenu(item)
        .onAppear { item.ensureThumbnailImage() }
      }
    }
    .padding(.horizontal, Popup.horizontalPadding)
  }
}
