import AppKit
import SwiftUI

enum Theme {
    static let cornerRadius: CGFloat = 22
    static let windowWidth: CGFloat = 440

    static let cardRadius: CGFloat = 12
    static let rowHeight: CGFloat = 44
    static let hPadding: CGFloat = 16
}

struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .popover
    var blending: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blending
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blending
    }
}

enum AppGlyph {
    static func statusBarIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        let body = NSRect(x: 1.4, y: 3.6, width: 15.2, height: 10.8)
        let outline = NSBezierPath(roundedRect: body, xRadius: 3, yRadius: 3)
        outline.lineWidth = 1.3
        NSColor.black.setStroke()
        outline.stroke()

        let tab = NSBezierPath(roundedRect: NSRect(x: 6.7, y: 12.6, width: 4.6, height: 3.4),
                               xRadius: 1.5, yRadius: 1.5)
        NSColor.black.setFill()
        tab.fill()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
