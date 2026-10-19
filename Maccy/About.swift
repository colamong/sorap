import Cocoa

class About {
  private var links: NSMutableAttributedString {
    let string = NSMutableAttributedString(string: "Website│GitHub│Support│Sponsor",
                                           attributes: [NSAttributedString.Key.foregroundColor: NSColor.labelColor])
    string.addAttribute(.link, value: "https://github.com/colamong/sorap", range: NSRange(location: 0, length: 7))
    string.addAttribute(.link, value: "https://github.com/colamong/sorap", range: NSRange(location: 8, length: 6))
    string.addAttribute(.link, value: "https://github.com/colamong/sorap/issues", range: NSRange(location: 15, length: 7))
    string.addAttribute(.link, value: "https://github.com/sponsors/colamong", range: NSRange(location: 23, length: 7))
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
