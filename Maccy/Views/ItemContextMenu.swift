import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ItemContextMenu: ViewModifier {
  let item: HistoryItemDecorator
  @Environment(AppState.self) private var appState

  func body(content: Content) -> some View {
    content.contextMenu {
      Button(String(localized: "item.name", table: "Sorap")) {
        appState.requestEdit(item)
      }
      Menu(String(localized: "item.move", table: "Sorap")) {
        Button(String(localized: "board.history", table: "Sorap")) {
          appState.history.move(item, to: nil)
        }
        .disabled(item.item.board == nil)
        ForEach(BoardStore.shared.boards, id: \.persistentModelID) { board in
          Button(board.name) {
            appState.history.move(item, to: board)
          }
          .disabled(item.item.board == board)
        }
      }
      if let paths = item.item.filePathsText {
        Button(String(localized: "item.copyPath", table: "Sorap")) {
          Clipboard.shared.copyInMaccy(paths)
        }
      }
      if item.item.imageData != nil {
        Button(String(localized: "item.saveImage", table: "Sorap")) {
          saveImage()
        }
      }
      if item.item.imageData != nil, let target = CaptureTarget.detect(in: item.item.title) {
        if target.kind != .text {
          Button(CapturePrompt.title(of: .open, for: target.kind)) {
            CapturePrompt.perform(.open, on: target)
          }
        }
        Button(String(localized: "capture.copyText", table: "Sorap")) {
          CapturePrompt.perform(.copy, on: .text(item.item.title))
        }
      }
      Divider()
      Button(String(localized: "item.delete", table: "Sorap"), role: .destructive) {
        appState.history.delete(item)
      }
    }
  }
}

extension ItemContextMenu {
  /// Uses the non-modal `begin` so no nested run loop starts inside the SwiftUI action.
  /// The panel and the FloatingPanel both sit above normal windows, so raise the save panel
  /// and hold the popup open via `isEditingItem` while it is up.
  private func saveImage() {
    guard let data = item.item.pngData() else { return }
    let fileName = item.item.suggestedImageFileName()
    let hostWindow = NSApp.keyWindow

    let panel = NSSavePanel()
    panel.allowedContentTypes = [.png]
    panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
    panel.nameFieldStringValue = fileName
    panel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)

    appState.isEditingItem = true
    // LSUIElement app + non-activating popup: without activation the panel is not key.
    NSApp.activate(ignoringOtherApps: true)
    panel.begin { response in
      Task { @MainActor in
        defer {
          AppState.shared.isEditingItem = false
          if hostWindow?.isVisible == true {
            hostWindow?.makeKeyAndOrderFront(nil)
          }
        }
        guard response == .OK, let url = panel.url else { return }
        do {
          try data.write(to: url, options: .atomic)
        } catch {
          let alert = NSAlert(error: error)
          alert.alertStyle = .warning
          alert.window.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
          NSApp.activate(ignoringOtherApps: true)
          alert.runModal()
        }
      }
    }
  }
}

extension View {
  func itemContextMenu(_ item: HistoryItemDecorator) -> some View {
    modifier(ItemContextMenu(item: item))
  }
}
