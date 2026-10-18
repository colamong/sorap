import SwiftUI
import UniformTypeIdentifiers

struct ImageGridView: View {
  let items: [HistoryItemDecorator]
  @Environment(AppState.self) private var appState

  static let columnCount = 3

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: columnCount)

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
              if let image = item.gridThumbnailImage {
                // scaledToFill overflows the cell and clipShape does not clip hit-testing,
                // so a wide capture would take hover from its neighbours.
                Image(nsImage: image)
                  .resizable()
                  .scaledToFill()
                  .allowsHitTesting(false)
              } else if let fileURL = fileURLWithoutImage(item) {
                // Finder-copied image files carry no image data; the icon works without file read access.
                Image(nsImage: NSWorkspace.shared.icon(forFile: fileURL.path))
                  .resizable()
                  .scaledToFit()
                  .padding(18)
              }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .bottomLeading) {
              if let label = pillText(for: item) {
                Text(label)
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
        .onDrag { dragProvider(for: item) }
        .itemContextMenu(item)
        .hoverSelectionId(item.id)
        .onAppear { item.ensureGridThumbnailImage() }
      }
    }
    .padding(.horizontal, Popup.horizontalPadding)
  }

  private func fileURLWithoutImage(_ item: HistoryItemDecorator) -> URL? {
    item.item.imageData == nil ? item.item.fileURLs.first : nil
  }

  private func pillText(for item: HistoryItemDecorator) -> String? {
    if item.item.name != nil { return item.title }
    return fileURLWithoutImage(item)?.lastPathComponent
  }

  /// Dropping on Finder or the Desktop creates a PNG file named after the item.
  private func dragProvider(for item: HistoryItemDecorator) -> NSItemProvider {
    let provider = NSItemProvider()
    guard let data = item.item.pngData() else { return provider }
    provider.suggestedName = (item.item.suggestedImageFileName() as NSString).deletingPathExtension
    provider.registerDataRepresentation(for: UTType.png, visibility: .all) { completion in
      completion(data, nil)
      return nil
    }
    return provider
  }
}
