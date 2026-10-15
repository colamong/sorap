import KeyboardShortcuts

extension KeyboardShortcuts.Name {
  static let popup = Self("popup", initial: Shortcut(.c, modifiers: [.command, .shift]))
  static let pin = Self("pin", initial: Shortcut(.p, modifiers: [.option]))
  static let delete = Self("delete", initial: Shortcut(.delete, modifiers: [.option]))
  // ⌃Space is the default Korean/English input switch on Korean Macs; ⌘Y matches Finder Quick Look.
  static let togglePreview = Self("togglePreview", initial: Shortcut(.y, modifiers: [.command]))
}
