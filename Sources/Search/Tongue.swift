import SwiftUI

extension NSMenu {
    /// A menu of the menu bar, found by the words the code gives it. The menu
    /// bar wears the language the Mac speaks, so the words in the code and the
    /// words on screen part company the moment there is a language file — this
    /// asks for either.
    static func barItem(_ title: String) -> NSMenuItem? {
        NSApp.mainMenu?.items.first { $0.title == title || $0.title == title.saidNow }
    }
}

// The words on the screen, in whatever language the Mac speaks.
//
// English is not stored anywhere: a sentence's own words are the lookup key,
// and a language file beside the binary replaces the sentences it knows. A key
// no language has heard passes through untouched, which is why English needs
// no file at all — and why a translation can be added a page at a time. The
// tables live in ../Localization, copied into the app bundle by build.sh;
// LocalizedStringKey does the rest.
//
// Text(_:) and Button(_:) fed a string literal already look themselves up.
// `.said` is for the plainer path — a String carried in from the caller, or
// handed to a panel of our own — which SwiftUI otherwise draws as it was
// given. `.saidNow` is for the places the answer has to stay a String.

extension String {
    /// The sentence, as the screen reads it through the language files.
    var said: LocalizedStringKey { LocalizedStringKey(self) }

    /// The sentence already resolved to plain text — for the places a sentence
    /// must stay a String (a menu item's title, a window's, a panel's) rather
    /// than become a view. Looked up now, at the source, where the words are
    /// known to be the app's own and not some page's title.
    var saidNow: String { NSLocalizedString(self, value: self, comment: "") }

    /// A sentence built at runtime, filled in from a language file that holds
    /// the same sentence with `%@` where the values go. The English key and
    /// the English answer are the same words, so a sentence no language knows
    /// still reads as it always did.
    static func said(_ key: String, _ values: CVarArg...) -> String {
        let sentence = NSLocalizedString(key, value: key, comment: "")
        return values.isEmpty ? sentence : String(format: sentence, arguments: values)
    }
}

/// Which language those sentences come out in.
///
/// Following the Mac needs nothing: the system's own list of languages is
/// already what the bundle reads. A choice made here is the same
/// `AppleLanguages` entry System Settings writes per app, from inside the app —
/// which is why changing it wants a relaunch, and why the panel says so rather
/// than half-redrawing the screen it is standing on.
enum Tongue: String, CaseIterable, Identifiable {
    case system, english, chinese

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Follow Mac"
        case .english: return "English"
        case .chinese: return "简体中文"
        }
    }

    /// What this choice writes into the app's own defaults; nil means the
    /// Mac's list is left to speak for itself.
    var codes: [String]? {
        switch self {
        case .system: return nil
        case .english: return ["en"]
        case .chinese: return ["zh-Hans", "en"]
        }
    }

    /// The language the running process was drawn in. Taken once, at launch,
    /// because everything on screen was resolved then — asking the bundle later
    /// can answer about a language nothing is wearing yet.
    private(set) static var shown = "en"

    static func remember() { shown = Bundle.main.preferredLocalizations.first ?? "en" }

    func write() {
        if let codes {
            UserDefaults.standard.set(codes, forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
    }

    /// True while the screen still shows a language this choice has moved on
    /// from — the moment a relaunch is worth offering.
    var pending: Bool {
        switch self {
        case .english: return !Tongue.shown.hasPrefix("en")
        case .chinese: return !Tongue.shown.hasPrefix("zh")
        case .system:
            let forced = UserDefaults.standard.persistentDomain(forName: Bundle.main.bundleIdentifier ?? "")?["AppleLanguages"] != nil
            return forced || !Tongue.shown.hasPrefix((Locale.preferredLanguages.first ?? "en").prefix(2))
        }
    }
}
