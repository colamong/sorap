import Foundation

/// What the text read from a captured image points at.
enum CaptureTarget: Equatable {
  case link(URL)
  case path(URL)
  case email(String)
  case phone(String)
  case text(String)

  enum Kind: String {
    case link
    case path
    case email
    case phone
    case text
  }

  var kind: Kind {
    switch self {
    case .link: .link
    case .path: .path
    case .email: .email
    case .phone: .phone
    case .text: .text
    }
  }

  /// The string that goes to the clipboard when the target is copied instead of opened.
  var value: String {
    switch self {
    case .link(let url): url.absoluteString
    case .path(let url): url.path
    case .email(let address): address
    case .phone(let number): number
    case .text(let text): text
    }
  }

  /// The URL that opens the target, or nil when it can only be copied.
  var openURL: URL? {
    switch self {
    case .link(let url), .path(let url): url
    case .email(let address): URL(string: "mailto:\(address)")
    case .phone(let number): URL(string: "tel:\(number.filter { $0.isNumber || $0 == "+" })")
    case .text: nil
    }
  }

  private static let linkDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
  private static let phoneDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
  private static let webSchemes: Set<String> = ["http", "https"]
  private static let mailScheme = "mailto"
  /// Domestic numbers start with 0 ("010-1234-5678", "02-123-4567"); international ones with "+".
  private static let domesticPhoneDigits = 9...11
  private static let internationalPhoneDigits = 8...15

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
    if let address = firstEmail(in: trimmed) {
      return .email(address)
    }
    if let number = firstPhoneNumber(in: trimmed) {
      return .phone(number)
    }
    return .text(trimmed)
  }

  private static func firstExistingPath(in text: String, fileExists: (String) -> Bool) -> String? {
    text
      .components(separatedBy: .newlines)
      .lazy
      .flatMap(pathCandidates)
      .filter(ItemKind.isSinglePath)
      .map { NSString(string: $0).expandingTildeInPath }
      .first(where: fileExists)
  }

  /// A path may follow a label on the same line ("설정 파일: /Users/me/a"), so every "/" or "~/"
  /// that starts a word begins a candidate running to the end of the line.
  private static func pathCandidates(in line: String) -> [String] {
    line.indices
      .filter { index in
        (index == line.startIndex || line[line.index(before: index)].isWhitespace)
          && (line[index...].hasPrefix("/") || line[index...].hasPrefix("~/"))
      }
      .map { String(line[$0...]).trimmingCharacters(in: .whitespaces) }
  }

  private static func firstWebLink(in text: String) -> URL? {
    webLinks(in: text).first
  }

  /// Every http(s) link in reading order, each once. A capture of notes or slides often holds several.
  static func webLinks(in text: String) -> [URL] {
    guard let linkDetector else { return [] }
    let fullRange = NSRange(text.startIndex..., in: text)
    var seen = Set<URL>()
    return linkDetector.matches(in: text, range: fullRange)
      .filter { !isPathSegment($0, in: text) }
      .compactMap(\.url)
      .filter { webSchemes.contains($0.scheme?.lowercased() ?? "") && seen.insert($0).inserted }
  }

  private static func firstEmail(in text: String) -> String? {
    guard let linkDetector else { return nil }
    return linkDetector.matches(in: text, range: NSRange(text.startIndex..., in: text))
      .lazy
      .compactMap(\.url)
      .first { $0.scheme?.lowercased() == mailScheme }
      .map { String($0.absoluteString.dropFirst(mailScheme.count + 1)) }
  }

  /// The detector also takes order numbers such as "2026-1019-0001", so the digits must look like a phone's.
  private static func firstPhoneNumber(in text: String) -> String? {
    guard let phoneDetector else { return nil }
    return phoneDetector.matches(in: text, range: NSRange(text.startIndex..., in: text))
      .lazy
      .compactMap(\.phoneNumber)
      .first(where: looksLikePhoneNumber)
  }

  private static func looksLikePhoneNumber(_ number: String) -> Bool {
    let digitCount = number.filter(\.isNumber).count
    if number.hasPrefix("+") { return internationalPhoneDigits.contains(digitCount) }
    return number.hasPrefix("0") && domesticPhoneDigits.contains(digitCount)
  }

  /// A bare domain right after "/" is part of a path, e.g. a wrapped ".../site/site.com/index.html".
  private static func isPathSegment(_ match: NSTextCheckingResult, in text: String) -> Bool {
    guard let range = Range(match.range, in: text), range.lowerBound > text.startIndex else { return false }
    return text[text.index(before: range.lowerBound)] == "/" && !text[range].contains("://")
  }
}
