import Foundation
import UniformTypeIdentifiers

enum ItemKind: String, CaseIterable, Identifiable {
  case text
  case link
  case file
  case image
  case other

  static let filters: [ItemKind] = [.text, .link, .file, .image]

  var id: String { rawValue }

  var symbol: String {
    switch self {
    case .text: "text.alignleft"
    case .link: "link"
    case .file: "folder"
    case .image: "photo"
    case .other: "doc"
    }
  }

  var labelKey: String.LocalizationValue {
    switch self {
    case .text: "filter.text"
    case .link: "filter.link"
    case .file: "filter.file"
    case .image: "filter.image"
    case .other: "filter.other"
    }
  }

  private static let linkDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

  static func classify(hasImage: Bool, text: String?, fileURLs: [URL]) -> ItemKind {
    if hasImage { return .image }

    if !fileURLs.isEmpty {
      let allImages = fileURLs.allSatisfy { url in
        UTType(filenameExtension: url.pathExtension)?.conforms(to: .image) ?? false
      }
      return allImages ? .image : .file
    }

    let trimmed = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return .other }
    if trimmed.hasPrefix("file://") { return .file }
    if isSingleLink(trimmed) { return .link }
    if isSinglePath(trimmed) { return .file }
    return .text
  }

  private static let maxPathLength = 1024

  /// A lone path such as Finder's ⌥⌘C produces. Spaces are allowed because paths contain them;
  /// a newline means prose or a list. An absolute path needs a second segment ("/Users/me"),
  /// so slash commands like "/compact" or "/help me" stay text.
  private static func isSinglePath(_ string: String) -> Bool {
    guard !string.contains(where: \.isNewline), string.count <= maxPathLength else { return false }
    if string.hasPrefix("~/") { return true }
    guard string.hasPrefix("/") else { return false }
    let afterRoot = string.dropFirst()
    guard let separator = afterRoot.firstIndex(of: "/") else { return false }
    return separator != afterRoot.startIndex
  }

  private static func isSingleLink(_ string: String) -> Bool {
    guard !string.contains(where: \.isWhitespace), let linkDetector else { return false }
    let fullRange = NSRange(string.startIndex..., in: string)
    let matches = linkDetector.matches(in: string, range: fullRange)
    return matches.count == 1 && matches[0].range == fullRange
  }
}
