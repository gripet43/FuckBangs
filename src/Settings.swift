import Foundation
import AppKit
import SwiftUI

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let store = UserDefaults.standard

    var didChange: (() -> Void)?

    @Published var enabled: Bool {
        didSet { store.set(enabled, forKey: Keys.enabled); didChange?() }
    }

    @Published var hideInFullScreen: Bool {
        didSet { store.set(hideInFullScreen, forKey: Keys.hideInFullScreen); didChange?() }
    }

    @Published var showInDock: Bool {
        didSet { store.set(showInDock, forKey: Keys.showInDock); didChange?() }
    }

    @Published var showInStatusBar: Bool {
        didSet { store.set(showInStatusBar, forKey: Keys.showInStatusBar); didChange?() }
    }

    @Published var cornerEnabled: Bool {
        didSet { store.set(cornerEnabled, forKey: Keys.cornerEnabled); didChange?() }
    }

    @Published var cornerRadius: Double {
        didSet { store.set(cornerRadius, forKey: Keys.cornerRadius); didChange?() }
    }

    private enum Keys {
        static let enabled = "enabled"
        static let hideInFullScreen = "hideInFullScreen"
        static let showInDock = "showInDock"
        static let showInStatusBar = "showInStatusBar"
        static let cornerEnabled = "cornerEnabled"
        static let cornerRadius = "cornerRadius"
    }

    private init() {
        store.register(defaults: [
            Keys.enabled: true,
            Keys.hideInFullScreen: true,
            Keys.showInDock: true,
            Keys.showInStatusBar: true,
            Keys.cornerEnabled: true,
            Keys.cornerRadius: 40.0
        ])
        enabled = Self.boolValue(store, Keys.enabled, fallback: true)
        hideInFullScreen = Self.boolValue(store, Keys.hideInFullScreen, fallback: true)
        showInDock = Self.boolValue(store, Keys.showInDock, fallback: true)
        showInStatusBar = Self.boolValue(store, Keys.showInStatusBar, fallback: true)
        cornerEnabled = Self.boolValue(store, Keys.cornerEnabled, fallback: true)

        let storedRadius = store.object(forKey: Keys.cornerRadius) != nil ? store.double(forKey: Keys.cornerRadius) : 40
        cornerRadius = min(max(storedRadius, 8), 48)
    }

    private static func boolValue(_ store: UserDefaults, _ key: String, fallback: Bool) -> Bool {
        guard let number = store.object(forKey: key) as? NSNumber else { return fallback }
        return number.boolValue
    }
}

enum AppInfo {
    static let name = "干掉刘海"
    static let version = "1.3.1"
    static let bundleID = "com.gripet.notchblack"
}

enum EntryGuard {
    static func allowHidingStatusBar(_ settings: AppSettings) -> Bool {
        guard !settings.showInDock else { return true }
        return confirm()
    }

    static func allowHidingDock(_ settings: AppSettings) -> Bool {
        guard !settings.showInStatusBar else { return true }
        return confirm()
    }

    private static func confirm() -> Bool {
        let alert = NSAlert()
        alert.messageText = "隐藏所有入口？"
        alert.informativeText = "状态栏图标和程序坞图标都将关闭，之后只能通过 Spotlight 搜索“\(AppInfo.name)”来重新打开设置。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "隐藏")
        alert.addButton(withTitle: "取消")
        return alert.runModal() == .alertFirstButtonReturn
    }
}

extension AppSettings {
    var statusBarToggleBinding: Binding<Bool> {
        Binding(
            get: { self.showInStatusBar },
            set: { on in
                if on {
                    self.showInStatusBar = true
                } else if EntryGuard.allowHidingStatusBar(self) {
                    self.showInStatusBar = false
                }
            }
        )
    }

    var dockToggleBinding: Binding<Bool> {
        Binding(
            get: { self.showInDock },
            set: { on in
                if on {
                    self.showInDock = true
                } else if EntryGuard.allowHidingDock(self) {
                    self.showInDock = false
                }
            }
        )
    }
}
