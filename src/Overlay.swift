import AppKit

struct OverlayStatus: Equatable {
    enum Level: Equatable {
        case active
        case disabled
        case noNotch
        case paused
    }

    var level: Level
    var displays: Int

    static let disabled = OverlayStatus(level: .disabled, displays: 0)
}

final class BarView: NSView {
    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        bounds.fill()
    }
}

final class OverlayWindow: NSWindow {
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class OverlayController {
    private var windows: [CGDirectDisplayID: OverlayWindow] = [:]
    private(set) var status = OverlayStatus.disabled


    private static func displayID(_ screen: NSScreen) -> CGDirectDisplayID {
        (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }

    static func isFullScreenApp(on screen: NSScreen) -> Bool {
        guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements],
                                                       kCGNullWindowID) as? [[String: Any]] else { return false }
        let referenceMaxY = NSScreen.screens.first(where: { $0.frame.origin == .zero })?.frame.maxY ?? screen.frame.maxY
        let flippedY = referenceMaxY - screen.frame.maxY

        for window in windows {
            guard let layer = window[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
            guard let dict = window[kCGWindowBounds as String] as? [String: CGFloat] else { continue }
            let rect = CGRect(x: dict["X"] ?? -1, y: dict["Y"] ?? -1,
                              width: dict["Width"] ?? 0, height: dict["Height"] ?? 0)
            if abs(rect.minX - screen.frame.minX) < 1,
               abs(rect.minY - flippedY) < 1,
               abs(rect.width - screen.frame.width) < 1,
               abs(rect.height - screen.frame.height) < 1 {
                return true
            }
        }
        return false
    }

    func hideAll() {
        for (_, window) in windows { window.orderOut(nil) }
        windows.removeAll()
    }

    private func makeWindow(frame: NSRect) -> OverlayWindow {
        let window = OverlayWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isMovable = false
        window.isReleasedWhenClosed = false
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) - 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]
        window.animationBehavior = .none

        let view = BarView(frame: NSRect(origin: .zero, size: frame.size))
        view.autoresizingMask = [.width, .height]
        window.contentView = view
        return window
    }

    @discardableResult
    func refresh() -> OverlayStatus {
        let settings = AppSettings.shared

        guard settings.enabled else {
            hideAll()
            status = .disabled
            return status
        }

        var alive = Set<CGDirectDisplayID>()
        var applied = 0
        var sawNotch = false
        var paused = false

        for screen in NSScreen.screens {
            let id = Self.displayID(screen)
            let barHeight = screen.safeAreaInsets.top
            guard barHeight > 0 else { continue }
            sawNotch = true

            let menuBarVisible = screen.visibleFrame.maxY < screen.frame.maxY - 0.5
            if settings.hideInFullScreen && (!menuBarVisible || Self.isFullScreenApp(on: screen)) {
                paused = true
                continue
            }

            let frame = NSRect(x: screen.frame.minX,
                               y: screen.frame.maxY - barHeight,
                               width: screen.frame.width,
                               height: barHeight)

            alive.insert(id)
            applied += 1


            if let existing = windows[id], existing.frame == frame {
                if !existing.isVisible { existing.orderFrontRegardless() }
            } else {
                windows[id]?.orderOut(nil)
                let window = makeWindow(frame: frame)
                windows[id] = window
                window.orderFrontRegardless()
            }
        }

        let stale = windows.keys.filter { !alive.contains($0) }
        for id in stale {
            windows[id]?.orderOut(nil)
            windows.removeValue(forKey: id)
        }

        if !sawNotch {
            status = OverlayStatus(level: .noNotch, displays: 0)
        } else if applied == 0 && paused {
            status = OverlayStatus(level: .paused, displays: 0)
        } else {
            status = OverlayStatus(level: .active, displays: applied)
        }
        return status
    }
}
