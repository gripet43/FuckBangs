import AppKit
import SwiftUI

final class PanelWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class PanelWindowController {
    private var window: PanelWindow?
    private var escMonitor: Any?
    private let model: AppModel
    private let settings: AppSettings

    private let positionKey = "panelOrigin"

    init(model: AppModel, settings: AppSettings) {
        self.model = model
        self.settings = settings
    }

    func show() {
        if window == nil { build() }
        guard let w = window else { return }
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
        w.orderFrontRegardless()
    }

    func close() {
        persistPosition()
        window?.orderOut(nil)
    }

    var isVisible: Bool { window?.isVisible ?? false }

    private func build() {
        let root = RootView(settings: settings, model: model, onClose: { [weak self] in self?.close() })
        let hosting = NSHostingView(rootView: root)
        let size = hosting.fittingSize

        let w = PanelWindow(contentRect: NSRect(origin: .zero, size: size),
                            styleMask: [.borderless],
                            backing: .buffered,
                            defer: false)
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = true
        w.isMovableByWindowBackground = true
        w.isReleasedWhenClosed = false
        w.collectionBehavior = [.fullScreenAuxiliary]
        w.contentView = hosting

        if let saved = savedOrigin(for: size) {
            w.setFrameOrigin(saved)
        } else {
            w.center()
        }

        window = w

        escMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53,
                  let self, let win = self.window, win.isKeyWindow else { return event }
            self.close()
            return nil
        }
    }

    private func savedOrigin(for size: NSSize) -> NSPoint? {
        guard let raw = UserDefaults.standard.string(forKey: positionKey) else { return nil }
        let point = NSPointFromString(raw)
        guard point.x.isFinite, point.y.isFinite else { return nil }
        let rect = NSRect(origin: point, size: size)
        let visible = NSScreen.screens.contains { $0.visibleFrame.contains(rect) }
        return visible ? point : nil
    }

    private func persistPosition() {
        guard let origin = window?.frame.origin else { return }
        UserDefaults.standard.set(NSStringFromPoint(origin), forKey: positionKey)
    }
}
