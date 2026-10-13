import AppKit

let size = 1024
guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                   isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0),
      let context = NSGraphicsContext(bitmapImageRep: bitmap) else { fatalError("Icon context failed") }
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context

let outer = NSBezierPath(roundedRect: NSRect(x: 36, y: 36, width: 952, height: 952), xRadius: 218, yRadius: 218)
let gradient = NSGradient(starting: NSColor(calibratedRed: 0.06, green: 0.19, blue: 0.26, alpha: 1),
                          ending: NSColor(calibratedRed: 0.09, green: 0.39, blue: 0.49, alpha: 1))!
gradient.draw(in: outer, angle: 70)

let glow = NSBezierPath(ovalIn: NSRect(x: 240, y: 210, width: 540, height: 610))
NSColor(calibratedRed: 0.18, green: 0.77, blue: 0.79, alpha: 0.12).setFill()
glow.fill()

let heights: [CGFloat] = [130, 260, 390, 530, 650, 530, 390, 260, 130]
let width: CGFloat = 42
let gap: CGFloat = 39
let total = CGFloat(heights.count) * width + CGFloat(heights.count - 1) * gap
let start = (CGFloat(size) - total) / 2
for (index, height) in heights.enumerated() {
    let x = start + CGFloat(index) * (width + gap)
    let y = (CGFloat(size) - height) / 2
    let bar = NSBezierPath(roundedRect: NSRect(x: x, y: y, width: width, height: height), xRadius: width / 2, yRadius: width / 2)
    let color = index == 4 ? NSColor(calibratedRed: 0.99, green: 0.73, blue: 0.41, alpha: 1) : NSColor(calibratedRed: 0.88, green: 0.98, blue: 0.98, alpha: 1)
    color.setFill()
    bar.fill()
}

context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()
guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("Icon rendering failed") }
let output = URL(fileURLWithPath: CommandLine.arguments[1])
try png.write(to: output)
