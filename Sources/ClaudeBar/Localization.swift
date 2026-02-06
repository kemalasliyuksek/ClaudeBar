import Foundation

/// Supported app languages with native display names
enum AppLanguage: String, CaseIterable {
    case system = "system"
    case en = "en"
    case tr = "tr"
    case zhHans = "zh-Hans"
    case es = "es"
    case ru = "ru"

    var displayName: String {
        switch self {
        case .system: return L("settings.language.system")
        case .en: return "English"
        case .tr: return "Türkçe"
        case .zhHans: return "中文"
        case .es: return "Español"
        case .ru: return "Русский"
        }
    }
}

/// Returns the override bundle for the selected language, or nil for system default
private func overrideBundle() -> Bundle? {
    let code = UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
    guard code != "system" else { return nil }

    if let path = Bundle.module.path(forResource: code, ofType: "lproj"),
       let bundle = Bundle(path: path) {
        return bundle
    }

    let bundlePath = Bundle.module.bundlePath
    let candidates = [code, code.lowercased()]
    for candidate in candidates {
        let lprojPath = (bundlePath as NSString).appendingPathComponent("\(candidate).lproj")
        if FileManager.default.fileExists(atPath: lprojPath),
           let bundle = Bundle(path: lprojPath) {
            return bundle
        }
    }

    return nil
}

/// Returns the active locale based on user's language selection
func activeLocale() -> Locale {
    let code = UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
    guard code != "system" else { return .current }
    return Locale(identifier: code)
}

/// Localized string lookup with language override support
func L(_ key: String) -> String {
    let bundle = overrideBundle() ?? Bundle.module
    return NSLocalizedString(key, bundle: bundle, comment: "")
}

/// Localized string with format arguments
func L(_ key: String, _ args: CVarArg...) -> String {
    let bundle = overrideBundle() ?? Bundle.module
    let format = NSLocalizedString(key, bundle: bundle, comment: "")
    return String(format: format, arguments: args)
}
