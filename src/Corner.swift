import AppKit

final class CornerView: NSView {
    /// 正文区域的圆角半径，四个角一致
    var radius: CGFloat = 40 {
        didSet { if oldValue != radius { needsDisplay = true } }
    }

    /// 顶部状态栏高度：正文区域从这条线以下开始
    var topInset: CGFloat = 0 {
        didSet { if oldValue != topInset { needsDisplay = true } }
    }

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        guard radius > 0, bounds.height > topInset else { return }

        let contentRect = NSRect(x: 0,
                                 y: 0,
                                 width: bounds.width,
                                 height: bounds.height - topInset)

        let path = NSBezierPath(rect: bounds)
        path.append(NSBezierPath(roundedRect: contentRect, xRadius: radius, yRadius: radius))
        path.windingRule = .evenOdd
        NSColor.black.setFill()
        path.fill()
    }
}

final class CornerController {
    private var windows: [CGDirectDisplayID: NSWindow] = [:]
    private var views: [CGDirectDisplayID: CornerView] = [:]

    private static func displayID(_ screen: NSScreen) -> CGDirectDisplayID {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }

    func hideAll() {
        for (_, window) in windows { window.orderOut(nil) }
        windows.removeAll()
        views.removeAll()
    }

    private func makeWindow(frame: NSRect, radius: CGFloat, topInset: CGFloat) -> (NSWindow, CornerView) {
        let window = NSWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.level = NSWindow.Level(rawValue: -1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.animationBehavior = .none

        let view = CornerView(frame: NSRect(origin: .zero, size: frame.size))
        view.autoresizingMask = [.width, .height]
        view.radius = radius
        view.topInset = topInset
        window.contentView = view
        return (window, view)
    }

    @discardableResult
    func refresh() -> Bool {
        let settings = AppSettings.shared

        guard settings.enabled, settings.cornerEnabled, settings.cornerRadius > 0 else {
            hideAll()
            return false
        }

        let radius = CGFloat(settings.cornerRadius)
        var alive = Set<CGDirectDisplayID>()

        for screen in NSScreen.screens {
            let id = Self.displayID(screen)
            guard CGDisplayIsBuiltin(id) != 0 else { continue }

            alive.insert(id)
            let frame = screen.frame
            let topInset = screen.safeAreaInsets.top

            if let window = windows[id], let view = views[id] {
                if window.frame != frame {
                    window.setFrame(frame, display: true)
                    view.frame = NSRect(origin: .zero, size: frame.size)
                    view.needsDisplay = true
                }
                view.radius = radius
                view.topInset = topInset
                if !window.isVisible { window.orderFrontRegardless() }
            } else {
                let (window, view) = makeWindow(frame: frame, radius: radius, topInset: topInset)
                windows[id] = window
                views[id] = view
                window.orderFrontRegardless()
                view.needsDisplay = true
            }
        }

        let stale = windows.keys.filter { !alive.contains($0) }
        for id in stale {
            windows[id]?.orderOut(nil)
            windows.removeValue(forKey: id)
            views.removeValue(forKey: id)
        }
        return !windows.isEmpty
    }
}
