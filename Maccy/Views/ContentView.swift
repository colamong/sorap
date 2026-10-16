import SwiftData
import SwiftUI

struct ContentView: View {
  @State private var appState = AppState.shared
  @State private var modifierFlags = ModifierFlags()
  @State private var scenePhase: ScenePhase = .background

  @FocusState private var searchFocused: Bool

  var body: some View {
    ZStack {
      if #available(macOS 26.0, *) {
        GlassEffectView()
      } else {
        VisualEffectView()
      }

      KeyHandlingView(searchQuery: $appState.history.searchQuery, searchFocused: $searchFocused) {
        VStack(spacing: 0) {
          SlideoutView(controller: appState.preview) {
            HeaderView(
              controller: appState.preview,
              searchFocused: $searchFocused
            )

            VStack(alignment: .leading, spacing: 0) {
              HistoryListView(
                searchQuery: $appState.history.searchQuery,
                searchFocused: $searchFocused
              )

              FooterView(footer: appState.footer)
            }
            .animation(.default.speed(3), value: appState.history.items)
            .animation(
              .default.speed(3),
              value: appState.history.pasteStack?.id
            )
            .padding(.horizontal, Popup.horizontalPadding)
            .onAppear {
              searchFocused = true
            }
            .onMouseMove {
              appState.navigator.isKeyboardNavigating = false
            }
          } slideout: {
            SlideoutContentView()
          }
          .frame(minHeight: 0)
          .layoutPriority(1)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .task {
        BoardStore.shared.load()
        try? await appState.history.load()
      }
    }
    .animation(.easeInOut(duration: 0.2), value: appState.searchVisible)
    .environment(appState)
    .environment(modifierFlags)
    .environment(\.scenePhase, scenePhase)
    .sheet(item: $appState.editingItem, onDismiss: { appState.finishEditing() }) { item in
      ItemEditorView(for: item)
        .environment(appState)
    }
    .sheet(item: $appState.boardEditorRequest, onDismiss: { appState.finishEditing() }) { request in
      BoardEditorSheet(request: request)
    }
    .confirmationDialog(
      emptyBoardTitle,
      isPresented: Binding(
        get: { appState.pendingBoardToEmpty != nil },
        set: { if !$0 { appState.cancelEmptyBoard() } }
      ),
      titleVisibility: .visible,
      presenting: appState.pendingBoardToEmpty
    ) { _ in
      Button(String(localized: "board.empty.confirm", table: "Sorap"), role: .destructive) {
        appState.confirmEmptyBoard()
      }
      Button(String(localized: "common.cancel", table: "Sorap"), role: .cancel) {
        appState.cancelEmptyBoard()
      }
    } message: { board in
      Text(String(localized: "board.empty.message \(appState.history.boardItemCount(in: board))", table: "Sorap"))
    }
    .onChange(of: appState.isEditingItem) { _, isEditingItem in
      // A sheet's text controls otherwise remain the logical focus target after
      // dismissal, preventing the popup's key handler from receiving shortcuts.
      searchFocused = !isEditingItem
    }
    // FloatingPanel is not a scene, so let's implement custom scenePhase..
    .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) {
      guard !appState.isEditingItem else { return }

      if let window = $0.object as? NSWindow,
         let bundleIdentifier = Bundle.main.bundleIdentifier,
         window.identifier == NSUserInterfaceItemIdentifier(bundleIdentifier) {
        scenePhase = .active
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) {
      guard !appState.isEditingItem else { return }

      if let window = $0.object as? NSWindow,
         let bundleIdentifier = Bundle.main.bundleIdentifier,
         window.identifier == NSUserInterfaceItemIdentifier(bundleIdentifier) {
        scenePhase = .background
      }
    }
  }
}

private extension ContentView {
  var emptyBoardTitle: String {
    guard let board = appState.pendingBoardToEmpty else { return "" }
    return String(format: String(localized: "board.empty.title", table: "Sorap"), board.name)
  }
}

#Preview {
  ContentView()
    .environment(\.locale, .init(identifier: "en"))
    .modelContainer(Storage.shared.container)
}
