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
          ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 8)
              .fill(.quaternary.opacity(0.5))
            if let image = item.thumbnailImage {
              Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
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
          .aspectRatio(4 / 3, contentMode: .fit)
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
  }
}
