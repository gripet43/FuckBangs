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

        let body = NSRect(x: 1.5, y: 2.5, width: 15, height: 13)
        let radius: CGFloat = 3.5

        let outline = NSBezierPath(roundedRect: body, xRadius: radius, yRadius: radius)
        outline.lineWidth = 1.4
        NSColor.black.setStroke()
        outline.stroke()

        // 顶部整宽实心黑条：表达"刘海被填平"，而不是"屏幕上有个刘海"
        let bandHeight: CGFloat = 4.2
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: body, xRadius: radius, yRadius: radius).addClip()
        NSColor.black.setFill()
        NSRect(x: body.minX,
               y: body.maxY - bandHeight,
               width: body.width,
               height: bandHeight).fill()
        NSGraphicsContext.restoreGraphicsState()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
