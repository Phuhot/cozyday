import SwiftUI
import UIKit

// Phần vẽ thú cưng thuần túy (không có View) — để có thể kiểm tra kiểu cả ngoài Xcode.

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

/// Màu cố định (không đổi theo dark mode) cho hình vẽ.
func rgb(_ hex: UInt32) -> Color { Color(UIColor(hex: hex)) }

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
        case .honey: return FurPalette(base: rgb(0xF7D27A), shade: rgb(0xE8B44E), belly: rgb(0xFCEBC0), inner: rgb(0xF4A9A0), eye: Palette.catInk)
        case .mint: return FurPalette(base: rgb(0xA9DDB8), shade: rgb(0x82C497), belly: rgb(0xDDF3E2), inner: rgb(0xF2A9B4), eye: Palette.catInk)
        case .sky: return FurPalette(base: rgb(0xAFCFF2), shade: rgb(0x88B2E3), belly: rgb(0xDDEBFA), inner: rgb(0xF2A9C4), eye: Palette.catInk)
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
    /// 0…1: đang được nựng (mắt híp, má đỏ hơn, tai cụp).
    var petted: CGFloat = 0
    /// Đang được nhấc lên (mắt tròn ngạc nhiên, chân lủng lẳng).
    var lifted = false
}

/// Vẽ thú cưng trong hệ tọa độ 100×100, theo lớp:
/// đuôi → đồ sau lưng → áo choàng → tai → thân → áo → mặt → kính → cổ → mũ → chân → đồ cầm trước → hiệu ứng.
struct PetPainter {
    var mood: PetMood
    var appearance: PetAppearance
    var pose: PetPose

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

    func draw(in base: GraphicsContext) {
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
        if let back = appearance.back { CostumeArt.back(back, ctx, appearance, front: false) }
        if appearance.outfit == "outfit.cape" { drawCapeBack(ctx) }
        drawEars(ctx, fur)
        let bodyFrame = bodyRect
        ctx.fill(Path(ellipseIn: bodyFrame), with: .color(fur.base))
        drawBelly(ctx, fur)
        if let outfit = appearance.outfit { drawOutfit(ctx, outfit, body: bodyFrame) }
        drawSideParts(ctx, fur)
        drawFace(ctx, fur)
        if let glasses = appearance.glasses { drawGlasses(ctx, glasses) }
        if let neck = appearance.neck { drawNeck(ctx, neck) }
        if let hat = appearance.hat {
            drawHat(ctx, hat)
            // Tai thỏ dài: thò ra ngoài mũ len / mũ cói thay vì bị che mất.
            if appearance.species == .bunny && (hat == "hat.beanie" || hat == "hat.straw") { drawEars(ctx, fur) }
        }
        drawPaws(ctx, fur)
        if let back = appearance.back { CostumeArt.back(back, ctx, appearance, front: true) }
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
        case .puppy:
            // Đuôi ngắn dựng lên, ngoáy qua lại.
            ctx.rotated(28 + Double(t) * 22, around: CGPoint(x: 77, y: 77)) { c in
                c.ellipse(72.5, 54, 9.5, 26, fur.shade)
                c.circle(77.25, 57.5, 3, Color.white.opacity(0.18))
            }
        case .duck:
            // Đuôi vểnh nhọn.
            ctx.rotated(Double(t) * 12, around: CGPoint(x: 78, y: 76)) { c in
                var p = Path()
                p.move(to: CGPoint(x: 72, y: 82))
                p.addQuadCurve(to: CGPoint(x: 93, y: 62), control: CGPoint(x: 88, y: 80))
                p.addQuadCurve(to: CGPoint(x: 74, y: 68), control: CGPoint(x: 84, y: 64))
                p.closeSubpath()
                c.fill(p, with: .color(fur.base))
            }
        case .frog, .capybara:
            break // không có đuôi — ếch phản ứng bằng mắt lồi, capybara bằng tai & chỏm lông.
        case .panda:
            ctx.circle(81 + t, 80, 5, fur.base)
        case .penguin:
            ctx.rotated(Double(t) * 10, around: CGPoint(x: 76, y: 82)) { c in
                c.polygon([CGPoint(x: 70, y: 80), CGPoint(x: 87, y: 87), CGPoint(x: 72, y: 87)], fur.shade)
            }
        }
    }

    // MARK: Bụng

    private func drawBelly(_ ctx: GraphicsContext, _ fur: FurPalette) {
        switch appearance.species {
        case .fox:
            ctx.ellipse(31, 56, 38, 30, rgb(0xFFF8F0))
        case .penguin:
            // Mặt hình trái tim liền với bụng trắng.
            let white = rgb(0xFFFDF9)
            if appearance.fur == .snow || appearance.fur == .cream {
                ctx.stroke(penguinBib, with: .color(fur.shade), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
            ctx.fill(penguinBib, with: .color(white))
        case .capybara:
            ctx.ellipse(34, 63, 32, 23, fur.belly.opacity(0.7))
        default:
            ctx.ellipse(33, 58, 34, 27, fur.belly)
        }
    }

    private var penguinBib: Path {
        var p = Path()
        let s: CGFloat = 46, c = CGPoint(x: 50, y: 51)
        p.move(to: CGPoint(x: c.x, y: c.y + s * 0.35))
        p.addCurve(to: CGPoint(x: c.x - s * 0.5, y: c.y - s * 0.1),
                   control1: CGPoint(x: c.x - s * 0.1, y: c.y + s * 0.1), control2: CGPoint(x: c.x - s * 0.5, y: c.y + s * 0.15))
        p.addArc(center: CGPoint(x: c.x - s * 0.25, y: c.y - s * 0.12), radius: s * 0.25,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addArc(center: CGPoint(x: c.x + s * 0.25, y: c.y - s * 0.12), radius: s * 0.25,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addCurve(to: CGPoint(x: c.x, y: c.y + s * 0.35),
                   control1: CGPoint(x: c.x + s * 0.5, y: c.y + s * 0.15), control2: CGPoint(x: c.x + s * 0.1, y: c.y + s * 0.1))
        p.closeSubpath()
        p.addEllipse(in: CGRect(x: 28, y: 55, width: 44, height: 32))
        return p
    }

    // MARK: Tay, cánh, tai cụp (vẽ trước thân, sau áo)

    private func drawSideParts(_ ctx: GraphicsContext, _ fur: FurPalette) {
        switch appearance.species {
        case .puppy:
            // Tai cụp mềm rủ hai bên má.
            let lift = Double(pose.ear) * -16 - Double(pose.petted) * 8
            ctx.rotated(14 + lift, around: CGPoint(x: 28, y: 34)) { c in
                c.ellipse(16, 30, 14, 30, fur.shade)
            }
            ctx.rotated(-14 + Double(pose.petted) * 8, around: CGPoint(x: 72, y: 34)) { c in
                c.ellipse(70, 30, 14, 30, fur.shade)
            }
        case .duck:
            let flap = Double(abs(pose.tail)) * 30 + Double(pose.petted) * 18
            ctx.rotated(14 + flap, around: CGPoint(x: 21, y: 62)) { c in
                c.ellipse(12, 60, 12, 20, fur.shade)
            }
            ctx.rotated(-14 - flap, around: CGPoint(x: 79, y: 62)) { c in
                c.ellipse(76, 60, 12, 20, fur.shade)
            }
        case .penguin:
            let flap = Double(abs(pose.tail)) * 26 + Double(pose.petted) * 22
            ctx.rotated(16 + flap, around: CGPoint(x: 20, y: 58)) { c in
                c.ellipse(12, 56, 10, 25, fur.shade)
            }
            ctx.rotated(-16 - flap, around: CGPoint(x: 80, y: 58)) { c in
                c.ellipse(78, 56, 10, 25, fur.shade)
            }
        case .panda:
            let dark = pandaDark
            let wave = Double(pose.petted) * 14
            ctx.rotated(-24 - wave, around: CGPoint(x: 22, y: 64)) { c in
                c.ellipse(15, 59, 14, 20, dark)
            }
            ctx.rotated(24 + wave, around: CGPoint(x: 78, y: 64)) { c in
                c.ellipse(71, 59, 14, 20, dark)
            }
        default:
            break
        }
    }

    private var pandaDark: Color {
        appearance.fur == .midnight ? rgb(0x1E1A24) : rgb(0x3A3442)
    }

    // MARK: Tai

    private func drawEars(_ ctx: GraphicsContext, _ fur: FurPalette) {
        let twitch = Double(pose.ear) * -10 + Double(pose.petted) * 12
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
        case .puppy:
            break // tai cụp vẽ phía trước đầu (drawSideParts)
        case .duck:
            // Chỏm lông trên đỉnh đầu.
            ctx.rotated(twitch * 1.2, around: CGPoint(x: 50, y: 30)) { c in
                c.rotated(24, around: CGPoint(x: 50, y: 30)) { r in r.ellipse(47.5, 17, 5.5, 15, fur.shade) }
                c.rotated(-12, around: CGPoint(x: 50, y: 30)) { r in r.ellipse(46.5, 13, 7, 19, fur.base) }
            }
        case .frog:
            // Hai mắt lồi tròn trên đỉnh đầu; giật/nựng thì "nháy" gò mắt.
            let bob = pose.ear * -3 + pose.petted * 2
            ctx.circle(35.5, 39 + bob, 14, fur.base)
            ctx.circle(64.5, 39 + pose.petted * 2, 14, fur.base)
            ctx.strokePath(Color.white.opacity(0.55), width: 1.6) { p in
                p.addArc(center: CGPoint(x: 35.5, y: 39 + bob), radius: 10.5, startAngle: .degrees(205), endAngle: .degrees(245), clockwise: false)
                p.move(to: CGPoint(x: 64.5 + 10.5 * cos(.pi * 205 / 180), y: 39 + pose.petted * 2 + 10.5 * sin(.pi * 205 / 180)))
                p.addArc(center: CGPoint(x: 64.5, y: 39 + pose.petted * 2), radius: 10.5, startAngle: .degrees(205), endAngle: .degrees(245), clockwise: false)
            }
        case .capybara:
            ctx.rotated(twitch + Double(pose.tail) * 6, around: CGPoint(x: 28, y: 36)) { c in
                c.ellipse(21, 27, 11, 10, fur.base)
                c.ellipse(23.5, 29.5, 6, 5.5, fur.shade)
            }
            ctx.rotated(-Double(pose.tail) * 6, around: CGPoint(x: 72, y: 36)) { c in
                c.ellipse(68, 27, 11, 10, fur.base)
                c.ellipse(70.5, 29.5, 6, 5.5, fur.shade)
            }
            // Chỏm lông nhỏ trên đỉnh đầu, lắc theo nhịp "đuôi".
            ctx.strokePath(fur.shade, width: 1.4) { p in
                let sway = pose.tail * 1.5
                for (x, lean) in [(46.5, -1.5), (50.0, 0.0), (53.5, 1.5)] as [(CGFloat, CGFloat)] {
                    p.move(to: CGPoint(x: x, y: 29.5)); p.addLine(to: CGPoint(x: x + lean + sway, y: 24.5))
                }
            }
        case .panda:
            let dark = pandaDark
            ctx.rotated(twitch, around: CGPoint(x: 27, y: 36)) { c in
                c.circle(27, 31.5, 9.5, dark)
            }
            ctx.circle(73, 31.5, 9.5, dark)
        case .penguin:
            break // không có tai
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
        case .puppy:
            // Đốm quanh mắt phải + mõm sáng.
            ctx.ellipse(52.5, 41, 19, 17, fur.shade)
            ctx.ellipse(39.5, 52, 21, 13, fur.belly)
        case .capybara:
            ctx.fill(capybaraMuzzle, with: .color(fur.shade))
            ctx.ellipse(44, 50.5, 7, 3, Color.white.opacity(0.18))
        case .panda:
            let dark = pandaDark
            ctx.rotated(28, around: CGPoint(x: 37.5, y: 51)) { c in c.ellipse(30.5, 42, 14, 18.5, dark) }
            ctx.rotated(-28, around: CGPoint(x: 62.5, y: 51)) { c in c.ellipse(55.5, 42, 14, 18.5, dark) }
            ctx.ellipse(41.5, 52, 17, 10, fur.belly)
        default:
            break
        }

        let f = eyeScale
        let dx = pose.look * 1.3
        let left = CGPoint(x: 37.5 + dx, y: 50)
        let right = CGPoint(x: 62.5 + dx, y: 50)
        let closed = pose.blink && (mood == .idle || mood == .happy)
        let faceMood: PetMood = pose.petted > 0.15 ? .happy : mood
        // Gấu trúc: mắt nằm trên quầng đen nên nét mắt nhắm/cười dùng màu sáng.
        let eyeLine = appearance.species == .panda ? rgb(0xFFFDF8) : line
        let panda = appearance.species == .panda
        if pose.lifted {
            for c in [left, right] {
                if panda { ctx.circle(c.x, c.y, 4.6 * f, rgb(0xFFFDF8)) }
                ctx.circle(c.x, c.y, 3.4 * f, ink)
                ctx.circle(c.x - 0.9 * f, c.y - 1.2 * f, 1.1 * f, .white)
            }
        } else {
            switch faceMood {
            case .idle where !closed && appearance.species == .capybara:
                // Mắt nhỏ tròn hiền lành.
                for c in [left, right] {
                    ctx.ellipse(c.x - 2.1 * f, c.y - 2.2 * f, 4.2 * f, 4.6 * f, ink)
                    ctx.circle(c.x - 0.6 * f, c.y - 0.9 * f, 0.75 * f, .white)
                }
            case .idle where !closed:
                for c in [left, right] {
                    if panda { ctx.circle(c.x, c.y, 4.4 * f, rgb(0xFFFDF8)) }
                    ctx.ellipse(c.x - 2.5 * f, c.y - 3.3 * f, 5 * f, 6.5 * f, ink)
                    ctx.circle(c.x - 0.6 * f, c.y - 1.6 * f, 0.9 * f, .white)
                }
            case .idle:
                ctx.strokePath(eyeLine, width: 2.2) { p in
                    for c in [left, right] {
                        p.move(to: CGPoint(x: c.x - 3.5, y: c.y)); p.addLine(to: CGPoint(x: c.x + 3.5, y: c.y))
                    }
                }
            case .happy:
                ctx.strokePath(eyeLine, width: 2.4) { p in
                    for c in [left, right] {
                        p.move(to: CGPoint(x: c.x - 4.5, y: c.y + 2)); p.addQuadCurve(to: CGPoint(x: c.x + 4.5, y: c.y + 2), control: CGPoint(x: c.x, y: c.y - 6 * f))
                    }
                }
            case .focus:
                ctx.strokePath(eyeLine, width: 2.4) { p in
                    p.move(to: CGPoint(x: left.x - 4.5, y: 51)); p.addLine(to: CGPoint(x: left.x + 4.5, y: 52))
                    p.move(to: CGPoint(x: right.x - 4.5, y: 52)); p.addLine(to: CGPoint(x: right.x + 4.5, y: 51))
                }
            case .rest:
                ctx.strokePath(eyeLine, width: 2.4) { p in
                    for c in [left, right] {
                        p.move(to: CGPoint(x: c.x - 4.5, y: c.y)); p.addQuadCurve(to: CGPoint(x: c.x + 4.5, y: c.y), control: CGPoint(x: c.x, y: c.y + 5))
                    }
                }
            }
        }
        // má hồng
        let blush = Palette.blush.opacity(min(1, (mood == .happy ? 1 : 0.75) + Double(pose.petted) * 0.4))
        let grow = pose.petted * 2
        ctx.ellipse(26 - grow / 2, 55 - grow / 4, 8 + grow, 4.5 + grow / 2, blush)
        ctx.ellipse(66 - grow / 2, 55 - grow / 4, 8 + grow, 4.5 + grow / 2, blush)
        // mũi + miệng
        switch appearance.species {
        case .duck:
            drawDuckBill(ctx)
        case .penguin:
            let orange = rgb(0xF4A04F)
            if pose.lifted {
                ctx.polygon([CGPoint(x: 46.5, y: 54), CGPoint(x: 53.5, y: 54), CGPoint(x: 50, y: 57)], orange)
                ctx.polygon([CGPoint(x: 47.5, y: 58.5), CGPoint(x: 52.5, y: 58.5), CGPoint(x: 50, y: 61)], rgb(0xE0823A))
            } else {
                var p = Path()
                p.move(to: CGPoint(x: 46, y: 54.5))
                p.addQuadCurve(to: CGPoint(x: 54, y: 54.5), control: CGPoint(x: 50, y: 52.5))
                p.addQuadCurve(to: CGPoint(x: 50, y: 59.5), control: CGPoint(x: 53.5, y: 57))
                p.addQuadCurve(to: CGPoint(x: 46, y: 54.5), control: CGPoint(x: 46.5, y: 57))
                p.closeSubpath()
                ctx.fill(p, with: .color(orange))
                ctx.circle(48.6, 54.6, 0.8, Color.white.opacity(0.6))
            }
        case .frog:
            ctx.circle(47.5, 54.5, 0.8, line)
            ctx.circle(52.5, 54.5, 0.8, line)
            if pose.lifted {
                ctx.ellipse(45, 57, 10, 5.5, line)
                ctx.ellipse(47, 59.5, 6, 2.5, rgb(0xF08C9A))
            } else {
                ctx.strokePath(line, width: 1.5) { p in
                    p.move(to: CGPoint(x: 39, y: 57)); p.addQuadCurve(to: CGPoint(x: 61, y: 57), control: CGPoint(x: 50, y: 64))
                }
                if mood == .happy || pose.petted > 0.15 {
                    var mouth = Path()
                    mouth.move(to: CGPoint(x: 42, y: 58.5)); mouth.addQuadCurve(to: CGPoint(x: 58, y: 58.5), control: CGPoint(x: 50, y: 65))
                    mouth.closeSubpath()
                    ctx.fill(mouth, with: .color(line))
                    ctx.ellipse(46.5, 60, 7, 2.6, rgb(0xF08C9A))
                }
            }
        case .capybara:
            let nostril = rgb(0x4A3530)
            ctx.rotated(-25, around: CGPoint(x: 46.5, y: 53.5)) { c in c.ellipse(45.4, 52.7, 2.2, 1.6, nostril) }
            ctx.rotated(25, around: CGPoint(x: 53.5, y: 53.5)) { c in c.ellipse(52.4, 52.7, 2.2, 1.6, nostril) }
            if pose.lifted {
                ctx.ellipse(48, 57.5, 4, 3.8, nostril)
            } else {
                ctx.strokePath(nostril.opacity(0.85), width: 1.3) { p in
                    p.move(to: CGPoint(x: 45.5, y: 57.5)); p.addQuadCurve(to: CGPoint(x: 50, y: 58), control: CGPoint(x: 47.5, y: 60.5))
                    p.addQuadCurve(to: CGPoint(x: 54.5, y: 57.5), control: CGPoint(x: 52.5, y: 60.5))
                }
            }
        default:
            let nose: CGFloat = appearance.species == .bear || appearance.species == .puppy ? 1.6 : (appearance.species == .panda ? 1.3 : 1)
            ctx.polygon([CGPoint(x: 50 - 1.5 * nose, y: 55), CGPoint(x: 50 + 1.5 * nose, y: 55), CGPoint(x: 50, y: 55 + 2 * nose)], line)
            if pose.lifted {
                ctx.ellipse(48, 58, 4, 4.5, line)
            } else {
                if appearance.species == .puppy && (mood == .happy || pose.petted > 0.15) {
                    ctx.rect(47.6, 58.6, 4.8, 4.6, rgb(0xF08C9A), radius: 2.4)
                }
                ctx.strokePath(line, width: 1.4) { p in
                    p.move(to: CGPoint(x: 46, y: 58)); p.addQuadCurve(to: CGPoint(x: 50, y: 58), control: CGPoint(x: 48, y: 61))
                    p.addQuadCurve(to: CGPoint(x: 54, y: 58), control: CGPoint(x: 52, y: 61))
                }
            }
        }
        if appearance.species == .bunny || appearance.species == .hamster {
            ctx.rect(48.4, 59.5, 3.2, 3, .white, radius: 0.8)
        }
    }

    private var capybaraMuzzle: Path {
        var p = Path()
        p.move(to: CGPoint(x: 50, y: 46.5))
        p.addCurve(to: CGPoint(x: 62.5, y: 58.5), control1: CGPoint(x: 57.5, y: 46.5), control2: CGPoint(x: 62.5, y: 51))
        p.addCurve(to: CGPoint(x: 50, y: 65.5), control1: CGPoint(x: 62.5, y: 64), control2: CGPoint(x: 57, y: 65.5))
        p.addCurve(to: CGPoint(x: 37.5, y: 58.5), control1: CGPoint(x: 43, y: 65.5), control2: CGPoint(x: 37.5, y: 64))
        p.addCurve(to: CGPoint(x: 50, y: 46.5), control1: CGPoint(x: 37.5, y: 51), control2: CGPoint(x: 42.5, y: 46.5))
        p.closeSubpath()
        return p
    }

    private func drawDuckBill(_ ctx: GraphicsContext) {
        let orange = rgb(0xF6A24E), dark = rgb(0xDF7E36)
        if pose.lifted {
            ctx.rect(41, 52, 18, 5.5, orange, radius: 2.8)
            ctx.rect(43, 58.5, 14, 4, dark, radius: 2)
        } else {
            ctx.rect(42.5, 56, 15, 5, dark, radius: 2.5)
            ctx.rect(40.5, 52.5, 19, 6.5, orange, radius: 3.25)
            ctx.ellipse(43, 53.5, 6, 2, Color.white.opacity(0.45))
        }
        ctx.circle(47, 54.5, 0.7, dark)
        ctx.circle(53, 54.5, 0.7, dark)
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
            CostumeArt.glasses(id, ctx, appearance)
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
            CostumeArt.neck(id, ctx, appearance)
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
            CostumeArt.outfit(id, ctx, clipped: clipped, appearance)
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
            CostumeArt.hat(id, c, appearance)
        }
    }

    // MARK: Chân & hiệu ứng

    private func drawPaws(_ ctx: GraphicsContext, _ fur: FurPalette) {
        let step = pose.walk.map { sin($0) * 2.2 } ?? 0
        let dangle: CGFloat = pose.lifted ? 4 : 0
        let feet: [(x: CGFloat, y: CGFloat, side: CGFloat)] = [(41, 80 - step + dangle, -1), (59, 80 + step + dangle, 1)]
        switch appearance.species {
        case .duck, .penguin:
            // Chân màng màu cam.
            let orange = rgb(0xF6A24E), dark = rgb(0xDF7E36)
            let w: CGFloat = appearance.species == .duck ? 13 : 11
            for foot in feet {
                ctx.rotated(Double(foot.side) * 10, around: CGPoint(x: foot.x, y: foot.y + 3)) { c in
                    var p = Path()
                    p.move(to: CGPoint(x: foot.x - 2, y: foot.y + 1))
                    p.addLine(to: CGPoint(x: foot.x - w / 2, y: foot.y + 6.5))
                    p.addQuadCurve(to: CGPoint(x: foot.x, y: foot.y + 6.5), control: CGPoint(x: foot.x - w / 4, y: foot.y + 8.5))
                    p.addQuadCurve(to: CGPoint(x: foot.x + w / 2, y: foot.y + 6.5), control: CGPoint(x: foot.x + w / 4, y: foot.y + 8.5))
                    p.addLine(to: CGPoint(x: foot.x + 2, y: foot.y + 1))
                    p.addQuadCurve(to: CGPoint(x: foot.x - 2, y: foot.y + 1), control: CGPoint(x: foot.x, y: foot.y - 1))
                    p.closeSubpath()
                    c.fill(p, with: .color(orange))
                    c.strokePath(dark, width: 0.9) { s in
                        s.move(to: CGPoint(x: foot.x - w / 4, y: foot.y + 4.5)); s.addLine(to: CGPoint(x: foot.x - w / 4, y: foot.y + 6.8))
                        s.move(to: CGPoint(x: foot.x + w / 4, y: foot.y + 4.5)); s.addLine(to: CGPoint(x: foot.x + w / 4, y: foot.y + 6.8))
                    }
                }
            }
        case .frog:
            for foot in feet {
                ctx.ellipse(foot.x - 7, foot.y + 0.5, 14, 6.5 + dangle / 2, fur.base)
                for k in [-1, 0, 1] as [CGFloat] {
                    ctx.circle(foot.x + k * 5, foot.y + 6.3 + dangle / 2 - abs(k) * 0.6, 2, fur.base)
                }
            }
        case .panda:
            for foot in feet {
                ctx.ellipse(foot.x - 5.5, foot.y - 0.5, 11, 7.5 + dangle / 2, pandaDark)
            }
        case .capybara:
            for foot in feet {
                ctx.ellipse(foot.x - 5.5, foot.y, 11, 7 + dangle / 2, fur.shade)
            }
        default:
            ctx.ellipse(36, 80 - step + dangle, 10, 7 + dangle / 2, fur.base)
            ctx.ellipse(54, 80 + step + dangle, 10, 7 + dangle / 2, fur.base)
        }
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
