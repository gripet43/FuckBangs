import AppKit
import ServiceManagement

enum SelfTest {
    static func run() {
        print("== \(AppInfo.name) 自检 \(AppInfo.version) ==")
        print("bundle:", Bundle.main.bundlePath)
        print("id:", Bundle.main.bundleIdentifier ?? "nil")

        for screen in NSScreen.screens {
            let aux = screen.auxiliaryTopLeftArea
            let menuBarVisible = screen.visibleFrame.maxY < screen.frame.maxY - 0.5
            print("screen:", screen.localizedName,
                  "frame:", screen.frame,
                  "visible:", screen.visibleFrame,
                  "safeTop:", screen.safeAreaInsets.top,
                  "notchWidth:", aux.map { screen.frame.width - $0.width * 2 } ?? -1,
                  "menuBarVisible:", menuBarVisible,
                  "fullScreenWindow:", OverlayController.isFullScreenApp(on: screen))
        }

        print("loginItem.status(before):", statusText(SMAppService.mainApp.status))
        do {
            try SMAppService.mainApp.register()
            print("loginItem.register: ok")
        } catch {
            print("loginItem.register: FAILED ->", error.localizedDescription)
        }
        print("loginItem.status(after register):", statusText(SMAppService.mainApp.status))
        do {
            try SMAppService.mainApp.unregister()
            print("loginItem.unregister: ok")
        } catch {
            print("loginItem.unregister: FAILED ->", error.localizedDescription)
        }
        print("loginItem.status(after unregister):", statusText(SMAppService.mainApp.status))
        print("== 结束 ==")
    }

    private static func statusText(_ status: SMAppService.Status) -> String {
        switch status {
        case .enabled: return "enabled"
        case .notRegistered: return "notRegistered"
        case .notFound: return "notFound"
        case .requiresApproval: return "requiresApproval"
        @unknown default: return "unknown(\(status.rawValue))"
        }
    }
}
