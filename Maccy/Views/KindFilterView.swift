import SwiftUI

struct KindFilterView: View {
  @Environment(AppState.self) private var appState

  var body: some View {
    HStack(spacing: 2) {
      filterButton(nil, symbol: "square.grid.2x2", label: "filter.all")
      ForEach(ItemKind.filters) { kind in
        filterButton(kind, symbol: kind.symbol, label: kind.labelKey)
      }
    }
    .padding(2)
    .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 7))
  }

  private func filterButton(_ kind: ItemKind?, symbol: String, label: String.LocalizationValue) -> some View {
    let selected = appState.history.kindFilter == kind
    let text = String(localized: label, table: "Sorap")
    return Button {
      appState.history.kindFilter = kind
    } label: {
      Image(systemName: symbol)
        .font(.system(size: 12, weight: .medium))
        .frame(width: 24, height: 20)
        .foregroundStyle(selected ? .primary : .secondary)
        .background(
          selected ? AnyShapeStyle(.background) : AnyShapeStyle(.clear),
          in: RoundedRectangle(cornerRadius: 5)
        )
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .help(text)
    .accessibilityLabel(text)
    .accessibilityAddTraits(selected ? .isSelected : [])
  }
}
