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
        case "hat.bucket": bucketHat(ctx)
        case "hat.strawberry": strawberryHat(ctx)
        case "hat.sailorcap": sailorHat(ctx)
        case "hat.mushroom": mushroomHat(ctx)
        case "hat.sunflower": sunflowerCrown(ctx)
        case "hat.viking": viking(ctx)
        case "hat.grad": gradCap(ctx)
        case "hat.sakura": sakuraCrown(ctx)
        case "hat.pirate": pirateHat(ctx)
        case "hat.galaxy": galaxyCrown(ctx)
        case "hat.dragon": dragonHood(ctx)
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
        hood.ellipse(22, 16, 56, 46, g)
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
        case "glasses.3d": glasses3D(ctx)
        case "glasses.sleepmask": sleepMask(ctx, a)
        case "glasses.flower": flowerGlasses(ctx)
        case "glasses.cateye": catEyeGlasses(ctx)
        case "glasses.snorkel": snorkel(ctx)
        case "glasses.goldwire": goldWire(ctx)
        case "glasses.eyepatch": eyePatch(ctx)
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
            // Cổ áo bèo kiểu chú hề: các cánh bèo trắng xòe quanh cổ.
            let white = rgb(0xFFFFFF), edge = rgb(0xD3C8E2), crease = rgb(0xE6DFEE)
            let angles: [Double] = [28, 43, 58, 74, 90, 106, 122, 137, 152]
            for layer in 0..<2 {
                for (i, deg) in angles.enumerated() {
                    let rad = deg * Double.pi / 180
                    let x = 50 + 22 * CGFloat(cos(rad)), y = 59 + 6.5 * CGFloat(sin(rad))
                    let rot = (deg - 90) * 0.9
                    let tone = i % 2 == 0 ? white : rgb(0xFBF8FD)
                    ctx.rotated(rot, around: pt(x, y)) { c in
                        if layer == 0 {
                            c.ellipse(x - 4.4, y - 2.8, 8.8, 10.4, edge)
                        } else {
                            c.ellipse(x - 3.8, y - 2.6, 7.6, 9.4, tone)
                            c.strokePath(crease, width: 0.8) { p in
                                p.move(to: pt(x, y + 0.5)); p.addLine(to: pt(x, y + 5))
                            }
                        }
                    }
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
        case "neck.bib": bib(ctx)
        case "neck.clover": clover(ctx)
        case "neck.stripes": stripeScarf(ctx)
        case "neck.whistle": whistle(ctx)
        case "neck.hibiscus": hibiscusLei(ctx)
        case "neck.camera": camera(ctx)
        case "neck.moon": moonPendant(ctx)
        case "neck.dragonpearl": dragonPearl(ctx)
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
        case "outfit.catsweater": catSweater(ctx, clipped)
        case "outfit.duckcoat": duckCoat(ctx, clipped)
        case "outfit.patches": patchOveralls(ctx, clipped)
        case "outfit.bee": beeSuit(ctx, clipped, a)
        case "outfit.chefcoat": chefCoat(ctx, clipped)
        case "outfit.dino": dinoSuit(ctx, clipped, a)
        case "outfit.knight": knightArmor(ctx, clipped, a)
        case "outfit.sakura": sakuraKimono(ctx, clipped, a)
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
                    p.move(to: pt(60, 85)); p.addLine(to: pt(76, 18))
                }
                ctx.strokePath(rgb(0xC94F5C), width: 2.6) { p in
                    p.move(to: pt(60.2, 84.2)); p.addLine(to: pt(61.4, 79.2))
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
        case "back.icecream": if front { iceCream(ctx, a) }
        case "back.kite": kite(ctx, a, front: front)
        case "back.balloons": balloons(ctx, a, front: front)
        case "back.bearpack": bearPack(ctx, w, front: front)
        case "back.wand": if front { starWand(ctx, a) }
        case "back.turtle": turtleShell(ctx, w, front: front)
        case "back.butterfly": if !front { butterflyWings(ctx, w) }
        case "back.leafcape": leafCape(ctx, w, front: front)
        case "back.petalwings": if !front { petalWings(ctx, w) }
        case "back.parrot": parrot(ctx, w, front: front)
        case "back.starcape": starCape(ctx, w, front: front)
        case "back.dragonwings": if !front { dragonWings(ctx, w) }
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
        let hub = pt(76, 18)
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

// MARK: - Trang phục thêm: cửa hàng & gacha

extension CostumeArt {

    // MARK: Hình dùng chung

    /// Hoa năm cánh tròn (anh đào, dâm bụt, cúc).
    fileprivate static func fivePetal(_ ctx: GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat,
                                      _ petal: Color, _ center: Color, turn: Double = 0) {
        for k in 0..<5 {
            let ang = (-90 + Double(k) * 72 + turn) * Double.pi / 180
            ctx.circle(cx + r * 0.58 * CGFloat(cos(ang)), cy + r * 0.58 * CGFloat(sin(ang)), r * 0.52, petal)
        }
        ctx.circle(cx, cy, r * 0.32, center)
    }

    /// Điểm trên một cung parabol quanh cổ (dùng cho chuỗi hạt, vòng hoa).
    fileprivate static func necklacePoint(_ x: CGFloat, depth: CGFloat = 6.5, top: CGFloat = 61.8) -> CGPoint {
        CGPoint(x: x, y: top + depth * (1 - pow((x - 50) / 23, 2)))
    }

    fileprivate static func duckPrint(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat) {
        let yellow = rgb(0xF7D35C)
        ctx.ellipse(x - 3.2, y - 1.3, 6.4, 4, yellow)
        ctx.circle(x + 2, y - 2, 1.9, yellow)
        ctx.polygon([pt(x + 3.6, y - 2.6), pt(x + 5.6, y - 1.9), pt(x + 3.6, y - 1.2)], rgb(0xF29A4A))
        ctx.circle(x + 2.3, y - 2.4, 0.45, rgb(0x3E3550))
        ctx.ellipse(x - 1.8, y - 0.6, 3, 1.6, rgb(0xEDBE45))
    }

    /// Cánh hoa giọt nước có khía ở chóp, gốc tại `root`, hướng sang trái rồi xoay `deg` độ.
    fileprivate static func petal(_ ctx: GraphicsContext, root: CGPoint, deg: Double, length l: CGFloat, width w: CGFloat,
                                  inner: Color, outer: Color) {
        ctx.rotated(deg, around: root) { c in
            let rx = root.x, ry = root.y
            var p = Path()
            p.move(to: root)
            p.addQuadCurve(to: pt(rx - l, ry - w * 0.55), control: pt(rx - l * 0.5, ry - w * 1.35))
            p.addLine(to: pt(rx - l + w * 0.4, ry))
            p.addLine(to: pt(rx - l, ry + w * 0.55))
            p.addQuadCurve(to: root, control: pt(rx - l * 0.5, ry + w * 1.35))
            p.closeSubpath()
            c.fill(p, with: .linearGradient(Gradient(colors: [inner, outer]), startPoint: root, endPoint: pt(rx - l, ry)))
            c.strokePath(Color.white.opacity(0.7), width: 0.8) { q in
                q.move(to: pt(rx - 3, ry)); q.addQuadCurve(to: pt(rx - l * 0.75, ry - 0.5), control: pt(rx - l * 0.4, ry - w * 0.25))
            }
        }
    }

    // MARK: Mũ

    fileprivate static func bucketHat(_ ctx: GraphicsContext) {
        let sage = rgb(0xA9D0A0), deep = rgb(0x8AB680), band = rgb(0xF6E6BA)
        var brim = Path()
        brim.move(to: pt(26, 27))
        brim.addLine(to: pt(74, 27))
        brim.addQuadCurve(to: pt(84, 37.5), control: pt(82, 31))
        brim.addQuadCurve(to: pt(16, 37.5), control: pt(50, 42))
        brim.addQuadCurve(to: pt(26, 27), control: pt(18, 31))
        brim.closeSubpath()
        ctx.fill(brim, with: .color(deep))
        ctx.strokePath(Color.white.opacity(0.45), width: 0.7) { p in
            p.move(to: pt(20.5, 35.2)); p.addQuadCurve(to: pt(79.5, 35.2), control: pt(50, 39.2))
        }
        var crown = Path()
        crown.move(to: pt(28.5, 31))
        crown.addCurve(to: pt(71.5, 31), control1: pt(28, 7), control2: pt(72, 7))
        crown.closeSubpath()
        ctx.fill(crown, with: .color(sage))
        ctx.rect(28.6, 25.5, 42.8, 4.4, band, radius: 1.2)
        fivePetal(ctx, 64.5, 24.5, 5, .white, rgb(0xF0C26A))
        ctx.ellipse(35, 14.5, 9, 4.5, Color.white.opacity(0.3))
    }

    fileprivate static func strawberryHat(_ ctx: GraphicsContext) {
        let red = rgb(0xF27886), deep = rgb(0xDA5D70), seed = rgb(0xFCE6A6)
        let leaf = rgb(0x86C774), leafDeep = rgb(0x67A95A)
        var b = Path()
        b.move(to: pt(24, 34))
        b.addCurve(to: pt(50, 7), control1: pt(23, 17), control2: pt(35, 7))
        b.addCurve(to: pt(76, 34), control1: pt(65, 7), control2: pt(77, 17))
        b.closeSubpath()
        ctx.fill(b, with: .color(red))
        ctx.rect(23.5, 30.5, 53, 5.2, deep, radius: 2.6)
        let seeds: [(CGFloat, CGFloat)] = [(32.5, 24), (40, 19), (60, 19), (67.5, 24), (41.5, 27), (50, 24.5), (58.5, 27)]
        for (x, y) in seeds { ctx.ellipse(x - 0.9, y - 1.3, 1.8, 2.6, seed) }
        for deg in [-110.0, -55, 0, 55, 110] {
            ctx.rotated(deg, around: pt(50, 10)) { c in
                soft(c, [pt(50, 9.5), pt(46.2, 16.5), pt(50, 19.5), pt(53.8, 16.5)], leaf, 1.2)
            }
        }
        ctx.rect(48.6, 3, 2.8, 8.5, leafDeep, radius: 1.4)
        ctx.rotated(-35, around: pt(33, 18)) { c in c.ellipse(29, 16, 8, 3.6, Color.white.opacity(0.35)) }
    }

    fileprivate static func sailorHat(_ ctx: GraphicsContext) {
        let white = rgb(0xFBFCFF), shade = rgb(0xD7DDEB), blue = rgb(0x5B82CC)
        ctx.rotated(-8, around: pt(50, 28)) { c in
            var dome = c
            dome.clip(to: Path(CGRect(x: 0, y: 0, width: 100, height: 30)))
            dome.ellipse(31, 11.5, 38, 32, shade)
            dome.ellipse(32, 12.3, 36, 30, white)
            c.strokePath(shade, width: 0.8) { p in
                p.move(to: pt(50, 12.5)); p.addQuadCurve(to: pt(42, 27), control: pt(43, 16))
                p.move(to: pt(50, 12.5)); p.addQuadCurve(to: pt(58, 27), control: pt(57, 16))
            }
            c.rect(22.5, 26.5, 55, 9.5, shade, radius: 4.75)
            c.rect(22.5, 25.8, 55, 8.6, white, radius: 4.3)
            c.rect(25.5, 28.3, 49, 1.7, blue, radius: 0.85)
            c.rect(25.5, 31.2, 49, 0.9, blue.opacity(0.5), radius: 0.45)
            star(c, 50, 20.5, 2.6, blue)
            c.ellipse(36, 16, 6, 3, Color.white.opacity(0.9))
        }
    }

    fileprivate static func mushroomHat(_ ctx: GraphicsContext) {
        let red = rgb(0xE96D6D), underShade = rgb(0xEBD6BA), spot = rgb(0xFFFBF5)
        ctx.ellipse(18, 26, 64, 11, underShade)
        ctx.strokePath(rgb(0xD8BC98), width: 0.7) { p in
            for x in stride(from: CGFloat(24), through: 76, by: 4.4) {
                p.move(to: pt(x, 31)); p.addLine(to: pt(50 + (x - 50) * 0.75, 34.5))
            }
        }
        var cap = Path()
        cap.move(to: pt(14, 31.5))
        cap.addCurve(to: pt(86, 31.5), control1: pt(15, 1), control2: pt(85, 1))
        cap.addQuadCurve(to: pt(14, 31.5), control: pt(50, 35))
        cap.closeSubpath()
        ctx.fill(cap, with: .color(red))
        let spots: [(CGFloat, CGFloat, CGFloat)] = [(33, 17.5, 4), (50.5, 12, 5), (67, 18.5, 3.6), (24, 26.5, 2.3),
                                                    (76, 26.5, 2.4), (42.5, 25, 2.2), (58.5, 26, 2.6)]
        for (x, y, r) in spots { ctx.circle(x, y, r, spot) }
        ctx.strokePath(Color.white.opacity(0.4), width: 1.4) { p in
            p.move(to: pt(21, 22)); p.addQuadCurve(to: pt(29, 11), control: pt(22, 14))
        }
    }

    fileprivate static func sunflower(_ ctx: GraphicsContext, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) {
        let petal = rgb(0xF7C948), petalDeep = rgb(0xEDAE3A)
        for i in 0..<10 {
            ctx.rotated(Double(i) * 36 + 18, around: pt(cx, cy)) { c in
                c.ellipse(cx - r * 0.3, cy - r * 1.05, r * 0.6, r * 0.8, petalDeep)
            }
        }
        for i in 0..<10 {
            ctx.rotated(Double(i) * 36, around: pt(cx, cy)) { c in
                c.ellipse(cx - r * 0.3, cy - r * 1.02, r * 0.6, r * 0.8, petal)
            }
        }
        ctx.circle(cx, cy, r * 0.5, rgb(0x8A5A3C))
        ctx.circle(cx, cy, r * 0.32, rgb(0xA8744E))
        ctx.circle(cx - r * 0.15, cy - r * 0.15, r * 0.11, Color.white.opacity(0.5))
    }

    fileprivate static func sunflowerCrown(_ ctx: GraphicsContext) {
        let vine = rgb(0x7FAE6A), leaf = rgb(0x8CC77A)
        ctx.strokePath(vine, width: 1.6) { p in
            p.move(to: pt(25, 37)); p.addQuadCurve(to: pt(75, 37), control: pt(50, 18))
        }
        let leaves: [(CGFloat, CGFloat, Double)] = [(35, 29, -50), (65, 29, 50), (44, 25.5, -20), (56, 25.5, 20)]
        for (x, y, d) in leaves {
            ctx.rotated(d, around: pt(x, y)) { c in c.ellipse(x - 2, y - 6, 4, 6.5, leaf) }
        }
        sunflower(ctx, 28.5, 33.5, 4.4)
        sunflower(ctx, 71.5, 33.5, 4.4)
        sunflower(ctx, 39, 26.5, 4.8)
        sunflower(ctx, 61, 26.5, 4.8)
        sunflower(ctx, 50, 22.5, 6.2)
    }

    fileprivate static func viking(_ ctx: GraphicsContext) {
        let steel = rgb(0xBAC4D8), steelDeep = rgb(0x96A2BC), horn = rgb(0xFBF1DD), hornShade = rgb(0xE4D2B0)
        let gold = rgb(0xE8B84E)
        for flip in [false, true] {
            let c = mirrored(ctx, flip)
            var h = Path()
            h.move(to: pt(29.5, 29))
            h.addQuadCurve(to: pt(15.5, 5), control: pt(14, 24))
            h.addQuadCurve(to: pt(37, 21), control: pt(23, 18))
            h.closeSubpath()
            c.fill(h, with: .color(horn))
            c.strokePath(hornShade, width: 1.2) { p in
                p.move(to: pt(21, 18)); p.addLine(to: pt(26.5, 16.5))
                p.move(to: pt(23, 24.5)); p.addLine(to: pt(30, 21.5))
            }
        }
        var dome = ctx
        dome.clip(to: Path(CGRect(x: 0, y: 0, width: 100, height: 33)))
        dome.ellipse(24, 11.5, 52, 46, steel)
        ctx.rect(48.4, 11.6, 3.2, 18, steelDeep, radius: 1.6)
        ctx.rect(23.5, 28, 53, 6.2, steelDeep, radius: 3.1)
        for x in stride(from: CGFloat(29), through: 71, by: 7) { ctx.circle(x, 31.1, 1.1, gold) }
        ctx.ellipse(31, 16.5, 9, 4.5, Color.white.opacity(0.45))
    }

    fileprivate static func gradCap(_ ctx: GraphicsContext) {
        let navy = rgb(0x3F4A78), top = rgb(0x52609A), gold = rgb(0xF0C26A)
        var cap = ctx
        cap.clip(to: Path(CGRect(x: 0, y: 0, width: 100, height: 33)))
        cap.ellipse(29, 16, 42, 34, navy)
        ctx.rect(28.5, 28.5, 43, 5.2, navy, radius: 2.6)
        soft(ctx, [pt(50, 8.5), pt(84, 17), pt(50, 25.5), pt(16, 17)], top, 1.6)
        ctx.strokePath(Color.white.opacity(0.3), width: 1) { p in
            p.move(to: pt(22, 17)); p.addLine(to: pt(50, 10.5))
        }
        ctx.strokePath(gold, width: 1) { p in
            p.move(to: pt(50, 17)); p.addQuadCurve(to: pt(76, 20), control: pt(66, 16.5))
            p.addLine(to: pt(76.5, 29))
        }
        ctx.circle(50, 17, 1.9, gold)
        ctx.rect(74.6, 28, 3.8, 7.5, gold, radius: 1.4)
        ctx.strokePath(rgb(0xD9A441), width: 0.6) { p in
            p.move(to: pt(75.8, 30)); p.addLine(to: pt(75.8, 35))
            p.move(to: pt(77.2, 30)); p.addLine(to: pt(77.2, 35))
        }
    }

    fileprivate static func sakuraCrown(_ ctx: GraphicsContext) {
        let twig = rgb(0x8A6A5A), pink = rgb(0xF7B6CB), pale = rgb(0xFDDDE7), deep = rgb(0xE7839F)
        ctx.strokePath(twig, width: 1.6) { p in
            p.move(to: pt(24, 37)); p.addQuadCurve(to: pt(76, 37), control: pt(50, 17))
            p.move(to: pt(37, 28)); p.addLine(to: pt(33, 22))
            p.move(to: pt(63, 28)); p.addLine(to: pt(68, 22.5))
        }
        let blooms: [(CGFloat, CGFloat, CGFloat, Bool)] = [(27, 33.5, 4.6, false), (73, 33.5, 4.6, false), (33, 21.5, 3.6, true),
                                                           (68, 22, 3.6, true), (38.5, 27.5, 5.4, true), (61.5, 27.5, 5.4, true),
                                                           (50, 23.5, 6.8, false)]
        for (i, b) in blooms.enumerated() {
            fivePetal(ctx, b.0, b.1, b.2 + 0.5, deep, deep, turn: Double(i) * 11)
            fivePetal(ctx, b.0, b.1, b.2, b.3 ? pale : pink, rgb(0xFFF4D6), turn: Double(i) * 11)
            ctx.circle(b.0, b.1, b.2 * 0.14, deep)
        }
        let falling: [(CGFloat, CGFloat, Double)] = [(80, 18, 30), (20, 22, -40), (85, 30, 70)]
        for (x, y, d) in falling {
            ctx.rotated(d, around: pt(x, y)) { c in c.ellipse(x - 1.6, y - 2.4, 3.2, 4.8, pink) }
        }
        sparkle(ctx, 57, 14, 5, rgb(0xF0C26A))
    }

    fileprivate static func pirateHat(_ ctx: GraphicsContext) {
        let felt = rgb(0x3E3850), feltLight = rgb(0x524A68), gold = rgb(0xEDBF55), bone = rgb(0xFBF8F2)
        // Lông vũ đỏ cắm phía sau.
        ctx.rotated(35, around: pt(70, 20)) { c in
            c.ellipse(64, -2, 10, 24, rgb(0xE56B6B))
            c.strokePath(rgb(0xC94F5C), width: 0.8) { p in p.move(to: pt(69, 20)); p.addLine(to: pt(69, 0)) }
        }
        var h = Path()
        h.move(to: pt(13, 31))
        h.addQuadCurve(to: pt(29, 13), control: pt(14, 17))
        h.addQuadCurve(to: pt(50, 9), control: pt(40, 7))
        h.addQuadCurve(to: pt(71, 13), control: pt(60, 7))
        h.addQuadCurve(to: pt(87, 31), control: pt(86, 17))
        h.addQuadCurve(to: pt(13, 31), control: pt(50, 38))
        h.closeSubpath()
        ctx.fill(h, with: .color(felt))
        ctx.strokePath(gold, width: 1.4) { p in
            p.move(to: pt(14.5, 30)); p.addQuadCurve(to: pt(29, 14.5), control: pt(15.5, 18))
            p.addQuadCurve(to: pt(50, 10.5), control: pt(40, 8.5))
            p.addQuadCurve(to: pt(71, 14.5), control: pt(60, 8.5))
            p.addQuadCurve(to: pt(85.5, 30), control: pt(84.5, 18))
        }
        ctx.strokePath(feltLight, width: 1.2) { p in
            p.move(to: pt(22, 30)); p.addQuadCurve(to: pt(78, 30), control: pt(50, 35.5))
        }
        // Đầu lâu tròn và xương chéo.
        ctx.strokePath(bone, width: 1.8) { p in
            p.move(to: pt(44, 17)); p.addLine(to: pt(56, 28))
            p.move(to: pt(56, 17)); p.addLine(to: pt(44, 28))
        }
        let ends: [(CGFloat, CGFloat)] = [(44, 17), (56, 17), (44, 28), (56, 28)]
        for (x, y) in ends {
            ctx.circle(x - 0.9, y, 1.1, bone)
            ctx.circle(x + 0.9, y, 1.1, bone)
        }
        ctx.circle(50, 21, 4.6, bone)
        ctx.rect(47.3, 23.5, 5.4, 3.4, bone, radius: 1.2)
        ctx.circle(48.2, 21, 1.15, felt)
        ctx.circle(51.8, 21, 1.15, felt)
        ctx.rect(49.6, 23, 0.8, 1.1, felt)
    }

    fileprivate static func orbitPath(_ from: Double, _ to: Double) -> Path {
        var p = Path()
        for k in 0...36 {
            let t = (from + (to - from) * Double(k) / 36) * Double.pi
            let q = pt(50 + 37 * CGFloat(cos(t)), 20 + 8 * CGFloat(sin(t)))
            if k == 0 { p.move(to: q) } else { p.addLine(to: q) }
        }
        return p
    }

    fileprivate static func galaxyCrown(_ ctx: GraphicsContext) {
        let gold = rgb(0xF2C462), ring = rgb(0xC9B8F5)
        ctx.rotated(-10, around: pt(50, 20)) { c in
            c.stroke(orbitPath(1, 2), with: .color(ring.opacity(0.85)), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
            c.circle(26, 13.5, 2.6, rgb(0x8FD8C8))
        }
        let pts = [pt(32, 33), pt(30.5, 16), pt(38.5, 23.5), pt(44, 9.5), pt(50, 19), pt(56, 9.5), pt(61.5, 23.5),
                   pt(69.5, 16), pt(68, 33)]
        var crown = Path()
        crown.addLines(pts)
        crown.closeSubpath()
        ctx.fill(crown, with: .linearGradient(Gradient(colors: [rgb(0x8A74E0), rgb(0x3A3A86)]),
                                              startPoint: pt(50, 9), endPoint: pt(50, 33)))
        ctx.stroke(crown, with: .color(rgb(0x2E2C6A)), style: StrokeStyle(lineWidth: 1, lineJoin: .round))
        let dust: [(CGFloat, CGFloat, CGFloat)] = [(40, 25, 0.6), (46, 18, 0.5), (55, 24, 0.7), (61, 28, 0.5), (36, 29, 0.5), (52, 29, 0.5)]
        for (x, y, r) in dust { ctx.circle(x, y, r, Color.white.opacity(0.9)) }
        ctx.rect(31, 29, 38, 4.6, gold, radius: 2.3)
        let tips: [(CGFloat, CGFloat)] = [(30.5, 16), (44, 9.5), (56, 9.5), (69.5, 16)]
        for (x, y) in tips { ctx.circle(x, y, 2, gold) }
        star(ctx, 50, 18.5, 3.2, gold)
        ctx.rotated(-10, around: pt(50, 20)) { c in
            c.stroke(orbitPath(0, 1), with: .color(ring), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            // Hành tinh có vành ở đầu quỹ đạo.
            let px: CGFloat = 80, py: CGFloat = 25
            c.circle(px, py, 5.2, rgb(0xF6A98B))
            c.ellipse(px - 4.2, py - 2.6, 4.4, 2.4, Color.white.opacity(0.45))
            c.rotated(-18, around: pt(px, py)) { r in
                r.strokePath(rgb(0xF6D36B), width: 1.3) { p in
                    p.move(to: pt(px - 8.5, py)); p.addQuadCurve(to: pt(px + 8.5, py), control: pt(px, py + 5.5))
                }
            }
        }
        sparkle(ctx, 20, 26, 5, gold)
        sparkle(ctx, 76, 8, 5, gold)
    }

    fileprivate static func dragonHood(_ ctx: GraphicsContext) {
        let mint = rgb(0x9FDCCB), mintDeep = rgb(0x7CC4B0), horn = rgb(0xF2C462), hornDeep = rgb(0xD9A441)
        let mane = rgb(0xF6A9BE)
        for flip in [false, true] {
            let c = mirrored(ctx, flip)
            c.strokePath(hornDeep, width: 3.6) { p in
                p.move(to: pt(40, 19)); p.addQuadCurve(to: pt(31, 1.5), control: pt(32.5, 12))
                p.move(to: pt(34, 9.5)); p.addQuadCurve(to: pt(25, 6.5), control: pt(28.5, 9.8))
            }
            c.strokePath(horn, width: 2.2) { p in
                p.move(to: pt(40, 19)); p.addQuadCurve(to: pt(31, 1.5), control: pt(32.5, 12))
                p.move(to: pt(34, 9.5)); p.addQuadCurve(to: pt(25, 6.5), control: pt(28.5, 9.8))
            }
            soft(c, [pt(25.5, 25), pt(12, 19.5), pt(16, 26), pt(11, 31.5), pt(24, 32.5)], mane, 1.6)
            c.strokePath(rgb(0xE7839F), width: 0.8) { p in
                p.move(to: pt(23, 27)); p.addLine(to: pt(16, 22.5))
                p.move(to: pt(23, 30)); p.addLine(to: pt(15, 30.5))
            }
        }
        var hood = ctx
        hood.clip(to: Path(CGRect(x: 0, y: 0, width: 100, height: 34.5)))
        hood.ellipse(22, 14, 56, 46, mint)
        let scales: [(CGFloat, CGFloat)] = [(36, 24), (44, 21), (52, 24), (60, 21), (40, 28.5), (56, 28.5)]
        ctx.strokePath(mintDeep, width: 0.9) { p in
            for (x, y) in scales {
                p.move(to: pt(x - 3, y)); p.addQuadCurve(to: pt(x + 3, y), control: pt(x, y + 2.6))
            }
        }
        ctx.rect(22.5, 31, 55, 5, mintDeep, radius: 2.5)
        let tufts: [(CGFloat, CGFloat, CGFloat)] = [(44.5, 14.5, 3), (50, 12.5, 3.6), (55.5, 14.5, 3)]
        for (x, y, r) in tufts { ctx.circle(x, y, r, mane) }
        ctx.circle(49, 11.5, 1, Color.white.opacity(0.7))
        ctx.ellipse(29, 19, 7, 3.5, Color.white.opacity(0.35))
    }

    // MARK: Kính

    fileprivate static func temples(_ ctx: GraphicsContext, _ color: Color, y: CGFloat = 47.5, inset: CGFloat = 28.5, width: CGFloat = 1.3) {
        ctx.strokePath(color, width: width) { p in
            p.move(to: pt(inset, y)); p.addLine(to: pt(21, y - 1.5))
            p.move(to: pt(100 - inset, y)); p.addLine(to: pt(79, y - 1.5))
        }
    }

    fileprivate static func glasses3D(_ ctx: GraphicsContext) {
        let frame = rgb(0xFBFAF6), edge = rgb(0xD6CEC0)
        temples(ctx, edge, y: 47, inset: 27, width: 2)
        ctx.rect(26, 42, 48, 16, edge, radius: 2.6)
        ctx.rect(26.7, 42.7, 46.6, 14.6, frame, radius: 2.2)
        ctx.rect(29.5, 44.6, 16, 10.8, rgb(0xEF6A6A).opacity(0.82), radius: 1.6)
        ctx.rect(54.5, 44.6, 16, 10.8, rgb(0x5EC6E8).opacity(0.82), radius: 1.6)
        ctx.strokePath(Color.white.opacity(0.7), width: 1) { p in
            p.move(to: pt(31.5, 47)); p.addLine(to: pt(35, 46))
            p.move(to: pt(56.5, 47)); p.addLine(to: pt(60, 46))
        }
    }

    fileprivate static func sleepMask(_ ctx: GraphicsContext, _ a: PetAppearance) {
        let dy: CGFloat = a.species == .hamster ? 3 : 0
        let fabric = rgb(0xBCA9E8), deep = rgb(0x9C88D6), lash = rgb(0x4A4060)
        ctx.strokePath(deep, width: 2.4) { p in
            p.move(to: pt(28, 37 + dy)); p.addLine(to: pt(18.5, 40 + dy))
            p.move(to: pt(72, 37 + dy)); p.addLine(to: pt(81.5, 40 + dy))
        }
        ctx.ellipse(26, 30 + dy, 25, 12, fabric)
        ctx.ellipse(49, 30 + dy, 25, 12, fabric)
        ctx.rect(40, 31 + dy, 20, 9, fabric, radius: 3)
        ctx.strokePath(Color.white.opacity(0.6), width: 0.7) { p in
            p.move(to: pt(29, 32.5 + dy)); p.addQuadCurve(to: pt(71, 32.5 + dy), control: pt(50, 30 + dy))
        }
        for cx in [CGFloat(38.5), 61.5] {
            ctx.strokePath(lash, width: 1.2) { p in
                p.move(to: pt(cx - 5, 35 + dy)); p.addQuadCurve(to: pt(cx + 5, 35 + dy), control: pt(cx, 39 + dy))
                p.move(to: pt(cx - 3.2, 37 + dy)); p.addLine(to: pt(cx - 4.2, 39 + dy))
                p.move(to: pt(cx, 37.6 + dy)); p.addLine(to: pt(cx, 39.8 + dy))
                p.move(to: pt(cx + 3.2, 37 + dy)); p.addLine(to: pt(cx + 4.2, 39 + dy))
            }
        }
        ctx.ellipse(32, 39 + dy, 4, 2, rgb(0xF4A3B4).opacity(0.8))
        ctx.ellipse(64, 39 + dy, 4, 2, rgb(0xF4A3B4).opacity(0.8))
    }

    fileprivate static func flowerGlasses(_ ctx: GraphicsContext) {
        let pink = rgb(0xF4A6BD), pale = rgb(0xFBD3DF), rim = rgb(0xE07F98)
        temples(ctx, rim, inset: 26)
        for cx in [CGFloat(37.5), 62.5] {
            for k in 0..<8 {
                let ang = Double(k) * Double.pi / 4 + 0.2
                ctx.circle(cx + 9.4 * CGFloat(cos(ang)), 50 + 9.4 * CGFloat(sin(ang)), 3, k % 2 == 0 ? pink : pale)
            }
            ctx.circle(cx, 50, 7.4, Color.white.opacity(0.25))
            ctx.strokePath(rim, width: 1.4) { p in
                p.addEllipse(in: CGRect(x: cx - 7.4, y: 42.6, width: 14.8, height: 14.8))
            }
            ctx.strokePath(Color.white.opacity(0.85), width: 1) { p in
                p.move(to: pt(cx - 4.5, 47.5)); p.addQuadCurve(to: pt(cx - 1, 45.2), control: pt(cx - 4, 45.4))
            }
        }
        ctx.circle(50, 44, 1.5, rgb(0xF6D36B))
    }

    fileprivate static func catEyeGlasses(_ ctx: GraphicsContext) {
        let pink = rgb(0xE77FA0)
        for flip in [false, true] {
            let c = mirrored(ctx, flip)
            var l = Path()
            l.move(to: pt(28.5, 45))
            l.addQuadCurve(to: pt(46.5, 46), control: pt(38, 42.5))
            l.addQuadCurve(to: pt(38, 57), control: pt(47.5, 56))
            l.addQuadCurve(to: pt(28.5, 45), control: pt(28.5, 56))
            l.closeSubpath()
            c.fill(l, with: .color(rgb(0xFCE0EA).opacity(0.35)))
            c.stroke(l, with: .color(pink), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
            soft(c, [pt(30, 44), pt(21.5, 39.5), pt(28, 49)], pink, 1.4)
            c.circle(24.8, 41.8, 0.9, .white)
            c.circle(31.5, 44.3, 0.7, .white)
            c.strokePath(Color.white.opacity(0.8), width: 1) { p in
                p.move(to: pt(32, 48)); p.addLine(to: pt(35, 46.6))
            }
        }
        ctx.strokePath(pink, width: 1.6) { p in
            p.move(to: pt(46.5, 47)); p.addQuadCurve(to: pt(53.5, 47), control: pt(50, 45))
        }
    }

    fileprivate static func snorkel(_ ctx: GraphicsContext) {
        let rim = rgb(0xF59A5B), strap = rgb(0xE3814A), tube = rgb(0x6FC2A8)
        ctx.strokePath(strap, width: 3) { p in
            p.move(to: pt(28, 49)); p.addLine(to: pt(18.5, 47))
            p.move(to: pt(72, 49)); p.addLine(to: pt(81.5, 47))
        }
        ctx.strokePath(tube, width: 3.4) { p in
            p.move(to: pt(73.5, 54)); p.addQuadCurve(to: pt(80, 44), control: pt(80, 52)); p.addLine(to: pt(80.5, 21))
        }
        ctx.rect(77.5, 16.5, 6, 6, rim, radius: 2)
        let mask = Path(roundedRect: CGRect(x: 27, y: 41, width: 46, height: 17), cornerRadius: 7.5)
        ctx.fill(mask, with: .color(rgb(0xBFE8F7).opacity(0.45)))
        ctx.stroke(mask, with: .color(rim), lineWidth: 2.8)
        ctx.strokePath(rim, width: 2) { p in
            p.move(to: pt(50, 41.5)); p.addLine(to: pt(50, 44))
        }
        ctx.strokePath(Color.white.opacity(0.85), width: 1.3) { p in
            p.move(to: pt(31.5, 47)); p.addQuadCurve(to: pt(36, 44.3), control: pt(32, 44.5))
            p.move(to: pt(56.5, 47)); p.addQuadCurve(to: pt(61, 44.3), control: pt(57, 44.5))
        }
    }

    fileprivate static func goldWire(_ ctx: GraphicsContext) {
        let gold = rgb(0xD9A441)
        // Dây đeo kính vòng xuống ngực.
        var chain = Path()
        chain.move(to: pt(21.5, 47))
        chain.addQuadCurve(to: pt(78.5, 47), control: pt(50, 93))
        ctx.stroke(chain, with: .color(gold.opacity(0.8)), lineWidth: 0.6)
        for k in 1..<14 {
            let t = CGFloat(k) / 14
            let x = (1 - t) * (1 - t) * 21.5 + 2 * (1 - t) * t * 50 + t * t * 78.5
            let y = (1 - t) * (1 - t) * 47 + 2 * (1 - t) * t * 93 + t * t * 47
            if y > 58 { ctx.circle(x, y, 0.65, gold) }
        }
        temples(ctx, gold, y: 48.5, inset: 29.3, width: 1.1)
        for cx in [CGFloat(37.5), 62.5] {
            ctx.circle(cx, 50, 8.2, rgb(0xFFF4D6).opacity(0.22))
            ctx.strokePath(gold, width: 1.2) { p in
                p.addEllipse(in: CGRect(x: cx - 8.2, y: 41.8, width: 16.4, height: 16.4))
            }
            ctx.strokePath(Color.white.opacity(0.8), width: 1) { p in
                p.move(to: pt(cx - 5, 47.5)); p.addQuadCurve(to: pt(cx - 1.5, 44.8), control: pt(cx - 4.6, 45))
            }
        }
        ctx.strokePath(gold, width: 1.1) { p in
            p.move(to: pt(45.7, 48.5)); p.addQuadCurve(to: pt(54.3, 48.5), control: pt(50, 45.5))
        }
    }

    fileprivate static func eyePatch(_ ctx: GraphicsContext) {
        let patch = rgb(0x3E3850)
        ctx.strokePath(patch, width: 1.6) { p in
            p.move(to: pt(57, 44.5)); p.addLine(to: pt(25, 35))
            p.move(to: pt(69.5, 51)); p.addLine(to: pt(80, 53))
        }
        ctx.ellipse(54.5, 42.5, 16, 14.5, patch)
        ctx.strokePath(rgb(0x5A5272), width: 0.7) { p in
            p.addEllipse(in: CGRect(x: 56.3, y: 44.2, width: 12.4, height: 11.1))
        }
        star(ctx, 62.5, 49.8, 2.6, rgb(0xEDBF55))
    }

    // MARK: Cổ

    fileprivate static func bib(_ ctx: GraphicsContext) {
        let white = rgb(0xFFFFFF), trim = rgb(0x8CC4E8)
        ctx.strokePath(trim, width: 2) { p in
            p.move(to: pt(37, 61.5)); p.addLine(to: pt(28, 60))
            p.move(to: pt(63, 61.5)); p.addLine(to: pt(72, 60))
        }
        var b = Path()
        b.move(to: pt(35.5, 61))
        b.addQuadCurve(to: pt(64.5, 61), control: pt(50, 67))
        b.addCurve(to: pt(35.5, 61), control1: pt(69, 83), control2: pt(31, 83))
        b.closeSubpath()
        ctx.fill(b, with: .color(white))
        ctx.stroke(b, with: .color(trim), style: StrokeStyle(lineWidth: 1.6, lineJoin: .round))
        // Củ cà rốt nhỏ in giữa yếm.
        ctx.rotated(-25, around: pt(50, 72)) { c in
            c.polygon([pt(47.4, 68.5), pt(52.6, 68.5), pt(50, 78)], rgb(0xF5A04F))
            c.strokePath(rgb(0xDD8636), width: 0.6) { p in
                p.move(to: pt(48.5, 71)); p.addLine(to: pt(50, 71.3))
                p.move(to: pt(50.5, 73.5)); p.addLine(to: pt(51.6, 73.7))
            }
            c.ellipse(46.6, 65, 3, 4.4, rgb(0x8CC77A))
            c.ellipse(50.4, 65, 3, 4.4, rgb(0x8CC77A))
        }
    }

    fileprivate static func clover(_ ctx: GraphicsContext) {
        let cord = rgb(0x6FAF72), leaf = rgb(0x86C774)
        ctx.strokePath(cord, width: 0.9) { p in
            p.move(to: pt(29, 61.5)); p.addQuadCurve(to: pt(71, 61.5), control: pt(50, 76))
        }
        let c0 = pt(50, 72.5)
        for k in 0..<4 {
            ctx.rotated(Double(k) * 90 + 45, around: c0) { c in
                c.heart(center: pt(c0.x, c0.y - 3.1), size: 6.2, leaf)
            }
        }
        ctx.strokePath(cord, width: 1) { p in
            p.move(to: c0); p.addQuadCurve(to: pt(53, 79), control: pt(51, 77))
        }
        ctx.circle(c0.x, c0.y, 0.9, rgb(0x5E9F55))
        ctx.circle(48, 70, 0.8, Color.white.opacity(0.7))
    }

    fileprivate static func stripeScarf(_ ctx: GraphicsContext) {
        let colors = [rgb(0xF29BB0), rgb(0xFBF3E4), rgb(0x8CC4E8)]
        // Đuôi khăn buông bên trái.
        ctx.rotated(12, around: pt(33, 63)) { c in
            let tail = Path(roundedRect: CGRect(x: 29, y: 62, width: 8.5, height: 17), cornerRadius: 1.5)
            var t = c
            t.clip(to: tail)
            for (i, y) in stride(from: CGFloat(62), to: 80, by: 3.4).enumerated() {
                t.rect(28, y, 11, 3.5, colors[i % 3])
            }
            c.strokePath(colors[0], width: 0.9) { p in
                for x in stride(from: CGFloat(30), through: 36.5, by: 1.6) {
                    p.move(to: pt(x, 79)); p.addLine(to: pt(x, 82))
                }
            }
        }
        let band = Path(roundedRect: CGRect(x: 25, y: 59.5, width: 50, height: 7), cornerRadius: 3.5)
        var b = ctx
        b.clip(to: band)
        for (i, x) in stride(from: CGFloat(25), to: 75, by: 3.6).enumerated() {
            b.rect(x, 59, 3.7, 8, colors[i % 3])
        }
        ctx.rect(30, 61.2, 7, 7.5, colors[2], radius: 3)
        ctx.rect(31.5, 62.5, 4, 1, Color.white.opacity(0.6), radius: 0.5)
    }

    fileprivate static func whistle(_ ctx: GraphicsContext) {
        let cord = rgb(0xE56B6B), silver = rgb(0xC9D0DE), silverDeep = rgb(0xA3ADC2)
        ctx.strokePath(cord, width: 1.5) { p in
            p.move(to: pt(32, 61.5)); p.addLine(to: pt(48.5, 71))
            p.move(to: pt(68, 61.5)); p.addLine(to: pt(51.5, 71))
        }
        ctx.strokePath(silverDeep, width: 0.9) { p in
            p.addEllipse(in: CGRect(x: 48.4, y: 70, width: 3.2, height: 3.2))
        }
        ctx.rect(53, 73.6, 8, 3.6, silverDeep, radius: 1)
        ctx.circle(50, 76.5, 4.6, silverDeep)
        ctx.circle(50, 76.3, 4, silver)
        ctx.rect(53, 73.3, 7.5, 3, silver, radius: 0.9)
        ctx.circle(50.3, 76.5, 1.2, rgb(0x5A5272))
        ctx.circle(48.4, 74.6, 0.9, Color.white.opacity(0.85))
    }

    fileprivate static func hibiscusLei(_ ctx: GraphicsContext) {
        let tones = [rgb(0xEF6B6B), rgb(0xF6A04F), rgb(0xF48FB1)]
        let leaf = rgb(0x7FBF6E)
        for i in 0..<6 {
            let p = necklacePoint(31.5 + CGFloat(i) * 7.4)
            ctx.rotated(Double(i) * 30 - 70, around: p) { c in c.ellipse(p.x - 1.8, p.y - 4.8, 3.6, 5.4, leaf) }
        }
        for i in 0..<7 {
            let p = necklacePoint(27.8 + CGFloat(i) * 7.4)
            fivePetal(ctx, p.x, p.y, 3.6, tones[i % 3], rgb(0xF6D36B), turn: Double(i) * 17)
            ctx.circle(p.x - 0.8, p.y - 1, 0.5, Color.white.opacity(0.8))
        }
    }

    fileprivate static func camera(_ ctx: GraphicsContext) {
        let strap = rgb(0x8A5A3C), body = rgb(0x9ED0C6), deep = rgb(0x7AB5AA)
        ctx.strokePath(strap, width: 1.8) { p in
            p.move(to: pt(31, 61.5)); p.addLine(to: pt(42, 71))
            p.move(to: pt(69, 61.5)); p.addLine(to: pt(58, 71))
        }
        ctx.rect(43, 67.8, 6.5, 3.4, deep, radius: 1)
        ctx.rect(40.5, 69.8, 19, 12.5, body, radius: 2.6)
        ctx.rect(40.5, 73.8, 19, 1.4, deep)
        ctx.rect(55, 71.3, 3, 1.8, rgb(0xFFF6D8), radius: 0.5)
        ctx.circle(50, 76.5, 4.6, rgb(0x4A4152))
        ctx.circle(50, 76.5, 3.2, rgb(0x6F86B8))
        ctx.circle(48.8, 75.3, 1, Color.white.opacity(0.85))
        ctx.circle(56.5, 68.9, 1, rgb(0xE56B6B))
    }

    fileprivate static func moonPendant(_ ctx: GraphicsContext) {
        let gold = rgb(0xF2C462), goldDeep = rgb(0xD9A441)
        ctx.strokePath(goldDeep, width: 0.8) { p in
            p.move(to: pt(28, 61.5)); p.addQuadCurve(to: pt(72, 61.5), control: pt(50, 74))
        }
        for x in stride(from: CGFloat(31), through: 69, by: 4.2) {
            ctx.circle(x, necklacePoint(x, depth: 6.1, top: 61.6).y, 0.7, gold)
        }
        ctx.circle(50, 68.3, 1.4, goldDeep)
        // Trăng khuyết: nửa đường tròn ngoài + nửa elip trong.
        let c = pt(50, 75.5), r: CGFloat = 7
        ctx.rotated(-28, around: c) { k in
            var m = Path()
            for i in 0...24 {
                let t = (-90 + 180 * Double(i) / 24) * Double.pi / 180
                let q = pt(c.x - r * CGFloat(cos(t)), c.y + r * CGFloat(sin(t)))
                if i == 0 { m.move(to: q) } else { m.addLine(to: q) }
            }
            for i in 0...24 {
                let t = (90 - 180 * Double(i) / 24) * Double.pi / 180
                m.addLine(to: pt(c.x - r * 0.3 * CGFloat(cos(t)), c.y + r * CGFloat(sin(t))))
            }
            m.closeSubpath()
            k.fill(m, with: .linearGradient(Gradient(colors: [rgb(0xFFE7A0), gold]),
                                            startPoint: pt(c.x - r, c.y - r), endPoint: pt(c.x, c.y + r)))
            k.stroke(m, with: .color(goldDeep), lineWidth: 0.7)
        }
        star(ctx, 56.5, 78.5, 2.3, rgb(0xFFE7A0))
        sparkle(ctx, 41, 79, 4, rgb(0xF2C462))
    }

    fileprivate static func dragonPearl(_ ctx: GraphicsContext) {
        let jade = rgb(0x7CC4B0), jadeLight = rgb(0xB5E6D8), gold = rgb(0xE8B84E)
        for i in 0..<12 {
            let x = 26.5 + CGFloat(i) * 4.27
            if abs(x - 50) < 4 { continue }
            let p = necklacePoint(x, depth: 5.5)
            ctx.circle(p.x, p.y, 2, jade)
            ctx.circle(p.x - 0.6, p.y - 0.6, 0.7, jadeLight)
        }
        let c = pt(50, 75)
        ctx.circle(c.x, c.y, 7.5, rgb(0xFFF2C2).opacity(0.35))
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - 5.4, y: c.y - 5.4, width: 10.8, height: 10.8)),
                 with: .radialGradient(Gradient(colors: [.white, rgb(0xE4DAF6), rgb(0xB9C8F0)]),
                                       center: pt(c.x - 1.6, c.y - 1.8), startRadius: 0, endRadius: 7))
        // Móng vàng giữ ngọc.
        ctx.strokePath(gold, width: 1.6) { p in
            p.move(to: pt(50, 67.5)); p.addLine(to: pt(50, 70))
            p.move(to: pt(45.5, 69.5)); p.addQuadCurve(to: pt(45.6, 78.5), control: pt(42.5, 74))
            p.move(to: pt(54.5, 69.5)); p.addQuadCurve(to: pt(54.4, 78.5), control: pt(57.5, 74))
            p.move(to: pt(45, 70)); p.addQuadCurve(to: pt(55, 70), control: pt(50, 67.6))
        }
        ctx.circle(45.6, 78.5, 1, gold)
        ctx.circle(54.4, 78.5, 1, gold)
        ctx.circle(48, 73, 1.3, .white)
        sparkle(ctx, 58.5, 81, 4, rgb(0xF2C462))
    }

    // MARK: Áo

    fileprivate static func catSweater(_ ctx: GraphicsContext, _ clipped: GraphicsContext) {
        let lilac = rgb(0xC9B6EC), deep = rgb(0xAE97DF), face = rgb(0xFBF3E4)
        clipped.rect(0, 62, 100, 40, lilac)
        clipped.rect(0, 84.5, 100, 5, deep)
        clipped.strokePath(lilac, width: 0.7) { p in
            for x in stride(from: CGFloat(14), through: 86, by: 2.6) {
                p.move(to: pt(x, 85)); p.addLine(to: pt(x, 89.5))
            }
        }
        ctx.strokePath(deep, width: 3.6) { p in
            p.move(to: pt(28, 61.2)); p.addQuadCurve(to: pt(72, 61.2), control: pt(50, 68))
        }
        // Mặt mèo in giữa áo.
        ctx.polygon([pt(42.5, 72), pt(43.5, 66), pt(47.5, 69.5)], face)
        ctx.polygon([pt(57.5, 72), pt(56.5, 66), pt(52.5, 69.5)], face)
        ctx.ellipse(41.5, 68.5, 17, 12.5, face)
        let ink = rgb(0x544866)
        ctx.circle(46.3, 74, 1.1, ink)
        ctx.circle(53.7, 74, 1.1, ink)
        ctx.polygon([pt(48.9, 76), pt(51.1, 76), pt(50, 77.3)], rgb(0xF29BB0))
        ctx.strokePath(ink, width: 0.5) { p in
            p.move(to: pt(43.5, 76.5)); p.addLine(to: pt(39.5, 76))
            p.move(to: pt(43.5, 77.6)); p.addLine(to: pt(39.8, 78.4))
            p.move(to: pt(56.5, 76.5)); p.addLine(to: pt(60.5, 76))
            p.move(to: pt(56.5, 77.6)); p.addLine(to: pt(60.2, 78.4))
        }
        ctx.ellipse(43.5, 76.6, 2.4, 1.3, rgb(0xF4A3B4).opacity(0.8))
        ctx.ellipse(54.1, 76.6, 2.4, 1.3, rgb(0xF4A3B4).opacity(0.8))
    }

    fileprivate static func duckCoat(_ ctx: GraphicsContext, _ clipped: GraphicsContext) {
        let blue = rgb(0x93C6EA), deep = rgb(0x6EA8D4)
        clipped.rect(0, 62, 100, 40, blue)
        let ducks: [(CGFloat, CGFloat)] = [(28, 71), (69, 69.5), (37, 83), (62, 82.5), (21, 80), (79, 79)]
        for d in ducks { duckPrint(clipped, d.0, d.1) }
        clipped.rect(48.6, 63, 2.8, 32, deep)
        for y in [CGFloat(70), 76.5, 83] {
            ctx.rect(46.2, y - 1.1, 7.6, 2.2, rgb(0xF7D35C), radius: 1.1)
        }
        for flip in [false, true] {
            soft(mirrored(ctx, flip), [pt(32, 60.8), pt(49.5, 61.8), pt(41, 69)], deep, 1.4)
        }
    }

    fileprivate static func patchOveralls(_ ctx: GraphicsContext, _ clipped: GraphicsContext) {
        let pink = rgb(0xEFA6B9), deep = rgb(0xD98AA0)
        clipped.rect(0, 77, 100, 20, pink)
        clipped.rect(36, 65, 28, 16, pink, radius: 3)
        clipped.strokePath(deep.opacity(0.55), width: 0.6) { p in
            for x in stride(from: CGFloat(38.5), through: 62, by: 2.6) {
                p.move(to: pt(x, 66)); p.addLine(to: pt(x, 77))
            }
            for x in stride(from: CGFloat(14), through: 86, by: 2.6) {
                p.move(to: pt(x, 78)); p.addLine(to: pt(x, 96))
            }
        }
        clipped.rect(43.5, 68.5, 13, 7, deep, radius: 1.5)
        ctx.strokePath(pink, width: 3) { p in
            p.move(to: pt(38, 67)); p.addLine(to: pt(31, 61))
            p.move(to: pt(62, 67)); p.addLine(to: pt(69, 61))
        }
        ctx.circle(39, 67, 1.4, rgb(0xF0C26A))
        ctx.circle(61, 67, 1.4, rgb(0xF0C26A))
        // Miếng vá ô vuông xanh có đường chỉ.
        ctx.rotated(-10, around: pt(29, 83.5)) { c in
            c.rect(24.5, 79, 9, 9, rgb(0x8FB6E3), radius: 1.2)
            c.strokePath(.white, width: 0.6) { p in
                for k in 0..<3 {
                    let o = CGFloat(k) * 2.8
                    p.move(to: pt(25.8 + o, 80.2)); p.addLine(to: pt(27.2 + o, 80.2))
                    p.move(to: pt(25.8 + o, 86.8)); p.addLine(to: pt(27.2 + o, 86.8))
                    p.move(to: pt(25.7, 80.6 + o)); p.addLine(to: pt(25.7, 82 + o))
                    p.move(to: pt(32.3, 80.6 + o)); p.addLine(to: pt(32.3, 82 + o))
                }
            }
        }
        ctx.heart(center: pt(67, 85), size: 9, rgb(0xF6D36B))
        ctx.strokePath(rgb(0xE0A92E), width: 0.6) { p in
            p.move(to: pt(64.3, 84)); p.addLine(to: pt(65.5, 85.5))
            p.move(to: pt(69.7, 84)); p.addLine(to: pt(68.5, 85.5))
        }
    }

    fileprivate static func beeSuit(_ ctx: GraphicsContext, _ clipped: GraphicsContext, _ a: PetAppearance) {
        let w: CGFloat = a.species == .hamster ? 3 : 0
        let yellow = rgb(0xF7CF52), black = rgb(0x4A4152), fluff = rgb(0xFFF6D8)
        clipped.rect(0, 62, 100, 40, yellow)
        clipped.rect(0, 70, 100, 4.8, black)
        clipped.rect(0, 79.5, 100, 4.8, black)
        for flip in [false, true] {
            var c = mirrored(ctx, flip)
            c.translateBy(x: -w, y: 0)
            let film = rgb(0xDDF0FB).opacity(0.9), vein = rgb(0x9CC8E6)
            c.rotated(-35, around: pt(21, 64)) { r in
                r.ellipse(3, 58, 19, 11, film)
                r.strokePath(vein, width: 0.9) { p in
                    p.addEllipse(in: CGRect(x: 3, y: 58, width: 19, height: 11))
                    p.move(to: pt(20, 63.5)); p.addQuadCurve(to: pt(7, 62), control: pt(13, 61.5))
                }
            }
            c.rotated(10, around: pt(21, 68)) { r in
                r.ellipse(6, 66, 15, 8, film)
                r.strokePath(vein, width: 0.9) { p in
                    p.addEllipse(in: CGRect(x: 6, y: 66, width: 15, height: 8))
                }
            }
        }
        for i in 0..<9 {
            let x = 28 + CGFloat(i) * 5.5
            ctx.circle(x, necklacePoint(x, depth: 3, top: 61.5).y, 3.1, fluff)
        }
    }

    fileprivate static func chefCoat(_ ctx: GraphicsContext, _ clipped: GraphicsContext) {
        let white = rgb(0xFBFAFD), line = rgb(0xDCD5E6), red = rgb(0xE56B6B)
        clipped.rect(0, 62, 100, 40, white)
        clipped.strokePath(line, width: 1) { p in
            p.move(to: pt(59, 66)); p.addLine(to: pt(59, 96))
            p.move(to: pt(26, 70)); p.addLine(to: pt(35, 70))
        }
        ctx.rect(28, 66, 1.6, 4.6, rgb(0x6FA3D9), radius: 0.8)
        ctx.rect(30.5, 67, 1.6, 3.6, rgb(0xF6C445), radius: 0.8)
        for y in [CGFloat(71), 77.5, 84] {
            for x in [CGFloat(45), 54] {
                ctx.circle(x, y, 1.5, line)
                ctx.circle(x, y, 0.9, white)
            }
        }
        soft(ctx, [pt(39.5, 61.3), pt(60.5, 61.3), pt(50, 69.5)], red, 1.4)
        ctx.circle(50, 62.5, 2.4, rgb(0xC94F5C))
        let dots: [(CGFloat, CGFloat)] = [(44, 63.5), (52, 64.5), (48, 66.5)]
        for (x, y) in dots { ctx.circle(x, y, 0.6, Color.white.opacity(0.85)) }
    }

    fileprivate static func dinoSuit(_ ctx: GraphicsContext, _ clipped: GraphicsContext, _ a: PetAppearance) {
        let w: CGFloat = a.species == .hamster ? 3 : 0
        let green = rgb(0x93D18C), deep = rgb(0x72B66C), belly = rgb(0xF4EDC8), spike = rgb(0xF6A85B)
        // Đuôi ló ra bên phải.
        var tail = Path()
        tail.move(to: pt(78 + w, 76))
        tail.addQuadCurve(to: pt(97 + w, 86), control: pt(92 + w, 76))
        tail.addQuadCurve(to: pt(78 + w, 88), control: pt(90 + w, 89))
        tail.closeSubpath()
        let tailSpikes: [(CGFloat, CGFloat)] = [(84, 77.3), (89.5, 79.2), (94, 82.3)]
        for (x, y) in tailSpikes {
            soft(ctx, [pt(x - 2.4 + w, y + 1), pt(x + 0.3 + w, y - 3.4), pt(x + 2.4 + w, y + 1)], spike, 1)
        }
        ctx.fill(tail, with: .color(green))
        clipped.rect(0, 62, 100, 40, green)
        var b = clipped
        b.clip(to: Path(ellipseIn: CGRect(x: 36, y: 66, width: 28, height: 26)))
        b.rect(0, 0, 100, 100, belly)
        b.strokePath(rgb(0xDCCFA2), width: 0.9) { p in
            for y in [CGFloat(72), 77.5, 83] { p.move(to: pt(36, y)); p.addLine(to: pt(64, y)) }
        }
        let spots: [(CGFloat, CGFloat, CGFloat)] = [(25, 72, 2.6), (76, 73.5, 2.9), (29, 84, 2), (72, 85, 2), (22, 79, 1.4)]
        for (x, y, r) in spots { clipped.circle(x, y, r, deep) }
        let shoulder: [(CGFloat, CGFloat)] = [(31, 61.5), (37.5, 63.5)]
        for flip in [false, true] {
            let c = mirrored(ctx, flip)
            for (x, y) in shoulder {
                soft(c, [pt(x - 2.4, y + 1.6), pt(x - 0.6, y - 2.6), pt(x + 2.2, y + 1.2)], spike, 1)
            }
        }
    }

    fileprivate static func knightArmor(_ ctx: GraphicsContext, _ clipped: GraphicsContext, _ a: PetAppearance) {
        let w: CGFloat = a.species == .hamster ? 3 : 0
        let steel = rgb(0xC8D0E0), steelDeep = rgb(0xA4AFC6), shine = rgb(0xF0F3FA), gold = rgb(0xEDBF55)
        clipped.rect(0, 62, 100, 40, steel)
        clipped.strokePath(steelDeep, width: 1.2) { p in
            for y in [CGFloat(75), 83.5] {
                p.move(to: pt(0, y - 4)); p.addQuadCurve(to: pt(100, y - 4), control: pt(50, y + 6))
            }
        }
        clipped.ellipse(23, 66, 7, 16, shine.opacity(0.6))
        var shield = Path()
        shield.move(to: pt(42.5, 66.5))
        shield.addLine(to: pt(57.5, 66.5))
        shield.addLine(to: pt(57.5, 73))
        shield.addQuadCurve(to: pt(50, 82.5), control: pt(57, 79.5))
        shield.addQuadCurve(to: pt(42.5, 73), control: pt(43, 79.5))
        shield.closeSubpath()
        ctx.fill(shield, with: .color(rgb(0x7FA6E0)))
        ctx.stroke(shield, with: .color(gold), style: StrokeStyle(lineWidth: 1.3, lineJoin: .round))
        ctx.heart(center: pt(50, 73.5), size: 7, rgb(0xF27D9B))
        for flip in [false, true] {
            var c = mirrored(ctx, flip)
            c.translateBy(x: -w, y: 0)
            c.ellipse(15, 58.5, 18, 11, steelDeep)
            c.ellipse(15.5, 58, 17, 9.5, steel)
            c.strokePath(steelDeep, width: 0.9) { p in
                p.move(to: pt(17, 64.5)); p.addQuadCurve(to: pt(31, 64.5), control: pt(24, 67.5))
            }
            c.circle(25, 61.5, 1, gold)
            c.ellipse(18, 59.5, 6, 2.6, shine.opacity(0.8))
        }
        ctx.rect(31, 60, 38, 4.6, steelDeep, radius: 2.3)
        ctx.rect(33, 60.8, 34, 1.2, shine.opacity(0.7), radius: 0.6)
    }

    fileprivate static func sakuraKimono(_ ctx: GraphicsContext, _ clipped: GraphicsContext, _ a: PetAppearance) {
        let w: CGFloat = a.species == .hamster ? 3 : 0
        let base = rgb(0xF9CCDA), blossom = rgb(0xFFF6F8), deep = rgb(0xE7839F)
        let obi = rgb(0xC85C7C), cord = rgb(0xF2C462), under = rgb(0xFFFDF9)
        // Tay áo dài buông hai bên.
        for flip in [false, true] {
            var c = mirrored(ctx, flip)
            c.translateBy(x: -w, y: 0)
            var s = Path()
            s.move(to: pt(22, 64))
            s.addQuadCurve(to: pt(10, 74), control: pt(12, 64))
            s.addQuadCurve(to: pt(14, 88), control: pt(8, 85))
            s.addQuadCurve(to: pt(25, 84), control: pt(21, 89))
            s.closeSubpath()
            c.fill(s, with: .color(base))
            c.stroke(s, with: .color(deep.opacity(0.5)), lineWidth: 0.8)
            fivePetal(c, 14.5, 80, 2.6, blossom, rgb(0xF6D36B))
        }
        clipped.rect(0, 62, 100, 40, base)
        let spots: [(CGFloat, CGFloat, CGFloat)] = [(27, 68, 2.8), (70, 67, 2.4), (24, 85, 2.6), (40, 86.5, 2.2),
                                                    (60, 85, 2.8), (76, 86, 2.2), (34, 66, 1.8), (64, 70, 1.6)]
        for (i, s) in spots.enumerated() {
            fivePetal(clipped, s.0, s.1, s.2, i % 3 == 2 ? deep.opacity(0.8) : blossom, rgb(0xF6D36B), turn: Double(i) * 23)
        }
        soft(clipped, [pt(39, 61.5), pt(61, 61.5), pt(50, 73)], under, 1)
        ctx.strokePath(rgb(0xE05A72), width: 2.4) { p in
            p.move(to: pt(37, 61.5)); p.addLine(to: pt(53.5, 76))
            p.move(to: pt(63, 61.5)); p.addLine(to: pt(50, 73.5))
        }
        clipped.rect(0, 73.5, 100, 7.5, obi)
        clipped.rect(0, 76.6, 100, 1.3, cord)
        ctx.circle(50, 77.2, 2, cord)
        ctx.strokePath(cord, width: 1) { p in
            p.move(to: pt(50, 78.5)); p.addQuadCurve(to: pt(46.5, 86), control: pt(47.5, 82))
            p.move(to: pt(50, 78.5)); p.addQuadCurve(to: pt(53.5, 86), control: pt(52.5, 82))
        }
        ctx.circle(46.5, 86.4, 1, cord)
        ctx.circle(53.5, 86.4, 1, cord)
    }

    // MARK: Phụ kiện

    fileprivate static func iceCream(_ ctx: GraphicsContext, _ a: PetAppearance) {
        let tip = pt(60.5, 82.5)
        var cone = Path()
        cone.addLines([tip, pt(54, 63), pt(67, 63)])
        cone.closeSubpath()
        ctx.rotated(32, around: tip) { c in
            c.fill(cone, with: .color(rgb(0xE8B26C)))
            var waffle = c
            waffle.clip(to: cone)
            waffle.strokePath(rgb(0xC98F4E), width: 0.7) { p in
                for k in 0..<5 {
                    let o = CGFloat(k) * 4
                    p.move(to: pt(52 + o, 62)); p.addLine(to: pt(62 + o, 84))
                    p.move(to: pt(69 - o, 62)); p.addLine(to: pt(59 - o, 84))
                }
            }
            c.circle(60.5, 59.5, 6.6, rgb(0xF4A6BD))
            c.ellipse(53.5, 60.5, 14, 4.5, rgb(0xF4A6BD))
            c.circle(60.5, 51, 5.6, rgb(0xA9DDB8))
            c.circle(58.5, 49, 1.4, Color.white.opacity(0.6))
            c.circle(57.5, 58, 1.3, Color.white.opacity(0.6))
            c.circle(61, 44.5, 2.4, rgb(0xE0565B))
            c.strokePath(rgb(0x6FAF72), width: 0.8) { p in
                p.move(to: pt(61.5, 42.5)); p.addQuadCurve(to: pt(64.5, 39.5), control: pt(62, 40))
            }
            let sprinkles: [(CGFloat, CGFloat, Color)] = [(57, 61, rgb(0xF6D36B)), (63, 57, rgb(0x6FA3D9)), (62, 52.5, rgb(0xF27D9B))]
            for (x, y, col) in sprinkles { c.rect(x, y, 1.8, 0.8, col, radius: 0.4) }
        }
        pawGrip(ctx, a, 58.5, 80.3)
    }

    fileprivate static func kite(_ ctx: GraphicsContext, _ a: PetAppearance, front: Bool) {
        if front {
            ctx.strokePath(rgb(0x9A8FB0), width: 0.8) { p in
                p.move(to: pt(60.5, 82)); p.addQuadCurve(to: pt(77, 21), control: pt(92, 60))
            }
            pawGrip(ctx, a, 58.5, 80)
            return
        }
        ctx.strokePath(rgb(0x9A8FB0), width: 0.8) { p in
            p.move(to: pt(78, 32)); p.addQuadCurve(to: pt(90, 52), control: pt(96, 38))
        }
        let bows: [(CGFloat, CGFloat, Color)] = [(86.5, 38, rgb(0xF27D9B)), (91, 45, rgb(0xF6D36B)), (90, 52, rgb(0x8CC4E8))]
        for (x, y, col) in bows {
            ctx.polygon([pt(x - 3, y - 1.8), pt(x, y), pt(x - 3, y + 1.8)], col)
            ctx.polygon([pt(x + 3, y - 1.8), pt(x, y), pt(x + 3, y + 1.8)], col)
        }
        ctx.rotated(12, around: pt(78, 16)) { c in
            let top = pt(78, 1), right = pt(90, 13), bottom = pt(78, 32), left = pt(66, 13), mid = pt(78, 13)
            c.polygon([top, right, mid], rgb(0xF6D36B))
            c.polygon([right, bottom, mid], rgb(0xF27D9B))
            c.polygon([bottom, left, mid], rgb(0x8CC4E8))
            c.polygon([left, top, mid], rgb(0xA9DDB8))
            c.strokePath(Color.white.opacity(0.9), width: 0.9) { p in
                p.move(to: top); p.addLine(to: bottom)
                p.move(to: left); p.addLine(to: right)
            }
        }
    }

    fileprivate static func balloons(_ ctx: GraphicsContext, _ a: PetAppearance, front: Bool) {
        let list: [(CGFloat, CGFloat, CGFloat, Color)] = [(73, 12, 7.5, rgb(0xF4A6BD)), (89, 17, 7, rgb(0xF6D36B)),
                                                          (80, 30, 6.5, rgb(0xA9DDB8))]
        if front {
            ctx.strokePath(rgb(0x9A8FB0), width: 0.8) { p in
                for b in list {
                    p.move(to: pt(60.5, 82)); p.addQuadCurve(to: pt(b.0, b.1 + b.2 + 2), control: pt(90, 64))
                }
            }
            pawGrip(ctx, a, 58.5, 80)
            return
        }
        for b in list {
            ctx.ellipse(b.0 - b.2, b.1 - b.2 * 1.1, b.2 * 2, b.2 * 2.2, b.3)
            ctx.polygon([pt(b.0, b.1 + b.2), pt(b.0 - 1.5, b.1 + b.2 + 2.3), pt(b.0 + 1.5, b.1 + b.2 + 2.3)], b.3)
            ctx.rotated(-30, around: pt(b.0 - b.2 * 0.4, b.1 - b.2 * 0.5)) { c in
                c.ellipse(b.0 - b.2 * 0.65, b.1 - b.2 * 0.75, b.2 * 0.55, b.2 * 0.35, Color.white.opacity(0.6))
            }
        }
    }

    fileprivate static func bearPack(_ ctx: GraphicsContext, _ w: CGFloat, front: Bool) {
        let fur = rgb(0xC8956A), deep = rgb(0xA97852), inner = rgb(0xF2DCC2)
        if front {
            for flip in [false, true] {
                let c = mirrored(ctx, flip)
                c.strokePath(deep, width: 3.4) { p in
                    p.move(to: pt(21 - w, 56)); p.addQuadCurve(to: pt(33, 82), control: pt(24 - w, 74))
                }
                c.circle(25.3 - w * 0.5, 71.5, 1.8, inner)
            }
            return
        }
        for flip in [false, true] {
            var c = mirrored(ctx, flip)
            c.translateBy(x: -w, y: 0)
            c.circle(14, 50, 7.5, fur)
            c.circle(14, 50, 4, inner)
            c.ellipse(4, 64, 9, 15, deep)
            c.ellipse(4.8, 74, 7.5, 5.5, inner)
        }
        ctx.rect(9 - w, 50, 82 + w * 2, 37, fur, radius: 15)
        ctx.strokePath(deep, width: 2.6) { p in
            p.move(to: pt(40, 52)); p.addQuadCurve(to: pt(60, 52), control: pt(50, 38))
        }
    }

    fileprivate static func starWand(_ ctx: GraphicsContext, _ a: PetAppearance) {
        let gold = rgb(0xF6C445), rim = rgb(0xE79A3A)
        ctx.strokePath(rgb(0xB79BEA), width: 2.6) { p in
            p.move(to: pt(60.5, 83)); p.addLine(to: pt(79, 55))
        }
        ctx.strokePath(Color.white.opacity(0.5), width: 0.8) { p in
            p.move(to: pt(61.5, 81)); p.addLine(to: pt(78.5, 55.5))
        }
        ctx.rotated(12, around: pt(81.5, 49)) { c in
            soft(c, starPoints(81.5, 49, 9, 4.3), rim, 2.2)
            soft(c, starPoints(81.5, 49, 7.8, 3.7), gold, 1.4)
            c.circle(79, 46.5, 1.2, Color.white.opacity(0.85))
        }
        ctx.strokePath(rgb(0xF4A6BD), width: 1.2) { p in
            p.move(to: pt(77.5, 58)); p.addQuadCurve(to: pt(72, 66), control: pt(78, 63))
            p.move(to: pt(77.5, 58)); p.addQuadCurve(to: pt(83, 66), control: pt(82, 60))
        }
        sparkle(ctx, 92, 40, 5, gold)
        sparkle(ctx, 70, 41, 4, rgb(0xB79BEA))
        pawGrip(ctx, a, 58.5, 80.3)
    }

    fileprivate static func turtleShell(_ ctx: GraphicsContext, _ w: CGFloat, front: Bool) {
        let shell = rgb(0x8CC07A), deep = rgb(0x6C9F5E), rim = rgb(0xE9D79A), strap = rgb(0xE0C27A)
        if front {
            for flip in [false, true] {
                let c = mirrored(ctx, flip)
                c.strokePath(strap, width: 3) { p in
                    p.move(to: pt(21 - w, 57)); p.addQuadCurve(to: pt(33, 82), control: pt(24 - w, 74))
                }
            }
            return
        }
        let r = CGRect(x: 5 - w, y: 37, width: 90 + w * 2, height: 56)
        ctx.fill(Path(ellipseIn: r), with: .color(rim))
        let inner = Path(ellipseIn: r.insetBy(dx: 3, dy: 2.6))
        ctx.fill(inner, with: .color(shell))
        var c = ctx
        c.clip(to: inner)
        c.strokePath(deep, width: 1.3) { p in
            let s: CGFloat = 9
            for row in 0..<8 {
                for col in -1..<8 {
                    let cx = CGFloat(col) * s * 1.5 + 2 + (row % 2 == 0 ? 0 : s * 0.75)
                    let cy = 36 + CGFloat(row) * s * 0.85
                    var pts: [CGPoint] = []
                    for k in 0..<6 {
                        let ang = Double(k) * Double.pi / 3
                        pts.append(pt(cx + s * 0.62 * CGFloat(cos(ang)), cy + s * 0.5 * CGFloat(sin(ang))))
                    }
                    p.addLines(pts)
                    p.closeSubpath()
                }
            }
        }
        ctx.ellipse(12 - w, 46, 10, 5, Color.white.opacity(0.3))
    }

    fileprivate static func butterflyWings(_ ctx: GraphicsContext, _ w: CGFloat) {
        let upper = rgb(0xF8B97C), lower = rgb(0xC9B2EE), edge = rgb(0x8A6AB8)
        let dots: [(CGFloat, CGFloat)] = [(-4.5, 43), (-2.5, 37), (3, 33), (9, 31.5), (-4, 49)]
        for flip in [false, true] {
            var c = mirrored(ctx, flip)
            c.translateBy(x: -w, y: 0)
            c.rotated(-38, around: pt(30, 50)) { r in
                r.ellipse(-8, 29, 40, 29, edge)
                r.ellipse(-6, 31, 36.5, 25.5, upper)
                r.ellipse(1, 37, 15, 11, rgb(0xFCD9B4))
                for (x, y) in dots { r.circle(x, y, 1.3, .white) }
            }
            c.rotated(30, around: pt(30, 62)) { r in
                r.ellipse(0, 55, 30, 21, edge)
                r.ellipse(2, 57, 26.5, 17.5, lower)
                r.circle(10, 65.5, 3.4, rgb(0xE6DAF8))
                r.circle(3.5, 70, 1.1, .white)
                r.circle(3.5, 61, 1.1, .white)
            }
        }
    }

    fileprivate static func leafCape(_ ctx: GraphicsContext, _ w: CGFloat, front: Bool) {
        if front {
            ctx.strokePath(rgb(0x8A6A4A), width: 1.6) { p in
                p.move(to: pt(28, 60.5)); p.addQuadCurve(to: pt(47, 63.5), control: pt(38, 64))
                p.move(to: pt(72, 60.5)); p.addQuadCurve(to: pt(53, 63.5), control: pt(62, 64))
            }
            ctx.rotated(-30, around: pt(50, 63.5)) { c in c.ellipse(47, 60.5, 6, 6.5, rgb(0x8CC77A)) }
            ctx.circle(50, 63.5, 1.6, rgb(0xC98F5E))
            return
        }
        let greens = [rgb(0x6FAF72), rgb(0x8CC77A), rgb(0x9FD38A), rgb(0x7DBB6C)]
        let root = pt(50, 56)
        let fan: [(Double, CGFloat)] = [(78, 40), (58, 42), (36, 42), (-36, 42), (-58, 42), (-78, 40), (16, 40), (-16, 40)]
        for (i, f) in fan.enumerated() {
            let spread = f.0 * Double(1 + w / 40)
            ctx.rotated(spread, around: root) { c in
                c.ellipse(root.x - 8.5, root.y + 2, 17, f.1, greens[i % greens.count])
                c.strokePath(rgb(0x5E9F55), width: 0.8) { p in
                    p.move(to: pt(root.x, root.y + 4)); p.addLine(to: pt(root.x, root.y + f.1 - 2))
                    for k in 1..<4 {
                        let y = root.y + 4 + CGFloat(k) * f.1 / 4.5
                        p.move(to: pt(root.x, y)); p.addLine(to: pt(root.x - 4.5, y + 3))
                        p.move(to: pt(root.x, y)); p.addLine(to: pt(root.x + 4.5, y + 3))
                    }
                }
            }
        }
    }

    fileprivate static func petalWings(_ ctx: GraphicsContext, _ w: CGFloat) {
        let inner = rgb(0xFDE3EC), outer = rgb(0xF29BB7)
        for flip in [false, true] {
            var c = mirrored(ctx, flip)
            c.translateBy(x: -w, y: 0)
            let root = pt(30, 55)
            petal(c, root: root, deg: -12, length: 23, width: 9, inner: inner, outer: rgb(0xE6A4E0))
            petal(c, root: root, deg: 42, length: 32, width: 11.5, inner: inner, outer: outer)
            petal(c, root: root, deg: 14, length: 30, width: 11, inner: inner, outer: outer)
        }
        sparkle(ctx, 7 - w, 22, 6, rgb(0xF0C26A))
        sparkle(ctx, 94 + w, 26, 5, rgb(0xF0C26A))
        ctx.rotated(30, around: pt(10, 80)) { c in c.ellipse(8.4, 77.6, 3.2, 4.8, rgb(0xF7B6CB)) }
    }

    fileprivate static func parrot(_ ctx: GraphicsContext, _ w: CGFloat, front: Bool) {
        let red = rgb(0xEF6B6B), redDeep = rgb(0xD5555F), blue = rgb(0x6FA3D9), yellow = rgb(0xF6D36B)
        var c = ctx
        c.translateBy(x: w, y: 0)
        if !front {
            // Đuôi dài buông sau lưng.
            c.rotated(-14, around: pt(83, 52)) { r in
                r.rect(80.5, 50, 4.4, 24, blue, radius: 2.2)
                r.rect(84.4, 50, 3.6, 20, yellow, radius: 1.8)
                r.rect(77.5, 50, 3.6, 19, redDeep, radius: 1.8)
            }
            return
        }
        c.ellipse(76, 36, 15, 20, red)
        c.circle(84, 31.5, 7, red)
        c.ellipse(77.5, 41, 9, 14, blue)
        c.ellipse(78.5, 46, 6.5, 9, rgb(0x6FC2A8))
        c.ellipse(80.5, 41.5, 4, 5, yellow.opacity(0.9))
        var beak = Path()
        beak.move(to: pt(89.5, 28.5))
        beak.addQuadCurve(to: pt(92.5, 36.5), control: pt(95, 30))
        beak.addQuadCurve(to: pt(89.5, 34), control: pt(90, 36))
        beak.closeSubpath()
        c.fill(beak, with: .color(rgb(0xF6C445)))
        c.circle(86, 30.5, 2.4, .white)
        c.circle(86.4, 30.6, 1.3, rgb(0x2E2A36))
        c.circle(86, 30.1, 0.4, .white)
        c.ellipse(85, 34, 3, 1.6, rgb(0xF6A9BE).opacity(0.9))
        c.strokePath(rgb(0x7A7486), width: 1.4) { p in
            p.move(to: pt(80, 54.5)); p.addLine(to: pt(80, 57.5))
            p.move(to: pt(85, 54.5)); p.addLine(to: pt(85, 57.5))
        }
    }

    fileprivate static func starCape(_ ctx: GraphicsContext, _ w: CGFloat, front: Bool) {
        let gold = rgb(0xF2C462)
        if front {
            ctx.strokePath(gold, width: 0.9) { p in
                p.move(to: pt(30, 61)); p.addQuadCurve(to: pt(46.5, 64), control: pt(38, 64.5))
                p.move(to: pt(70, 61)); p.addQuadCurve(to: pt(53.5, 64), control: pt(62, 64.5))
            }
            star(ctx, 50, 64, 3.8, gold)
            ctx.circle(50, 64, 1, rgb(0xFFF2C2))
            return
        }
        let night = Gradient(colors: [rgb(0x3A3A86), rgb(0x6C5BC4), rgb(0x9C7FD8)])
        let span = 92 + 2 * w
        var cape = Path()
        cape.move(to: pt(24 - w, 56))
        cape.addLine(to: pt(76 + w, 56))
        cape.addQuadCurve(to: pt(96 + w, 93), control: pt(92 + w, 70))
        for i in 0..<5 {
            let x0 = 96 + w - CGFloat(i) * span / 5
            let x1 = x0 - span / 5
            cape.addQuadCurve(to: pt(x1, 93), control: pt((x0 + x1) / 2, 98))
        }
        cape.addQuadCurve(to: pt(24 - w, 56), control: pt(8 - w, 70))
        cape.closeSubpath()
        ctx.fill(cape, with: .linearGradient(night, startPoint: pt(50, 56), endPoint: pt(50, 96)))
        // Cổ áo dựng cao sau đầu.
        for flip in [false, true] {
            var c = mirrored(ctx, flip)
            c.translateBy(x: -w, y: 0)
            soft(c, [pt(34, 60), pt(14, 34), pt(23, 38), pt(22, 30), pt(31, 41), pt(40, 58)], rgb(0x4A3F9A), 1.6)
            soft(c, [pt(33.5, 57), pt(18.5, 37.5), pt(24.5, 40.5), pt(24.5, 34.5), pt(31, 43.5), pt(37.5, 56)], rgb(0x8A74E0), 1)
        }
        var dots = ctx
        dots.clip(to: cape)
        let stars: [(CGFloat, CGFloat, CGFloat)] = [(12, 78, 2.2), (88, 74, 2.4), (8, 90, 1.6), (93, 88, 1.8), (20, 66, 1.4),
                                                    (82, 64, 1.5), (30, 92, 1.6), (70, 92, 1.8)]
        for (x, y, r) in stars { star(dots, x + (x < 50 ? -w : w), y, r, Color.white.opacity(0.9)) }
        let specks: [(CGFloat, CGFloat)] = [(16, 86), (86, 82), (13, 70), (90, 68), (24, 88), (77, 90)]
        for (x, y) in specks { dots.circle(x + (x < 50 ? -w : w), y, 0.6, rgb(0xFFF2C2)) }
    }

    fileprivate static func dragonWings(_ ctx: GraphicsContext, _ w: CGFloat) {
        let membrane = Gradient(colors: [rgb(0x9FDCCB), rgb(0xC5B6EE)])
        let bone = rgb(0x6FB8A6), cloud = rgb(0xFFFFFF), cloudShade = rgb(0xDCE6F2)
        let puffs: [(CGFloat, CGFloat, CGFloat)] = [(4, 46, 5.5), (11, 52, 5.5), (18.5, 57.5, 5), (25, 62, 4.4)]
        for flip in [false, true] {
            var c = mirrored(ctx, flip)
            c.translateBy(x: -w, y: 0)
            var wing = Path()
            wing.move(to: pt(29, 48))
            wing.addQuadCurve(to: pt(5, 17), control: pt(13, 26))
            wing.addQuadCurve(to: pt(1, 46), control: pt(-1, 31))
            wing.addLine(to: pt(26, 64))
            wing.closeSubpath()
            c.fill(wing, with: .linearGradient(membrane, startPoint: pt(28, 40), endPoint: pt(2, 30)))
            c.strokePath(bone, width: 1.6) { p in
                p.move(to: pt(29, 48)); p.addQuadCurve(to: pt(5, 17), control: pt(13, 26))
            }
            c.strokePath(bone, width: 0.9) { p in
                p.move(to: pt(14, 29)); p.addQuadCurve(to: pt(5, 44), control: pt(8, 36))
                p.move(to: pt(20, 37)); p.addQuadCurve(to: pt(14, 52), control: pt(15, 44))
            }
            c.circle(5, 16.5, 1.8, rgb(0xF2C462))
            // Mép cánh là các cụm mây.
            for (x, y, r) in puffs {
                c.circle(x + 0.6, y + 1, r, cloudShade)
                c.circle(x, y, r, cloud)
            }
            c.circle(8, 48, 1.3, Color.white)
        }
        sparkle(ctx, 50, 10, 4, rgb(0xF2C462))
    }
}
