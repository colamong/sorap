import AppKit

/// Turns rich text (HTML or RTF) into Markdown: paragraphs, bullet and numbered lists,
/// bold, italic, inline code and links. Headings and tables come out as plain paragraphs.
enum MarkdownConverter {
  /// AppKit writes a list marker into the text itself, e.g. "\t•\tItem" or "\t1\tItem".
  private static let listMarker = try? NSRegularExpression(pattern: #"^\t([^\t]*)\t"#)

  static func markdown(from text: NSAttributedString) -> String {
    let string = text.string as NSString
    var blocks: [(line: String, isListItem: Bool)] = []

    string.enumerateSubstrings(
      in: NSRange(location: 0, length: string.length),
      options: [.byParagraphs, .substringNotRequired]
    ) { _, paragraphRange, _, _ in
      guard paragraphRange.length > 0 else { return }
      let paragraph = text.attributedSubstring(from: paragraphRange)
      let isListItem = (paragraph.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)?
        .textLists.isEmpty == false

      var body = paragraph
      var prefix = ""
      if isListItem, let (marker, markerLength) = leadingListMarker(in: paragraph.string) {
        prefix = orderedNumber(marker).map { "\($0). " } ?? "- "
        body = paragraph.attributedSubstring(
          from: NSRange(location: markerLength, length: paragraph.length - markerLength)
        )
      }

      let line = inlineMarkdown(body).trimmingCharacters(in: .whitespaces)
      guard !line.isEmpty else { return }
      blocks.append((prefix + line, isListItem))
    }

    var output = ""
    for (index, block) in blocks.enumerated() {
      if index > 0 {
        output += block.isListItem && blocks[index - 1].isListItem ? "\n" : "\n\n"
      }
      output += block.line
    }
    return output
  }

  private static func leadingListMarker(in line: String) -> (String, Int)? {
    let range = NSRange(location: 0, length: (line as NSString).length)
    guard let match = listMarker?.firstMatch(in: line, range: range) else { return nil }
    return ((line as NSString).substring(with: match.range(at: 1)), match.range.length)
  }

  private static func orderedNumber(_ marker: String) -> Int? {
    Int(marker.trimmingCharacters(in: CharacterSet(charactersIn: ".)")))
  }

  private static func inlineMarkdown(_ text: NSAttributedString) -> String {
    var output = ""
    text.enumerateAttributes(in: NSRange(location: 0, length: text.length)) { attributes, range, _ in
      let run = (text.string as NSString).substring(with: range)
      output += styledRun(run, attributes)
    }
    return output
  }

  /// Markers go around the trimmed run, so "a<b> bold </b>b" becomes "a **bold** b", not "a** bold **b".
  private static func styledRun(_ run: String, _ attributes: [NSAttributedString.Key: Any]) -> String {
    let core = run.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !core.isEmpty else { return run }

    var styled = core
    let traits = (attributes[.font] as? NSFont)?.fontDescriptor.symbolicTraits ?? []
    if traits.contains(.monoSpace) {
      styled = "`\(styled)`"
    } else {
      if traits.contains(.italic) { styled = "*\(styled)*" }
      if traits.contains(.bold) { styled = "**\(styled)**" }
    }
    if let url = linkURL(attributes[.link]) {
      styled = "[\(styled)](\(url))"
    }

    let leading = run.prefix { $0.isWhitespace }
    let trailing = String(run.reversed().prefix { $0.isWhitespace }.reversed())
    return leading + styled + trailing
  }

  private static func linkURL(_ value: Any?) -> String? {
    switch value {
    case let url as URL: url.absoluteString
    case let string as String: string
    default: nil
    }
  }
}
