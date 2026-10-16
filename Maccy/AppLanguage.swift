import Foundation

/// The language the app shows its UI in, independent of the system language.
/// Stored through `AppleLanguages`, which Foundation reads at launch.
enum AppLanguage: String, CaseIterable, Identifiable {
  case system
  case ko
  case en
  case ja
  case zhHans = "zh-Hans"
  case zhHant = "zh-Hant"
  case es

  static let defaultsKey = "AppleLanguages"

  var id: String { rawValue }

  /// Names are shown in their own language so a user can find theirs.
  /// `nil` for `.system`, which is localized instead.
  var endonym: String? {
    switch self {
    case .system: return nil
    case .ko: return "한국어"
    case .en: return "English"
    case .ja: return "日本語"
    case .zhHans: return "简体中文"
    case .zhHant: return "繁體中文"
    case .es: return "Español"
    }
  }

  /// The app's own defaults domain. `UserDefaults.standard` writes there, and reading only that domain
  /// keeps the system's AppleLanguages (global domain) from showing up as a choice.
  static var appDomain: String { Bundle.main.bundleIdentifier ?? "" }

  /// For a suite other than `.standard`, pass the suite name as `domain`.
  static func current(defaults: UserDefaults = .standard, domain: String = appDomain) -> AppLanguage {
    let stored = defaults.persistentDomain(forName: domain)?[defaultsKey] as? [String]
    return stored?.first.flatMap(AppLanguage.init(rawValue:)) ?? .system
  }

  func apply(defaults: UserDefaults = .standard) {
    if self == .system {
      defaults.removeObject(forKey: AppLanguage.defaultsKey)
    } else {
      defaults.set([rawValue], forKey: AppLanguage.defaultsKey)
    }
  }
}
