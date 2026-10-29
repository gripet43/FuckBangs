import AppKit

let size = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                           pixelsWide: size, pixelsHigh: size,
                           bitsPerSample: 8, samplesPerPixel: 4,
                           hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

let body = CGRect(x: 96, y: 96, width: 832, height: 832)
let squircle = CGPath(roundedRect: body, cornerWidth: 188, cornerHeight: 188, transform: nil)

ctx.saveGState()
ctx.addPath(squircle)
ctx.clip()
let colors = [NSColor(srgbRed: 0.984, green: 0.984, blue: 0.992, alpha: 1).cgColor,
              NSColor(srgbRed: 0.882, green: 0.886, blue: 0.906, alpha: 1).cgColor] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
ctx.drawLinearGradient(gradient,
                       start: CGPoint(x: 512, y: 928),
                       end: CGPoint(x: 512, y: 96),
                       options: [])
ctx.restoreGState()

ctx.addPath(squircle)
ctx.setLineWidth(3)
ctx.setStrokeColor(NSColor(srgbRed: 0.20, green: 0.20, blue: 0.24, alpha: 0.18).cgColor)
ctx.strokePath()

let x0: CGFloat = 312, x1: CGFloat = 712
let yTop: CGFloat = 928, yBot: CGFloat = 700
let r: CGFloat = 64

ctx.saveGState()
ctx.addPath(squircle)
ctx.clip()


let notch = CGMutablePath()
notch.move(to: CGPoint(x: x0, y: yTop))
notch.addLine(to: CGPoint(x: x0, y: yBot + r))
notch.addQuadCurve(to: CGPoint(x: x0 + r, y: yBot), control: CGPoint(x: x0, y: yBot))
notch.addLine(to: CGPoint(x: x1 - r, y: yBot))
notch.addQuadCurve(to: CGPoint(x: x1, y: yBot + r), control: CGPoint(x: x1, y: yBot))
notch.addLine(to: CGPoint(x: x1, y: yTop))
notch.closeSubpath()

ctx.addPath(notch)
ctx.setFillColor(NSColor(srgbRed: 0.055, green: 0.055, blue: 0.066, alpha: 1).cgColor)
ctx.fillPath()

ctx.restoreGState()

NSGraphicsContext.restoreGraphicsState()

let data = rep.representation(using: .png, properties: [:])!
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/AppIcon-1024.png"
try! data.write(to: URL(fileURLWithPath: out))
print("wrote", out)
