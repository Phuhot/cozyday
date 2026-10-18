import SwiftUI
import UIKit

enum PetMood: Equatable {
    case idle
    case happy
    case focus
    case rest

    var label: String {
        switch self {
        case .idle: return "đang thư giãn"
        case .happy: return "đang vui"
        case .focus: return "đang tập trung cùng bạn"
        case .rest: return "đang nghỉ ngơi"
        }
    }
}

extension GraphicsContext {
    func ellipse(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: Color) {
        fill(Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h)), with: .color(color))
    }

    func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: Color, radius: CGFloat = 0) {
        fill(Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: radius), with: .color(color))
    }

    func polygon(_ points: [CGPoint], _ color: Color) {
        var p = Path()
        p.addLines(points)
        p.closeSubpath()
        fill(p, with: .color(color))
    }

    func strokePath(_ color: Color, width: CGFloat, _ build: (inout Path) -> Void) {
        var p = Path()
        build(&p)
        stroke(p, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ color: Color) {
        ellipse(cx - r, cy - r, r * 2, r * 2, color)
    }

    /// Vẽ trong hệ tọa độ đã xoay quanh một điểm.
    func rotated(_ degrees: Double, around c: CGPoint, _ draw: (GraphicsContext) -> Void) {
        var ctx = self
        ctx.translateBy(x: c.x, y: c.y)
        ctx.rotate(by: .degrees(degrees))
        ctx.translateBy(x: -c.x, y: -c.y)
        draw(ctx)
    }

    func heart(center c: CGPoint, size s: CGFloat, _ color: Color) {
        var p = Path()
        p.move(to: CGPoint(x: c.x, y: c.y + s * 0.35))
        p.addCurve(to: CGPoint(x: c.x - s * 0.5, y: c.y - s * 0.1),
                   control1: CGPoint(x: c.x - s * 0.1, y: c.y + s * 0.1), control2: CGPoint(x: c.x - s * 0.5, y: c.y + s * 0.15))
        p.addArc(center: CGPoint(x: c.x - s * 0.25, y: c.y - s * 0.12), radius: s * 0.25,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addArc(center: CGPoint(x: c.x + s * 0.25, y: c.y - s * 0.12), radius: s * 0.25,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addCurve(to: CGPoint(x: c.x, y: c.y + s * 0.35),
                   control1: CGPoint(x: c.x + s * 0.5, y: c.y + s * 0.15), control2: CGPoint(x: c.x + s * 0.1, y: c.y + s * 0.1))
        fill(p, with: .color(color))
    }
}

private func rgb(_ hex: UInt32) -> Color { Color(UIColor(hex: hex)) }

/// Bảng màu của từng màu lông. Màu nhân vật cố định, không đổi theo dark mode để giữ nhận diện.
struct FurPalette {
    let base: Color
    let shade: Color
    let belly: Color
    let inner: Color
    let eye: Color

    static func of(_ fur: FurColor) -> FurPalette {
        switch fur {
        case .cream: return FurPalette(base: Palette.catCream, shade: Palette.catShade, belly: Palette.catShade, inner: Palette.blush, eye: Palette.catInk)
        case .snow: return FurPalette(base: rgb(0xFBFAF8), shade: rgb(0xE4DFEA), belly: rgb(0xEDE9F1), inner: Palette.blush, eye: Palette.catInk)
        case .ginger: return FurPalette(base: rgb(0xF2B27A), shade: rgb(0xE0925A), belly: rgb(0xFBE3C8), inner: rgb(0xF4A9A0), eye: Palette.catInk)
        case .smoke: return FurPalette(base: rgb(0xBDB9C8), shade: rgb(0x9F9AAE), belly: rgb(0xE0DDE7), inner: rgb(0xF0B4BC), eye: Palette.catInk)
        case .cocoa: return FurPalette(base: rgb(0xB0805F), shade: rgb(0x8E6247), belly: rgb(0xDDBFA6), inner: rgb(0xE9A9A0), eye: rgb(0x2E2430))
        case .peach: return FurPalette(base: rgb(0xF8CBC4), shade: rgb(0xEDA9A2), belly: rgb(0xFCE5E1), inner: rgb(0xF08C9A), eye: Palette.catInk)
        case .midnight: return FurPalette(base: rgb(0x433D50), shade: rgb(0x302B3B), belly: rgb(0x5C5669), inner: rgb(0xC98A9A), eye: rgb(0xF0C26A))
        case .lilac: return FurPalette(base: rgb(0xD3C1EE), shade: rgb(0xB59FDB), belly: rgb(0xEBE1F8), inner: rgb(0xF2A9C4), eye: Palette.catInk)
        }
    }
}

/// Tư thế tại một thời điểm — do PetView tính theo thời gian; bản tĩnh dùng giá trị mặc định.
struct PetPose: Equatable {
    /// −1…1: thở (co giãn nhẹ theo chiều dọc).
    var breath: CGFloat = 0
    var blink = false
    /// −1…1: vẫy đuôi.
    var tail: CGFloat = 0
    /// 0…1: giật tai.
    var ear: CGFloat = 0
    /// Độ cao khi nhảy (đơn vị 100×100).
    var hop: CGFloat = 0
    /// Nghiêng người (độ).
    var tilt: Double = 0
    /// −1…1: liếc mắt.
    var look: CGFloat = 0
    /// Pha bước chân khi đang đi (radian), nil = đứng yên.
    var walk: CGFloat?
    /// 0…1: tim bay lên sau khi được vuốt ve; nil = không có.
    var hearts: CGFloat?
    /// 0…1: pha chữ "z" khi ngủ.
    var z: CGFloat = 0
}

/// Thú cưng của Cozyday — vẽ hoàn toàn bằng code trong hệ tọa độ 100×100, theo lớp:
/// đuôi → áo choàng → tai → thân → áo → mặt → kính → cổ → mũ → chân → hiệu ứng.
struct PetArt: View {
    var mood: PetMood
    var appearance = PetAppearance()
    var pose = PetPose()

    var body: some View {
        Canvas { context, size in
            var ctx = context
            ctx.scaleBy(x: size.width / 100, y: size.height / 100)
            draw(in: ctx)
        }
        .accessibilityHidden(true)
    }

    private var stageScale: CGFloat {
        switch appearance.stage {
        case .little: return 0.80
        case .growing: return 0.91
        case .grown: return 1.0
        }
    }

    private var eyeScale: CGFloat {
        switch appearance.stage {
        case .little: return 1.22
        case .growing: return 1.08
        case .grown: return 1.0
        }
    }

    private func draw(in base: GraphicsContext) {
        let fur = FurPalette.of(appearance.fur)
        let anchor = CGPoint(x: 50, y: 88)

        // Bóng: nhỏ lại khi nhảy lên.
        let shadowW = 56 * stageScale * max(0.6, 1 - pose.hop / 30)
        base.ellipse(50 - shadowW / 2, 84, shadowW, 9, Color.black.opacity(0.10))

        var ctx = base
        ctx.translateBy(x: 0, y: -pose.hop)
        ctx.translateBy(x: anchor.x, y: anchor.y)
        ctx.rotate(by: .degrees(pose.tilt))
        ctx.scaleBy(x: stageScale * (1 - pose.breath * 0.008), y: stageScale * (1 + pose.breath * 0.022))
        ctx.translateBy(x: -anchor.x, y: -anchor.y)

        drawTail(ctx, fur)
        if appearance.outfit == "outfit.cape" { drawCapeBack(ctx) }
        drawEars(ctx, fur)
        let bodyFrame = bodyRect
        ctx.fill(Path(ellipseIn: bodyFrame), with: .color(fur.base))
        if appearance.species == .fox {
            ctx.ellipse(31, 56, 38, 30, rgb(0xFFF8F0))
        } else {
            ctx.ellipse(33, 58, 34, 27, fur.belly)
        }
        if let outfit = appearance.outfit { drawOutfit(ctx, outfit, body: bodyFrame) }
        drawFace(ctx, fur)
        if let glasses = appearance.glasses { drawGlasses(ctx, glasses) }
        if let neck = appearance.neck { drawNeck(ctx, neck) }
        if let hat = appearance.hat { drawHat(ctx, hat) }
        drawPaws(ctx, fur)
        drawMoodExtras(ctx)
        drawHearts(base)
    }

    private var bodyRect: CGRect {
        appearance.species == .hamster ? CGRect(x: 13, y: 32, width: 74, height: 56) : CGRect(x: 16, y: 28, width: 68, height: 60)
    }

    // MARK: Đuôi

    private func drawTail(_ ctx: GraphicsContext, _ fur: FurPalette) {
        let t = pose.tail
        switch appearance.species {
        case .cat:
            ctx.strokePath(fur.shade, width: 7) { p in
                p.move(to: CGPoint(x: 74, y: 78))
                p.addQuadCurve(to: CGPoint(x: 88 + t * 5, y: 56 - abs(t) * 2), control: CGPoint(x: 95 + t * 2, y: 76))
            }
        case .fox:
            ctx.rotated(-38 + Double(t) * 9, around: CGPoint(x: 72, y: 80)) { c in
                c.ellipse(70, 46, 22, 40, fur.base)
                c.ellipse(74, 44, 14, 14, rgb(0xFFF8F0))
            }
        case .bunny:
            ctx.circle(80 + t * 1.5, 78, 8, fur.belly)
        case .bear:
            ctx.circle(81 + t, 80, 5, fur.shade)
        case .hamster:
            break
        }
    }

    // MARK: Tai

    private func drawEars(_ ctx: GraphicsContext, _ fur: FurPalette) {
        let twitch = Double(pose.ear) * -10
        switch appearance.species {
        case .cat:
            ctx.rotated(twitch, around: CGPoint(x: 34, y: 40)) { c in
                c.polygon([CGPoint(x: 24, y: 44), CGPoint(x: 27, y: 18), CGPoint(x: 45, y: 32)], fur.base)
                c.polygon([CGPoint(x: 29, y: 38), CGPoint(x: 30, y: 25), CGPoint(x: 40, y: 32)], fur.inner)
            }
            ctx.polygon([CGPoint(x: 76, y: 44), CGPoint(x: 73, y: 18), CGPoint(x: 55, y: 32)], fur.base)
            ctx.polygon([CGPoint(x: 71, y: 38), CGPoint(x: 70, y: 25), CGPoint(x: 60, y: 32)], fur.inner)
        case .bunny:
            ctx.rotated(-14 + twitch * 1.4, around: CGPoint(x: 38, y: 36)) { c in
                c.ellipse(30, 2, 14, 38, fur.base)
                c.ellipse(34, 8, 6, 26, fur.inner)
            }
            ctx.rotated(14, around: CGPoint(x: 62, y: 36)) { c in
                c.ellipse(56, 2, 14, 38, fur.base)
                c.ellipse(60, 8, 6, 26, fur.inner)
            }
        case .hamster:
            ctx.rotated(twitch, around: CGPoint(x: 27, y: 36)) { c in
                c.circle(27, 33, 7, fur.base)
                c.circle(27, 33, 4, fur.inner)
            }
            ctx.circle(73, 33, 7, fur.base)
            ctx.circle(73, 33, 4, fur.inner)
        case .bear:
            ctx.rotated(twitch, around: CGPoint(x: 27, y: 36)) { c in
                c.circle(27, 32, 10, fur.base)
                c.circle(27, 32, 5.5, fur.shade)
            }
            ctx.circle(73, 32, 10, fur.base)
            ctx.circle(73, 32, 5.5, fur.shade)
        case .fox:
            let tip = rgb(0x5A4038)
            ctx.rotated(twitch, around: CGPoint(x: 32, y: 40)) { c in
                c.polygon([CGPoint(x: 19, y: 46), CGPoint(x: 21, y: 10), CGPoint(x: 46, y: 31)], fur.base)
                c.polygon([CGPoint(x: 20.4, y: 21), CGPoint(x: 21, y: 10), CGPoint(x: 29, y: 17)], tip)
                c.polygon([CGPoint(x: 25, y: 39), CGPoint(x: 25, y: 22), CGPoint(x: 39, y: 32)], fur.inner)
            }
            ctx.polygon([CGPoint(x: 81, y: 46), CGPoint(x: 79, y: 10), CGPoint(x: 54, y: 31)], fur.base)
            ctx.polygon([CGPoint(x: 79.6, y: 21), CGPoint(x: 79, y: 10), CGPoint(x: 71, y: 17)], tip)
            ctx.polygon([CGPoint(x: 75, y: 39), CGPoint(x: 75, y: 22), CGPoint(x: 61, y: 32)], fur.inner)
        }
    }

    // MARK: Mặt

    private func drawFace(_ ctx: GraphicsContext, _ fur: FurPalette) {
        let ink = fur.eye
        let line = appearance.fur == .midnight ? rgb(0xF4E6CF) : Palette.catInk
        switch appearance.species {
        case .fox:
            ctx.ellipse(17, 53, 24, 16, rgb(0xFFF8F0))
            ctx.ellipse(59, 53, 24, 16, rgb(0xFFF8F0))
        case .bear:
            ctx.ellipse(39, 52, 22, 15, fur.belly)
        case .hamster:
            ctx.ellipse(13, 50, 22, 18, fur.belly)
            ctx.ellipse(65, 50, 22, 18, fur.belly)
        default:
            break
        }

        let f = eyeScale
        let dx = pose.look * 1.3
        let left = CGPoint(x: 37.5 + dx, y: 50)
        let right = CGPoint(x: 62.5 + dx, y: 50)
        let closed = pose.blink && (mood == .idle || mood == .happy)
        switch mood {
        case .idle where !closed:
            for c in [left, right] {
                ctx.ellipse(c.x - 2.5 * f, c.y - 3.3 * f, 5 * f, 6.5 * f, ink)
                ctx.circle(c.x - 0.6 * f, c.y - 1.6 * f, 0.9 * f, .white)
            }
        case .idle:
            ctx.strokePath(line, width: 2.2) { p in
                for c in [left, right] {
                    p.move(to: CGPoint(x: c.x - 3.5, y: c.y)); p.addLine(to: CGPoint(x: c.x + 3.5, y: c.y))
                }
            }
        case .happy:
            ctx.strokePath(line, width: 2.4) { p in
                for c in [left, right] {
                    p.move(to: CGPoint(x: c.x - 4.5, y: c.y + 2)); p.addQuadCurve(to: CGPoint(x: c.x + 4.5, y: c.y + 2), control: CGPoint(x: c.x, y: c.y - 6 * f))
                }
            }
        case .focus:
            ctx.strokePath(line, width: 2.4) { p in
                p.move(to: CGPoint(x: left.x - 4.5, y: 51)); p.addLine(to: CGPoint(x: left.x + 4.5, y: 52))
                p.move(to: CGPoint(x: right.x - 4.5, y: 52)); p.addLine(to: CGPoint(x: right.x + 4.5, y: 51))
            }
        case .rest:
            ctx.strokePath(line, width: 2.4) { p in
                for c in [left, right] {
                    p.move(to: CGPoint(x: c.x - 4.5, y: c.y)); p.addQuadCurve(to: CGPoint(x: c.x + 4.5, y: c.y), control: CGPoint(x: c.x, y: c.y + 5))
                }
            }
        }
        // má hồng
        let blush = Palette.blush.opacity(mood == .happy ? 1 : 0.75)
        ctx.ellipse(26, 55, 8, 4.5, blush)
        ctx.ellipse(66, 55, 8, 4.5, blush)
        // mũi + miệng
        let nose: CGFloat = appearance.species == .bear ? 1.6 : 1
        ctx.polygon([CGPoint(x: 50 - 1.5 * nose, y: 55), CGPoint(x: 50 + 1.5 * nose, y: 55), CGPoint(x: 50, y: 55 + 2 * nose)], line)
        ctx.strokePath(line, width: 1.4) { p in
            p.move(to: CGPoint(x: 46, y: 58)); p.addQuadCurve(to: CGPoint(x: 50, y: 58), control: CGPoint(x: 48, y: 61))
            p.addQuadCurve(to: CGPoint(x: 54, y: 58), control: CGPoint(x: 52, y: 61))
        }
        if appearance.species == .bunny || appearance.species == .hamster {
            ctx.rect(48.4, 59.5, 3.2, 3, .white, radius: 0.8)
        }
    }

    // MARK: Kính

    private func drawGlasses(_ ctx: GraphicsContext, _ id: String) {
        let frame = rgb(0x3E3550)
        switch id {
        case "glasses.round":
            ctx.strokePath(frame, width: 1.5) { p in
                p.addEllipse(in: CGRect(x: 30, y: 42.5, width: 15, height: 15))
                p.addEllipse(in: CGRect(x: 55, y: 42.5, width: 15, height: 15))
                p.move(to: CGPoint(x: 45, y: 49)); p.addQuadCurve(to: CGPoint(x: 55, y: 49), control: CGPoint(x: 50, y: 46))
                p.move(to: CGPoint(x: 30, y: 48)); p.addLine(to: CGPoint(x: 21, y: 46))
                p.move(to: CGPoint(x: 70, y: 48)); p.addLine(to: CGPoint(x: 79, y: 46))
            }
        case "glasses.sun":
            ctx.rect(28, 44, 19, 11, rgb(0x2B2833), radius: 4.5)
            ctx.rect(53, 44, 19, 11, rgb(0x2B2833), radius: 4.5)
            ctx.strokePath(rgb(0x2B2833), width: 1.6) { p in
                p.move(to: CGPoint(x: 47, y: 47)); p.addLine(to: CGPoint(x: 53, y: 47))
            }
            ctx.strokePath(Color.white.opacity(0.45), width: 1.2) { p in
                p.move(to: CGPoint(x: 31, y: 47)); p.addLine(to: CGPoint(x: 35, y: 46))
                p.move(to: CGPoint(x: 56, y: 47)); p.addLine(to: CGPoint(x: 60, y: 46))
            }
        case "glasses.heart":
            ctx.heart(center: CGPoint(x: 37.5, y: 50), size: 17, rgb(0xF27D9B).opacity(0.85))
            ctx.heart(center: CGPoint(x: 62.5, y: 50), size: 17, rgb(0xF27D9B).opacity(0.85))
            ctx.strokePath(rgb(0xD9667A), width: 1.4) { p in
                p.move(to: CGPoint(x: 45, y: 48)); p.addLine(to: CGPoint(x: 55, y: 48))
            }
        case "glasses.monocle":
            ctx.strokePath(rgb(0xD9A441), width: 1.8) { p in
                p.addEllipse(in: CGRect(x: 54.5, y: 42, width: 16, height: 16))
            }
            ctx.strokePath(rgb(0xD9A441), width: 0.9) { p in
                p.move(to: CGPoint(x: 69, y: 55)); p.addQuadCurve(to: CGPoint(x: 72, y: 72), control: CGPoint(x: 76, y: 62))
            }
        default:
            break
        }
    }

    // MARK: Cổ

    private func drawNeck(_ ctx: GraphicsContext, _ id: String) {
        switch id {
        case "neck.scarf":
            let red = rgb(0xD9667A)
            ctx.rect(22, 62, 56, 8, red, radius: 4)
            ctx.rotated(8, around: CGPoint(x: 60, y: 66)) { c in
                c.rect(56, 65, 9, 17, red, radius: 3)
                c.rect(56, 76, 9, 2, Color.white.opacity(0.7))
            }
            ctx.rect(30, 64.5, 2, 3, Color.white.opacity(0.7))
            ctx.rect(42, 64.5, 2, 3, Color.white.opacity(0.7))
        case "neck.bowtie":
            let c = Palette.lavender
            ctx.polygon([CGPoint(x: 39, y: 61), CGPoint(x: 39, y: 72), CGPoint(x: 50, y: 66.5)], c)
            ctx.polygon([CGPoint(x: 61, y: 61), CGPoint(x: 61, y: 72), CGPoint(x: 50, y: 66.5)], c)
            ctx.circle(50, 66.5, 2.8, rgb(0x6F5AB8))
        case "neck.bell":
            ctx.rect(26, 62, 48, 4.5, rgb(0xC2565A), radius: 2.2)
            ctx.circle(50, 70, 4.2, rgb(0xF0C26A))
            ctx.rect(46.5, 70, 7, 1, rgb(0xB8862E))
            ctx.circle(50, 72.3, 0.9, rgb(0xB8862E))
        case "neck.bandana":
            let blue = rgb(0x6FA3D9)
            ctx.polygon([CGPoint(x: 29, y: 62), CGPoint(x: 71, y: 62), CGPoint(x: 50, y: 80)], blue)
            for (x, y) in [(40.0, 66.0), (50.0, 65.0), (60.0, 66.0), (45.0, 71.0), (55.0, 71.0), (50.0, 76.0)] {
                ctx.circle(x, y, 1.1, Color.white.opacity(0.9))
            }
        case "neck.lei":
            let colors = [rgb(0xF2A3B8), rgb(0xF0C26A), Color.white, rgb(0xC8A6F0)]
            for i in 0..<9 {
                let x = 27 + CGFloat(i) * 5.75
                let y = 62 + 5 * (1 - pow((x - 50) / 23, 2))
                ctx.circle(x, y, 3.3, colors[i % colors.count])
                ctx.circle(x, y, 1, rgb(0xE0925A))
            }
        default:
            break
        }
    }

    // MARK: Áo

    private func drawCapeBack(_ ctx: GraphicsContext) {
        ctx.polygon([CGPoint(x: 22, y: 60), CGPoint(x: 78, y: 60), CGPoint(x: 93, y: 90), CGPoint(x: 7, y: 90)], rgb(0xC2565A))
    }

    private func drawOutfit(_ ctx: GraphicsContext, _ id: String, body: CGRect) {
        var clipped = ctx
        clipped.clip(to: Path(ellipseIn: body))
        switch id {
        case "outfit.sweater":
            let green = rgb(0x8DB890)
            clipped.rect(0, 64, 100, 40, green)
            clipped.rect(0, 64, 100, 3.5, rgb(0x6F9A72))
            clipped.rect(0, 73, 100, 3, Color.white.opacity(0.55))
            clipped.rect(0, 80, 100, 3, Color.white.opacity(0.55))
        case "outfit.overalls":
            let denim = rgb(0x6F8FC9)
            clipped.rect(0, 77, 100, 20, denim)
            clipped.rect(36, 65, 28, 16, denim, radius: 3)
            clipped.rect(44, 69, 12, 7, rgb(0x5A78B0), radius: 1.5)
            ctx.strokePath(denim, width: 3) { p in
                p.move(to: CGPoint(x: 38, y: 67)); p.addLine(to: CGPoint(x: 31, y: 61))
                p.move(to: CGPoint(x: 62, y: 67)); p.addLine(to: CGPoint(x: 69, y: 61))
            }
            ctx.circle(39, 67, 1.4, rgb(0xF0C26A))
            ctx.circle(61, 67, 1.4, rgb(0xF0C26A))
        case "outfit.raincoat":
            let yellow = rgb(0xF2C14E)
            clipped.rect(0, 62, 100, 40, yellow)
            ctx.polygon([CGPoint(x: 36, y: 61), CGPoint(x: 50, y: 61), CGPoint(x: 43, y: 68)], rgb(0xE0A92E))
            ctx.polygon([CGPoint(x: 64, y: 61), CGPoint(x: 50, y: 61), CGPoint(x: 57, y: 68)], rgb(0xE0A92E))
            ctx.circle(50, 71, 1.6, rgb(0x3E3550))
            ctx.circle(50, 77, 1.6, rgb(0x3E3550))
        case "outfit.cape":
            ctx.circle(50, 64, 3, rgb(0xF0C26A))
            ctx.strokePath(rgb(0xC2565A), width: 3) { p in
                p.move(to: CGPoint(x: 47, y: 64)); p.addLine(to: CGPoint(x: 27, y: 60))
                p.move(to: CGPoint(x: 53, y: 64)); p.addLine(to: CGPoint(x: 73, y: 60))
            }
        default:
            break
        }
    }

    // MARK: Mũ

    private func drawHat(_ ctx: GraphicsContext, _ id: String) {
        let top: CGFloat = appearance.species == .hamster ? 32 : 28
        let dy = top - 28
        var c = ctx
        c.translateBy(x: 0, y: dy)
        switch id {
        case "hat.sprout":
            c.strokePath(rgb(0x5E8A61), width: 1.4) { p in
                p.move(to: CGPoint(x: 50, y: 30)); p.addLine(to: CGPoint(x: 50, y: 22))
            }
            c.rotated(-20, around: CGPoint(x: 50, y: 22)) { r in r.ellipse(46, 10, 8, 13, Palette.sage) }
            c.rotated(35, around: CGPoint(x: 50, y: 24)) { r in r.ellipse(50, 17, 5, 8, Palette.sage.opacity(0.85)) }
        case "hat.bow":
            let pink = rgb(0xF2A3B8)
            c.polygon([CGPoint(x: 24, y: 26), CGPoint(x: 24, y: 38), CGPoint(x: 33, y: 32)], pink)
            c.polygon([CGPoint(x: 42, y: 26), CGPoint(x: 42, y: 38), CGPoint(x: 33, y: 32)], pink)
            c.circle(33, 32, 2.8, rgb(0xE07F98))
        case "hat.party":
            c.polygon([CGPoint(x: 38, y: 33), CGPoint(x: 50, y: 4), CGPoint(x: 62, y: 33)], Palette.lavender)
            c.strokePath(rgb(0xF0C26A), width: 2) { p in
                p.move(to: CGPoint(x: 43, y: 22)); p.addLine(to: CGPoint(x: 55, y: 18))
                p.move(to: CGPoint(x: 40, y: 30)); p.addLine(to: CGPoint(x: 59, y: 25))
            }
            c.circle(50, 4.5, 3.5, rgb(0xF2A3B8))
        case "hat.beanie":
            var dome = c
            dome.clip(to: Path(CGRect(x: 0, y: 0, width: 100, height: 34)))
            dome.ellipse(24, 13, 52, 44, rgb(0xD9667A))
            c.rect(23, 29, 54, 7, rgb(0xC2565A), radius: 3.5)
            c.circle(50, 13, 5, Color.white)
        case "hat.flower":
            let spots: [(CGFloat, CGFloat)] = [(28, 36), (34, 30), (42, 26.5), (50, 25.5), (58, 26.5), (66, 30), (72, 36)]
            for (i, s) in spots.enumerated() {
                c.circle(s.0, s.1, 4, i % 2 == 0 ? Color.white : rgb(0xF0C26A))
                c.circle(s.0, s.1, 1.4, i % 2 == 0 ? rgb(0xF0C26A) : rgb(0xE0925A))
            }
        case "hat.straw":
            let straw = rgb(0xE8C77E)
            c.ellipse(12, 27, 76, 11, straw)
            c.rect(30, 12, 40, 21, rgb(0xDDB766), radius: 9)
            c.rect(30, 25, 40, 4, rgb(0xD9667A))
        case "hat.wizard":
            let purple = rgb(0x5B4B8A)
            c.ellipse(24, 27, 52, 8, purple)
            c.polygon([CGPoint(x: 35, y: 31), CGPoint(x: 60, y: -2), CGPoint(x: 66, y: 31)], purple)
            c.draw(Text("✦").font(.system(size: 6)).foregroundColor(rgb(0xF0C26A)), at: CGPoint(x: 53, y: 20))
            c.draw(Text("✦").font(.system(size: 4)).foregroundColor(rgb(0xF0C26A)), at: CGPoint(x: 58, y: 10))
        case "hat.crown":
            let gold = rgb(0xF0C26A)
            c.polygon([CGPoint(x: 33, y: 32), CGPoint(x: 33, y: 18), CGPoint(x: 39.5, y: 25), CGPoint(x: 45, y: 13),
                       CGPoint(x: 50, y: 22), CGPoint(x: 55, y: 13), CGPoint(x: 60.5, y: 25), CGPoint(x: 67, y: 18), CGPoint(x: 67, y: 32)], gold)
            c.circle(45, 13, 1.8, rgb(0xF27D9B))
            c.circle(55, 13, 1.8, rgb(0x6FA3D9))
            c.circle(50, 28, 2.2, rgb(0xD9667A))
        default:
            break
        }
    }

    // MARK: Chân & hiệu ứng

    private func drawPaws(_ ctx: GraphicsContext, _ fur: FurPalette) {
        let step = pose.walk.map { sin($0) * 2.2 } ?? 0
        ctx.ellipse(36, 80 - step, 10, 7, fur.base)
        ctx.ellipse(54, 80 + step, 10, 7, fur.base)
    }

    private func drawMoodExtras(_ ctx: GraphicsContext) {
        switch mood {
        case .focus:
            ctx.rect(36, 70, 28, 13, Palette.lavender, radius: 2)
            ctx.rect(49.5, 70, 1, 13, Color.white.opacity(0.7))
        case .rest:
            let z = pose.z
            ctx.draw(Text("z").font(.system(size: 9, weight: .bold, design: .rounded)).foregroundColor(Palette.lavender.opacity(Double(1 - z * 0.6))),
                     at: CGPoint(x: 80 + z * 4, y: 26 - z * 8))
            ctx.draw(Text("z").font(.system(size: 6, weight: .bold, design: .rounded)).foregroundColor(Palette.lavender.opacity(Double(0.4 + z * 0.6))),
                     at: CGPoint(x: 86 + z * 3, y: 16 - z * 6))
        case .happy:
            ctx.draw(Text("✦").font(.system(size: 8)).foregroundColor(Palette.honey), at: CGPoint(x: 15, y: 26))
            ctx.draw(Text("✦").font(.system(size: 6)).foregroundColor(Palette.honey), at: CGPoint(x: 86, y: 34))
        case .idle:
            break
        }
    }

    private func drawHearts(_ ctx: GraphicsContext) {
        guard let p = pose.hearts else { return }
        let fade = Double(max(0, 1 - p))
        let xs: [CGFloat] = [36, 50, 64]
        for (i, x) in xs.enumerated() {
            let k = CGFloat(i)
            let rise: CGFloat = p * 26 + CGFloat(i % 2) * 4
            let sway: CGFloat = sin(p * 6 + k) * 2
            let size: CGFloat = 7 + CGFloat(i % 2) * 2
            ctx.heart(center: CGPoint(x: x + sway, y: 26 - rise), size: size, rgb(0xF27D9B).opacity(fade))
        }
    }
}

/// Thú cưng có chuyển động: thở, chớp mắt, vẫy đuôi, giật tai, liếc nhìn, nhảy khi vui;
/// chạm vào (nếu `interactive`) thì thả tim, rung nhẹ và nói một câu.
/// Bật Giảm chuyển động: đứng yên hoàn toàn, vẫn chạm và nói được.
struct PetView: View {
    var appearance = PetAppearance()
    var mood: PetMood
    var name: String
    var bounceTrigger: Int = 0
    var walking = false
    var facingLeft = false
    var interactive = false
    var haptics = true
    /// Câu nói khi được chạm (số lần chạm → câu).
    var speech: ((Int) -> String)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var hopStart: Date?
    @State private var heartsStart: Date?
    @State private var bubble: String?
    @State private var taps = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { timeline in
            PetArt(mood: mood, appearance: appearance, pose: reduceMotion ? PetPose() : pose(at: timeline.date))
                .scaleEffect(x: facingLeft ? -1 : 1, y: 1)
        }
        .overlay(alignment: .top) {
            if let bubble {
                SpeechBubble(text: bubble)
                    .frame(width: 180)
                    .alignmentGuide(.top) { $0[.bottom] + 2 }
                    .transition(.scale(scale: 0.8, anchor: .bottom).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { if interactive { tapped() } }
        .sensoryFeedback(trigger: taps) { _, _ in haptics ? .impact(weight: .light) : nil }
        .onChange(of: bounceTrigger) { _, _ in hopStart = Date() }
        .accessibilityElement()
        .accessibilityLabel("\(appearance.species.name.capitalized) \(name), \(mood.label)")
        .accessibilityAddTraits(interactive ? .isButton : [])
        .accessibilityHint(interactive ? "Chạm để vuốt ve" : "")
        .accessibilityAction { if interactive { tapped() } }
    }

    private func tapped() {
        taps += 1
        hopStart = Date()
        heartsStart = Date()
        guard let speech else { return }
        let line = speech(taps - 1)
        withAnimation(Motion.quick) { bubble = line }
        UIAccessibility.post(notification: .announcement, argument: line)
        let token = taps
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_200_000_000)
            if taps == token { withAnimation(Motion.quick) { bubble = nil } }
        }
    }

    private func pose(at date: Date) -> PetPose {
        let t = date.timeIntervalSince(start)
        var p = PetPose()
        p.breath = CGFloat(sin(t * 2 * .pi / 3.2))
        p.blink = t.truncatingRemainder(dividingBy: 4.3) < 0.14
        p.tail = CGFloat(sin(t * 2 * .pi / (mood == .happy ? 0.9 : 1.9)))
        let earPhase = t.truncatingRemainder(dividingBy: 6.7)
        p.ear = earPhase < 0.3 ? CGFloat(sin(earPhase / 0.3 * .pi)) : 0
        p.look = mood == .focus ? 0 : CGFloat(sin(t / 3.1) * 0.8)
        if mood == .happy { p.tilt = sin(t * 2 * .pi / 1.6) * 3 }
        if walking {
            p.walk = CGFloat(t * 2 * .pi / 0.55)
            p.hop = abs(sin(t * 2 * .pi / 0.55)) * 1.6
        }
        if let h = hopStart {
            let d = date.timeIntervalSince(h)
            if d >= 0 && d < 0.7 { p.hop = CGFloat(abs(sin(d / 0.35 * .pi))) * 9 }
        }
        if let hs = heartsStart {
            let d = date.timeIntervalSince(hs)
            if d >= 0 && d < 1.4 { p.hearts = CGFloat(d / 1.4) }
        }
        p.z = CGFloat((t / 2.4).truncatingRemainder(dividingBy: 1))
        return p
    }
}

struct SpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Typography.caption.weight(.semibold))
            .foregroundStyle(Palette.ink)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.s)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.m, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radius.m, style: .continuous).strokeBorder(Palette.line))
            .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
    }
}
