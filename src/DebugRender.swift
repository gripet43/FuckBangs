import AppKit
import SwiftUI

enum DebugRender {
    static func run(directory: String) {
        let settings = AppSettings.shared
        let model = AppModel()
        model.status = OverlayStatus(level: .active, displays: 1)
        model.launchAtLogin = false

        let dark = ProcessInfo.processInfo.environment["NB_DARK"] != nil
        let scheme: ColorScheme = dark ? .dark : .light
        let suffix = dark ? "-dark" : ""

        render(QuickPanelView(settings: settings,
                              model: model,
                              openSettings: {},
                              quit: {})
                .environment(\.colorScheme, scheme),
               to: "\(directory)/quick\(suffix).png",
               dark: dark)

        render(RootView(settings: settings,
                        model: model,
                        onClose: {})
                .environment(\.colorScheme, scheme),
               to: "\(directory)/main\(suffix).png",
               dark: dark)
    }

    private static func render<V: View>(_ view: V, to path: String, dark: Bool) {
        let host = NSHostingView(rootView: view)
        let size = host.fittingSize
        host.frame = NSRect(origin: .zero, size: size)

        let container = NSView(frame: NSRect(origin: .zero, size: size))
        container.wantsLayer = true
        container.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        container.layer?.backgroundColor = (dark
            ? NSColor(white: 0.16, alpha: 1)
            : NSColor(white: 0.96, alpha: 1)).cgColor
        container.addSubview(host)
        host.layoutSubtreeIfNeeded()

        guard let rep = container.bitmapImageRepForCachingDisplay(in: container.bounds) else { return }
        container.cacheDisplay(in: container.bounds, to: rep)
        if let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: path))
            print("rendered \(Int(size.width))x\(Int(size.height)) ->", path)
        }
    }
}
