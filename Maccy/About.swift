import Cocoa

class About {
  private static let kakaoPayTitle = "카카오페이"
  private static let kakaoPayURL = "https://qr.kakaopay.com/Ej8VWiQ4o"

  /// KakaoPay lets Korean users without a GitHub account chip in; outside a Korean UI it would be noise.
  private var showsKakaoPay: Bool { Bundle.main.preferredLocalizations.first == AppLanguage.ko.rawValue }

  private var links: NSMutableAttributedString {
    let titles = "Website│GitHub│Support│Sponsor" + (showsKakaoPay ? "│\(Self.kakaoPayTitle)" : "")
    let string = NSMutableAttributedString(string: titles,
                                           attributes: [NSAttributedString.Key.foregroundColor: NSColor.labelColor])
    string.addAttribute(.link, value: "https://github.com/colamong/sorap", range: NSRange(location: 0, length: 7))
    string.addAttribute(.link, value: "https://github.com/colamong/sorap", range: NSRange(location: 8, length: 6))
    string.addAttribute(.link, value: "https://github.com/colamong/sorap/issues", range: NSRange(location: 15, length: 7))
    string.addAttribute(.link, value: "https://github.com/sponsors/colamong", range: NSRange(location: 23, length: 7))
    if showsKakaoPay {
      string.addAttribute(.link, value: Self.kakaoPayURL, range: (titles as NSString).range(of: Self.kakaoPayTitle))
    }
    return string
  }

  private var maccyCredits: NSMutableAttributedString {
    let string = NSMutableAttributedString(string: "Based on Maccy by Alex Rodionov",
                                           attributes: [NSAttributedString.Key.foregroundColor: NSColor.labelColor])
    string.addAttribute(.link, value: "https://github.com/p0deje/Maccy", range: NSRange(location: 9, length: 5))
    return string
  }

  private var credits: NSMutableAttributedString {
    let credits = NSMutableAttributedString(string: "",
                                            attributes: [NSAttributedString.Key.foregroundColor: NSColor.labelColor])
    credits.append(links)
    credits.append(NSAttributedString(string: "\n\n"))
    credits.append(maccyCredits)
    credits.setAlignment(.center, range: NSRange(location: 0, length: credits.length))
    return credits
  }

  @objc
  func openAbout(_ sender: NSMenuItem?) {
    NSApp.activate(ignoringOtherApps: true)
    NSApp.orderFrontStandardAboutPanel(options: [NSApplication.AboutPanelOptionKey.credits: credits])
  }
}
