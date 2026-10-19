import AppKit
import Defaults
import Vision

enum CaptureAction: String, CaseIterable, Identifiable, Defaults.Serializable {
  case open
  case copy

  var id: String { rawValue }
}

/// Reads a freshly captured image and offers to open or copy what it says.
@MainActor
enum CapturePrompt {
  private static let maxShownCharacters = 300

  /// Skips images Sorap put on the pasteboard itself, so picking an old capture from history stays quiet.
  static func handle(_ item: HistoryItem) {
    guard Defaults[.capturePrompt], !item.fromMaccy, let imageData = item.imageData else { return }

    Task {
      // A QR code says exactly what it means, so it wins over whatever text surrounds it.
      var text = await readQRPayload(imageData: imageData)
      if text == nil {
        text = await HistoryItem.recognizeText(imageData: imageData, fileURL: nil)
      }
      guard let text, let target = CaptureTarget.detect(in: text) else { return }
      present(target)
    }
  }

  @concurrent
  nonisolated static func readQRPayload(imageData: Data) async -> String? {
    let request = VNDetectBarcodesRequest()
    request.symbologies = [.qr, .microQR]
    do {
      try VNImageRequestHandler(data: imageData).perform([request])
    } catch {
      print("Unable to detect QR codes: \(error).")
      return nil
    }
    return request.results?.lazy.compactMap(\.payloadStringValue).first
  }

  static func perform(_ action: CaptureAction, on target: CaptureTarget) {
    switch (action, target) {
    case (.open, .link(let url)):
      NSWorkspace.shared.open(url)
    case (.open, .path(let url)):
      NSWorkspace.shared.activateFileViewerSelecting([url])
    default:
      Clipboard.shared.copyInMaccy(target.value)
    }
  }

  static func defaultAction(for kind: CaptureTarget.Kind) -> CaptureAction {
    switch kind {
    case .link: Defaults[.captureLinkAction]
    case .path: Defaults[.capturePathAction]
    case .text: .copy
    }
  }

  static func title(of action: CaptureAction, for kind: CaptureTarget.Kind) -> String {
    switch (action, kind) {
    case (.open, .path): String(localized: "capture.showInFinder", table: "Sorap")
    case (.open, _): String(localized: "capture.openLink", table: "Sorap")
    case (.copy, .link): String(localized: "capture.copyLink", table: "Sorap")
    case (.copy, .path): String(localized: "item.copyPath", table: "Sorap")
    case (.copy, .text): String(localized: "capture.copyText", table: "Sorap")
    }
  }

  private static func present(_ target: CaptureTarget) {
    let kind = target.kind
    if Defaults[.captureSkipPrompt].contains(kind.rawValue) {
      perform(defaultAction(for: kind), on: target)
      return
    }

    let actions = offeredActions(for: kind)
    let alert = NSAlert()
    alert.messageText = message(for: kind)
    alert.informativeText = target.value.shortened(to: maxShownCharacters)
    actions.forEach { alert.addButton(withTitle: title(of: $0, for: kind)) }
    alert.addButton(withTitle: String(localized: "capture.cancel", table: "Sorap"))
    alert.showsSuppressionButton = true
    alert.suppressionButton?.title = String(localized: "capture.dontAskAgain", table: "Sorap")
    alert.window.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
    centerOnScreenWithPointer(alert)

    // The capture happened in another app; hand focus back to it unless a browser or Finder takes over.
    let previousApp = NSWorkspace.shared.frontmostApplication
    NSApp.activate(ignoringOtherApps: true)
    let index = alert.runModal().rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
    guard actions.indices.contains(index) else {
      previousApp?.activate()
      return
    }

    let action = actions[index]
    if alert.suppressionButton?.state == .on {
      remember(action, for: kind)
    }
    if action == .copy {
      previousApp?.activate()
    }
    perform(action, on: target)
  }

  /// With several displays the alert would open on the main one, away from the capture just made.
  private static func centerOnScreenWithPointer(_ alert: NSAlert) {
    let pointer = NSEvent.mouseLocation
    guard let screen = NSScreen.screens.first(where: { NSMouseInRect(pointer, $0.frame, false) }) else { return }
    alert.layout()
    let size = alert.window.frame.size
    let visible = screen.visibleFrame
    alert.window.setFrameOrigin(NSPoint(x: visible.midX - size.width / 2, y: visible.midY - size.height / 2))
  }

  /// The configured default comes first so Return picks it.
  private static func offeredActions(for kind: CaptureTarget.Kind) -> [CaptureAction] {
    guard kind != .text else { return [.copy] }
    let preferred = defaultAction(for: kind)
    return [preferred] + CaptureAction.allCases.filter { $0 != preferred }
  }

  private static func remember(_ action: CaptureAction, for kind: CaptureTarget.Kind) {
    switch kind {
    case .link: Defaults[.captureLinkAction] = action
    case .path: Defaults[.capturePathAction] = action
    case .text: break
    }
    Defaults[.captureSkipPrompt].insert(kind.rawValue)
  }

  private static func message(for kind: CaptureTarget.Kind) -> String {
    switch kind {
    case .link: String(localized: "capture.link.message", table: "Sorap")
    case .path: String(localized: "capture.path.message", table: "Sorap")
    case .text: String(localized: "capture.text.message", table: "Sorap")
    }
  }
}
