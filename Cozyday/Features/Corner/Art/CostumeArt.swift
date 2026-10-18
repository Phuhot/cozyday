import SwiftUI

/// Trang phục & phụ kiện thêm cho thú cưng (hệ tọa độ 100×100 giống `PetPainter`).
/// Mắt ở (37.5, 50) và (62.5, 50); đỉnh đầu ở y≈28; vùng cổ y≈61–67; chân trước ở (36..46 | 54..64, 80..87).
enum CostumeArt {

    // MARK: Tiện ích

    private static func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    /// Bản lật ngang (x → 100 − x) để vẽ đồ đối xứng một lần cho cả hai bên.
    private static func mirrored(_ ctx: GraphicsContext, _ flip: Bool) -> GraphicsContext {
        var c = ctx
        if flip {
            c.translateBy(x: 100, y: 0)
            c.scaleBy(x: -1, y: 1)
        }
        return c
    }

    /// Đa giác bo tròn góc (tô rồi viền cùng màu, đầu nét tròn).
    private static func soft(_ ctx: GraphicsContext, _ pts: [CGPoint], _ color: Color, _ round: CGFloat = 2) {
        ctx.polygon(pts, color)
        ctx.strokePath(color, width: round) { p in
            p.addLines(pts)
            p.closeSubpath()
        }
    }

    private static func starPoints(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ inner: CGFloat) -> [CGPoint] {
        var pts: [CGPoint] = []
        for i in 0..<10 {
            let ang = -Double.pi / 2 + Double(i) * Double.pi / 5
            let rr = i % 2 == 0 ? r : inner
            pts.append(CGPoint(x: cx + rr * CGFloat(cos(ang)), y: cy + rr * CGFloat(sin(ang))))
        }
        return pts
    }

    private static func star(_ ctx: GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ color: Color) {
        soft(ctx, starPoints(cx, cy, r, r * 0.48), color, r * 0.3)
    }

    private static func sparkle(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ color: Color) {
        ctx.draw(Text("✦").font(.system(size: size)).foregroundColor(color), at: CGPoint(x: x, y: y))
    }

    // MARK: Mũ

    static func hat(_ id: String, _ ctx: GraphicsContext, _ a: PetAppearance) {
        switch id {
        case "hat.catears": catEars(ctx, a)
        case "hat.cap": cap(ctx, a)
        case "hat.beret": beret(ctx)
        case "hat.santa": santa(ctx)
        case "hat.antlers": antlers(ctx)
        case "hat.chef": chef(ctx)
        case "hat.pumpkin": pumpkin(ctx)
        case "hat.frog": frogHat(ctx)
        case "hat.headphones": headphones(ctx, a)
        case "hat.cowboy": cowboy(ctx)
        case "hat.cloud": cloud(ctx)
        case "hat.halo": halo(ctx)
        case "hat.tiara": tiara(ctx)
        default: break
        }
    }

    private static func catEars(_ ctx: GraphicsContext, _ a: PetAppearance) {
        let night = a.fur == .midnight
        let band = night ? rgb(0xE77FA0) : rgb(0x544866)
        let inner = night ? rgb(0xFCE0EA) : rgb(0xF4A9C0)
        for flip in [false, true] {
            let c = mirrored(ctx, flip)
            soft(c, [pt(32.5, 34.5), pt(36, 13.5), pt(48, 29)], band, 3)
            soft(c, [pt(36, 30.5), pt(37.6, 20), pt(44, 29)], inner, 1.2)
        }
        ctx.strokePath(band, width: 3.2) { p in
            p.move(to: pt(25, 41)); p.addQuadCurve(to: pt(75, 41), control: pt(50, 15))
        }
        ctx.strokePath(Color.white.opacity(0.35), width: 0.9) { p in
            p.move(to: pt(30, 33.5)); p.addQuadCurve(to: pt(40, 28.5), control: pt(34, 30))
        }
    }

    private static func cap(_ ctx: GraphicsContext, _ a: PetAppearance) {
        let blue = rgb(0x7FA6E0), deep = rgb(0x5F86C6)
        // Lưỡi trai quay ra sau, ló lên phía sau đỉnh mũ.
        ctx.rotated(-24, around: pt(66, 22)) { c in c.ellipse(54, 16, 32, 8.5, deep) }
        var dome = ctx
        dome.clip(to: Path(CGRect(x: 0, y: 0, width: 100, height: 34)))
        dome.ellipse(26, 15, 48, 38, blue)
        ctx.strokePath(deep.opacity(0.55), width: 0.9) { p in
            p.move(to: pt(50, 16)); p.addQuadCurve(to: pt(37, 33), control: pt(39, 19))
            p.move(to: pt(50, 16)); p.addQuadCurve(to: pt(63, 33), control: pt(61, 19))
        }
        // Lỗ khóa cài phía trước (vì đội ngược).
        var hole = ctx
        hole.clip(to: Path(CGRect(x: 0, y: 0, width: 100, height: 32)))
        hole.ellipse(42.5, 24.5, 15, 16, FurPalette.of(a.fur).base)
        ctx.rect(42, 28.8, 16, 2.2, deep, radius: 1.1)
        ctx.rect(47.5, 28.4, 3, 3, rgb(0xF0C26A), radius: 0.8)
        ctx.rect(26, 31.5, 48, 3.6, deep, radius: 1.8)
        ctx.circle(50, 15.6, 2.2, deep)
        ctx.ellipse(31, 20, 8, 4, Color.white.opacity(0.35))
    }

    private static func beret(_ ctx: GraphicsContext) {
        let red = rgb(0xCF5866), deep = rgb(0xA9424F)
        ctx.rotated(-9, around: pt(54, 26)) { c in
            c.rect(52.5, 11.5, 3, 6, deep, radius: 1.5)
            c.ellipse(29, 23, 50, 10.5, deep)
            c.ellipse(27, 15, 54, 16, red)
            c.ellipse(36, 17.5, 15, 4.5, Color.white.opacity(0.3))
        }
    }

    private static func santa(_ ctx: GraphicsContext) {
        let red = rgb(0xE0565B), deep = rgb(0xC4434B)
        let fluff = rgb(0xFFFDFB), fshade = rgb(0xE6DFEC)
        var p = Path()
        p.move(to: pt(29, 31))
        p.addQuadCurve(to: pt(60, 8), control: pt(33, 11))
        p.addQuadCurve(to: pt(82, 25), control: pt(78, 8))
        p.addQuadCurve(to: pt(71, 31), control: pt(73, 19))
        p.closeSubpath()
        ctx.fill(p, with: .color(red))
        ctx.strokePath(deep, width: 1.2) { q in
            q.move(to: pt(64, 12)); q.addQuadCurve(to: pt(74, 24), control: pt(72, 14))
        }
        ctx.strokePath(Color.white.opacity(0.35), width: 1.4) { q in
            q.move(to: pt(37, 25)); q.addQuadCurve(to: pt(48, 13), control: pt(40, 16))
        }
        ctx.rect(22.5, 28.3, 55, 8.7, fshade, radius: 4.3)
        ctx.rect(22.5, 27.3, 55, 8, fluff, radius: 4)
        for x in stride(from: CGFloat(28), through: 72, by: 7) {
            ctx.circle(x, 32.5, 1.1, fshade)
        }
        ctx.circle(83.4, 26.6, 5.3, fshade)
        ctx.circle(83, 26, 4.9, fluff)
    }

    private static func antlers(_ ctx: GraphicsContext) {
        let horn = rgb(0xB98256)
        for flip in [false, true] {
            let c = mirrored(ctx, flip)
            c.strokePath(horn, width: 3.4) { p in
                p.move(to: pt(40, 30)); p.addQuadCurve(to: pt(31, 5), control: pt(29, 21))
                p.move(to: pt(32.2, 19.3)); p.addQuadCurve(to: pt(21, 12), control: pt(25, 18.5))
                p.move(to: pt(30.8, 12.6)); p.addQuadCurve(to: pt(37.5, 5.5), control: pt(34, 10))
            }
            c.strokePath(Color.white.opacity(0.35), width: 0.9) { p in
                p.move(to: pt(37.5, 27)); p.addQuadCurve(to: pt(31.5, 12), control: pt(31, 20))
            }
        }
        // Nhánh nhựa ruồi nhỏ ở giữa.
        let leaf = rgb(0x6FAF72)
        ctx.rotated(-28, around: pt(47, 27)) { c in c.ellipse(39.5, 24.5, 9, 5, leaf) }
        ctx.rotated(28, around: pt(53, 27)) { c in c.ellipse(51.5, 24.5, 9, 5, leaf) }
        let berry = rgb(0xE0565B)
        ctx.circle(48.2, 28.2, 1.9, berry)
        ctx.circle(51.8, 28.2, 1.9, berry)
        ctx.circle(50, 25.6, 1.9, berry)
        ctx.circle(49.5, 25, 0.6, Color.white.opacity(0.7))
    }

    private static func chef(_ ctx: GraphicsContext) {
        let white = rgb(0xFFFFFF), line = rgb(0xDAD2E4)
        ctx.circle(38, 17.5, 10.5, line)
        ctx.circle(50, 13, 12, line)
        ctx.circle(62, 17.5, 10.5, line)
        ctx.rect(31, 16, 38, 18.5, line, radius: 4)
        ctx.circle(38, 17.5, 9.5, white)
        ctx.circle(50, 13, 11, white)
        ctx.circle(62, 17.5, 9.5, white)
        ctx.rect(32, 17, 36, 10, white)
        ctx.rect(32, 24.5, 36, 9, rgb(0xF6F2F8), radius: 3)
        ctx.strokePath(line, width: 1) { p in
            p.move(to: pt(33, 24.5)); p.addLine(to: pt(67, 24.5))
            p.move(to: pt(44, 14)); p.addQuadCurve(to: pt(43, 23), control: pt(41.5, 18.5))
            p.move(to: pt(56, 14)); p.addQuadCurve(to: pt(57, 23), control: pt(58.5, 18.5))
        }
        ctx.ellipse(43, 6, 7, 4, rgb(0xF4F0F8))
    }

    private static func pumpkin(_ ctx: GraphicsContext) {
        let o1 = rgb(0xF6A04F), o2 = rgb(0xE5853A)
        ctx.strokePath(rgb(0x7FA052), width: 1.2) { p in
            p.move(to: pt(52, 9)); p.addQuadCurve(to: pt(60, 6), control: pt(54, 3))
            p.addQuadCurve(to: pt(58, 9.5), control: pt(62, 9))
        }
        ctx.rect(48.2, 4.5, 3.6, 8, rgb(0x7A8F4E), radius: 1.6)
        ctx.ellipse(30, 12, 24, 22.5, o2)
        ctx.ellipse(46, 12, 24, 22.5, o2)
        ctx.ellipse(37, 10.5, 26, 24, o1)
        ctx.ellipse(40, 12.5, 6, 3.5, Color.white.opacity(0.35))
        ctx.rotated(28, around: pt(56, 8)) { c in c.ellipse(53, 5.5, 10, 5, rgb(0x8CBF6E)) }
        let carve = rgb(0x8A4A1E)
        soft(ctx, [pt(41, 21.5), pt(46, 21.5), pt(43.5, 17.5)], carve, 1)
        soft(ctx, [pt(54, 21.5), pt(59, 21.5), pt(56.5, 17.5)], carve, 1)
        ctx.strokePath(carve, width: 1.6) { p in
            p.move(to: pt(44, 25.5)); p.addQuadCurve(to: pt(56, 25.5), control: pt(50, 30))
        }
    }

    private static func frogHat(_ ctx: GraphicsContext) {
        let g = rgb(0x8CCB7E), gd = rgb(0x6FB063)
        var hood = ctx
        hood.clip(to: Path(CGRect(x: 0, y: 0, width: 100, height: 35)))
        hood.ellipse(23, 19, 54, 42, g)
        ctx.rect(22.5, 31.5, 55, 5, gd, radius: 2.5)
        for x in [CGFloat(37), 63] {
            ctx.circle(x, 20, 7.5, g)
            ctx.circle(x, 20.5, 5, .white)
            ctx.circle(x, 21.3, 2.7, rgb(0x2E2A36))
            ctx.circle(x - 0.9, 20.3, 0.9, .white)
        }
        ctx.strokePath(gd, width: 1.3) { p in
            p.move(to: pt(45, 27.5)); p.addQuadCurve(to: pt(55, 27.5), control: pt(50, 31))
        }
        ctx.ellipse(29.5, 26.5, 5, 2.6, rgb(0xF4A3B4).opacity(0.85))
        ctx.ellipse(65.5, 26.5, 5, 2.6, rgb(0xF4A3B4).opacity(0.85))
    }

    private static func headphones(_ ctx: GraphicsContext, _ a: PetAppearance) {
        let hx: CGFloat = a.species == .hamster ? 3 : 0
        let band = rgb(0x8E7CC9), cup = rgb(0xF4A6BD), pad = rgb(0xDE8AA3)
        ctx.strokePath(band, width: 3.6) { p in
            p.move(to: pt(18 - hx, 44))
            p.addCurve(to: pt(82 + hx, 44), control1: pt(17 - hx, 16), control2: pt(83 + hx, 16))
        }
        ctx.strokePath(Color.white.opacity(0.4), width: 1) { p in
            p.move(to: pt(40, 24.5)); p.addQuadCurve(to: pt(56, 24), control: pt(48, 23))
        }
        for flip in [false, true] {
            let c = mirrored(ctx, flip)
            c.rect(19.5 - hx, 41.5, 5, 14, pad, radius: 2.5)
            c.rect(11.5 - hx, 39, 11, 19, cup, radius: 5.5)
            c.ellipse(13.5 - hx, 42, 3, 7, Color.white.opacity(0.5))
        }
        ctx.draw(Text("♪").font(.system(size: 7, weight: .bold)).foregroundColor(band), at: pt(88, 26))
    }

    private static func cowboy(_ ctx: GraphicsContext) {
        let crown = rgb(0xC98F5E), brim = rgb(0xB57D4D), band = rgb(0x7A4E33)
        var cp = Path()
        cp.move(to: pt(34, 30))
        cp.addLine(to: pt(35.5, 14))
        cp.addQuadCurve(to: pt(50, 13), control: pt(42, 7.5))
        cp.addQuadCurve(to: pt(64.5, 14), control: pt(58, 7.5))
        cp.addLine(to: pt(66, 30))
        cp.closeSubpath()
        ctx.fill(cp, with: .color(crown))
        ctx.strokePath(Color.white.opacity(0.3), width: 1.6) { p in
            p.move(to: pt(39, 15.5)); p.addLine(to: pt(38.5, 21.5))
        }
        ctx.rect(34.3, 23.3, 31.4, 4.6, band)
        star(ctx, 50, 25.6, 2.1, rgb(0xF0C26A))
        var bp = Path()
        bp.move(to: pt(8, 21))
        bp.addQuadCurve(to: pt(50, 34), control: pt(20, 35.5))
        bp.addQuadCurve(to: pt(92, 21), control: pt(80, 35.5))
        bp.addQuadCurve(to: pt(50, 28.5), control: pt(78, 30))
        bp.addQuadCurve(to: pt(8, 21), control: pt(22, 30))
        bp.closeSubpath()
        ctx.fill(bp, with: .color(brim))
        ctx.strokePath(Color.white.opacity(0.25), width: 1) { p in
            p.move(to: pt(14, 25)); p.addQuadCurve(to: pt(30, 30.5), control: pt(20, 29.5))
        }
    }

    private static func cloud(_ ctx: GraphicsContext) {
        let shade = rgb(0xC9D8EE), white = rgb(0xF9FBFF)
        for (dy, color) in [(CGFloat(1.6), shade), (CGFloat(0), white)] {
            ctx.circle(39, 16 + dy, 7, color)
            ctx.circle(50, 12 + dy, 9.5, color)
            ctx.circle(61, 16 + dy, 7, color)
            ctx.rect(32, 14 + dy, 36, 9, color, radius: 4.5)
        }
        let ink = rgb(0x6B6390)
        ctx.strokePath(ink, width: 1.1) { p in
            p.move(to: pt(43.4, 17)); p.addQuadCurve(to: pt(47, 17), control: pt(45.2, 14.6))
            p.move(to: pt(53, 17)); p.addQuadCurve(to: pt(56.6, 17), control: pt(54.8, 14.6))
            p.move(to: pt(48.8, 18.8)); p.addQuadCurve(to: pt(51.2, 18.8), control: pt(50, 20.3))
        }
        ctx.ellipse(39.5, 18, 4, 2, rgb(0xF4A3B4).opacity(0.75))
        ctx.ellipse(56.5, 18, 4, 2, rgb(0xF4A3B4).opacity(0.75))
        sparkle(ctx, 71, 8, 6, rgb(0xF0C26A))
        sparkle(ctx, 28, 9, 4, rgb(0xF0C26A))
    }

    private static func halo(_ ctx: GraphicsContext) {
        let ring = CGRect(x: 31, y: 9.5, width: 38, height: 11)
        ctx.strokePath(rgb(0xFFE7A0).opacity(0.6), width: 5.5) { p in p.addEllipse(in: ring) }
        ctx.strokePath(rgb(0xF2C14E), width: 2.6) { p in p.addEllipse(in: ring) }
        ctx.strokePath(Color.white.opacity(0.75), width: 1) { p in
            p.move(to: pt(36, 11.8)); p.addQuadCurve(to: pt(46, 9.8), control: pt(40, 10))
        }
        sparkle(ctx, 73, 9, 5, rgb(0xF2C14E))
    }

    private static func tiara(_ ctx: GraphicsContext) {
        let silver = rgb(0xBAC4E2), light = rgb(0xE9EEFB)
        let pts = [pt(29, 33), pt(31, 26), pt(35, 29.5), pt(40, 20), pt(45, 27), pt(50, 13), pt(55, 27), pt(60, 20),
                   pt(65, 29.5), pt(69, 26), pt(71, 33), pt(60, 30.5), pt(50, 29.5), pt(40, 30.5)]
        soft(ctx, pts, silver, 1.6)
        ctx.strokePath(light, width: 1) { p in
            p.move(to: pt(31, 31.5)); p.addQuadCurve(to: pt(69, 31.5), control: pt(50, 26.5))
        }
        ctx.circle(40, 19.6, 1.6, light)
        ctx.circle(60, 19.6, 1.6, light)
        ctx.circle(31, 25.6, 1.2, light)
        ctx.circle(69, 25.6, 1.2, light)
        // Viên đá giữa hình giọt nước.
        var gem = Path()
        gem.move(to: pt(50, 15.5))
        gem.addQuadCurve(to: pt(50, 26.5), control: pt(45, 23))
        gem.addQuadCurve(to: pt(50, 15.5), control: pt(55, 23))
        ctx.fill(gem, with: .color(rgb(0x7FD1EA)))
        ctx.ellipse(48.4, 20, 1.6, 3, Color.white.opacity(0.75))
        ctx.circle(40.5, 26, 1.9, rgb(0xF59AC0))
        ctx.circle(59.5, 26, 1.9, rgb(0xF59AC0))
        ctx.circle(34, 29.5, 1.2, rgb(0xB79BEA))
        ctx.circle(66, 29.5, 1.2, rgb(0xB79BEA))
        sparkle(ctx, 57, 13, 5, rgb(0xF0C26A))
        sparkle(ctx, 33, 19, 4, rgb(0xF0C26A))
    }

    // MARK: Kính

    static func glasses(_ id: String, _ ctx: GraphicsContext, _ a: PetAppearance) {
        switch id {
        case "glasses.nerd":
            let frame = rgb(0x5A4136)
            ctx.rect(28.5, 43, 18, 14, Color.white.opacity(0.22), radius: 3)
            ctx.rect(53.5, 43, 18, 14, Color.white.opacity(0.22), radius: 3)
            ctx.strokePath(frame, width: 2.4) { p in
                p.addRoundedRect(in: CGRect(x: 28.5, y: 43, width: 18, height: 14), cornerSize: CGSize(width: 3, height: 3))
                p.addRoundedRect(in: CGRect(x: 53.5, y: 43, width: 18, height: 14), cornerSize: CGSize(width: 3, height: 3))
                p.move(to: pt(46.5, 48)); p.addLine(to: pt(53.5, 48))
                p.move(to: pt(28.5, 47)); p.addLine(to: pt(21, 46))
                p.move(to: pt(71.5, 47)); p.addLine(to: pt(79, 46))
            }
            ctx.rect(47.8, 45.6, 4.4, 5, rgb(0xFBF8F2), radius: 0.8)
            ctx.strokePath(Color.white.opacity(0.6), width: 1) { p in
                p.move(to: pt(31.5, 46.5)); p.addLine(to: pt(34, 45.5))
                p.move(to: pt(56.5, 46.5)); p.addLine(to: pt(59, 45.5))
            }
        case "glasses.goggles":
            let rim = rgb(0x4FA9D6), strap = rgb(0x3F8FBE)
            ctx.strokePath(strap, width: 3) { p in
                p.move(to: pt(29, 50)); p.addLine(to: pt(18.5, 48))
                p.move(to: pt(71, 50)); p.addLine(to: pt(81.5, 48))
            }
            ctx.strokePath(strap, width: 2) { p in
                p.move(to: pt(46, 50)); p.addQuadCurve(to: pt(54, 50), control: pt(50, 47.5))
            }
            for cx in [CGFloat(37.5), 62.5] {
                ctx.ellipse(cx - 8.5, 42.5, 17, 15, rgb(0xBFE8F7).opacity(0.4))
                ctx.strokePath(rim, width: 2.8) { p in
                    p.addEllipse(in: CGRect(x: cx - 8.5, y: 42.5, width: 17, height: 15))
                }
                ctx.strokePath(Color.white.opacity(0.85), width: 1.2) { p in
                    p.move(to: pt(cx - 5, 47.5)); p.addQuadCurve(to: pt(cx - 1, 45), control: pt(cx - 4.5, 45))
                }
            }
        case "glasses.star":
            let yellow = rgb(0xF6C445), rim = rgb(0xE79A3A)
            for cx in [CGFloat(37.5), 62.5] {
                soft(ctx, starPoints(cx, 50.5, 10.5, 5.6), rim, 2.4)
                soft(ctx, starPoints(cx, 50.5, 9.2, 4.9), yellow.opacity(0.92), 1.6)
                ctx.circle(cx - 2.5, 47.5, 1.2, Color.white.opacity(0.85))
            }
            ctx.strokePath(rim, width: 1.4) { p in
                p.move(to: pt(46.5, 48.5)); p.addLine(to: pt(53.5, 48.5))
                p.move(to: pt(28, 47.5)); p.addLine(to: pt(21, 46))
                p.move(to: pt(72, 47.5)); p.addLine(to: pt(79, 46))
            }
            sparkle(ctx, 76, 40, 6, rgb(0xF0C26A))
        case "glasses.aviator":
            let gold = rgb(0xD9A441), lens = rgb(0x5E7FA3)
            for flip in [false, true] {
                let c = mirrored(ctx, flip)
                var l = Path()
                l.move(to: pt(28.5, 44.5))
                l.addLine(to: pt(46.5, 44.5))
                l.addCurve(to: pt(38.5, 57.5), control1: pt(47.5, 50.5), control2: pt(44.5, 57.5))
                l.addCurve(to: pt(28.5, 44.5), control1: pt(31, 57.5), control2: pt(27, 49.5))
                l.closeSubpath()
                c.fill(l, with: .color(lens.opacity(0.85)))
                c.stroke(l, with: .color(gold), style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round))
                c.strokePath(Color.white.opacity(0.5), width: 1.4) { p in
                    p.move(to: pt(31.5, 47.5)); p.addLine(to: pt(35.5, 46.5))
                }
                c.strokePath(gold, width: 1.2) { p in
                    p.move(to: pt(28.5, 45.5)); p.addLine(to: pt(21, 46))
                }
            }
            ctx.strokePath(gold, width: 1.2) { p in
                p.move(to: pt(46.5, 44.8)); p.addLine(to: pt(53.5, 44.8))
                p.move(to: pt(47, 48)); p.addQuadCurve(to: pt(53, 48), control: pt(50, 46.5))
            }
        case "glasses.pixel":
            let ink = rgb(0x1F1B26)
            let s: CGFloat = 2.5, ox: CGFloat = 26.25, oy: CGFloat = 44.5
            func cell(_ col: Int, _ row: Int, _ color: Color) {
                ctx.rect(ox + CGFloat(col) * s, oy + CGFloat(row) * s, s + 0.05, s + 0.05, color)
            }
            for col in -2...20 { cell(col, 0, ink) }
            for col in Array(1...7) + Array(11...17) { cell(col, 1, ink) }
            for col in Array(2...6) + Array(12...16) { cell(col, 2, ink) }
            for col in Array(3...5) + Array(13...15) { cell(col, 3, ink) }
            for col in [2, 12] { cell(col, 1, Color.white.opacity(0.85)) }
            for col in [3, 13] { cell(col, 2, Color.white.opacity(0.85)) }
        default:
            break
        }
    }

    // MARK: Cổ

    static func neck(_ id: String, _ ctx: GraphicsContext, _ a: PetAppearance) {
        switch id {
        case "neck.collar":
            let band = rgb(0x7FB7D9)
            ctx.rect(26, 61.2, 48, 4.8, band, radius: 2.4)
            ctx.rect(30, 62.1, 40, 1.1, Color.white.opacity(0.45), radius: 0.5)
            ctx.strokePath(rgb(0xD9A441), width: 1) { p in
                p.addEllipse(in: CGRect(x: 48.4, y: 65.2, width: 3.2, height: 3.2))
            }
            ctx.heart(center: pt(50, 72.6), size: 10, rgb(0xE8B23A))
            ctx.heart(center: pt(50, 72.3), size: 8.4, rgb(0xF4CB5A))
            ctx.circle(47.6, 70.6, 0.9, Color.white.opacity(0.85))
        case "neck.tie":
            for flip in [false, true] {
                let c = mirrored(ctx, flip)
                soft(c, [pt(41, 60.8), pt(48, 62.2), pt(44.5, 67)], rgb(0xFBFAFD), 1.2)
            }
            let navy = rgb(0x5A72C0)
            var blade = Path()
            blade.addLines([pt(47.6, 66.5), pt(52.4, 66.5), pt(55, 77.5), pt(50, 82), pt(45, 77.5)])
            blade.closeSubpath()
            ctx.fill(blade, with: .color(navy))
            var stripes = ctx
            stripes.clip(to: blade)
            stripes.strokePath(rgb(0xF0C26A), width: 1.2) { p in
                for y in stride(from: CGFloat(64), through: 84, by: 4.5) {
                    p.move(to: pt(43, y + 4)); p.addLine(to: pt(57, y - 2))
                }
            }
            soft(ctx, [pt(46.5, 61.8), pt(53.5, 61.8), pt(52.3, 67), pt(47.7, 67)], rgb(0x4A60AA), 1)
        case "neck.ruff":
            let white = rgb(0xFFFFFF), shade = rgb(0xDFD8E8)
            for i in 0..<10 {
                let x = 27 + CGFloat(i) * 5.1
                let y = 61.5 + 2.2 * (1 - pow((x - 50) / 24, 2))
                ctx.circle(x, y, 4.3, shade)
            }
            for i in 0..<9 {
                let x = 29.5 + CGFloat(i) * 5.12
                let y = 63.5 + 3.5 * (1 - pow((x - 50) / 22, 2))
                ctx.circle(x, y + 0.6, 4.4, shade)
                ctx.circle(x, y, 4.2, white)
                ctx.strokePath(shade, width: 0.8) { p in
                    p.move(to: pt(x, y - 2.2)); p.addLine(to: pt(x, y + 2.6))
                }
            }
        case "neck.pearls":
            let rim = rgb(0xD8CCC2), pearl = rgb(0xFFF9F3), shade = rgb(0xEFE4DA)
            for i in 0..<11 {
                let x = 27 + CGFloat(i) * 4.6
                let y = 61.8 + 6.5 * (1 - pow((x - 50) / 23, 2))
                ctx.circle(x, y, 2.7, rim)
                ctx.circle(x, y, 2.3, pearl)
                ctx.circle(x + 0.6, y + 0.7, 1.3, shade)
                ctx.circle(x - 0.8, y - 0.8, 0.7, .white)
            }
            ctx.circle(50, 73, 3.3, rgb(0xE9A9BC))
            ctx.circle(50, 73, 2.8, rgb(0xF8CBD8))
            ctx.circle(49, 72, 0.9, .white)
        case "neck.medal":
            soft(ctx, [pt(36.5, 61), pt(42.5, 61), pt(52, 72.5), pt(47.5, 74)], rgb(0x6FA3D9), 1)
            soft(ctx, [pt(63.5, 61), pt(57.5, 61), pt(48, 72.5), pt(52.5, 74)], rgb(0xE56B6B), 1)
            ctx.circle(50, 76, 6.3, rgb(0xDDA332))
            ctx.circle(50, 76, 4.9, rgb(0xF6CF5A))
            star(ctx, 50, 76.2, 3, rgb(0xE5AE3C))
            ctx.circle(47.3, 73.6, 1, Color.white.opacity(0.85))
        default:
            break
        }
    }

    // MARK: Áo

    static func outfit(_ id: String, _ ctx: GraphicsContext, clipped: GraphicsContext, _ a: PetAppearance) {
        switch id {
        case "outfit.apron":
            let pink = rgb(0xF6BCCB), deep = rgb(0xE38FA6)
            ctx.strokePath(deep, width: 2.2) { p in
                p.move(to: pt(38.5, 63.5)); p.addLine(to: pt(32.5, 60.5))
                p.move(to: pt(61.5, 63.5)); p.addLine(to: pt(67.5, 60.5))
            }
            clipped.rect(37, 62.5, 26, 14, pink, radius: 3)
            clipped.rect(29, 71, 42, 30, pink, radius: 5)
            clipped.rect(0, 70.5, 100, 3.4, deep)
            clipped.rect(37.5, 63.4, 25, 1.4, Color.white.opacity(0.75), radius: 0.7)
            ctx.heart(center: pt(50, 80.5), size: 10, rgb(0xE07F98))
            ctx.circle(47.8, 78.8, 0.8, Color.white.opacity(0.7))
            for (x, y) in [(CGFloat(31.5), CGFloat(76)), (31.5, 81), (68.5, 76), (68.5, 81)] {
                clipped.circle(x, y, 0.8, Color.white.opacity(0.85))
            }
        case "outfit.pajamas":
            let navy = rgb(0x5468A8), light = rgb(0x8C9CD8)
            clipped.rect(0, 62, 100, 40, navy)
            for (x, y, r) in [(CGFloat(27), CGFloat(70), CGFloat(2.2)), (40, 79, 2), (60, 73, 2.2), (72, 81, 2),
                              (24, 81, 1.8), (77, 69, 1.8), (55, 84, 1.8), (36, 69.5, 1.5)] {
                star(clipped, x, y, r, rgb(0xF6D36B))
            }
            clipped.rect(49.3, 66, 1.4, 30, light)
            ctx.circle(50, 72, 1.3, rgb(0xFBF8F2))
            ctx.circle(50, 78, 1.3, rgb(0xFBF8F2))
            soft(ctx, [pt(35.5, 61.2), pt(49.5, 62), pt(43, 68.5)], light, 1.4)
            soft(ctx, [pt(64.5, 61.2), pt(50.5, 62), pt(57, 68.5)], light, 1.4)
        case "outfit.hoodie":
            let blue = rgb(0x9FB4E3), deep = rgb(0x8098D2)
            clipped.rect(0, 62, 100, 40, blue)
            clipped.rect(0, 85, 100, 4, deep)
            var pocket = Path()
            pocket.move(to: pt(36, 75))
            pocket.addLine(to: pt(64, 75))
            pocket.addLine(to: pt(68.5, 86))
            pocket.addLine(to: pt(31.5, 86))
            pocket.closeSubpath()
            clipped.fill(pocket, with: .color(deep))
            clipped.strokePath(blue, width: 1) { p in
                p.move(to: pt(37.5, 77)); p.addLine(to: pt(34, 85))
                p.move(to: pt(62.5, 77)); p.addLine(to: pt(66, 85))
            }
            ctx.strokePath(deep, width: 4.6) { p in
                p.move(to: pt(25, 61.5)); p.addQuadCurve(to: pt(75, 61.5), control: pt(50, 72))
            }
            ctx.strokePath(rgb(0xFBF8F2), width: 1) { p in
                p.move(to: pt(45.5, 66)); p.addQuadCurve(to: pt(44.5, 74), control: pt(44.5, 70))
                p.move(to: pt(54.5, 66)); p.addQuadCurve(to: pt(55.5, 74), control: pt(55.5, 70))
            }
            ctx.rect(43.5, 73.5, 2, 2.6, rgb(0xE8E2EE), radius: 0.8)
            ctx.rect(54.5, 73.5, 2, 2.6, rgb(0xE8E2EE), radius: 0.8)
        case "outfit.dress":
            let yellow = rgb(0xF6D36B), pink = rgb(0xF29BB0)
            clipped.rect(0, 62, 100, 40, yellow)
            var skirt = Path()
            skirt.move(to: pt(22, 71))
            skirt.addLine(to: pt(78, 71))
            skirt.addQuadCurve(to: pt(88, 87), control: pt(85, 78))
            for i in 0..<6 {
                let x0 = 88 - CGFloat(i) * 12.67
                skirt.addQuadCurve(to: pt(x0 - 12.67, 87), control: pt(x0 - 6.33, 90.5))
            }
            skirt.addQuadCurve(to: pt(22, 71), control: pt(15, 78))
            skirt.closeSubpath()
            ctx.fill(skirt, with: .color(yellow))
            clipped.rect(0, 69.2, 100, 3.4, pink)
            let flowers: [(CGFloat, CGFloat)] = [(30, 66), (44, 65.5), (58, 66), (70, 66.5), (24, 78), (37, 77),
                                                 (50, 79), (63, 77), (76, 78), (30, 84), (44, 85), (57, 85), (70, 84)]
            for (i, f) in flowers.enumerated() {
                let petal = i % 3 == 1 ? rgb(0xF6A9BE) : Color.white
                for k in 0..<4 {
                    let ang = Double(k) * Double.pi / 2 + 0.4
                    ctx.circle(f.0 + 1.1 * CGFloat(cos(ang)), f.1 + 1.1 * CGFloat(sin(ang)), 1, petal)
                }
                ctx.circle(f.0, f.1, 0.7, rgb(0xE88A4E))
            }
            ctx.ellipse(38, 60.5, 12, 6.5, rgb(0xFFFDFB))
            ctx.ellipse(50, 60.5, 12, 6.5, rgb(0xFFFDFB))
            ctx.heart(center: pt(50, 64.5), size: 4.5, pink)
        case "outfit.tutu":
            let leo = rgb(0xF4AFC8), tulle = rgb(0xF9C9DA), top = rgb(0xFDE2EC)
            clipped.rect(0, 62.5, 100, 40, leo)
            for i in 0..<9 {
                ctx.circle(14 + CGFloat(i) * 9, 79.5, 6, tulle)
            }
            ctx.ellipse(9, 69.5, 82, 14, tulle)
            ctx.ellipse(15, 68.5, 70, 9, top)
            ctx.rect(21, 67.5, 58, 3.4, rgb(0xEC8FB0), radius: 1.7)
            for (x, y) in [(CGFloat(20), CGFloat(75)), (34, 79), (66, 79), (80, 75), (48, 76), (27, 82), (73, 82)] {
                ctx.circle(x, y, 0.8, Color.white.opacity(0.9))
            }
            sparkle(ctx, 88, 70, 5, rgb(0xF0C26A))
            ctx.heart(center: pt(50, 66.2), size: 4.5, rgb(0xEC8FB0))
        case "outfit.sailor":
            let shirt = rgb(0xF5F7FD), blue = rgb(0x4F7CC9), red = rgb(0xE05A5A)
            clipped.rect(0, 62, 100, 40, shirt)
            clipped.rect(0, 81, 100, 2.2, blue)
            clipped.rect(0, 85, 100, 2.2, blue)
            soft(ctx, [pt(23.5, 61.5), pt(76.5, 61.5), pt(73, 67.5), pt(50, 80), pt(27, 67.5)], blue, 1.5)
            soft(ctx, [pt(38, 61.5), pt(62, 61.5), pt(50, 73.5)], shirt, 1)
            ctx.strokePath(Color.white.opacity(0.9), width: 0.8) { p in
                p.move(to: pt(27, 64.5)); p.addLine(to: pt(50, 77.2)); p.addLine(to: pt(73, 64.5))
            }
            soft(ctx, [pt(50, 74), pt(43, 70.5), pt(43, 77)], red, 1)
            soft(ctx, [pt(50, 74), pt(57, 70.5), pt(57, 77)], red, 1)
            soft(ctx, [pt(48.5, 75), pt(45.5, 82), pt(48.8, 81)], red, 0.8)
            soft(ctx, [pt(51.5, 75), pt(54.5, 82), pt(51.2, 81)], red, 0.8)
            ctx.circle(50, 74, 2.2, rgb(0xC94848))
        case "outfit.yukata":
            let indigo = rgb(0x5B6FB3), trim = rgb(0x3F4F8F), under = rgb(0xF4EEE6)
            clipped.rect(0, 62, 100, 40, indigo)
            for (i, d) in [(CGFloat(26), CGFloat(68)), (40, 66), (62, 67), (74, 69), (30, 85), (45, 84), (60, 86), (72, 84),
                           (22, 77), (78, 77)].enumerated() {
                if i % 2 == 0 {
                    for k in 0..<5 {
                        let ang = Double(k) * 2 * Double.pi / 5
                        clipped.circle(d.0 + 1.3 * CGFloat(cos(ang)), d.1 + 1.3 * CGFloat(sin(ang)), 0.9, rgb(0xF8C6D6))
                    }
                    clipped.circle(d.0, d.1, 0.6, rgb(0xF6D36B))
                } else {
                    clipped.circle(d.0, d.1, 1, Color.white.opacity(0.75))
                }
            }
            soft(clipped, [pt(39, 61.5), pt(61, 61.5), pt(50, 72)], under, 1)
            ctx.strokePath(trim, width: 2.6) { p in
                p.move(to: pt(36.5, 61.5)); p.addLine(to: pt(54, 76))
                p.move(to: pt(63.5, 61.5)); p.addLine(to: pt(50, 73))
            }
            clipped.rect(0, 73.5, 100, 6.5, rgb(0xF2A3B8))
            clipped.rect(0, 76.2, 100, 1.1, rgb(0xE07F98))
            ctx.circle(62, 76.7, 1.8, rgb(0xF6D36B))
        case "outfit.tux":
            let jacket = rgb(0x434A6B), lapel = rgb(0x2F3550), shirt = rgb(0xFBFAFD)
            clipped.rect(0, 62, 100, 40, jacket)
            clipped.polygon([pt(40, 61), pt(60, 61), pt(50, 88)], shirt)
            soft(clipped, [pt(40, 61.5), pt(34, 64), pt(47, 80), pt(48.2, 84)], lapel, 1)
            soft(clipped, [pt(60, 61.5), pt(66, 64), pt(53, 80), pt(51.8, 84)], lapel, 1)
            ctx.circle(50, 72, 1, jacket)
            ctx.circle(50, 77, 1, jacket)
            clipped.rect(24, 70, 9, 1.4, lapel, radius: 0.7)
            soft(ctx, [pt(25, 70.2), pt(28, 66.5), pt(30, 70.2)], rgb(0xF29BB0), 0.8)
            soft(ctx, [pt(28.5, 70.2), pt(31, 67.2), pt(32.5, 70.2)], rgb(0xF6BCCB), 0.8)
            soft(ctx, [pt(50, 64), pt(44.5, 61.5), pt(44.5, 66.5)], rgb(0x2A2A3A), 0.8)
            soft(ctx, [pt(50, 64), pt(55.5, 61.5), pt(55.5, 66.5)], rgb(0x2A2A3A), 0.8)
            ctx.circle(50, 64, 1.6, rgb(0x2A2A3A))
        case "outfit.astronaut":
            let suit = rgb(0xF2F4FA), seam = rgb(0xCBD2E2), metal = rgb(0xB7C0D6)
            clipped.rect(0, 62, 100, 40, suit)
            clipped.strokePath(seam, width: 1) { p in
                p.move(to: pt(28, 64)); p.addQuadCurve(to: pt(24, 88), control: pt(22, 76))
                p.move(to: pt(72, 64)); p.addQuadCurve(to: pt(76, 88), control: pt(78, 76))
            }
            clipped.rect(0, 82, 100, 3, metal)
            clipped.rect(40.5, 68.5, 19, 11, rgb(0xD9DFEC), radius: 2.2)
            ctx.circle(45, 72.2, 1.5, rgb(0xE56B6B))
            ctx.circle(50, 72.2, 1.5, rgb(0xF6C445))
            ctx.circle(55, 72.2, 1.5, rgb(0x6FC2A8))
            ctx.rect(43.5, 75.7, 13, 1.6, rgb(0x6FA3D9), radius: 0.8)
            ctx.circle(30.5, 71.5, 4.3, rgb(0x4F7CC9))
            ctx.strokePath(Color.white.opacity(0.9), width: 0.7) { p in
                p.addEllipse(in: CGRect(x: 26.8, y: 70.2, width: 7.4, height: 2.6))
            }
            ctx.circle(30.5, 71.5, 1.1, rgb(0xF6D36B))
            ctx.rect(65, 68.8, 7.5, 5, rgb(0xFBFAFD), radius: 0.6)
            ctx.rect(65, 68.8, 7.5, 1.4, rgb(0xE56B6B), radius: 0.6)
            ctx.rect(65, 71.4, 7.5, 1.1, rgb(0xE56B6B))
            ctx.rect(24.5, 60.5, 51, 6, metal, radius: 3)
            ctx.rect(26.5, 61.5, 47, 1.4, Color.white.opacity(0.55), radius: 0.7)
        default:
            break
        }
    }

    // MARK: Phụ kiện sau lưng / cầm tay

    static func back(_ id: String, _ ctx: GraphicsContext, _ a: PetAppearance, front: Bool) {
        let w: CGFloat = a.species == .hamster ? 3 : 0
        switch id {
        case "back.lollipop":
            guard front else { return }
            ctx.strokePath(rgb(0xDCD3CC), width: 2.8) { p in
                p.move(to: pt(60.5, 83)); p.addLine(to: pt(79, 60))
            }
            ctx.strokePath(rgb(0xFBF8F2), width: 2) { p in
                p.move(to: pt(60.5, 83)); p.addLine(to: pt(79, 60))
            }
            lollipopCandy(ctx, center: pt(82, 53), r: 9.5)
            pawGrip(ctx, a, 58.5, 80.3)
        case "back.balloon":
            if front {
                ctx.strokePath(rgb(0x9A8FB0), width: 0.9) { p in
                    p.move(to: pt(60.5, 82)); p.addQuadCurve(to: pt(80, 25.5), control: pt(90, 60))
                }
                pawGrip(ctx, a, 58.5, 80)
            } else {
                ctx.heart(center: pt(80, 15), size: 23, rgb(0xF27D9B))
                ctx.rotated(-35, around: pt(73.5, 10.5)) { c in c.ellipse(71, 8.5, 5, 3.2, Color.white.opacity(0.6)) }
                ctx.polygon([pt(80, 22.5), pt(78.3, 25.6), pt(81.7, 25.6)], rgb(0xE0607F))
            }
        case "back.backpack":
            let bag = rgb(0x6FC2A8), deep = rgb(0x529E87)
            if front {
                for flip in [false, true] {
                    let c = mirrored(ctx, flip)
                    c.strokePath(deep, width: 3.4) { p in
                        p.move(to: pt(21 - w, 56)); p.addQuadCurve(to: pt(33, 82), control: pt(24 - w, 74))
                    }
                    c.rect(23.2 - w * 0.5, 70, 4.2, 3.4, rgb(0xF0C26A), radius: 1)
                }
            } else {
                ctx.rect(7 - w, 48, 86 + w * 2, 38, bag, radius: 14)
                ctx.rect(4.5 - w, 62, 9, 18, deep, radius: 4)
                ctx.rect(86.5 + w, 62, 9, 18, deep, radius: 4)
                ctx.rect(6 - w, 66, 6, 1.2, Color.white.opacity(0.6))
                ctx.rect(88 + w, 66, 6, 1.2, Color.white.opacity(0.6))
                ctx.strokePath(deep, width: 2.6) { p in
                    p.move(to: pt(40, 50)); p.addQuadCurve(to: pt(60, 50), control: pt(50, 36))
                }
            }
        case "back.umbrella":
            if front {
                ctx.strokePath(rgb(0x8A5A3C), width: 1.8) { p in
                    p.move(to: pt(60, 85)); p.addLine(to: pt(79.5, 19))
                }
                ctx.strokePath(rgb(0xC94F5C), width: 2.6) { p in
                    p.move(to: pt(60.3, 84)); p.addLine(to: pt(61.8, 79))
                }
                pawGrip(ctx, a, 58.5, 80.5)
            } else {
                parasol(ctx)
            }
        case "back.bat":
            guard !front else { return }
            let wing = rgb(0x6A5A9A), bone = rgb(0x8E7EC0)
            for flip in [false, true] {
                var c = mirrored(ctx, flip)
                c.translateBy(x: -w, y: 0)
                var p = Path()
                p.move(to: pt(28, 46))
                p.addQuadCurve(to: pt(2, 30), control: pt(12, 32))
                p.addQuadCurve(to: pt(6, 47), control: pt(7, 40))
                p.addQuadCurve(to: pt(13, 55), control: pt(12, 49))
                p.addQuadCurve(to: pt(22, 61), control: pt(20, 54))
                p.addQuadCurve(to: pt(30, 66), control: pt(28, 59))
                p.closeSubpath()
                c.fill(p, with: .color(wing))
                c.strokePath(bone, width: 1) { q in
                    q.move(to: pt(26, 52)); q.addLine(to: pt(4, 31))
                    q.move(to: pt(26, 52)); q.addLine(to: pt(6.5, 46))
                    q.move(to: pt(26, 52)); q.addLine(to: pt(13, 54.5))
                    q.move(to: pt(26, 52)); q.addLine(to: pt(22, 60.5))
                }
            }
        case "back.guitar":
            if front {
                ctx.strokePath(rgb(0x8A5A3C), width: 2.4) { p in
                    p.move(to: pt(81, 60)); p.addQuadCurve(to: pt(20, 78), control: pt(52, 76))
                }
                ctx.strokePath(rgb(0xF0C26A), width: 0.7) { p in
                    p.move(to: pt(76, 63.5)); p.addLine(to: pt(73, 64.8))
                    p.move(to: pt(64, 68.5)); p.addLine(to: pt(61, 69.4))
                    p.move(to: pt(36, 73.6)); p.addLine(to: pt(33, 74.2))
                }
            } else {
                guitar(ctx, w)
            }
        case "back.fairy":
            guard !front else { return }
            for flip in [false, true] {
                var c = mirrored(ctx, flip)
                c.translateBy(x: -w, y: 0)
                c.rotated(-38, around: pt(26, 52)) { r in
                    r.ellipse(2, 36, 28, 18, rgb(0xBFE3F7).opacity(0.75))
                    r.ellipse(7, 40, 18, 10, rgb(0xF7CBE6).opacity(0.55))
                    r.strokePath(Color.white.opacity(0.95), width: 1) { p in
                        p.addEllipse(in: CGRect(x: 2, y: 36, width: 28, height: 18))
                        p.move(to: pt(26, 46)); p.addQuadCurve(to: pt(8, 42), control: pt(16, 41))
                    }
                }
                c.rotated(28, around: pt(26, 60)) { r in
                    r.ellipse(6, 56, 22, 12, rgb(0xD8C9F4).opacity(0.75))
                    r.strokePath(Color.white.opacity(0.95), width: 1) { p in
                        p.addEllipse(in: CGRect(x: 6, y: 56, width: 22, height: 12))
                    }
                }
            }
            sparkle(ctx, 8 - w, 24, 6, rgb(0xF0C26A))
            sparkle(ctx, 93 + w, 30, 5, rgb(0xF0C26A))
            sparkle(ctx, 6 - w, 74, 4, rgb(0xB59FDB))
        case "back.wings":
            guard !front else { return }
            for flip in [false, true] {
                var c = mirrored(ctx, flip)
                c.translateBy(x: -w, y: 0)
                var sh = c
                sh.translateBy(x: 0.8, y: 1.3)
                angelWing(sh, rgb(0xDCD6E8))
                angelWing(c, rgb(0xFFFFFF))
                c.strokePath(rgb(0xE4DFEE), width: 0.9) { p in
                    p.move(to: pt(10, 44)); p.addQuadCurve(to: pt(24, 47), control: pt(16, 48))
                    p.move(to: pt(10, 53)); p.addQuadCurve(to: pt(24, 54), control: pt(17, 56))
                    p.move(to: pt(14, 60)); p.addQuadCurve(to: pt(25, 60), control: pt(19, 62))
                }
            }
        default:
            break
        }
    }

    /// "Ngón tay" nhỏ cùng màu lông che lên cán để trông như đang cầm.
    private static func pawGrip(_ ctx: GraphicsContext, _ a: PetAppearance, _ x: CGFloat, _ y: CGFloat) {
        ctx.ellipse(x - 1, y - 0.5, 7, 5, FurPalette.of(a.fur).base)
    }

    private static func lollipopCandy(_ ctx: GraphicsContext, center c: CGPoint, r: CGFloat) {
        let colors = [rgb(0xF27D9B), rgb(0xF6A85B), rgb(0xF6D36B), rgb(0x8CCB7E), rgb(0x6FA3D9), rgb(0xA98BE0)]
        ctx.circle(c.x, c.y, r + 0.8, rgb(0xFBF8F2))
        for (i, color) in colors.enumerated() {
            var p = Path()
            p.move(to: c)
            p.addArc(center: c, radius: r, startAngle: .degrees(Double(i) * 60 - 90), endAngle: .degrees(Double(i + 1) * 60 - 90), clockwise: false)
            p.closeSubpath()
            ctx.fill(p, with: .color(color))
        }
        ctx.strokePath(Color.white.opacity(0.95), width: 1.3) { p in
            p.move(to: c)
            for k in 1...40 {
                let t = Double(k) / 40
                let ang = t * 4.2 * Double.pi
                let rr = r * 0.92 * CGFloat(t)
                p.addLine(to: CGPoint(x: c.x + rr * CGFloat(cos(ang)), y: c.y + rr * CGFloat(sin(ang))))
            }
        }
        ctx.ellipse(c.x - r * 0.65, c.y - r * 0.7, r * 0.5, r * 0.32, Color.white.opacity(0.6))
    }

    private static func parasol(_ ctx: GraphicsContext) {
        let hub = pt(79.5, 19)
        ctx.rotated(17, around: hub) { c in
            let canopy = rgb(0xEC8E9D), panel = rgb(0xF6B7C2), rib = rgb(0xC96676)
            let left: CGFloat = hub.x - 25, right: CGFloat = hub.x + 25, rim = hub.y + 6
            var p = Path()
            p.move(to: pt(left, rim))
            p.addQuadCurve(to: pt(hub.x, hub.y - 12), control: pt(left + 6, hub.y - 9))
            p.addQuadCurve(to: pt(right, rim), control: pt(right - 6, hub.y - 9))
            for i in 0..<6 {
                let x0 = right - CGFloat(i) * 50 / 6
                p.addQuadCurve(to: pt(x0 - 50 / 6, rim), control: pt(x0 - 25 / 6, rim - 3))
            }
            p.closeSubpath()
            c.fill(p, with: .color(canopy))
            var inner = c
            inner.clip(to: p)
            for i in stride(from: 0, to: 6, by: 2) {
                let x0 = left + CGFloat(i) * 50 / 6
                inner.polygon([pt(hub.x, hub.y - 12), pt(x0, rim + 2), pt(x0 + 50 / 6, rim + 2)], panel)
            }
            c.strokePath(rib, width: 0.8) { q in
                for i in 0...6 {
                    q.move(to: pt(hub.x, hub.y - 12)); q.addLine(to: pt(left + CGFloat(i) * 50 / 6, rim - 1.5))
                }
            }
            c.strokePath(Color.white.opacity(0.85), width: 1.2) { q in
                q.addEllipse(in: CGRect(x: hub.x - 7, y: hub.y - 10.5, width: 14, height: 5))
            }
            c.circle(hub.x, hub.y - 12.5, 1.5, rib)
        }
    }

    private static func guitar(_ ctx: GraphicsContext, _ w: CGFloat) {
        let wood = rgb(0xE3A866), woodDeep = rgb(0xC98A4E), neckColor = rgb(0x8A5A3C)
        let origin = pt(11 - w, 77)
        var c = ctx
        c.translateBy(x: origin.x, y: origin.y)
        c.rotate(by: .degrees(-28))
        // Hệ tọa độ cục bộ: trục đàn nằm ngang, thân ở gốc.
        c.rect(16, -2.3, 62, 4.6, neckColor, radius: 1.5)
        c.rect(76, -3.8, 12, 7.6, woodDeep, radius: 2.4)
        for x in [CGFloat(79), 82.5, 86] {
            c.circle(x, -4.6, 1.2, rgb(0xF0C26A))
            c.circle(x, 4.6, 1.2, rgb(0xF0C26A))
        }
        c.circle(14, 0, 8.5, woodDeep)
        c.circle(0, 0, 11, woodDeep)
        c.circle(14, 0, 7.6, wood)
        c.circle(0, 0, 10.1, wood)
        c.circle(2.5, 0, 3.4, rgb(0x5A3B2A))
        c.rect(-7, -3.2, 2.2, 6.4, rgb(0x8A5A3C), radius: 0.8)
        c.ellipse(-6, -8, 6, 3.4, Color.white.opacity(0.35))
    }

    private static func angelWing(_ c: GraphicsContext, _ color: Color) {
        c.rotated(-22, around: pt(24, 48)) { r in
            r.ellipse(1, 36, 28, 17, color)
        }
        c.rotated(-12, around: pt(24, 54)) { r in
            r.ellipse(3, 47, 22, 9.5, color)
        }
        c.rotated(-4, around: pt(24, 60)) { r in
            r.ellipse(7, 55, 18, 8.5, color)
        }
        c.ellipse(11, 61, 15, 7.5, color)
    }
}
