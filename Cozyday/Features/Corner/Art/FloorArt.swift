import SwiftUI

/// Sàn mua riêng: vẽ trong hệ tọa độ phòng 125×100, chỉ phủ vùng sàn từ `top` (y = 62) xuống đáy.
/// ID dạng "<vị trí>.<mẫu>" (vd. "studyFloor.oak", "bedroomFloor.oak"): các phòng dùng chung mẫu, mỗi phòng một ID riêng.
enum FloorArt {
    static let top: CGFloat = 62
    private static let depth: CGFloat = 100 - top

    /// Trả về false nếu `id` không phải sàn.
    static func draw(_ id: String, in base: GraphicsContext) -> Bool {
        guard Catalog.item(id)?.slot.isFloor == true,
              let pattern = id.split(separator: ".", maxSplits: 1).last.map(String.init) else { return false }
        var ctx = base
        ctx.clip(to: Path(CGRect(x: 0, y: top, width: 125, height: depth)))
        switch pattern {
        // Trong nhà
        case "oak": planks(ctx, tones: [0xEBCB9F, 0xE6C395, 0xEFD3AC], gap: rgb(0xC0905F).opacity(0.45), shade: rgb(0x8A6040))
        case "walnut": planks(ctx, tones: [0xCDA17E, 0xC59873, 0xD3A985], gap: rgb(0x7E5638).opacity(0.5), shade: rgb(0x5E3E28))
        case "birch": planks(ctx, tones: [0xF5EADB, 0xF1E3D1, 0xF8EFE3], gap: rgb(0xD2B896).opacity(0.5), shade: rgb(0x9A7B5C))
        case "herringbone": herringbone(ctx)
        case "checker": checker(ctx)
        case "hex": hexTiles(ctx)
        case "dots": dotCarpet(ctx)
        case "tatami": tatami(ctx)
        case "marble": marble(ctx)
        case "cloud": cloudCarpet(ctx)
        case "heart": heartTiles(ctx)
        case "terrazzo": terrazzo(ctx)
        case "subway": subway(ctx)
        case "star": starCarpet(ctx)
        // Vườn
        case "grass": grass(ctx)
        case "path": stonePath(ctx)
        case "sand": sand(ctx)
        case "plaza": plaza(ctx)
        case "clover": clover(ctx)
        case "deck": deck(ctx, tones: [0xE6C29A, 0xE0BA90, 0xEBCAA5], gap: 0xB98D64, nail: 0xA27852)
        case "deckWhite": deck(ctx, tones: [0xF6F1EA, 0xF1EBE3, 0xF9F5F0], gap: 0xCFC4B6, nail: 0xB4A796)
        default: return false
        }
        return true
    }

    // MARK: - Hình học

    /// Điểm trên sàn: `u` theo bề ngang (0…125 ở chân tường), `v` theo chiều sâu (0 chân tường … 1 mép dưới).
    /// Càng gần càng rộng ra một chút và hàng gạch cao dần, cho cảm giác phối cảnh nhẹ.
    private static func P(_ u: CGFloat, _ v: CGFloat) -> CGPoint {
        let y = top + depth * (0.8 * v + 0.2 * v * v)
        return CGPoint(x: 62.5 + (u - 62.5) * (1 + 0.32 * v), y: y)
    }

    private static func quad(_ ctx: GraphicsContext, _ u0: CGFloat, _ v0: CGFloat, _ u1: CGFloat, _ v1: CGFloat, _ color: Color) {
        ctx.polygon([P(u0, v0), P(u1, v0), P(u1, v1), P(u0, v1)], color)
    }

    /// Bóng mềm dưới chân tường để sàn "ăn" vào tường.
    private static func wallShadow(_ ctx: GraphicsContext, _ tint: Color) {
        ctx.rect(0, top, 125, 2.6, tint.opacity(0.07))
        ctx.rect(0, top, 125, 1.1, tint.opacity(0.09))
    }

    /// Ngữ cảnh "nằm trên sàn": nén theo chiều dọc để hình tròn thành bầu dục.
    private static func flat(_ ctx: GraphicsContext, squash: CGFloat) -> GraphicsContext {
        var c = ctx
        c.translateBy(x: 0, y: top)
        c.scaleBy(x: 1, y: squash)
        return c
    }

    /// Bộ sinh số giả ngẫu nhiên cố định để họa tiết không đổi giữa các lần vẽ.
    private struct Seeded {
        var s: UInt32
        mutating func next() -> CGFloat {
            s = s &* 1_664_525 &+ 1_013_904_223
            return CGFloat(s >> 8) / CGFloat(1 << 24)
        }
    }

    // MARK: - Gỗ

    private static func planks(_ ctx: GraphicsContext, tones: [UInt32], gap: Color, shade: Color) {
        ctx.rect(0, top, 125, depth, rgb(tones[0]))
        var rng = Seeded(s: 11)
        let w: CGFloat = 12.5
        var u: CGFloat = -25
        var joints: [(CGFloat, CGFloat)] = []
        while u < 150 {
            var v = -rng.next() * 0.7
            while v < 1 {
                let v1 = min(1, v + 0.7)
                let tone = tones[Int(rng.next() * 30) % tones.count]
                quad(ctx, u, max(0, v), u + w, v1, rgb(tone))
                if v1 < 1 { joints.append((u, v1)) }
                v = v1
            }
            u += w
        }
        ctx.strokePath(gap, width: 0.5) { p in
            var x: CGFloat = -25
            while x < 150 {
                p.move(to: P(x, 0)); p.addLine(to: P(x, 1))
                x += w
            }
            for (x, v) in joints {
                p.move(to: P(x, v)); p.addLine(to: P(x + w, v))
            }
        }
        wallShadow(ctx, shade)
    }

    /// Ván xương cá: từng cột ván nghiêng ngược chiều nhau tạo hình mũi tên.
    private static func herringbone(_ base: GraphicsContext) {
        base.rect(0, top, 125, depth, rgb(0xE6BF8E))
        let ctx = flat(base, squash: 0.5)
        let colW: CGFloat = 12.5, t: CGFloat = 6.25
        let tones: [UInt32] = [0xE9C597, 0xE1B784, 0xEDCDA4]
        let line = rgb(0xB98A5B).opacity(0.45)
        var rng = Seeded(s: 5)
        for col in 0..<15 {
            let x0 = CGFloat(col) * colW - 4
            let dir: CGFloat = col % 2 == 0 ? -1 : 1
            var y: CGFloat = -12 + (col % 2 == 0 ? 0 : t / 2)
            while y < 80 {
                let pts = [CGPoint(x: x0, y: y), CGPoint(x: x0 + colW, y: y + dir * colW),
                           CGPoint(x: x0 + colW, y: y + dir * colW + t), CGPoint(x: x0, y: y + t)]
                ctx.polygon(pts, rgb(tones[Int(rng.next() * 30) % tones.count]))
                ctx.strokePath(line, width: 0.45) { p in
                    p.move(to: pts[3]); p.addLine(to: pts[2])
                }
                y += t
            }
            ctx.strokePath(line, width: 0.45) { p in
                p.move(to: CGPoint(x: x0 + colW, y: -20)); p.addLine(to: CGPoint(x: x0 + colW, y: 90))
            }
        }
        wallShadow(base, rgb(0x8A6040))
    }

    private static func tatami(_ ctx: GraphicsContext) {
        let mat = rgb(0xDCDEAA), matLight = rgb(0xE4E6B8), weave = rgb(0xB9BE84).opacity(0.35)
        let border = rgb(0x93A878), gapLine = rgb(0xA9AE78).opacity(0.6)
        ctx.rect(0, top, 125, depth, mat)
        let rows: [(CGFloat, CGFloat, CGFloat)] = [(0, 0.36, 0), (0.36, 0.7, 15.5), (0.7, 1.0, 0)]
        for (i, (v0, v1, off)) in rows.enumerated() {
            var u: CGFloat = -40 + off
            var k = 0
            while u < 160 {
                quad(ctx, u, v0, u + 31, v1, (k + i) % 2 == 0 ? mat : matLight)
                u += 31; k += 1
            }
            // vân cói chạy dọc theo chiếu
            ctx.strokePath(weave, width: 0.35) { p in
                var v = v0 + 0.05
                while v < v1 - 0.03 {
                    p.move(to: P(-40, v)); p.addLine(to: P(160, v))
                    v += 0.045
                }
            }
            // viền vải hai cạnh dài
            quad(ctx, -40, v0, 160, v0 + 0.022, border)
            quad(ctx, -40, v1 - 0.022, 160, v1, border)
            ctx.strokePath(gapLine, width: 0.5) { p in
                var u: CGFloat = -40 + off
                while u < 160 {
                    p.move(to: P(u, v0)); p.addLine(to: P(u, v1))
                    u += 31
                }
            }
        }
        wallShadow(ctx, rgb(0x6E7A4E))
    }

    // MARK: - Gạch

    private static func checker(_ ctx: GraphicsContext) {
        let a = rgb(0xF9DCDC), b = rgb(0xFFF5EE)
        ctx.rect(0, top, 125, depth, b)
        let w: CGFloat = 15.625
        for r in 0..<5 {
            let v0 = CGFloat(r) * 0.2
            for c in -2..<10 where (r + c) % 2 == 0 {
                quad(ctx, CGFloat(c) * w, v0, CGFloat(c + 1) * w, v0 + 0.2, a)
            }
        }
        wallShadow(ctx, rgb(0x9A6A6A))
    }

    private static func hexTiles(_ base: GraphicsContext) {
        base.rect(0, top, 125, depth, rgb(0xFBFDFB))
        let ctx = flat(base, squash: 0.6)
        let r: CGFloat = 6.4
        let hw = r * 0.866
        var rng = Seeded(s: 3)
        for row in 0..<11 {
            let cy = CGFloat(row) * r * 1.5 - 2
            let shift: CGFloat = row % 2 == 0 ? 0 : hw
            var cx: CGFloat = -hw + shift
            while cx < 135 {
                let ri = r - 0.75
                let pts = (0..<6).map { i -> CGPoint in
                    let a = Double(i) * .pi / 3 + .pi / 6
                    return CGPoint(x: cx + ri * CGFloat(cos(a)), y: cy + ri * CGFloat(sin(a)))
                }
                let n = rng.next()
                ctx.polygon(pts, rgb(n < 0.18 ? 0xBFE3D0 : (n < 0.55 ? 0xD8EFE2 : 0xE0F3E8)))
                cx += hw * 2
            }
        }
        wallShadow(base, rgb(0x5E8A72))
    }

    private static func marble(_ ctx: GraphicsContext) {
        let a = rgb(0xFCF8F6), b = rgb(0xF8E8EA)
        ctx.rect(0, top, 125, depth, a)
        let w: CGFloat = 31.25
        for r in 0..<3 {
            let v0 = CGFloat(r) / 3
            for c in -1..<6 where (r + c) % 2 == 0 {
                quad(ctx, CGFloat(c) * w, v0, CGFloat(c + 1) * w, v0 + 1.0 / 3, b)
            }
        }
        // vân đá: một dải mờ rộng và một đường mảnh chạy chéo nhẹ
        let veins: [(CGPoint, CGPoint, CGPoint)] = [
            (CGPoint(x: -2, y: 67), CGPoint(x: 36, y: 71), CGPoint(x: 18, y: 64)),
            (CGPoint(x: 72, y: 65), CGPoint(x: 112, y: 70), CGPoint(x: 90, y: 72)),
            (CGPoint(x: 92, y: 84), CGPoint(x: 128, y: 92), CGPoint(x: 106, y: 82)),
            (CGPoint(x: 6, y: 90), CGPoint(x: 52, y: 97), CGPoint(x: 30, y: 98))
        ]
        ctx.strokePath(rgb(0xF1DCE0).opacity(0.45), width: 1.6) { p in
            for (a, b, c) in veins { p.move(to: a); p.addQuadCurve(to: b, control: c) }
        }
        ctx.strokePath(rgb(0xE6C8CE).opacity(0.5), width: 0.3) { p in
            for (a, b, c) in veins { p.move(to: a); p.addQuadCurve(to: b, control: c) }
        }
        ctx.strokePath(rgb(0xEBDCDC), width: 0.5) { p in
            for r in 1..<3 {
                let v = CGFloat(r) / 3
                p.move(to: P(-40, v)); p.addLine(to: P(170, v))
            }
            for c in -1..<6 {
                p.move(to: P(CGFloat(c) * w, 0)); p.addLine(to: P(CGFloat(c) * w, 1))
            }
        }
        wallShadow(ctx, rgb(0x9A7A80))
    }

    private static func heartTiles(_ ctx: GraphicsContext) {
        let tile = rgb(0xFCE3EA), alt = rgb(0xFDEDF1), grout = rgb(0xFFFAFA), heart = rgb(0xF5B5C6)
        ctx.rect(0, top, 125, depth, grout)
        let w: CGFloat = 15.625, dv: CGFloat = 0.25
        let g: CGFloat = 0.6
        for r in 0..<4 {
            let v0 = CGFloat(r) * dv
            for c in -2..<10 {
                let u0 = CGFloat(c) * w
                quad(ctx, u0 + g, v0 + 0.012, u0 + w - g, v0 + dv - 0.012, (r + c) % 2 == 0 ? tile : alt)
                guard (r + c) % 2 == 0 else { continue }
                let p = P(u0 + w / 2, v0 + dv / 2)
                let s = 1 + 0.32 * (v0 + dv / 2)
                var hc = ctx
                hc.translateBy(x: p.x, y: p.y)
                hc.scaleBy(x: s, y: s * 0.62)
                hc.heart(center: .zero, size: 5.2, heart)
            }
        }
        wallShadow(ctx, rgb(0xA0627A))
    }

    private static func terrazzo(_ base: GraphicsContext) {
        base.rect(0, top, 125, depth, rgb(0xF7F1E8))
        let ctx = flat(base, squash: 0.6)
        var rng = Seeded(s: 21)
        let chips: [UInt32] = [0xF4C6B8, 0xB9DECB, 0xF6DFA2, 0xD3C8EF, 0xE6DACA]
        for i in 0..<64 {
            let x = rng.next() * 130 - 2, y = rng.next() * 64
            let s = 1.1 + rng.next() * 1.3
            let a = Double(rng.next()) * .pi
            let pts = (0..<5).map { k -> CGPoint in
                let ang = a + Double(k) * 1.256
                let rr = s * (0.7 + rng.next() * 0.45)
                return CGPoint(x: x + rr * CGFloat(cos(ang)), y: y + rr * CGFloat(sin(ang)))
            }
            ctx.polygon(pts, rgb(chips[i % chips.count]).opacity(0.8))
        }
        base.strokePath(rgb(0xE6DCCD), width: 0.45) { p in
            for r in 1..<2 {
                let v = CGFloat(r) / 2
                p.move(to: P(-40, v)); p.addLine(to: P(170, v))
            }
            for c in -1..<5 {
                p.move(to: P(CGFloat(c) * 41.7, 0)); p.addLine(to: P(CGFloat(c) * 41.7, 1))
            }
        }
        wallShadow(base, rgb(0x8A7A60))
    }

    private static func subway(_ ctx: GraphicsContext) {
        let grout = rgb(0xF3FAF6), tones: [UInt32] = [0xCDEBDD, 0xD6EFE3, 0xC6E7D7]
        ctx.rect(0, top, 125, depth, grout)
        let w: CGFloat = 14, dv: CGFloat = 1.0 / 7, g: CGFloat = 0.45
        var rng = Seeded(s: 9)
        for r in 0..<7 {
            let v0 = CGFloat(r) * dv
            var u: CGFloat = r % 2 == 0 ? -28 : -21
            while u < 155 {
                quad(ctx, u + g, v0 + 0.012, u + w - g, v0 + dv - 0.012, rgb(tones[Int(rng.next() * 30) % tones.count]))
                u += w
            }
        }
        wallShadow(ctx, rgb(0x4E7A66))
    }

    // MARK: - Thảm

    private static func carpetEdge(_ ctx: GraphicsContext, _ edge: Color) {
        ctx.rect(0, top, 125, 1.4, edge)
    }

    private static func dotCarpet(_ base: GraphicsContext) {
        base.rect(0, top, 125, depth, rgb(0xE6DCF6))
        let ctx = flat(base, squash: 0.6)
        for row in 0..<10 {
            let y = 4 + CGFloat(row) * 6.4
            var x: CGFloat = row % 2 == 0 ? 3 : 8
            while x < 128 {
                ctx.circle(x, y, 0.95, rgb(0xF8F4FD))
                x += 10
            }
        }
        carpetEdge(base, rgb(0xD5C8EE))
        wallShadow(base, rgb(0x6A5A9A))
    }

    private static func cloudCarpet(_ base: GraphicsContext) {
        base.rect(0, top, 125, depth, rgb(0xD3E8F7))
        let ctx = flat(base, squash: 0.6)
        let puff = Color.white.opacity(0.8)
        let clouds: [(CGFloat, CGFloat, CGFloat)] = [(14, 10, 0.8), (64, 6, 0.7), (108, 14, 0.85), (36, 34, 1.0),
                                                    (92, 42, 1.0), (10, 56, 0.9), (62, 60, 0.8), (118, 62, 0.8)]
        for (x, y, s) in clouds {
            ctx.ellipse(x - 9 * s, y - 2 * s, 18 * s, 6 * s, puff)
            ctx.circle(x - 3.5 * s, y - 2.5 * s, 3.6 * s, puff)
            ctx.circle(x + 2.5 * s, y - 3.5 * s, 4.4 * s, puff)
        }
        carpetEdge(base, rgb(0xBFDBF0))
        wallShadow(base, rgb(0x4E6E9A))
    }

    private static func starCarpet(_ base: GraphicsContext) {
        base.rect(0, top, 125, depth, rgb(0xBFC6EC))
        let ctx = flat(base, squash: 0.6)
        let stars: [(CGFloat, CGFloat, CGFloat)] = [(12, 8, 2.6), (46, 4, 2.0), (84, 10, 2.8), (116, 5, 2.0), (28, 26, 2.2),
                                                   (66, 30, 2.8), (104, 28, 2.2), (8, 46, 2.4), (44, 52, 2.2), (86, 54, 2.6),
                                                   (122, 46, 2.4), (24, 62, 2.0), (64, 62, 2.0), (104, 64, 2.2)]
        for (x, y, r) in stars {
            let pts = (0..<10).map { i -> CGPoint in
                let a = Double(i) * .pi / 5 - .pi / 2
                let rr = i % 2 == 0 ? r : r * 0.45
                return CGPoint(x: x + rr * CGFloat(cos(a)), y: y + rr * CGFloat(sin(a)))
            }
            ctx.polygon(pts, rgb(0xFFE9A8))
        }
        let dots: [(CGFloat, CGFloat)] = [(30, 10), (64, 16), (100, 18), (16, 34), (52, 38), (84, 40), (116, 34), (30, 50), (70, 46), (100, 56), (46, 66), (84, 68)]
        for (x, y) in dots { ctx.circle(x, y, 0.7, Color.white.opacity(0.8)) }
        carpetEdge(base, rgb(0xAAB2E0))
        wallShadow(base, rgb(0x3E4A7A))
    }

    // MARK: - Vườn

    /// Nền ngoài trời: mờ dần ở mép trên để hòa vào cỏ của bầu trời đang dùng.
    private static func ground(_ ctx: GraphicsContext, _ color: Color) {
        let g = Gradient(colors: [color.opacity(0), color])
        ctx.fill(Path(CGRect(x: 0, y: top, width: 125, height: 6)),
                 with: .linearGradient(g, startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: top + 6)))
        ctx.rect(0, top + 5.9, 125, depth, color)
    }

    private static func tuft(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ color: Color) {
        ctx.strokePath(color, width: 0.7 * s) { p in
            p.move(to: CGPoint(x: x - 1.6 * s, y: y)); p.addLine(to: CGPoint(x: x - 2.4 * s, y: y - 2.4 * s))
            p.move(to: CGPoint(x: x, y: y)); p.addLine(to: CGPoint(x: x, y: y - 3.2 * s))
            p.move(to: CGPoint(x: x + 1.6 * s, y: y)); p.addLine(to: CGPoint(x: x + 2.4 * s, y: y - 2.4 * s))
        }
    }

    private static func flower(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ color: Color, _ s: CGFloat = 1) {
        for i in 0..<5 {
            let a = Double(i) * 2 * .pi / 5
            ctx.circle(x + 1.1 * s * CGFloat(cos(a)), y + 0.8 * s * CGFloat(sin(a)), 0.85 * s, color)
        }
        ctx.circle(x, y, 0.6 * s, rgb(0xF2B84B))
    }

    private static func grass(_ ctx: GraphicsContext) {
        let base = rgb(0xB5DFA0), dark = rgb(0xA4D48E), tuftC = rgb(0x8EC27D)
        ground(ctx, base)
        // dải cỏ đậm nhạt như vừa cắt
        for (x, y, w, h) in [(-20.0, 70.0, 70.0, 12.0), (60.0, 66.0, 80.0, 10.0), (20.0, 84.0, 90.0, 14.0), (-30.0, 94.0, 60.0, 12.0)] {
            ctx.ellipse(x, y, w, h, dark.opacity(0.7))
        }
        let tufts: [(CGFloat, CGFloat, CGFloat)] = [(8, 69, 1.0), (30, 66, 0.9), (52, 72, 1.0), (78, 68, 0.9), (104, 71, 1.0),
                                                   (120, 80, 1.1), (16, 84, 1.2), (96, 88, 1.2), (40, 92, 1.3), (70, 97, 1.3), (6, 98, 1.3)]
        for (x, y, s) in tufts { tuft(ctx, x, y, s, tuftC) }
        let flowers: [(CGFloat, CGFloat, UInt32, CGFloat)] = [(20, 72, 0xFFFFFF, 0.9), (46, 66, 0xF7B6C8, 0.8), (66, 76, 0xF9D86E, 0.9),
                                                             (92, 66, 0xFFFFFF, 0.8), (112, 74, 0xF7B6C8, 0.9), (30, 88, 0xF9D86E, 1.1),
                                                             (84, 92, 0xFFFFFF, 1.1), (116, 94, 0xF9D86E, 1.1), (10, 92, 0xF7B6C8, 1.0)]
        for (x, y, c, s) in flowers { flower(ctx, x, y, rgb(c), s) }
    }

    private static func clover(_ ctx: GraphicsContext) {
        let base = rgb(0xA6D893), leaf = rgb(0x8CC77C), leafLight = rgb(0xBCE5A8)
        ground(ctx, base)
        var rng = Seeded(s: 17)
        for i in 0..<34 {
            let x = rng.next() * 128 - 2
            let v = rng.next()
            let y = top + 4 + v * 34
            let s = 0.75 + v * 0.6
            let c = i % 3 == 0 ? leafLight : leaf
            ctx.circle(x - 0.9 * s, y, 1.0 * s, c)
            ctx.circle(x + 0.9 * s, y, 1.0 * s, c)
            ctx.circle(x, y - 1.2 * s, 1.0 * s, c)
        }
        let blooms: [(CGFloat, CGFloat, CGFloat)] = [(22, 70, 1.0), (58, 67, 0.9), (98, 72, 1.0), (14, 90, 1.2), (78, 88, 1.2), (114, 96, 1.3), (44, 97, 1.2)]
        for (x, y, s) in blooms {
            ctx.ellipse(x - 1.4 * s, y - 1.6 * s, 2.8 * s, 3.0 * s, Color.white)
            ctx.ellipse(x - 0.9 * s, y - 0.4 * s, 1.8 * s, 1.4 * s, rgb(0xF6D7E2))
        }
    }

    private static func stonePath(_ ctx: GraphicsContext) {
        let grassC = rgb(0xB5DFA0)
        ground(ctx, grassC)
        // lối sỏi uốn từ mép dưới vào trong vườn
        var band = Path()
        band.move(to: CGPoint(x: 40, y: 100))
        band.addCurve(to: CGPoint(x: 70, y: 62), control1: CGPoint(x: 44, y: 82), control2: CGPoint(x: 80, y: 76))
        band.addLine(to: CGPoint(x: 80, y: 62))
        band.addCurve(to: CGPoint(x: 78, y: 100), control1: CGPoint(x: 96, y: 76), control2: CGPoint(x: 64, y: 84))
        band.closeSubpath()
        let g = Gradient(colors: [rgb(0xEDE2C8).opacity(0), rgb(0xEDE2C8)])
        ctx.fill(band, with: .linearGradient(g, startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: top + 6)))
        let stones: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [(49, 91, 20, 7), (56, 82, 15, 5.4), (66, 74.5, 12, 4.4), (71, 68.5, 9, 3.4)]
        for (x, y, w, h) in stones {
            ctx.ellipse(x, y + 0.9, w, h, rgb(0x9A8E78).opacity(0.18))
            ctx.ellipse(x, y, w, h, rgb(0xDCD6CA))
            ctx.ellipse(x + w * 0.18, y + h * 0.15, w * 0.5, h * 0.4, Color.white.opacity(0.35))
        }
        let pebbles: [(CGFloat, CGFloat)] = [(48, 86), (70, 89), (62, 80), (72, 79), (64, 70), (78, 72), (52, 97), (74, 97)]
        for (x, y) in pebbles { ctx.ellipse(x, y, 1.6, 1.0, rgb(0xC9BDA4)) }
        let tufts: [(CGFloat, CGFloat, CGFloat)] = [(10, 70, 1.0), (30, 76, 1.1), (100, 70, 1.0), (116, 84, 1.2), (20, 94, 1.3), (104, 96, 1.3)]
        for (x, y, s) in tufts { tuft(ctx, x, y, s, rgb(0x8EC27D)) }
        for (x, y, c) in [(18.0, 82.0, 0xFFFFFF), (94.0, 80.0, 0xF7B6C8), (112, 68, 0xF9D86E)] as [(CGFloat, CGFloat, UInt32)] {
            flower(ctx, x, y, rgb(c), 1.0)
        }
    }

    private static func sand(_ ctx: GraphicsContext) {
        let base = rgb(0xF5E6C6)
        ground(ctx, base)
        ctx.strokePath(rgb(0xE6D1A8).opacity(0.8), width: 0.6) { p in
            for (y, a) in [(68.0, 0.0), (75.0, 8.0), (83.0, -6.0), (92.0, 4.0)] as [(CGFloat, CGFloat)] {
                p.move(to: CGPoint(x: -4, y: y))
                var x: CGFloat = -4
                while x < 130 {
                    p.addQuadCurve(to: CGPoint(x: x + 16, y: y), control: CGPoint(x: x + 8 + a * 0.2, y: y - 1.6))
                    x += 16
                }
            }
        }
        // vỏ sò và sao biển nhỏ
        for (x, y, s) in [(24.0, 79.0, 1.0), (98.0, 88.0, 1.2), (60, 70, 0.8)] as [(CGFloat, CGFloat, CGFloat)] {
            ctx.polygon([CGPoint(x: x, y: y + 1.6 * s), CGPoint(x: x - 2.2 * s, y: y - 0.8 * s), CGPoint(x: x + 2.2 * s, y: y - 0.8 * s)], rgb(0xF6C3BD))
            ctx.ellipse(x - 2.4 * s, y - 2.2 * s, 4.8 * s, 2.8 * s, rgb(0xF6C3BD))
            ctx.strokePath(rgb(0xE59E98), width: 0.35) { p in
                p.move(to: CGPoint(x: x, y: y + 1.4 * s)); p.addLine(to: CGPoint(x: x, y: y - 2 * s))
                p.move(to: CGPoint(x: x, y: y + 1.4 * s)); p.addLine(to: CGPoint(x: x - 1.3 * s, y: y - 1.7 * s))
                p.move(to: CGPoint(x: x, y: y + 1.4 * s)); p.addLine(to: CGPoint(x: x + 1.3 * s, y: y - 1.7 * s))
            }
        }
        let star: (CGFloat, CGFloat, CGFloat) = (82, 74, 2.4)
        let pts = (0..<10).map { i -> CGPoint in
            let a = Double(i) * .pi / 5 - .pi / 2
            let rr = i % 2 == 0 ? star.2 : star.2 * 0.5
            return CGPoint(x: star.0 + rr * CGFloat(cos(a)), y: star.1 + rr * 0.75 * CGFloat(sin(a)))
        }
        ctx.polygon(pts, rgb(0xF2A98A))
        for (x, y) in [(12.0, 70.0), (40.0, 90.0), (70.0, 96.0), (112.0, 72.0), (118.0, 96.0), (50.0, 76.0)] as [(CGFloat, CGFloat)] {
            ctx.circle(x, y, 0.5, rgb(0xD9C095))
        }
    }

    private static func plaza(_ ctx: GraphicsContext) {
        let moss = rgb(0xC9D7AE)
        ground(ctx, moss)
        let tones: [UInt32] = [0xE6E0D4, 0xDDD6C9, 0xEBE6DD, 0xE2D9CC]
        var rng = Seeded(s: 13)
        let dv: CGFloat = 1.0 / 7
        for r in 0..<7 {
            let v0 = CGFloat(r) * dv + 0.02
            var u: CGFloat = r % 2 == 0 ? -30 : -24
            while u < 155 {
                let w: CGFloat = 10 + rng.next() * 4
                let a = P(u + 0.7, v0 + 0.015), b = P(u + w - 0.7, v0 + dv - 0.015)
                let s = 1 + 0.32 * v0
                let rect = CGRect(x: a.x, y: a.y, width: b.x - a.x, height: b.y - a.y)
                ctx.fill(Path(roundedRect: rect, cornerRadius: 1.6 * s), with: .color(rgb(tones[Int(rng.next() * 30) % tones.count])))
                ctx.fill(Path(roundedRect: CGRect(x: rect.minX + 0.8, y: rect.minY + 0.5, width: rect.width * 0.55, height: rect.height * 0.35),
                              cornerRadius: 1), with: .color(Color.white.opacity(0.25)))
                u += w
            }
        }
    }

    private static func deck(_ ctx: GraphicsContext, tones: [UInt32], gap: UInt32, nail: UInt32) {
        // cỏ phía sau mép sàn, rồi sàn gỗ bắt đầu từ v = 0.1
        ground(ctx, rgb(0xB5DFA0))
        let v0Deck: CGFloat = 0.1, n = 7
        let rowH = (1 - v0Deck) / CGFloat(n)
        let firstY = P(0, v0Deck).y
        ctx.rect(0, firstY, 125, 100 - firstY, rgb(gap))
        var rng = Seeded(s: 19)
        for r in 0..<n {
            let v0 = v0Deck + CGFloat(r) * rowH
            let a = P(0, v0 + 0.01), b = P(0, v0 + rowH - 0.01)
            ctx.rect(0, a.y, 125, b.y - a.y, rgb(tones[Int(rng.next() * 30) % tones.count]))
            ctx.rect(0, a.y, 125, 0.5, Color.white.opacity(0.22))
            // đinh ở các thanh dầm
            for u in stride(from: CGFloat(-15), through: 140, by: 31.25) {
                let p = P(u, v0 + rowH / 2)
                ctx.circle(p.x, p.y, 0.4 + 0.15 * v0, rgb(nail))
            }
        }
        ctx.strokePath(rgb(gap).opacity(0.6), width: 0.45) { p in
            for (r, u) in [(0, 40.0), (1, 92.0), (2, 18.0), (3, 70.0), (4, 110.0), (5, 44.0), (6, 86.0)] as [(Int, CGFloat)] {
                let v0 = v0Deck + CGFloat(r) * rowH
                p.move(to: P(u, v0)); p.addLine(to: P(u, v0 + rowH))
            }
        }
        // cỏ lấp ló ở mép sau sàn
        for (x, s) in [(6.0, 0.8), (30.0, 0.7), (58.0, 0.8), (88.0, 0.7), (114.0, 0.8)] as [(CGFloat, CGFloat)] {
            tuft(ctx, x, firstY + 0.6, s, rgb(0x8EC27D))
        }
    }
}
