import AppIntents

struct Select: AppIntent, CustomIntentMigratedAppIntent {
  static let intentClassName = "SelectIntent"

  static let title: LocalizedStringResource = "Select Item in Clipboard History"
  static let description = IntentDescription("""
  Selects an item in Sorap clipboard history.
  Depending on Sorap settings, it might trigger pasting of the selected item.
  """)

  static var parameterSummary: some ParameterSummary {
    Summary("Select \(\.$number) Item in Clipboard History")
  }

  @Parameter(title: "Number", default: 1, requestValueDialog: "What is the number of the item?")
  var number: Int

  func perform() async throws -> some IntentResult & ReturnsValue<String> {
    let value = try await MainActor.run { () -> String in
      let items = AppState.shared.history.historyItems
      guard let index = History.index(forNumber: number, count: items.count) else {
        throw AppIntentError.notFound
      }

      let value = items[index].title
      AppState.shared.history.select(items[index], flags: .currentModifierFlags)

      return value
    }

    return .result(value: value)
  }
}
