import SwiftUI
import Defaults
import KeyboardShortcuts
import LaunchAtLogin
import Settings

struct GeneralSettingsPane: View {
  private let notificationsURL = URL(
    string: "x-apple.systempreferences:com.apple.preference.notifications?id=\(Bundle.main.bundleIdentifier ?? "")"
  )

  @Default(.searchMode) private var searchMode
  @Default(.captureLinkAction) private var captureLinkAction
  @Default(.capturePathAction) private var capturePathAction
  @Default(.captureEmailAction) private var captureEmailAction
  @Default(.capturePhoneAction) private var capturePhoneAction
  @Default(.captureSkipPrompt) private var captureSkipPrompt

  @State private var copyModifier = HistoryItemAction.copy.modifierFlags.description
  @State private var pasteModifier = HistoryItemAction.paste.modifierFlags.description
  @State private var pasteWithoutFormatting = HistoryItemAction.pasteWithoutFormatting.modifierFlags.description

  @State private var updater = SoftwareUpdater()

  // Changing the language only takes effect after a relaunch, so remember what is in effect now.
  @State private var activeLanguage = AppLanguage.current()
  @State private var language = AppLanguage.current()
  @State private var languageChanged = false

  var body: some View {
    Settings.Container(contentWidth: 450) {
      Settings.Section(title: "", bottomDivider: true) {
        LaunchAtLogin.Toggle {
          Text("LaunchAtLogin", tableName: "GeneralSettings")
        }
        Toggle(isOn: $updater.automaticallyChecksForUpdates) {
          Text("CheckForUpdates", tableName: "GeneralSettings")
        }
        Button(
          action: { updater.checkForUpdates() },
          label: { Text("CheckNow", tableName: "GeneralSettings") }
        )
      }

      Settings.Section(
        bottomDivider: true,
        label: { Text("settings.language", tableName: "Sorap") }
      ) {
        Picker("", selection: $language) {
          ForEach(AppLanguage.allCases) { option in
            if let endonym = option.endonym {
              Text(endonym).tag(option)
            } else {
              Text("settings.language.system", tableName: "Sorap").tag(option)
            }
          }
        }
        .labelsHidden()
        .accessibilityLabel(Text("settings.language", tableName: "Sorap"))
        .frame(width: 180, alignment: .leading)
        .onChange(of: language) { _, newValue in
          newValue.apply()
          languageChanged = newValue != activeLanguage
        }

        if languageChanged {
          HStack {
            Text("settings.language.restartNote", tableName: "Sorap")
              .foregroundStyle(.secondary)
            Button(
              action: { relaunch() },
              label: { Text("settings.language.restart", tableName: "Sorap") }
            )
          }
        }
      }

      Settings.Section(label: { Text("Open", tableName: "GeneralSettings") }) {
        KeyboardShortcuts.Recorder(for: .popup, onChange: { newShortcut in
          if newShortcut == nil {
            // No shortcut is recorded. Remove keys monitor
            AppState.shared.popup.deinitEventsMonitor()
          } else {
            // User is using shortcut. Ensure keys monitor is initialized
            AppState.shared.popup.initEventsMonitor()
          }
        })
          .help(Text("OpenTooltip", tableName: "GeneralSettings"))
          .accessibilityLabel(Text("Open", tableName: "GeneralSettings"))
      }

      // The stored shortcut is still named .pin; it now toggles Favorites.
      Settings.Section(label: { Text("settings.favorite", tableName: "Sorap") }) {
        KeyboardShortcuts.Recorder(for: .pin)
          .help(Text("settings.favorite.tooltip", tableName: "Sorap"))
          .accessibilityLabel(Text("settings.favorite", tableName: "Sorap"))
      }
      Settings.Section(label: { Text("Delete", tableName: "GeneralSettings") }
      ) {
        KeyboardShortcuts.Recorder(for: .delete)
          .help(Text("DeleteTooltip", tableName: "GeneralSettings"))
          .accessibilityLabel(Text("Delete", tableName: "GeneralSettings"))
      }
      Settings.Section(
        bottomDivider: true,
        label: { Text("ShowPreview", tableName: "GeneralSettings") }
      ) {
        KeyboardShortcuts.Recorder(for: .togglePreview)
          .help(Text("ShowPreviewTooltip", tableName: "GeneralSettings"))
          .accessibilityLabel(Text("ShowPreview", tableName: "GeneralSettings"))
      }

      Settings.Section(
        bottomDivider: true,
        label: { Text("Search", tableName: "GeneralSettings") }
      ) {
        Picker("", selection: $searchMode) {
          ForEach(Search.Mode.allCases) { mode in
            Text(mode.description)
          }
        }
        .labelsHidden()
        .accessibilityLabel(Text("Search", tableName: "GeneralSettings"))
        .frame(width: 180, alignment: .leading)
      }

      Settings.Section(
        bottomDivider: true,
        label: { Text("Behavior", tableName: "GeneralSettings") }
      ) {
        Defaults.Toggle(key: .pasteByDefault) {
          Text("PasteAutomatically", tableName: "GeneralSettings")
        }
        .onChange(refreshModifiers)
        .fixedSize()

        Defaults.Toggle(key: .removeFormattingByDefault) {
          Text("PasteWithoutFormatting", tableName: "GeneralSettings")
        }
        .onChange(refreshModifiers)
        .fixedSize()

        Text(String(
          format: NSLocalizedString("Modifiers", tableName: "GeneralSettings", comment: ""),
          copyModifier, pasteModifier, pasteWithoutFormatting
        ))
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(.gray)
        .controlSize(.small)
      }

      Settings.Section(
        bottomDivider: true,
        label: { Text("settings.capture", tableName: "Sorap") }
      ) {
        Defaults.Toggle(key: .capturePrompt) {
          Text("settings.capture.prompt", tableName: "Sorap")
        }
        .fixedSize()

        captureActionPicker("settings.capture.link", selection: $captureLinkAction)
        captureActionPicker("settings.capture.path", selection: $capturePathAction)
        captureActionPicker("settings.capture.email", selection: $captureEmailAction)
        captureActionPicker("settings.capture.phone", selection: $capturePhoneAction)

        Button(
          action: { captureSkipPrompt = [] },
          label: { Text("settings.capture.resetSkip", tableName: "Sorap") }
        )
        .disabled(captureSkipPrompt.isEmpty)
      }

      Settings.Section(title: "") {
        if let notificationsURL = notificationsURL {
          Link(destination: notificationsURL, label: {
            Text("NotificationsAndSounds", tableName: "GeneralSettings")
          })
        }
      }
    }
  }

  private func relaunch() {
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.createsNewApplicationInstance = true
    NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: configuration) { _, error in
      Task { @MainActor in
        if let error {
          NSAlert(error: error).runModal()
        } else {
          NSApp.terminate(nil)
        }
      }
    }
  }

  private func captureActionPicker(_ label: LocalizedStringKey, selection: Binding<CaptureAction>) -> some View {
    Picker(selection: selection) {
      Text("settings.capture.open", tableName: "Sorap").tag(CaptureAction.open)
      Text("settings.capture.copy", tableName: "Sorap").tag(CaptureAction.copy)
    } label: {
      Text(label, tableName: "Sorap")
    }
    .frame(width: 240, alignment: .leading)
  }

  private func refreshModifiers(_ sender: Sendable) {
    copyModifier = HistoryItemAction.copy.modifierFlags.description
    pasteModifier = HistoryItemAction.paste.modifierFlags.description
    pasteWithoutFormatting = HistoryItemAction.pasteWithoutFormatting.modifierFlags.description
  }
}

#Preview {
  GeneralSettingsPane()
    .environment(\.locale, .init(identifier: "en"))
}
