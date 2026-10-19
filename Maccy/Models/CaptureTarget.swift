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

  /// A bare domain right after "/" is part of a path, e.g. a wrapped ".../site/site.com/index.html".
  private static func isPathSegment(_ match: NSTextCheckingResult, in text: String) -> Bool {
    guard let range = Range(match.range, in: text), range.lowerBound > text.startIndex else { return false }
    return text[text.index(before: range.lowerBound)] == "/" && !text[range].contains("://")
  }
}
