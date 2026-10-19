@_exported import Foundation

// SwiftUI giả để vẽ ra SVG trên Linux (chỉ phục vụ xem trước hình vẽ).

public struct UIColor {
    public let hex: UInt32
    public init(hex: UInt32, alpha: CGFloat = 1) { self.hex = hex }
}

public struct Color: Equatable {
    public var r: Double, g: Double, b: Double, a: Double
    public init(r: Double, g: Double, b: Double, a: Double) { self.r = r; self.g = g; self.b = b; self.a = a }
    public init(hex: UInt32) {
        self.init(r: Double((hex >> 16) & 0xFF), g: Double((hex >> 8) & 0xFF), b: Double(hex & 0xFF), a: 1)
    }
    public init(_ ui: UIColor) { self.init(hex: ui.hex) }
    public init(red: Double, green: Double, blue: Double, opacity: Double = 1) { self.init(r: red * 255, g: green * 255, b: blue * 255, a: opacity) }
    public init(white: Double, opacity: Double = 1) { self.init(r: white * 255, g: white * 255, b: white * 255, a: opacity) }
    public static let white = Color(hex: 0xFFFFFF), black = Color(hex: 0x000000), clear = Color(r: 0, g: 0, b: 0, a: 0)
    public static let red = Color(hex: 0xFF3B30), yellow = Color(hex: 0xFFCC00), orange = Color(hex: 0xFF9500), pink = Color(hex: 0xFF2D55)
    public static let green = Color(hex: 0x34C759), blue = Color(hex: 0x007AFF), purple = Color(hex: 0xAF52DE), brown = Color(hex: 0xA2845E), gray = Color(hex: 0x8E8E93)
    public func opacity(_ o: Double) -> Color { Color(r: r, g: g, b: b, a: a * o) }
    public static func dynamic(light: UInt32, dark: UInt32) -> Color { Color(hex: light) }
    var css: String { "rgba(\(Int(r)),\(Int(g)),\(Int(b)),\(a))" }
}
public enum Palette {
    public static let background = Color(hex: 0xFEF6EC)
    public static let surface = Color(hex: 0xFFFDF8)
    public static let surfaceMuted = Color(hex: 0xF6EDE0)
    public static let line = Color(hex: 0xE8DCCB)
    public static let ink = Color(hex: 0x3E3550)
    public static let inkMuted = Color(hex: 0x786E87)
    public static let lavender = Color(hex: 0x8D78CF)
    public static let lavenderSoft = Color(hex: 0xECE6FA)
    public static let sage = Color(hex: 0x6F9A72)
    public static let sageSoft = Color(hex: 0xE4EFE2)
    public static let peach = Color(hex: 0xE59A7A)
    public static let honey = Color(hex: 0xD9A441)
    public static let danger = Color(hex: 0xC2565A)
    public static let nowLine = Color(hex: 0xD9667A)
    public static let onAccent = Color(hex: 0xFFFFFF)
    public static let catCream = Color(hex: 0xFCF1DE)
    public static let catShade = Color(hex: 0xEEDCC2)
    public static let catInk = Color(hex: 0x4A3C5C)
    public static let blush = Color(hex: 0xF4B0B0)
    public static let wood = Color(hex: 0xC89B6D)
    public static let woodDark = Color(hex: 0xA07448)
    public static let roomWall = Color(hex: 0xF3E9F7)
    public static let roomFloor = Color(hex: 0xEAD9C3)
}

public struct Angle {
    public var radians: Double
    public static func degrees(_ d: Double) -> Angle { Angle(radians: d * .pi / 180) }
    public static func radians(_ r: Double) -> Angle { Angle(radians: r) }
}

public enum CGLineCap { case butt, round, square }
public enum CGLineJoin { case miter, round, bevel }
public struct StrokeStyle {
    var lineWidth: CGFloat, lineCap: CGLineCap, lineJoin: CGLineJoin, dash: [CGFloat]
    public init(lineWidth: CGFloat = 1, lineCap: CGLineCap = .butt, lineJoin: CGLineJoin = .miter, miterLimit: CGFloat = 10, dash: [CGFloat] = [], dashPhase: CGFloat = 0) {
        self.lineWidth = lineWidth; self.lineCap = lineCap; self.lineJoin = lineJoin; self.dash = dash
    }
}
public enum RoundedCornerStyle { case circular, continuous }

enum PathOp {
    case move(CGPoint), line(CGPoint), quad(CGPoint, CGPoint), cubic(CGPoint, CGPoint, CGPoint), close
}

public struct Path {
    var ops: [PathOp] = []
    var cur: CGPoint = .zero
    var startPt: CGPoint = .zero
    public init() {}
    public init(_ rect: CGRect) { addRect(rect) }
    public init(ellipseIn rect: CGRect) { addEllipse(in: rect) }
    public init(roundedRect rect: CGRect, cornerRadius: CGFloat, style: RoundedCornerStyle = .circular) {
        addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
    }
    public init(roundedRect rect: CGRect, cornerSize: CGSize, style: RoundedCornerStyle = .circular) {
        addRoundedRect(in: rect, cornerSize: cornerSize)
    }
    public init(_ build: (inout Path) -> Void) { build(&self) }
    public mutating func move(to p: CGPoint) { ops.append(.move(p)); cur = p; startPt = p }
    public mutating func addLine(to p: CGPoint) { if ops.isEmpty { move(to: p); return }; ops.append(.line(p)); cur = p }
    public mutating func addLines(_ ps: [CGPoint]) { guard let f = ps.first else { return }; move(to: f); for p in ps.dropFirst() { addLine(to: p) } }
    public mutating func addQuadCurve(to p: CGPoint, control: CGPoint) { ops.append(.quad(control, p)); cur = p }
    public mutating func addCurve(to p: CGPoint, control1: CGPoint, control2: CGPoint) { ops.append(.cubic(control1, control2, p)); cur = p }
    public mutating func addArc(center: CGPoint, radius: CGFloat, startAngle: Angle, endAngle: Angle, clockwise: Bool) {
        var a0 = startAngle.radians, a1 = endAngle.radians
        if !clockwise { while a1 < a0 { a1 += 2 * .pi } } else { while a1 > a0 { a1 -= 2 * .pi } }
        let n = max(4, Int(abs(a1 - a0) / (.pi / 24)))
        for i in 0...n {
            let a = a0 + (a1 - a0) * Double(i) / Double(n)
            let p = CGPoint(x: center.x + radius * cos(a), y: center.y + radius * sin(a))
            if i == 0 && !ops.isEmpty { addLine(to: p) } else if i == 0 { move(to: p) } else { addLine(to: p) }
        }
    }
    public mutating func addEllipse(in r: CGRect) {
        let n = 48
        for i in 0...n {
            let a = Double(i) / Double(n) * 2 * .pi
            let p = CGPoint(x: r.midX + r.width / 2 * cos(a), y: r.midY + r.height / 2 * sin(a))
            if i == 0 { move(to: p) } else { addLine(to: p) }
        }
        closeSubpath()
    }
    public mutating func addRect(_ r: CGRect) {
        addLines([CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY), CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.minX, y: r.maxY)])
        closeSubpath()
    }
    public mutating func addRoundedRect(in r: CGRect, cornerSize: CGSize, style: RoundedCornerStyle = .circular) {
        let rx = min(cornerSize.width, r.width / 2), ry = min(cornerSize.height, r.height / 2)
        if rx <= 0 || ry <= 0 { addRect(r); return }
        let corners: [(CGPoint, Double)] = [
            (CGPoint(x: r.maxX - rx, y: r.minY + ry), -Double.pi / 2), (CGPoint(x: r.maxX - rx, y: r.maxY - ry), 0),
            (CGPoint(x: r.minX + rx, y: r.maxY - ry), Double.pi / 2), (CGPoint(x: r.minX + rx, y: r.minY + ry), Double.pi)
        ]
        var first = true
        for (c, a0) in corners {
            for i in 0...8 {
                let a = a0 + Double.pi / 2 * Double(i) / 8
                let p = CGPoint(x: c.x + rx * cos(a), y: c.y + ry * sin(a))
                if first { move(to: p); first = false } else { addLine(to: p) }
            }
        }
        closeSubpath()
    }
    public mutating func addPath(_ p: Path) { ops += p.ops; cur = p.cur }
    public mutating func closeSubpath() { ops.append(.close); cur = startPt }
    public var boundingRect: CGRect { .zero }
    public var currentPoint: CGPoint? { ops.isEmpty ? nil : cur }
}

public struct Font {
    var size: CGFloat = 12, bold = false
    public enum Weight { case ultraLight, thin, light, regular, medium, semibold, bold, heavy, black }
    public enum Design { case `default`, serif, rounded, monospaced }
    public static func system(size: CGFloat, weight: Weight = .regular, design: Design = .default) -> Font {
        Font(size: size, bold: weight == .bold || weight == .heavy || weight == .black || weight == .semibold)
    }
}
public struct Text {
    var s: String, font = Font(), color = Color.black
    public init(_ s: String) { self.s = s }
    public func font(_ f: Font?) -> Text { var c = self; if let f { c.font = f }; return c }
    public func foregroundColor(_ col: Color?) -> Text { var c = self; if let col { c.color = col }; return c }
    public func bold() -> Text { var c = self; c.font.bold = true; return c }
}
public struct Gradient {
    var colors: [Color]
    public init(colors: [Color]) { self.colors = colors }
}

/// Bộ ghi SVG.
public final class SVGRecorder {
    public var body = ""
    var defs = ""
    var clipCount = 0
    public let width: Int, height: Int
    public init(width: Int, height: Int) { self.width = width; self.height = height }
    public var svg: String {
        "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\(width)\" height=\"\(height)\" viewBox=\"0 0 \(width) \(height)\"><defs>\(defs)</defs>\(body)</svg>"
    }
}

struct Affine {
    var a = 1.0, b = 0.0, c = 0.0, d = 1.0, tx = 0.0, ty = 0.0
    func apply(_ p: CGPoint) -> CGPoint { CGPoint(x: a * p.x + c * p.y + tx, y: b * p.x + d * p.y + ty) }
    func then(_ m: Affine) -> Affine { // self rồi m? (m áp dụng trước trong hệ cục bộ)
        Affine(a: m.a * a + m.b * c, b: m.a * b + m.b * d, c: m.c * a + m.d * c, d: m.c * b + m.d * d,
               tx: m.tx * a + m.ty * c + tx, ty: m.tx * b + m.ty * d + ty)
    }
    var scale: Double { sqrt(abs(a * d - b * c)) }
}

func f(_ v: CGFloat) -> String { String(format: "%.2f", Double(v)) }

public struct GraphicsContext {
    public struct Shading {
        var fill: String
        var grad: ((GraphicsContext) -> String)? = nil
        public static func color(_ c: Color) -> Shading { Shading(fill: c.css) }
        static func stops(_ g: Gradient) -> String {
            let n = max(1, g.colors.count - 1)
            return g.colors.enumerated().map { i, c in
                "<stop offset=\"\(Double(i) / Double(n))\" stop-color=\"rgb(\(Int(c.r)),\(Int(c.g)),\(Int(c.b)))\" stop-opacity=\"\(c.a)\"/>"
            }.joined()
        }
        public static func linearGradient(_ g: Gradient, startPoint: CGPoint, endPoint: CGPoint) -> Shading {
            Shading(fill: (g.colors.first ?? .black).css, grad: { ctx in
                ctx.rec.clipCount += 1
                let id = "g\(ctx.rec.clipCount)"
                let a = ctx.m.apply(startPoint), b = ctx.m.apply(endPoint)
                ctx.rec.defs += "<linearGradient id=\"\(id)\" gradientUnits=\"userSpaceOnUse\" x1=\"\(f(a.x))\" y1=\"\(f(a.y))\" x2=\"\(f(b.x))\" y2=\"\(f(b.y))\">\(stops(g))</linearGradient>"
                return "url(#\(id))"
            })
        }
        public static func radialGradient(_ g: Gradient, center: CGPoint, startRadius: CGFloat, endRadius: CGFloat) -> Shading {
            Shading(fill: (g.colors.first ?? .black).css, grad: { ctx in
                ctx.rec.clipCount += 1
                let id = "g\(ctx.rec.clipCount)"
                let c = ctx.m.apply(center), r = endRadius * ctx.m.scale
                let fr = endRadius > 0 ? Double(startRadius / endRadius) : 0
                let n = max(1, g.colors.count - 1)
                let st = g.colors.enumerated().map { i, col in
                    "<stop offset=\"\(fr + (1 - fr) * Double(i) / Double(n))\" stop-color=\"rgb(\(Int(col.r)),\(Int(col.g)),\(Int(col.b)))\" stop-opacity=\"\(col.a)\"/>"
                }.joined()
                ctx.rec.defs += "<radialGradient id=\"\(id)\" gradientUnits=\"userSpaceOnUse\" cx=\"\(f(c.x))\" cy=\"\(f(c.y))\" r=\"\(f(r))\">\(st)</radialGradient>"
                return "url(#\(id))"
            })
        }
        func paint(_ ctx: GraphicsContext) -> String { grad?(ctx) ?? fill }
    }
    public enum BlendMode { case normal, multiply, screen, overlay, plusLighter }
    public var opacity: Double = 1
    public var blendMode: BlendMode = .normal
    let rec: SVGRecorder
    var m = Affine()
    var clipID: String?
    public init(recorder: SVGRecorder) { rec = recorder }

    func d(_ p: Path) -> String {
        var s = ""
        for op in p.ops {
            switch op {
            case .move(let q): let t = m.apply(q); s += "M\(f(t.x)) \(f(t.y)) "
            case .line(let q): let t = m.apply(q); s += "L\(f(t.x)) \(f(t.y)) "
            case .quad(let c1, let q): let a = m.apply(c1), t = m.apply(q); s += "Q\(f(a.x)) \(f(a.y)) \(f(t.x)) \(f(t.y)) "
            case .cubic(let c1, let c2, let q):
                let a = m.apply(c1), b = m.apply(c2), t = m.apply(q)
                s += "C\(f(a.x)) \(f(a.y)) \(f(b.x)) \(f(b.y)) \(f(t.x)) \(f(t.y)) "
            case .close: s += "Z "
            }
        }
        return s
    }
    var clipAttr: String { clipID.map { " clip-path=\"url(#\($0))\"" } ?? "" }
    public func fill(_ path: Path, with shading: Shading) {
        rec.body += "<path d=\"\(d(path))\" fill=\"\(shading.paint(self))\" opacity=\"\(opacity)\"\(clipAttr)/>"
    }
    public func stroke(_ path: Path, with shading: Shading, lineWidth: CGFloat = 1) {
        stroke(path, with: shading, style: StrokeStyle(lineWidth: lineWidth))
    }
    public func stroke(_ path: Path, with shading: Shading, style: StrokeStyle) {
        let cap = style.lineCap == .round ? "round" : style.lineCap == .square ? "square" : "butt"
        let join = style.lineJoin == .round ? "round" : style.lineJoin == .bevel ? "bevel" : "miter"
        let dash = style.dash.isEmpty ? "" : " stroke-dasharray=\"\(style.dash.map { f($0 * m.scale) }.joined(separator: ","))\""
        rec.body += "<path d=\"\(d(path))\" fill=\"none\" stroke=\"\(shading.paint(self))\" stroke-width=\"\(f(style.lineWidth * m.scale))\" stroke-linecap=\"\(cap)\" stroke-linejoin=\"\(join)\"\(dash) opacity=\"\(opacity)\"\(clipAttr)/>"
    }
    public mutating func clip(to path: Path) {
        rec.clipCount += 1
        let id = "c\(rec.clipCount)"
        rec.defs += "<clipPath id=\"\(id)\"\(clipAttr)><path d=\"\(d(path))\"/></clipPath>"
        clipID = id
    }
    public mutating func translateBy(x: CGFloat, y: CGFloat) { m = m.then(Affine(tx: x, ty: y)) }
    public mutating func rotate(by a: Angle) { m = m.then(Affine(a: cos(a.radians), b: sin(a.radians), c: -sin(a.radians), d: cos(a.radians))) }
    public mutating func scaleBy(x: CGFloat, y: CGFloat) { m = m.then(Affine(a: x, d: y)) }
    public func draw(_ text: Text, at p: CGPoint) {
        let t = m.apply(p)
        let esc = text.s.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
        rec.body += "<text x=\"\(f(t.x))\" y=\"\(f(t.y))\" font-size=\"\(f(text.font.size * m.scale))\" font-family=\"sans-serif\" font-weight=\"\(text.font.bold ? "bold" : "normal")\" text-anchor=\"middle\" dominant-baseline=\"central\" fill=\"\(text.color.css)\" opacity=\"\(opacity)\"\(clipAttr)>\(esc)</text>"
    }
    public func drawLayer(content: (inout GraphicsContext) throws -> Void) rethrows {
        var copy = self
        try content(&copy)
    }
}
