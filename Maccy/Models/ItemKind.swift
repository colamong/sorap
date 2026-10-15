import Foundation
import UniformTypeIdentifiers

enum ItemKind: String, CaseIterable, Identifiable {
  case text
  case link
  case image
  case other

  static let filters: [ItemKind] = [.text, .link, .image]

  var id: String { rawValue }

  var symbol: String {
    switch self {
    case .text: "text.alignleft"
    case .link: "link"
    case .image: "photo"
    case .other: "doc"
    }
  }

  var labelKey: String.LocalizationValue {
    switch self {
    case .text: "filter.text"
    case .link: "filter.link"
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
      return allImages ? .image : .other
    }

    let trimmed = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return .other }
    if isSingleLink(trimmed) { return .link }
    return .text
  }

  private static func isSingleLink(_ string: String) -> Bool {
    guard !string.contains(where: \.isWhitespace), let linkDetector else { return false }
    let fullRange = NSRange(string.startIndex..., in: string)
    let matches = linkDetector.matches(in: string, range: fullRange)
    return matches.count == 1 && matches[0].range == fullRange
  }
}
