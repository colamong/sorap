import Foundation

/// What the text read from a captured image points at.
enum CaptureTarget: Equatable {
  case link(URL)
  case path(URL)
  case text(String)

  enum Kind: String {
    case link
    case path
    case text
  }

  var kind: Kind {
    switch self {
    case .link: .link
    case .path: .path
    case .text: .text
    }
  }

  /// The string that goes to the clipboard when the target is copied instead of opened.
  var value: String {
    switch self {
    case .link(let url): url.absoluteString
    case .path(let url): url.path
    case .text(let text): text
    }
  }

  private static let linkDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
  private static let webSchemes: Set<String> = ["http", "https"]

  /// An existing path wins over a link because a path such as "/Users/me/site.com" also contains one.
  static func detect(
    in text: String,
    fileExists: (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }
  ) -> CaptureTarget? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    if let path = firstExistingPath(in: trimmed, fileExists: fileExists) {
      return .path(URL(fileURLWithPath: path))
    }
    if let url = firstWebLink(in: trimmed) {
      return .link(url)
    }
    return .text(trimmed)
  }

  private static func firstExistingPath(in text: String, fileExists: (String) -> Bool) -> String? {
    text
      .components(separatedBy: .newlines)
      .lazy
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter(ItemKind.isSinglePath)
      .map { NSString(string: $0).expandingTildeInPath }
      .first(where: fileExists)
  }

  private static func firstWebLink(in text: String) -> URL? {
    guard let linkDetector else { return nil }
    let fullRange = NSRange(text.startIndex..., in: text)
    return linkDetector.matches(in: text, range: fullRange)
      .lazy
      .compactMap(\.url)
      .first { webSchemes.contains($0.scheme?.lowercased() ?? "") }
  }
}
