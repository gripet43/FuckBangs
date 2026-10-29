import AppKit
import SwiftUI

final class StatusPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class StatusPanelController {
    private var panel: StatusPanel?
    private weak var anchorButton: NSStatusBarButton?
    private var lastHide = Date.distantPast
    private var shownAt = Date.distantPast
    private var observers: [NSObjectProtocol] = []
    private var keyMonitor: Any?

    var isShown: Bool { panel?.isVisible ?? false }

    func attach(button: NSStatusBarButton,
                model: AppModel,
                settings: AppSettings,
                openSettings: @escaping () -> Void,
                quit: @escaping () -> Void) {
        anchorButton = button
        guard panel == nil else { return }

        let root = QuickPanelView(settings: settings,
                                  model: model,
                                  openSettings: openSettings,
                                  quit: quit)
        let hosting = NSHostingView(rootView: root)
        hosting.setFrameSize(hosting.fittingSize)

        let panel = StatusPanel(contentRect: NSRect(origin: .zero, size: hosting.fittingSize),
                                styleMask: [.borderless],
                                backing: .buffered,
                                defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovable = false
        panel.isReleasedWhenClosed = false
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)))
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.contentView = hosting

        self.panel = panel

        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
                self?.dismiss()
            })

        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
                self?.dismiss()
            })

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53, let self, self.isShown else { return event }
            self.dismiss()
            return nil
        }
    }

    func toggle() {
        if isShown {
            dismiss()
            return
        }
        if Date().timeIntervalSince(lastHide) < 0.22 { return }
        present()
    }

    func present() {
        guard let panel, let button = anchorButton, let window = button.window else { return }

        NSApp.activate(ignoringOtherApps: true)

        let buttonRect = window.convertToScreen(button.convert(button.bounds, to: nil))
        let size = panel.frame.size
        let screen = window.screen ?? NSScreen.main

        var x = buttonRect.midX - size.width / 2
        if let frame = screen?.frame {
            x = min(max(x, frame.minX + 8), frame.maxX - size.width - 8)
        }
        let y = buttonRect.minY - size.height - 4

        panel.setFrameOrigin(NSPoint(x: x.rounded(), y: y.rounded()))
        shownAt = Date()
        panel.makeKeyAndOrderFront(nil)

        if ProcessInfo.processInfo.environment["NB_DEBUG"] != nil {
            let message = "[NB] panel at \(panel.frame) button \(buttonRect)"
            FileHandle.standardError.write(Data((message + "\n").utf8))
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                let state = "[NB] visible: \(self?.panel?.isVisible ?? false) key: \(self?.panel?.isKeyWindow ?? false) appActive: \(NSApp.isActive)"
                FileHandle.standardError.write(Data((state + "\n").utf8))
            }
        }
    }

    func dismiss() {
        guard let panel, panel.isVisible else { return }
        if Date().timeIntervalSince(shownAt) < 0.2 { return }
        panel.orderOut(nil)
        lastHide = Date()
    }
}
