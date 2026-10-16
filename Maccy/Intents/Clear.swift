import AppIntents
import Defaults

struct Clear: AppIntent, CustomIntentMigratedAppIntent {
  static let intentClassName = "ClearIntent"

  static let title: LocalizedStringResource = "Clear Clipboard History"
  static let description = IntentDescription("Clears Sorap clipboard history. Items saved in boards are kept.")

  static var parameterSummary: some ParameterSummary {
    Summary("Clear Clipboard History")
  }

  func perform() async throws -> some IntentResult {
    if !Defaults[.suppressClearAlert] {
      try await requestConfirmation()
    }

    await AppState.shared.history.clear()
    return .result()
  }
}
