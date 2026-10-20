import SwiftUI

// Các loài có dáng người riêng (không phải khối tròn): ma bông, thạch dẻo, nấm nhỏ, cá mập con,
// cú mèo, rồng con, kỳ lân. Cùng hệ tọa độ 100×100 với `PetPainter` và giữ các mốc để đồ mặc vừa:
// mắt ở (37.5, 50) / (62.5, 50), đỉnh đầu y≈28 (trừ khi `hatTop` nói khác), cổ y≈61–67, chân y≈80–87.

extension PetSpecies {
    /// Loài có thân vẽ bằng đường riêng thay cho hình elip chung.
    var hasCustomShape: Bool {
        switch self {
        case .ghost, .slime, .mushroom, .shark, .owl, .dragon, .unicorn: return true
        default: return false
        }
    }
}

private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

/// Màu bờm/đuôi kỳ lân (màu kẹo nhạt).
private let manePastels: [Color] = [rgb(0xF7B8D0), rgb(0xD4BFF3), rgb(0xAFD6F6), rgb(0xB9E8CC), rgb(0xFAD7AE)]
private let hornGold = rgb(0xF4D27A), hornStripe = rgb(0xE2B04C)
private let dragonHorn = rgb(0xF6E4BC), dragonHornLine = rgb(0xE0C690)
private let owlBeak = rgb(0xE9A04B), owlBeakDark = rgb(0xCF8636)

extension PetPainter {

    // MARK: Khung chung

    /// Ma bông bay lơ lửng: nhấp nhô theo nhịp thở.
    var floatLift: CGFloat { appearance.species == .ghost ? 6 + pose.breath * 2.2 : 0 }

    /// Hệ số co giãn (x, y) theo nhịp thở, khi được nựng và khi nhảy.
    var squash: (x: CGFloat, y: CGFloat) {
        let b = pose.breath
        switch appearance.species {
        case .slime:
            // Thạch dẻo: thở phập phồng rõ, nựng thì bẹp xuống, nhảy thì dài ra.
            let p = pose.petted, h = min(pose.hop, 10) / 10
            return (1 - b * 0.03 + p * 0.08 - h * 0.05, 1 + b * 0.045 - p * 0.09 + h * 0.07)
        case .ghost:
            return (1 - b * 0.012, 1 + b * 0.016)
        default:
            return (1 - b * 0.008, 1 + b * 0.022)
        }
    }

    /// Bóng dưới chân: (rộng, cao, độ đậm) trước khi nhân theo giai đoạn.
    var shadowStyle: (width: CGFloat, height: CGFloat, opacity: Double) {
        switch appearance.species {
        case .ghost: return (34 * (1 - pose.breath * 0.1), 6.5, 0.07)
        case .slime: return (70, 9, 0.12)
        case .owl: return (50, 9, 0.10)
        case .mushroom: return (50, 8, 0.10)
        default: return (56, 9, 0.10)
        }
    }

    /// Đỉnh đầu (nơi đặt mũ).
    var hatTop: CGFloat {
        switch appearance.species {
        case .hamster: return 32
        case .mushroom: return 12
        case .owl: return 21
        default: return 28
        }
    }

    func bodyColor(_ fur: FurPalette) -> Color {
        appearance.species == .mushroom ? fur.belly : fur.base
    }

    /// Thân vẽ bằng đường riêng; nil = elip chung.
    var customBodyPath: Path? {
        switch appearance.species {
        case .ghost: return ghostBody
        case .slime: return slimeBody
        case .mushroom: return mushroomStem
        case .shark: return sharkBody
        case .owl: return Path(ellipseIn: CGRect(x: 19, y: 20, width: 62, height: 68))
        case .dragon: return dragonBody
        case .unicorn: return Path(ellipseIn: CGRect(x: 16, y: 26, width: 68, height: 53))
        default: return nil
        }
    }

    private var ghostBody: Path {
        var p = Path()
        p.move(to: pt(14, 80))
        p.addCurve(to: pt(50, 24), control1: pt(12, 40), control2: pt(28, 24))
        p.addCurve(to: pt(86, 80), control1: pt(72, 24), control2: pt(88, 40))
        // Vạt dưới gợn sóng, lay động theo nhịp "đuôi".
        let xs: [CGFloat] = [86, 68, 50, 32, 14]
        for i in 0..<4 {
            let wave = sin(CGFloat(i) * 1.7 + pose.tail * 1.5) * 1.8
            p.addQuadCurve(to: pt(xs[i + 1], 80), control: pt((xs[i] + xs[i + 1]) / 2, 95 + wave))
        }
        p.closeSubpath()
        return p
    }

    private var slimeBody: Path {
        var p = Path()
        p.move(to: pt(13, 83))
        p.addCurve(to: pt(50, 30), control1: pt(7, 57), control2: pt(26, 30))
        p.addCurve(to: pt(87, 83), control1: pt(74, 30), control2: pt(93, 57))
        p.addQuadCurve(to: pt(78, 89), control: pt(89, 89))
        p.addLine(to: pt(22, 89))
        p.addQuadCurve(to: pt(13, 83), control: pt(11, 89))
        p.closeSubpath()
        return p
    }

    private var mushroomStem: Path {
        var p = Path()
        p.move(to: pt(27, 38))
        p.addQuadCurve(to: pt(21, 79), control: pt(22, 58))
        p.addCurve(to: pt(50, 88), control1: pt(21, 86), control2: pt(33, 88))
        p.addCurve(to: pt(79, 79), control1: pt(67, 88), control2: pt(79, 86))
        p.addQuadCurve(to: pt(73, 38), control: pt(78, 58))
        p.closeSubpath()
        return p
    }

    private var mushroomCap: Path {
        var p = Path()
        p.move(to: pt(5, 42))
        p.addCurve(to: pt(50, 10), control1: pt(5, 21), control2: pt(25, 10))
        p.addCurve(to: pt(95, 42), control1: pt(75, 10), control2: pt(95, 21))
        p.addQuadCurve(to: pt(88, 46), control: pt(96, 47))
        p.addQuadCurve(to: pt(12, 46), control: pt(50, 37))
        p.addQuadCurve(to: pt(5, 42), control: pt(4, 47))
        p.closeSubpath()
        return p
    }

    private var sharkBody: Path {
        var p = Path()
        p.move(to: pt(50, 26))
        p.addCurve(to: pt(87, 65), control1: pt(74, 26), control2: pt(87, 45))
        p.addCurve(to: pt(50, 88), control1: pt(87, 82), control2: pt(70, 88))
        p.addCurve(to: pt(13, 65), control1: pt(30, 88), control2: pt(13, 82))
        p.addCurve(to: pt(50, 26), control1: pt(13, 45), control2: pt(26, 26))
        p.closeSubpath()
        return p
    }

    private var dragonBody: Path {
        var p = Path()
        p.move(to: pt(50, 28))
        p.addCurve(to: pt(80, 57), control1: pt(70, 28), control2: pt(80, 41))
        p.addCurve(to: pt(50, 88), control1: pt(87, 75), control2: pt(76, 88))
        p.addCurve(to: pt(20, 57), control1: pt(24, 88), control2: pt(13, 75))
        p.addCurve(to: pt(50, 28), control1: pt(20, 41), control2: pt(30, 28))
        p.closeSubpath()
        return p
    }

    /// Bụng trắng của cá mập: nền sáng cho lông sẫm, sắc lông nhạt khi lông vốn đã trắng.
    private func sharkBelly(_ fur: FurPalette) -> Color {
        appearance.fur == .snow || appearance.fur == .cream ? fur.belly : rgb(0xFBF8F4)
    }

    // MARK: Đuôi & phần phía sau thân

    func drawShapeTail(_ ctx: GraphicsContext, _ fur: FurPalette) {
        let t = pose.tail
        switch appearance.species {
        case .shark:
            ctx.rotated(Double(t) * 12, around: pt(80, 77)) { c in
                var p = Path()
                p.move(to: pt(75, 71))
                p.addQuadCurve(to: pt(97, 55), control: pt(88, 69))
                p.addQuadCurve(to: pt(90, 76), control: pt(92, 68))
                p.addQuadCurve(to: pt(96, 90), control: pt(91, 83))
                p.addQuadCurve(to: pt(75, 83), control: pt(86, 82))
                p.closeSubpath()
                c.fill(p, with: .color(fur.base))
                c.strokePath(fur.shade, width: 1.2) { s in
                    s.move(to: pt(83, 74)); s.addQuadCurve(to: pt(93, 60), control: pt(89, 69))
                }
            }
        case .dragon:
            // Cánh nhỏ sau lưng: vỗ theo nhịp, vỗ mạnh khi được nựng.
            let flap = Double(t) * 8 + Double(pose.petted) * 20
            for flip in [false, true] {
                var w = ctx
                if flip { w.translateBy(x: 100, y: 0); w.scaleBy(x: -1, y: 1) }
                w.rotated(-flap, around: pt(26, 50)) { c in
                    var p = Path()
                    p.move(to: pt(28, 44))
                    p.addQuadCurve(to: pt(6, 26), control: pt(14, 29))
                    p.addQuadCurve(to: pt(5, 43), control: pt(1, 34))
                    p.addQuadCurve(to: pt(13, 48), control: pt(10, 43))
                    p.addQuadCurve(to: pt(20, 54), control: pt(18, 48))
                    p.addQuadCurve(to: pt(28, 57), control: pt(27, 53))
                    p.closeSubpath()
                    c.fill(p, with: .color(fur.shade))
                    c.strokePath(fur.base.opacity(0.75), width: 1.1) { s in
                        s.move(to: pt(26, 47)); s.addLine(to: pt(7, 28))
                        s.move(to: pt(26, 49)); s.addLine(to: pt(6, 42))
                        s.move(to: pt(26, 51)); s.addLine(to: pt(13, 47))
                    }
                }
            }
            // Đuôi gai cong lên, chóp hình mũi tên.
            ctx.rotated(Double(t) * 10, around: pt(74, 80)) { c in
                for (x, y, a) in [(CGFloat(82), CGFloat(80.5), -60.0), (89, 75, -35), (93, 68, -15)] {
                    c.rotated(a, around: pt(x, y)) { s in
                        s.polygon([pt(x - 2.6, y), pt(x, y - 5.5), pt(x + 2.6, y)], fur.shade)
                    }
                }
                var p = Path()
                p.move(to: pt(70, 85))
                p.addQuadCurve(to: pt(94, 62), control: pt(93, 85))
                p.addQuadCurve(to: pt(73, 74), control: pt(86, 73))
                p.closeSubpath()
                c.fill(p, with: .color(fur.base))
                c.polygon([pt(89.5, 63), pt(97.5, 53.5), pt(98.5, 64.5)], fur.shade)
            }
        case .unicorn:
            // Hai chân trước như ngựa con, móng vàng (vẽ sau thân để thân phủ lên đầu gối).
            let step = pose.walk.map { sin($0) * 2.2 } ?? 0
            let dangle: CGFloat = pose.lifted ? 3 : 0
            for (x, dy) in [(CGFloat(40.5), -step), (59.5, step)] {
                ctx.rect(x - 5, 68 + dy, 10, 20 + dangle, fur.base, radius: 4.5)
                var hoof = ctx
                hoof.clip(to: Path(roundedRect: CGRect(x: x - 5, y: 68 + dy, width: 10, height: 20 + dangle), cornerRadius: 4.5))
                hoof.rect(x - 6, 83.5 + dy + dangle, 12, 6, hornGold)
            }
            // Đuôi bờm màu kẹo: ba lọn dài phe phẩy.
            ctx.rotated(Double(t) * 12, around: pt(76, 80)) { c in
                let strands: [(end: CGPoint, ctrl: CGPoint, w: CGFloat, color: Color)] = [
                    (pt(95, 58), pt(94, 80), 7, manePastels[1]),
                    (pt(97, 70), pt(92, 84), 6.5, manePastels[2]),
                    (pt(92, 88), pt(88, 85), 6, manePastels[0])
                ]
                for s in strands {
                    c.strokePath(s.color, width: s.w) { p in
                        p.move(to: pt(76, 80))
                        p.addQuadCurve(to: pt(s.end.x + t * 1.5, s.end.y), control: s.ctrl)
                    }
                }
            }
        case .slime:
            // Vũng thạch loang dưới chân: dáng rộng dần xuống đáy.
            ctx.ellipse(7, 82.5, 86, 9.5, fur.base)
            ctx.ellipse(10, 87.5, 80, 4.5, fur.shade.opacity(0.45))
            ctx.circle(96, 89, 1.8, fur.base)
        default:
            break // ma bông, nấm, cú: không có đuôi phía sau.
        }
    }

    // MARK: Tai & phần trên đỉnh đầu (vẽ trước thân)

    func drawShapeEars(_ ctx: GraphicsContext, _ fur: FurPalette) {
        let twitch = Double(pose.ear) * -10 + Double(pose.petted) * 12
        switch appearance.species {
        case .ghost:
            // Một lọn xoăn nhỏ trên đỉnh, ngoe nguẩy khi giật tai.
            ctx.rotated(twitch * 0.8 + Double(pose.tail) * 5, around: pt(50, 27)) { c in
                c.strokePath(fur.base, width: 4.2) { p in
                    p.move(to: pt(48, 28)); p.addQuadCurve(to: pt(55, 17), control: pt(47, 19))
                    p.addQuadCurve(to: pt(59.5, 21), control: pt(59, 16))
                }
            }
        case .slime:
            // Chóp giọt thạch, lắc lư.
            ctx.rotated(Double(pose.tail) * 7 + twitch * 0.7, around: pt(50, 34)) { c in
                var p = Path()
                p.move(to: pt(42, 36))
                p.addQuadCurve(to: pt(54, 18), control: pt(43, 24))
                p.addQuadCurve(to: pt(59, 36), control: pt(59, 27))
                p.closeSubpath()
                c.fill(p, with: .color(fur.base))
            }
        case .shark:
            ctx.rotated(twitch * 0.5, around: pt(50, 30)) { c in
                var p = Path()
                p.move(to: pt(37, 33))
                p.addQuadCurve(to: pt(57, 7), control: pt(43, 14))
                p.addQuadCurve(to: pt(63, 31), control: pt(55, 19))
                p.closeSubpath()
                c.fill(p, with: .color(fur.base))
                c.strokePath(fur.shade, width: 1.2) { s in
                    s.move(to: pt(53, 13)); s.addQuadCurve(to: pt(58, 28), control: pt(54, 20))
                }
            }
        case .owl:
            ctx.rotated(twitch, around: pt(30, 30)) { c in
                c.polygon([pt(21, 36), pt(20, 9), pt(41, 25)], fur.base)
                c.polygon([pt(20.6, 20), pt(20, 9), pt(28, 15)], fur.shade)
            }
            ctx.polygon([pt(79, 36), pt(80, 9), pt(59, 25)], fur.base)
            ctx.polygon([pt(79.4, 20), pt(80, 9), pt(72, 15)], fur.shade)
        case .dragon:
            for flip in [false, true] {
                var h = ctx
                if flip { h.translateBy(x: 100, y: 0); h.scaleBy(x: -1, y: 1) }
                h.rotated(flip ? 0 : twitch * 0.6, around: pt(33, 32)) { c in
                    var p = Path()
                    p.move(to: pt(30, 34))
                    p.addQuadCurve(to: pt(24, 13), control: pt(23, 26))
                    p.addQuadCurve(to: pt(40, 30), control: pt(33, 17))
                    p.closeSubpath()
                    c.fill(p, with: .color(dragonHorn))
                    c.strokePath(dragonHornLine, width: 1) { s in
                        s.move(to: pt(26, 22)); s.addLine(to: pt(31, 21))
                        s.move(to: pt(27, 27)); s.addLine(to: pt(33, 25.5))
                    }
                }
            }
        case .unicorn:
            // Bờm phía sau: những lọn màu kẹo chảy từ đỉnh đầu xuống bên trái, đung đưa theo nhịp.
            let sw = pose.tail
            let mane: [(from: CGPoint, ctrl: CGPoint, to: CGPoint, w: CGFloat)] = [
                (pt(62, 26), pt(48, 15), pt(30, 27), 8.5),
                (pt(48, 25), pt(28, 21), pt(20, 42 + sw), 8.5),
                (pt(36, 30), pt(17, 36), pt(14, 58 + sw * 1.5), 8),
                (pt(27, 40), pt(10, 54), pt(15, 73 + sw * 2), 7.5),
                (pt(22, 54), pt(13, 68), pt(22, 84 + sw * 2), 6.5)
            ]
            for (i, m) in mane.enumerated() {
                ctx.strokePath(manePastels[i % manePastels.count], width: m.w) { p in
                    p.move(to: m.from)
                    p.addQuadCurve(to: pt(m.to.x - sw * CGFloat(i) * 0.6, m.to.y), control: m.ctrl)
                }
            }
            // Tai hình lá, chĩa ra hai bên như ngựa con.
            ctx.rotated(-28 + twitch, around: pt(30, 35)) { c in
                c.ellipse(24.5, 13, 11, 24, fur.base)
                c.ellipse(27.5, 17.5, 5, 15, fur.inner)
            }
            ctx.rotated(28, around: pt(70, 35)) { c in
                c.ellipse(64.5, 13, 11, 24, fur.base)
                c.ellipse(67.5, 17.5, 5, 15, fur.inner)
            }
        default:
            break // nấm: mũ nấm vẽ sau thân (drawShapeSideParts).
        }
    }

    // MARK: Bụng & chi tiết trên thân

    func drawShapeBelly(_ ctx: GraphicsContext, _ fur: FurPalette, body: Path) {
        switch appearance.species {
        case .ghost:
            ctx.rotated(-32, around: pt(30, 38)) { c in c.ellipse(25.5, 31, 9, 15, Color.white.opacity(0.38)) }
            ctx.circle(36.5, 32, 1.8, Color.white.opacity(0.45))
            // Bóng nhẹ dọc vạt dưới cho có khối.
            var hem = ctx
            hem.clip(to: body)
            var shade = hem
            shade.translateBy(x: 0, y: -5)
            hem.fill(Path(CGRect(x: 0, y: 70, width: 100, height: 30)), with: .color(fur.shade.opacity(0.32)))
            shade.fill(body, with: .color(fur.base))
        case .slime:
            ctx.ellipse(26, 60, 48, 27, fur.belly.opacity(0.5))
            for (x, y, r) in [(CGFloat(64), CGFloat(77), CGFloat(2.4)), (70.5, 71.5, 1.4), (33, 79, 1.8), (58, 82.5, 1.2)] {
                ctx.circle(x, y, r, Color.white.opacity(0.4))
            }
            ctx.rotated(-35, around: pt(27, 48)) { c in c.ellipse(22, 39, 9, 18, Color.white.opacity(0.55)) }
            ctx.circle(32.5, 36.5, 2.3, Color.white.opacity(0.65))
            // Giọt thạch chảy xuống bên hông.
            let sag = pose.breath * 0.8
            var drip = Path()
            drip.move(to: pt(82.5, 56))
            drip.addQuadCurve(to: pt(93.6, 76 + sag), control: pt(92, 63))
            drip.addArc(center: pt(90, 76.5 + sag), radius: 3.9, startAngle: .degrees(-8), endAngle: .degrees(178), clockwise: false)
            drip.addQuadCurve(to: pt(84.5, 69), control: pt(86.5, 72))
            drip.closeSubpath()
            ctx.fill(drip, with: .color(fur.base))
            ctx.circle(88.6, 76.6 + sag, 1.2, Color.white.opacity(0.7))
        case .mushroom:
            break // bóng mũ nấm vẽ cùng mũ.
        case .shark:
            var c = ctx
            c.clip(to: body)
            c.ellipse(19, 55, 62, 44, sharkBelly(fur))
        case .owl:
            ctx.ellipse(31, 60, 38, 27, fur.belly)
            ctx.strokePath(fur.shade, width: 1.3) { p in
                for (x, y) in [(CGFloat(42), CGFloat(71)), (50, 71), (58, 71), (46, 78), (54, 78)] {
                    p.move(to: pt(x - 2.6, y - 1.6)); p.addLine(to: pt(x, y + 1)); p.addLine(to: pt(x + 2.6, y - 1.6))
                }
            }
        case .dragon:
            let belly = CGRect(x: 33, y: 58, width: 34, height: 29)
            ctx.fill(Path(ellipseIn: belly), with: .color(fur.belly))
            var c = ctx
            c.clip(to: Path(ellipseIn: belly))
            c.strokePath(fur.shade.opacity(0.75), width: 1.2) { p in
                for y in [CGFloat(66), 72.5, 79] {
                    p.move(to: pt(30, y)); p.addQuadCurve(to: pt(70, y), control: pt(50, y + 3))
                }
            }
        case .unicorn:
            ctx.ellipse(34.5, 57, 31, 20, fur.belly)
        default:
            break
        }
    }

    // MARK: Tay, vây, cánh, mũ nấm, sừng (sau áo, trước mặt)

    func drawShapeSideParts(_ ctx: GraphicsContext, _ fur: FurPalette) {
        let wave = Double(pose.petted)
        let sway = Double(pose.tail)
        switch appearance.species {
        case .ghost:
            // Hai tay nhỏ: vẫy lên khi được nựng.
            ctx.rotated(-26 + wave * 62 + sway * 6, around: pt(18, 58)) { c in c.ellipse(5, 53.5, 15, 9.5, fur.base) }
            ctx.rotated(26 - wave * 62 + sway * 6, around: pt(82, 58)) { c in c.ellipse(80, 53.5, 15, 9.5, fur.base) }
        case .mushroom:
            for flip in [false, true] {
                var a = ctx
                if flip { a.translateBy(x: 100, y: 0); a.scaleBy(x: -1, y: 1) }
                a.rotated(24 - wave * 34 + (flip ? -sway : sway) * 5, around: pt(24, 62)) { c in
                    c.ellipse(13, 60, 13, 8.5, fur.shade)
                }
            }
            // Bóng mũ nấm đổ xuống thân.
            var under = ctx
            under.clip(to: mushroomStem)
            under.ellipse(18, 36, 64, 14, fur.shade.opacity(0.7))
            // Mũ nấm chấm bi: lắc khi giật tai, nhún xuống khi được nựng.
            var cap = ctx
            cap.translateBy(x: 0, y: pose.petted * 1.6)
            cap.rotated(Double(pose.ear) * -6 + sway * 1.5, around: pt(50, 44)) { c in
                let shape = mushroomCap
                c.fill(shape, with: .color(fur.base))
                var dots = c
                dots.clip(to: shape)
                let light = appearance.fur == .snow || appearance.fur == .cream
                let spot = light ? fur.shade : Color.white.opacity(0.88)
                for (x, y, r) in [(CGFloat(26), CGFloat(24), CGFloat(5.6)), (50, 16, 4.6), (72, 25, 6.2), (12.5, 37, 3.2),
                                  (87, 37, 3.4), (39, 33.5, 3), (61, 34, 2.6)] {
                    dots.circle(x, y, r, spot)
                }
                dots.strokePath(fur.shade, width: 2.2) { p in
                    p.move(to: pt(10, 46)); p.addQuadCurve(to: pt(90, 46), control: pt(50, 37.5))
                }
                dots.strokePath(Color.white.opacity(0.35), width: 2) { p in
                    p.move(to: pt(12, 30)); p.addQuadCurve(to: pt(30, 14.5), control: pt(17, 18))
                }
            }
        case .shark:
            let flap = Double(abs(pose.tail)) * 14 + wave * 26
            ctx.rotated(34 + flap, around: pt(19, 66)) { c in c.ellipse(4, 62.5, 19, 9, fur.shade) }
            ctx.rotated(-34 - flap, around: pt(81, 66)) { c in c.ellipse(77, 62.5, 19, 9, fur.shade) }
        case .owl:
            let flap = Double(abs(pose.tail)) * 12 + wave * 30
            for flip in [false, true] {
                var a = ctx
                if flip { a.translateBy(x: 100, y: 0); a.scaleBy(x: -1, y: 1) }
                a.rotated(10 + flap, around: pt(22, 52)) { c in
                    c.ellipse(11, 50, 14, 32, fur.shade)
                    c.strokePath(fur.base.opacity(0.55), width: 1.1) { p in
                        p.move(to: pt(15, 70)); p.addLine(to: pt(15, 79))
                        p.move(to: pt(19.5, 72)); p.addLine(to: pt(19.5, 80))
                    }
                }
            }
        case .unicorn:
            // Lọn bờm trước trán rồi tới sừng vàng.
            let sw = pose.tail * 0.8
            ctx.strokePath(manePastels[0], width: 5.5) { p in
                p.move(to: pt(56, 29)); p.addQuadCurve(to: pt(36 - sw, 37), control: pt(44, 28))
            }
            ctx.strokePath(manePastels[1], width: 4.2) { p in
                p.move(to: pt(58, 29.5)); p.addQuadCurve(to: pt(63 + sw, 35), control: pt(62, 29.5))
            }
            ctx.rotated(Double(pose.ear) * -4, around: pt(50, 31)) { c in
                c.polygon([pt(45, 32), pt(50, 5), pt(55, 32)], hornGold)
                c.strokePath(hornStripe, width: 1.1) { p in
                    for y in [CGFloat(13), 19.5, 26] {
                        let half = (y - 5) / 27 * 5
                        p.move(to: pt(50 - half, y + 1.4)); p.addLine(to: pt(50 + half, y - 1.4))
                    }
                }
                c.strokePath(Color.white.opacity(0.5), width: 0.9) { p in
                    p.move(to: pt(48.6, 12)); p.addLine(to: pt(47, 28))
                }
            }
        default:
            break
        }
    }

    // MARK: Mặt

    /// Vẽ trước mắt: đĩa mặt cú, mang cá mập, mõm kỳ lân…
    func drawShapeFaceMarks(_ ctx: GraphicsContext, _ fur: FurPalette) {
        switch appearance.species {
        case .owl:
            ctx.circle(37.5, 50, 12.6, fur.shade)
            ctx.circle(62.5, 50, 12.6, fur.shade)
            ctx.circle(37.5, 50, 11.3, fur.belly)
            ctx.circle(62.5, 50, 11.3, fur.belly)
        case .shark:
            ctx.strokePath(fur.shade, width: 1.3) { p in
                for k in 0..<3 {
                    let d = CGFloat(k) * 2.8
                    p.move(to: pt(17.5 + d, 49)); p.addQuadCurve(to: pt(17.5 + d, 58), control: pt(19.5 + d, 53.5))
                    p.move(to: pt(82.5 - d, 49)); p.addQuadCurve(to: pt(82.5 - d, 58), control: pt(80.5 - d, 53.5))
                }
            }
        case .unicorn:
            ctx.ellipse(38.5, 52, 23, 12, fur.belly)
        default:
            break
        }
    }

    /// Chi tiết quanh mắt sau khi vẽ mắt (lông mi kỳ lân).
    func drawShapeEyeExtras(_ ctx: GraphicsContext, _ line: Color, left: CGPoint, right: CGPoint) {
        guard appearance.species == .unicorn, !pose.lifted else { return }
        ctx.strokePath(line, width: 1.2) { p in
            p.move(to: pt(left.x - 3.6, left.y - 2.6)); p.addLine(to: pt(left.x - 6, left.y - 4.4))
            p.move(to: pt(left.x - 2.2, left.y - 3.8)); p.addLine(to: pt(left.x - 3.6, left.y - 6.2))
            p.move(to: pt(right.x + 3.6, right.y - 2.6)); p.addLine(to: pt(right.x + 6, right.y - 4.4))
            p.move(to: pt(right.x + 2.2, right.y - 3.8)); p.addLine(to: pt(right.x + 3.6, right.y - 6.2))
        }
    }

    /// Miệng (và mũi/mỏ) của các loài dáng riêng.
    func drawShapeMouth(_ ctx: GraphicsContext, _ fur: FurPalette, line: Color) {
        let happy = mood == .happy || pose.petted > 0.15
        switch appearance.species {
        case .owl:
            if pose.lifted {
                ctx.polygon([pt(46.5, 54), pt(53.5, 54), pt(50, 57.5)], owlBeak)
                ctx.polygon([pt(47.5, 59), pt(52.5, 59), pt(50, 61.5)], owlBeakDark)
            } else {
                var p = Path()
                p.move(to: pt(46.2, 54.6))
                p.addQuadCurve(to: pt(53.8, 54.6), control: pt(50, 52.6))
                p.addQuadCurve(to: pt(50, 61), control: pt(53.4, 57.5))
                p.addQuadCurve(to: pt(46.2, 54.6), control: pt(46.6, 57.5))
                p.closeSubpath()
                ctx.fill(p, with: .color(owlBeak))
                ctx.circle(48.7, 55, 0.8, Color.white.opacity(0.6))
            }
        case .shark:
            simpleMouth(ctx, line, happy: happy, y: 58.5, half: 7.5, depth: 5)
        case .slime:
            simpleMouth(ctx, line, happy: happy, y: 57, half: 5, depth: 4)
        case .ghost, .mushroom:
            simpleMouth(ctx, line, happy: happy, y: 57, half: 3.6, depth: 3.4)
        case .dragon:
            ctx.circle(46.5, 55, 0.95, line)
            ctx.circle(53.5, 55, 0.95, line)
            if pose.lifted {
                ctx.ellipse(48, 58, 4, 4.5, line)
            } else {
                ctx.strokePath(line, width: 1.4) { p in
                    p.move(to: pt(45.5, 58)); p.addQuadCurve(to: pt(50, 58), control: pt(47.75, 61))
                    p.addQuadCurve(to: pt(54.5, 58), control: pt(52.25, 61))
                }
                // Một chiếc răng nanh bé xíu.
                ctx.polygon([pt(51.6, 59.3), pt(54, 59.1), pt(53, 61.6)], .white)
            }
        case .unicorn:
            ctx.ellipse(44.2, 55.2, 2.6, 1.8, fur.shade)
            ctx.ellipse(53.2, 55.2, 2.6, 1.8, fur.shade)
            simpleMouth(ctx, line, happy: happy, y: 59.3, half: 3.4, depth: 2.6)
        default:
            break
        }
    }

    private func simpleMouth(_ ctx: GraphicsContext, _ line: Color, happy: Bool, y: CGFloat, half: CGFloat, depth: CGFloat) {
        if pose.lifted {
            ctx.ellipse(48, y - 0.5, 4, 4.5, line)
        } else if happy {
            var m = Path()
            m.move(to: pt(50 - half, y))
            m.addQuadCurve(to: pt(50 + half, y), control: pt(50, y + depth * 2))
            m.closeSubpath()
            ctx.fill(m, with: .color(line))
            var tongue = ctx
            tongue.clip(to: m)
            tongue.ellipse(50 - half * 0.55, y + depth * 0.55, half * 1.1, depth, rgb(0xF08C9A))
        } else {
            ctx.strokePath(line, width: 1.5) { p in
                p.move(to: pt(50 - half, y)); p.addQuadCurve(to: pt(50 + half, y), control: pt(50, y + depth))
            }
        }
    }

    // MARK: Chân

    func drawShapePaws(_ ctx: GraphicsContext, _ fur: FurPalette, feet: [(x: CGFloat, y: CGFloat, side: CGFloat)], dangle: CGFloat) {
        switch appearance.species {
        case .ghost, .slime:
            break // bay lơ lửng / trườn: không có chân.
        case .mushroom:
            for foot in feet {
                ctx.ellipse(foot.x - 5, foot.y + 2.5, 10, 6 + dangle / 2, fur.shade)
            }
        case .shark:
            for foot in feet {
                ctx.rotated(Double(foot.side) * 18, around: pt(foot.x, foot.y + 3)) { c in
                    c.ellipse(foot.x - 6, foot.y + 0.5, 12, 6.5 + dangle / 2, fur.shade)
                }
            }
        case .owl:
            for foot in feet {
                for k in [-1, 0, 1] as [CGFloat] {
                    ctx.rotated(Double(k) * 14, around: pt(foot.x, foot.y + 4)) { c in
                        c.ellipse(foot.x - 1.7, foot.y + 3 + dangle, 3.4, 6.5, owlBeak)
                    }
                }
            }
        case .dragon:
            for foot in feet {
                ctx.ellipse(foot.x - 5, foot.y, 10, 7 + dangle / 2, fur.base)
                for k in [-1, 0, 1] as [CGFloat] {
                    ctx.circle(foot.x + k * 2.6, foot.y + 6.2 + dangle / 2 - abs(k) * 0.5, 0.95, dragonHorn)
                }
            }
        default: // kỳ lân: chân vẽ cùng đuôi, phía sau thân.
            break
        }
    }
}
