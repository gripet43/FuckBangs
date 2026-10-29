import AppKit

// 干掉刘海 应用图标
// 设计意图：一块屏幕，顶部被一条整宽的黑填平——表达"刘海被干掉"的结果，
// 而不是"屏幕上有个刘海"。黑条足够厚，16px 下仍可辨认。

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

// 底板
let body = CGRect(x: 88, y: 88, width: 848, height: 848)
let squircle = CGPath(roundedRect: body, cornerWidth: 192, cornerHeight: 192, transform: nil)

ctx.saveGState()
ctx.addPath(squircle)
ctx.clip()
let bgColors = [NSColor(srgbRed: 0.988, green: 0.988, blue: 0.996, alpha: 1).cgColor,
                NSColor(srgbRed: 0.898, green: 0.902, blue: 0.918, alpha: 1).cgColor] as CFArray
let bgGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                            colors: bgColors, locations: [0, 1])!
ctx.drawLinearGradient(bgGradient,
                       start: CGPoint(x: 512, y: 936),
                       end: CGPoint(x: 512, y: 88),
                       options: [])
ctx.restoreGState()

ctx.addPath(squircle)
ctx.setLineWidth(3)
ctx.setStrokeColor(NSColor(srgbRed: 0.18, green: 0.18, blue: 0.22, alpha: 0.16).cgColor)
ctx.strokePath()

// 屏幕
let screen = CGRect(x: 148, y: 210, width: 728, height: 604)
let screenPath = CGPath(roundedRect: screen, cornerWidth: 56, cornerHeight: 56, transform: nil)

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -10),
              blur: 34,
              color: NSColor(srgbRed: 0.1, green: 0.1, blue: 0.2, alpha: 0.22).cgColor)
ctx.addPath(screenPath)
ctx.setFillColor(NSColor.white.cgColor)
ctx.fillPath()
ctx.restoreGState()

// 屏幕里的壁纸（呼应真实使用场景的紫到橙）
ctx.saveGState()
ctx.addPath(screenPath)
ctx.clip()
let wpColors = [NSColor(srgbRed: 0.42, green: 0.28, blue: 0.52, alpha: 1).cgColor,
                NSColor(srgbRed: 0.64, green: 0.30, blue: 0.42, alpha: 1).cgColor,
                NSColor(srgbRed: 0.96, green: 0.47, blue: 0.18, alpha: 1).cgColor] as CFArray
let wpGradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                            colors: wpColors, locations: [0, 0.55, 1])!
ctx.drawLinearGradient(wpGradient,
                       start: CGPoint(x: screen.midX, y: screen.maxY),
                       end: CGPoint(x: screen.midX, y: screen.minY),
                       options: [])

// 顶部整宽黑条：刘海被填平
let bandHeight: CGFloat = 196
let band = CGRect(x: screen.minX, y: screen.maxY - bandHeight,
                  width: screen.width, height: bandHeight)
ctx.setFillColor(NSColor(srgbRed: 0.031, green: 0.031, blue: 0.039, alpha: 1).cgColor)
ctx.fill(band)
ctx.restoreGState()

NSGraphicsContext.restoreGraphicsState()

let data = rep.representation(using: .png, properties: [:])!
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/AppIcon-1024.png"
try! data.write(to: URL(fileURLWithPath: out))
print("wrote", out)
