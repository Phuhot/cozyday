import SwiftUI

/// Phim mở viên nang, vẽ toàn màn hình bằng Canvas. Dựng 2.5D: căn phòng đêm có nhiều lớp chiều sâu
/// (tường xa, phòng, tiền cảnh mờ), máy quay có vị trí/độ phóng/độ nghiêng/rung, ánh sáng đèn và ánh sáng theo độ hiếm.
/// Không có mô hình 3D. Tọa độ thế giới: rộng 400, sàn bắt đầu ở y = 470, càng xuống dưới càng gần máy quay.
/// Thời gian và cảnh quay lấy từ `GachaStoryboard` (phần lõi, có kiểm thử).
enum GachaFilmPainter {
    struct Camera {
        var x: CGFloat, y: CGFloat, zoom: CGFloat, roll: Double = 0
        static func mix(_ a: Camera, _ b: Camera, _ k: Double) -> Camera {
            let f = CGFloat(k)
            return Camera(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f, zoom: a.zoom + (b.zoom - a.zoom) * f,
                          roll: a.roll + (b.roll - a.roll) * k)
        }
    }

    /// Mọi thứ thay đổi theo thời gian trong một khung hình.
    struct Frame {
        var cam = Camera(x: 200, y: 440, zoom: 1)
        var shake: CGFloat = 0
        var black: Double = 0          // màn đen lúc mở đầu
        var cream: Double = 0          // chuyển sang màn nhận món
        var lamp: Double = 1           // đèn phòng 0…1
        var dark: Double = 0           // phòng tối dần khi viên nang rỉ sáng
        var flash: Double = 0
        var petX: CGFloat = 300, petGround: CGFloat = 575, petScale: CGFloat = 1.55
        var squashX: CGFloat = 1, squashY: CGFloat = 1
        var pose = PetPose()
        var mood: PetMood = .idle
        var spin: Double = -1          // núm máy: < 0 đứng yên
        var domeGlow: Double = 0
        var capsule: CGPoint?          // điểm chạm sàn của viên nang
        var capsuleLift: CGFloat = 0
        var capsuleRadius: CGFloat = 14
        var capsuleRoll: Double = 0
        var wobble: Double = 0
        var leak: Double = 0           // ánh sáng rỉ qua khe 0…1
        var gold: Double = 0           // Bí mật: viên đổi sang vàng
        var opened: Double = -1        // < 0 chưa mở; 0…1 nắp bay
        var burst: Double = -1         // pha bùng sáng sau khi mở
        var orb: Double = 0
        var confetti: Double = -1
    }

    // MARK: Vẽ

    static func draw(_ base: GraphicsContext, size: CGSize, time t: Double, cut: GachaStoryboard.Cut,
                     pet: PetAppearance, tier: ItemRarity, still: Bool) {
        let f = frame(at: t, cut: cut, tier: tier, still: still)
        let tierColor = color(tier, gold: f.gold)
        var cam = f.cam
        if f.shake > 0 {
            cam.x += f.shake * CGFloat(sin(t * 91))
            cam.y += f.shake * CGFloat(cos(t * 77))
        }
        base.fill(Path(CGRect(origin: .zero, size: size)), with: .color(rgb(0x241D36)))

        // Lớp xa: tường, cửa sổ, dây đèn (đi theo máy quay ít hơn).
        let wall = layer(base, size: size, cam: cam, depth: 0.82)
        drawWall(wall, t: t, lamp: f.lamp)

        // Lớp phòng: sàn, đèn, máy, viên nang, thú cưng.
        let room = layer(base, size: size, cam: cam, depth: 1)
        drawFloor(room, lamp: f.lamp)
        drawLamp(room, lamp: f.lamp)
        drawMachine(room, f: f, t: t)
        if let p = f.capsule { drawCapsuleShadow(room, at: p, f: f) }
        let capsuleInFront = (f.capsule?.y ?? 0) > f.petGround + 4
        if !capsuleInFront { drawCapsule(room, f: f, t: t, tier: tier, tierColor: tierColor, still: still) }
        drawPet(room, f: f, pet: pet)
        if capsuleInFront { drawCapsule(room, f: f, t: t, tier: tier, tierColor: tierColor, still: still) }

        // Tiền cảnh gần máy quay: lá cây và gối, làm mờ như ống kính lấy nét vào giữa.
        var front = layer(base, size: size, cam: cam, depth: 1.3)
        front.addFilter(.blur(radius: 5))
        drawForeground(front)

        // Ánh sáng màn hình: tối viền, tối phòng, chớp sáng, confetti, chuyển cảnh.
        drawGrade(base, size: size, f: f, tierColor: tierColor)
        drawLeak(room, f: f, t: t, tierColor: tierColor)
        drawBurst(room, f: f, t: t, tier: tier, tierColor: tierColor)
        if f.confetti >= 0 { drawConfetti(base, size: size, k: f.confetti, tier: tier, tierColor: tierColor) }
        drawLetterbox(base, size: size)
        if f.flash > 0 { base.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color.white.opacity(f.flash))) }
        if f.black > 0 { base.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color.black.opacity(f.black))) }
        if f.cream > 0 { base.fill(Path(CGRect(origin: .zero, size: size)), with: .color(rgb(0xFFF8EF).opacity(f.cream))) }
    }

    /// Hệ tọa độ thế giới nhìn qua máy quay. `depth` < 1 trôi chậm hơn (xa), > 1 trôi nhanh hơn (gần).
    private static func layer(_ base: GraphicsContext, size: CGSize, cam: Camera, depth: CGFloat) -> GraphicsContext {
        var c = base
        let zoom = 1 + (cam.zoom - 1) * depth
        let cx = 200 + (cam.x - 200) * depth, cy = 440 + (cam.y - 440) * depth
        c.translateBy(x: size.width / 2, y: size.height / 2)
        c.rotate(by: .degrees(cam.roll * Double(depth)))
        let k = size.width / 400 * zoom
        c.scaleBy(x: k, y: k)
        c.translateBy(x: -cx, y: -cy)
        return c
    }

    private static func drawWall(_ c: GraphicsContext, t: Double, lamp: Double) {
        c.fill(Path(CGRect(x: -500, y: -700, width: 1400, height: 1180)),
               with: .linearGradient(Gradient(colors: [rgb(0x2B2342), rgb(0x4A3D63), rgb(0x5B4A70)]),
                                     startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: 470)))
        // Họa tiết giấy dán tường: chấm nhỏ so le.
        for row in 0..<14 {
            for col in -6..<16 {
                let x = CGFloat(col) * 34 + (row % 2 == 0 ? 0 : 17), y = CGFloat(row) * 34 - 20
                c.circle(x, y, 1.6, rgb(0xC9B6E4).opacity(0.10))
            }
        }
        // Cửa sổ đêm: trăng, sao, rèm.
        c.rect(248, 118, 124, 168, rgb(0xF2DEC8), radius: 12)
        var glass = c
        glass.clip(to: Path(roundedRect: CGRect(x: 256, y: 126, width: 108, height: 152), cornerRadius: 8))
        glass.fill(Path(CGRect(x: 256, y: 126, width: 108, height: 152)),
                   with: .linearGradient(Gradient(colors: [rgb(0x1C2A55), rgb(0x34508A)]),
                                         startPoint: CGPoint(x: 0, y: 126), endPoint: CGPoint(x: 0, y: 278)))
        glass.fill(Path(ellipseIn: CGRect(x: 296, y: 132, width: 70, height: 70)),
                   with: .radialGradient(Gradient(colors: [rgb(0xFFF1C2).opacity(0.55), rgb(0xFFF1C2).opacity(0)]),
                                         center: CGPoint(x: 331, y: 167), startRadius: 0, endRadius: 35))
        glass.circle(331, 167, 13, rgb(0xFFF3CF))
        glass.circle(337, 162, 11, rgb(0x223260))
        for i in 0..<9 {
            let x = 262 + CGFloat((i * 37) % 96), y = 140 + CGFloat((i * 53) % 120)
            let tw = 0.5 + 0.5 * sin(t * 3 + Double(i) * 1.7)
            GachaMachineArt.star(glass, center: CGPoint(x: x, y: y), r: 2 + CGFloat(tw), color: rgb(0xFFF6D8).opacity(0.5 + tw * 0.5))
        }
        c.rect(307, 126, 6, 152, rgb(0xF2DEC8))
        c.rect(256, 199, 108, 6, rgb(0xF2DEC8))
        c.rect(236, 108, 20, 196, rgb(0xC97F9B), radius: 8)
        c.rect(364, 108, 20, 196, rgb(0xC97F9B), radius: 8)
        c.rect(230, 102, 160, 9, rgb(0x8E6A86), radius: 4)
        // Kệ treo với chậu cây và sách.
        c.rect(26, 236, 104, 7, rgb(0x8E6A86), radius: 3)
        c.rect(36, 206, 9, 30, rgb(0xE9A9A0), radius: 2)
        c.rect(46, 210, 8, 26, rgb(0x9CC5C9), radius: 2)
        c.rect(55, 203, 10, 33, rgb(0xF3D08A), radius: 2)
        c.rect(96, 216, 20, 20, rgb(0xD8A273), radius: 4)
        c.ellipse(90, 190, 32, 30, rgb(0x7FAF8D))
        c.ellipse(100, 182, 18, 18, rgb(0x96C2A0))
        // Dây đèn nhỏ chạy ngang tường, nhấp nháy chậm.
        var string = Path()
        string.move(to: CGPoint(x: -60, y: 54))
        string.addQuadCurve(to: CGPoint(x: 460, y: 54), control: CGPoint(x: 200, y: 120))
        c.stroke(string, with: .color(rgb(0x1F182E).opacity(0.7)), lineWidth: 1.5)
        let bulbs: [UInt32] = [0xFFD27F, 0xF4A6B8, 0xA9D3F5, 0xC7B4F0]
        for i in 0..<14 {
            let u = CGFloat(i) / 13
            let x = -60 + 520 * u
            let y = (1 - u) * (1 - u) * 54 + 2 * (1 - u) * u * 120 + u * u * 54 + 6
            let on = lamp * (0.65 + 0.35 * sin(t * 2.2 + Double(i)))
            let col = rgb(bulbs[i % bulbs.count])
            c.fill(Path(ellipseIn: CGRect(x: x - 14, y: y - 14, width: 28, height: 28)),
                   with: .radialGradient(Gradient(colors: [col.opacity(0.45 * on), col.opacity(0)]),
                                         center: CGPoint(x: x, y: y), startRadius: 0, endRadius: 14))
            c.ellipse(x - 3, y - 4, 6, 8, col.opacity(0.4 + 0.6 * on))
        }
    }

    private static func drawFloor(_ c: GraphicsContext, lamp: Double) {
        c.rect(-500, 462, 1400, 10, rgb(0x2F2740))
        c.fill(Path(CGRect(x: -500, y: 470, width: 1400, height: 900)),
               with: .linearGradient(Gradient(colors: [rgb(0x6E4A3E), rgb(0x9C6C55), rgb(0xB98468)]),
                                     startPoint: CGPoint(x: 0, y: 470), endPoint: CGPoint(x: 0, y: 900)))
        // Ván sàn hội tụ về điểm tụ phía sau giữa phòng.
        let vanish = CGPoint(x: 200, y: 250)
        for i in -10...20 {
            let x0 = CGFloat(i) * 40
            let k = (470 - vanish.y) / (1100 - vanish.y)
            let top = CGPoint(x: vanish.x + (x0 - vanish.x) * k, y: 470)
            c.strokePath(rgb(0x5A3B31).opacity(0.35), width: 1) { p in p.move(to: top); p.addLine(to: CGPoint(x: x0, y: 1100)) }
        }
        for y: CGFloat in [492, 522, 562, 616, 690, 790] { c.rect(-500, y, 1400, 1, rgb(0x5A3B31).opacity(0.25)) }
        // Thảm tròn dưới chân bạn nhỏ.
        c.ellipse(80, 590, 330, 110, rgb(0xD99AAE))
        c.ellipse(98, 597, 294, 96, rgb(0xEDB8C7))
        c.ellipse(130, 610, 230, 70, rgb(0xF5CDD8).opacity(0.7))
        // Vũng sáng của đèn sàn.
        c.fill(Path(ellipseIn: CGRect(x: 160, y: 480, width: 300, height: 190)),
               with: .radialGradient(Gradient(colors: [rgb(0xFFD9A0).opacity(0.28 * lamp), rgb(0xFFD9A0).opacity(0)]),
                                     center: CGPoint(x: 330, y: 560), startRadius: 0, endRadius: 160))
    }

    private static func drawLamp(_ c: GraphicsContext, lamp: Double) {
        c.ellipse(352, 538, 52, 10, Color.black.opacity(0.18))
        c.rect(375, 330, 5, 210, rgb(0x3A2F45), radius: 2)
        c.ellipse(358, 532, 40, 10, rgb(0x3A2F45))
        // Chao đèn.
        c.polygon([CGPoint(x: 352, y: 336), CGPoint(x: 403, y: 336), CGPoint(x: 392, y: 296), CGPoint(x: 363, y: 296)],
                  lamp > 0.3 ? rgb(0xFFE3B0) : rgb(0xC8B49A))
        var glow = c
        glow.blendMode = .screen
        glow.fill(Path(ellipseIn: CGRect(x: 268, y: 236, width: 220, height: 200)),
                  with: .radialGradient(Gradient(colors: [rgb(0xFFD28A).opacity(0.5 * lamp), rgb(0xFFD28A).opacity(0)]),
                                        center: CGPoint(x: 378, y: 330), startRadius: 0, endRadius: 110))
    }

    private static func drawMachine(_ c: GraphicsContext, f: Frame, t: Double) {
        // Đèn rọi từ trần xuống máy.
        var beam = c
        beam.blendMode = .screen
        beam.fill(Path { p in
            p.move(to: CGPoint(x: 120, y: -40)); p.addLine(to: CGPoint(x: 180, y: -40))
            p.addLine(to: CGPoint(x: 290, y: 525)); p.addLine(to: CGPoint(x: 10, y: 525)); p.closeSubpath()
        }, with: .linearGradient(Gradient(colors: [rgb(0xFFF1D6).opacity(0.0), rgb(0xFFF1D6).opacity(0.16 * f.lamp)]),
                                 startPoint: CGPoint(x: 0, y: -40), endPoint: CGPoint(x: 0, y: 525)))
        c.fill(Path(ellipseIn: CGRect(x: 0, y: 492, width: 300, height: 56)),
               with: .radialGradient(Gradient(colors: [rgb(0xFFF1D6).opacity(0.3 * f.lamp), rgb(0xFFF1D6).opacity(0)]),
                                     center: CGPoint(x: 150, y: 520), startRadius: 0, endRadius: 150))
        var m = c
        m.translateBy(x: 25, y: 195)
        if f.spin >= 0 && f.spin < 0.5 {
            // Máy nảy nhẹ khi núm được vỗ.
            let k = 1 - f.spin / 0.5
            m.translateBy(x: 125, y: 325)
            m.scaleBy(x: 1 + CGFloat(0.03 * k * sin(f.spin * 40)), y: 1 - CGFloat(0.03 * k * sin(f.spin * 40)))
            m.translateBy(x: -125, y: -325)
        }
        GachaMachineArt.draw(m, size: CGSize(width: 250, height: 325), spin: f.spin, dropsCapsule: false)
        if f.domeGlow > 0 {
            var g = c
            g.blendMode = .screen
            g.fill(Path(ellipseIn: CGRect(x: 40, y: 190, width: 220, height: 220)),
                   with: .radialGradient(Gradient(colors: [rgb(0xFFF6E0).opacity(0.55 * f.domeGlow), rgb(0xFFF6E0).opacity(0)]),
                                         center: CGPoint(x: 150, y: 300), startRadius: 0, endRadius: 110))
        }
    }

    private static func drawPet(_ c: GraphicsContext, f: Frame, pet: PetAppearance) {
        var p = c
        p.translateBy(x: f.petX - 50 * f.petScale, y: f.petGround - 88 * f.petScale)
        p.scaleBy(x: f.petScale, y: f.petScale)
        // Nén/giãn quanh bàn chân.
        p.translateBy(x: 50, y: 88)
        p.scaleBy(x: f.squashX, y: f.squashY)
        p.translateBy(x: -50, y: -88)
        PetPainter(mood: f.mood, appearance: pet, pose: f.pose).draw(in: p)
    }

    private static func drawCapsuleShadow(_ c: GraphicsContext, at p: CGPoint, f: Frame) {
        let r = f.capsuleRadius
        let k = max(0.35, 1 - f.capsuleLift / 120)
        c.ellipse(p.x - r * k, p.y - r * 0.18, 2 * r * k, r * 0.5 * k, Color.black.opacity(0.22 * Double(k)))
    }

    private static func drawCapsule(_ c: GraphicsContext, f: Frame, t: Double, tier: ItemRarity, tierColor: Color, still: Bool) {
        guard let ground = f.capsule else { return }
        let r = f.capsuleRadius
        let center = CGPoint(x: ground.x, y: ground.y - r - f.capsuleLift)
        let wob = still ? 0 : f.wobble * sin(t * 38) * 12
        let shellColor = mixColor(rgb(0xF2A3BC), rgb(0xFFCF5A), f.gold)

        if f.opened < 0 {
            c.rotated(f.capsuleRoll + wob, around: center) { k in
                capsuleBody(k, center: center, r: r, shell: shellColor)
                if f.leak > 0 {
                    // Khe sáng chạy dọc đường nối hai nửa.
                    k.strokePath(Color.white.opacity(0.9 * f.leak), width: 2.4) { p in
                        p.move(to: CGPoint(x: center.x - r * 0.95, y: center.y))
                        p.addLine(to: CGPoint(x: center.x + r * 0.95, y: center.y))
                    }
                    k.strokePath(tierColor.opacity(f.leak), width: 1.2) { p in
                        p.move(to: CGPoint(x: center.x - r * 0.95, y: center.y))
                        p.addLine(to: CGPoint(x: center.x + r * 0.95, y: center.y))
                    }
                }
            }
            if f.gold > 0 {
                for i in 0..<5 {
                    let a = t * 3 + Double(i) * 1.26
                    GachaMachineArt.star(c, center: CGPoint(x: center.x + CGFloat(cos(a)) * r * 1.5, y: center.y + CGFloat(sin(a)) * r * 0.9),
                                         r: 3, color: rgb(0xFFF2B0).opacity(f.gold))
                }
            }
        } else {
            // Nửa dưới nằm lại, nửa trên bay vút lên và xoay.
            let o = f.opened
            capsuleBottom(c, center: center, r: r)
            let fly = CGPoint(x: center.x - CGFloat(o * 70), y: center.y - CGFloat(o * 150 - o * o * 60))
            c.rotated(-o * 260, around: fly) { k in
                capsuleTop(k, center: fly, r: r, shell: shellColor)
            }
        }
    }

    /// Ánh sáng rỉ ra trước khi mở. Vẽ sau lớp làm tối phòng: viên nang là nguồn sáng.
    private static func drawLeak(_ c: GraphicsContext, f: Frame, t: Double, tierColor: Color) {
        guard let ground = f.capsule, f.leak > 0, f.opened < 0 else { return }
        let r = f.capsuleRadius
        let center = CGPoint(x: ground.x, y: ground.y - r - f.capsuleLift)
        // Ánh sáng rỉ ra trước khi mở.
        do {
            var g = c
            g.blendMode = .screen
            let rr = r * CGFloat(2.2 + 2.5 * f.leak)
            g.fill(Path(ellipseIn: CGRect(x: center.x - rr, y: center.y - rr, width: rr * 2, height: rr * 2)),
                   with: .radialGradient(Gradient(colors: [tierColor.opacity(0.55 * f.leak), tierColor.opacity(0)]),
                                         center: center, startRadius: 0, endRadius: rr))
            let rays = 7
            for i in 0..<rays {
                let a = Double(i) / Double(rays) * 2 * .pi + t * 0.8
                let len = r * CGFloat(1.6 + 2.6 * f.leak) * CGFloat(0.7 + 0.3 * sin(t * 6 + Double(i)))
                g.strokePath(tierColor.opacity(0.5 * f.leak), width: 2.2) { p in
                    p.move(to: CGPoint(x: center.x + CGFloat(cos(a)) * r * 0.9, y: center.y + CGFloat(sin(a)) * r * 0.3))
                    p.addLine(to: CGPoint(x: center.x + CGFloat(cos(a)) * (r + len), y: center.y + CGFloat(sin(a)) * (r * 0.3 + len * 0.6)))
                }
            }
        }

    }

    private static func capsuleBody(_ c: GraphicsContext, center: CGPoint, r: CGFloat, shell: Color) {
        capsuleBottom(c, center: center, r: r)
        capsuleTop(c, center: center, r: r, shell: shell)
    }

    private static func capsuleBottom(_ c: GraphicsContext, center: CGPoint, r: CGFloat) {
        let half = Path { p in
            p.addArc(center: center, radius: r, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
            p.closeSubpath()
        }
        c.fill(half, with: .linearGradient(Gradient(colors: [rgb(0xFFFDF8), rgb(0xE6DCD6)]),
                                           startPoint: CGPoint(x: center.x, y: center.y), endPoint: CGPoint(x: center.x, y: center.y + r)))
        c.stroke(half, with: .color(rgb(0xCDBFB8)), lineWidth: 1)
    }

    private static func capsuleTop(_ c: GraphicsContext, center: CGPoint, r: CGFloat, shell: Color) {
        let half = Path { p in
            p.addArc(center: center, radius: r, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
            p.closeSubpath()
        }
        c.fill(half, with: .radialGradient(Gradient(colors: [shell.opacity(0.75), shell]),
                                           center: CGPoint(x: center.x - r * 0.35, y: center.y - r * 0.55), startRadius: 0, endRadius: r * 1.2))
        c.rect(center.x - r, center.y - r * 0.12, r * 2, r * 0.16, shell.opacity(0.6))
        c.ellipse(center.x - r * 0.62, center.y - r * 0.78, r * 0.5, r * 0.3, Color.white.opacity(0.75))
        c.stroke(half, with: .color(shell.opacity(0.7)), lineWidth: 1)
    }

    private static func drawBurst(_ c: GraphicsContext, f: Frame, t: Double, tier: ItemRarity, tierColor: Color) {
        guard f.burst >= 0, let ground = f.capsule else { return }
        let center = CGPoint(x: ground.x, y: ground.y - f.capsuleRadius - f.capsuleLift - 6)
        let k = f.burst
        var g = c
        g.blendMode = .screen
        var soft = g
        soft.addFilter(.blur(radius: 14))
        // Cột sáng thẳng đứng, viền mềm.
        let w = CGFloat(18 + 26 * min(1, k * 3)) * (tier >= .epic ? 1.4 : 1)
        soft.fill(Path(CGRect(x: center.x - w, y: center.y - 700, width: w * 2, height: 700)),
               with: .linearGradient(Gradient(colors: [tierColor.opacity(0), tierColor.opacity(0.35), Color.white.opacity(0.55)]),
                                     startPoint: CGPoint(x: 0, y: center.y - 700), endPoint: CGPoint(x: 0, y: center.y)))
        // Tia sáng xoay chậm.
        let rays = tier == .secret ? 16 : tier == .epic ? 12 : tier == .rare ? 9 : 7
        let reach = CGFloat(90 + 160 * min(1, k * 2))
        for i in 0..<rays {
            let a = Double(i) / Double(rays) * 2 * .pi + t * 0.35
            let spread = 0.09
            g.fill(Path { p in
                p.move(to: center)
                p.addLine(to: CGPoint(x: center.x + CGFloat(cos(a - spread)) * reach, y: center.y + CGFloat(sin(a - spread)) * reach))
                p.addLine(to: CGPoint(x: center.x + CGFloat(cos(a + spread)) * reach, y: center.y + CGFloat(sin(a + spread)) * reach))
                p.closeSubpath()
            }, with: .radialGradient(Gradient(colors: [tierColor.opacity(0.55), tierColor.opacity(0)]),
                                     center: center, startRadius: 0, endRadius: reach))
        }
        // Quả cầu sáng: món quà đang chờ.
        let orbR: CGFloat = 20 + 6 * CGFloat(f.orb)
        let bob = CGFloat(sin(t * 3)) * 4 * CGFloat(f.orb)
        let oc = CGPoint(x: center.x, y: center.y - 46 * CGFloat(f.orb) + bob)
        g.fill(Path(ellipseIn: CGRect(x: oc.x - orbR * 2.2, y: oc.y - orbR * 2.2, width: orbR * 4.4, height: orbR * 4.4)),
               with: .radialGradient(Gradient(colors: [tierColor.opacity(0.8), tierColor.opacity(0)]),
                                     center: oc, startRadius: 0, endRadius: orbR * 2.2))
        c.fill(Path(ellipseIn: CGRect(x: oc.x - orbR, y: oc.y - orbR, width: orbR * 2, height: orbR * 2)),
               with: .radialGradient(Gradient(colors: [Color.white, Color.white, tierColor.opacity(0.9)]),
                                     center: CGPoint(x: oc.x - orbR * 0.3, y: oc.y - orbR * 0.3), startRadius: 0, endRadius: orbR * 1.3))
        // Sao bắn ra rồi rơi chậm.
        let count = tier == .secret ? 30 : tier == .epic ? 22 : tier == .rare ? 16 : 10
        for i in 0..<count {
            let a = Double(i) / Double(count) * 2 * .pi + Double(i % 3) * 0.3
            let speed = 80 + Double((i * 37) % 60)
            let d = speed * min(k, 1.6)
            let x = center.x + CGFloat(cos(a) * d)
            let y = center.y + CGFloat(sin(a) * d * 0.75 + 60 * k * k)
            let fade = max(0, 1 - k / 1.6)
            GachaMachineArt.star(c, center: CGPoint(x: x, y: y), r: CGFloat(tier >= .epic ? 4.5 : 3.5) * CGFloat(0.6 + fade * 0.4),
                                 color: (i % 3 == 0 ? Color.white : tierColor).opacity(fade))
        }
        // Vòng sóng lan ra lúc mở.
        if k < 0.6 {
            let rr = CGFloat(20 + k * 260)
            g.stroke(Path(ellipseIn: CGRect(x: center.x - rr, y: center.y - rr * 0.45, width: rr * 2, height: rr * 0.9)),
                     with: .color(tierColor.opacity(0.7 * (1 - k / 0.6))), lineWidth: 4)
        }
    }

    private static func drawForeground(_ c: GraphicsContext) {
        c.ellipse(-70, 770, 170, 120, rgb(0x3E5E4E))
        c.rotated(-30, around: CGPoint(x: 20, y: 790)) { k in k.ellipse(-10, 700, 70, 150, rgb(0x4F7A62)) }
        c.rotated(25, around: CGPoint(x: 60, y: 800)) { k in k.ellipse(40, 720, 55, 130, rgb(0x5C8A70)) }
        c.ellipse(330, 800, 170, 90, rgb(0x6B4F7A))
        c.ellipse(345, 790, 120, 50, rgb(0x82659A))
    }

    private static func drawGrade(_ c: GraphicsContext, size: CGSize, f: Frame, tierColor: Color) {
        let rect = CGRect(origin: .zero, size: size)
        if f.dark > 0 { c.fill(Path(rect), with: .color(rgb(0x120B22).opacity(f.dark))) }
        let center = CGPoint(x: size.width / 2, y: size.height * 0.52)
        c.fill(Path(rect), with: .radialGradient(Gradient(colors: [Color.black.opacity(0), Color.black.opacity(0), rgb(0x0E0818).opacity(0.62)]),
                                                 center: center, startRadius: 0, endRadius: max(size.width, size.height) * 0.62))
        if f.dark > 0 {
            // Viên nang thành nguồn sáng chính: phủ ánh màu độ hiếm lên phần giữa khung hình.
            var g = c
            g.blendMode = .screen
            g.fill(Path(rect), with: .radialGradient(Gradient(colors: [tierColor.opacity(0.22 * f.dark / 0.4), tierColor.opacity(0)]),
                                                     center: center, startRadius: 0, endRadius: size.width * 0.7))
        }
    }

    private static func drawConfetti(_ c: GraphicsContext, size: CGSize, k: Double, tier: ItemRarity, tierColor: Color) {
        let colors: [Color] = [tierColor, rgb(0xFFD27F), rgb(0xF4A6B8), rgb(0xA9D3F5), Color.white]
        let n = tier == .secret ? 60 : tier == .epic ? 46 : 32
        for i in 0..<n {
            let seed = Double((i * 7919) % 1000) / 1000
            let x = CGFloat(seed) * size.width + CGFloat(sin(k * 4 + Double(i))) * 14
            let y = -20 + CGFloat(k * (0.55 + seed * 0.6)) * size.height - CGFloat(i % 5) * 26
            guard y > -20 && y < size.height else { continue }
            c.rotated(k * 400 + Double(i * 40), around: CGPoint(x: x, y: y)) { r in
                r.rect(x - 4, y - 2, 8, 4.5, colors[i % colors.count], radius: 1)
            }
        }
    }

    private static func drawLetterbox(_ c: GraphicsContext, size: CGSize) {
        let h = size.height * 0.055
        c.rect(0, 0, size.width, h, Color.black.opacity(0.85))
        c.rect(0, size.height - h, size.width, h, Color.black.opacity(0.85))
    }

    // MARK: Kịch bản → khung hình

    static func frame(at time: Double, cut: GachaStoryboard.Cut, tier: ItemRarity, still: Bool) -> Frame {
        if still {
            // Giảm chuyển động: một khung tĩnh của cảnh vui mừng, chỉ mờ dần vào/ra.
            var f = scene(at: 7.95, tier: tier)
            f.shake = 0; f.pose.hop = 0; f.squashX = 1; f.squashY = 1; f.confetti = -1; f.flash = 0
            let d = GachaStoryboard.duration(.short) - 0.2
            f.cream = max(1 - min(time / 0.3, 1), max(0, (time - d + 0.3) / 0.3))
            return f
        }
        switch cut {
        case .full:
            return scene(at: time, tier: tier)
        case .short:
            // Bản ngắn: rung viên nang → bật nắp → mừng, dùng chung kịch bản với bản đầy đủ.
            let mapped = time < 0.9 ? 6.0 + time : 7.15 + (time - 0.9) * 1.5
            return scene(at: mapped, tier: tier)
        }
    }

    private static func scene(at t: Double, tier: ItemRarity) -> Frame {
        var f = Frame()
        f.pose.tail = CGFloat(sin(t * 5)) * 0.6
        f.pose.breath = CGFloat(sin(t * 2.4)) * 0.6
        let shot = GachaStoryboard.shot(at: t, cut: .full)
        let local = (t - shot.start) / (shot.end - shot.start)
        let restCapsule = CGPoint(x: 236, y: 646)

        switch shot.shot {
        case .establish:
            f.cam = .mix(Camera(x: 200, y: 440, zoom: 1.0), Camera(x: 212, y: 452, zoom: 1.12), smooth(local))
            f.black = 1 - seg(t, 0.05, 0.6)
            let flicker = t > 0.25 && t < 0.42 ? (Int(t * 30) % 2 == 0 ? 0.3 : 1) : 1
            f.lamp = seg(t, 0.2, 0.5) * flicker
            f.petX = 300; f.petGround = 575
            f.pose.look = -CGFloat(smooth(seg(t, 0.55, 0.8)))
            f.pose.ear = t > 0.8 && t < 0.95 ? 1 : 0
            f.pose.blink = t > 0.42 && t < 0.52
            if t > 1.05 {
                let k = seg(t, 1.05, 1.5)
                f.petX = 300 - 68 * CGFloat(smooth(k))
                f.pose.walk = CGFloat(t * 22)
                f.pose.hop = CGFloat(abs(sin(k * .pi * 2))) * 7
            }
        case .crank:
            f.cam = .mix(Camera(x: 188, y: 430, zoom: 1.8), Camera(x: 184, y: 424, zoom: 1.92), smooth(local))
            f.petX = 250; f.petGround = 575
            f.pose.look = -1
            if t < 1.75 {
                let k = seg(t, 1.5, 1.75)
                f.squashY = 1 - 0.14 * CGFloat(smooth(k)); f.squashX = 1 + 0.08 * CGFloat(smooth(k))
            } else if t < 2.15 {
                let k = seg(t, 1.75, 2.15)
                f.pose.hop = CGFloat(4 * k * (1 - k)) * 70
                f.squashY = k < 0.5 ? 1.1 : 1.02; f.squashX = k < 0.5 ? 0.93 : 0.99
                let bell = CGFloat(max(0, sin(seg(t, 1.8, 2.12) * .pi)))
                f.pawLiftReach(lift: 24 * bell, reach: 44 * bell)
                f.pose.tilt = -12 * Double(bell)
                f.pose.ear = bell
            } else {
                let k = seg(t, 2.15, 2.4)
                let land = CGFloat(sin(k * .pi))
                f.squashY = 1 - 0.13 * land; f.squashX = 1 + 0.09 * land
                f.pose.headTilt = -9 * smooth(seg(t, 2.3, 2.55))
                f.pose.look = -0.6
            }
            f.spin = t >= 1.95 ? t - 1.95 : -1
            f.domeGlow = seg(t, 2.2, 2.6) * (0.7 + 0.3 * sin(t * 20))
        case .drop:
            let k = seg(t, 2.85, 4.1)
            // Đường lăn trên sàn: từ máng máy ra trước, chậm dần.
            let ease = 1 - pow(1 - k, 2.2)
            let start = CGPoint(x: 132, y: 500)
            let ground = CGPoint(x: start.x + (restCapsule.x - start.x) * CGFloat(ease), y: start.y + (restCapsule.y - start.y) * CGFloat(ease))
            f.capsule = ground
            f.capsuleRadius = 11 + 6 * CGFloat(ease)
            f.capsuleLift = bounceHeight(t)
            f.capsuleRoll = ease * 420
            f.shake = impactShake(t)
            let follow = Camera(x: ground.x + 24, y: ground.y - 70, zoom: 2.0 - 0.35 * CGFloat(smooth(k)))
            f.cam = .mix(Camera(x: 150, y: 470, zoom: 2.05), follow, smooth(seg(t, 2.8, 3.25)))
            f.petX = 316; f.petGround = 640; f.petScale = 1.7
            f.pose.lifted = t > 3.0 && t < 3.9
            f.pose.hop = t > 3.0 && t < 3.25 ? CGFloat(sin(seg(t, 3.0, 3.25) * .pi)) * 10 : 0
            f.pose.tilt = 7 * smooth(seg(t, 3.0, 3.2)) * (1 - smooth(seg(t, 3.7, 4.1)))
            f.pose.look = max(-1, min(1, (ground.x - f.petX) / 60))
            f.pose.lookDown = CGFloat(smooth(seg(t, 3.85, 4.2)))
        case .curious:
            f.cam = .mix(Camera(x: 276, y: 592, zoom: 2.55), Camera(x: 272, y: 596, zoom: 2.75), smooth(local))
            f.capsule = restCapsule; f.capsuleRadius = 17; f.capsuleRoll = 420
            f.petX = 316; f.petGround = 640; f.petScale = 1.7
            f.pose.look = -0.8
            f.pose.lookDown = 1 - CGFloat(smooth(seg(t, 5.3, 5.55)))
            f.pose.tilt = -6 * smooth(seg(t, 4.2, 4.55)) * (1 - smooth(seg(t, 5.3, 5.5)))
            if t > 4.55 && t < 5.0 {
                f.squashY = 1 + 0.015 * CGFloat(sin(t * 32)); f.pose.ear = CGFloat(max(0, sin(t * 16)))
            }
            let poke = CGFloat(max(0, sin(seg(t, 5.0, 5.3) * .pi)))
            f.pawLiftReach(lift: 8 * poke, reach: 34 * poke)
            if t > 5.3 {
                f.pose.tilt = 5 * smooth(seg(t, 5.3, 5.5)) * (1 - smooth(seg(t, 5.7, 5.9)))
                f.pose.headTilt = 14 * smooth(seg(t, 5.32, 5.55)) * (1 - smooth(seg(t, 5.75, 5.95)))
                f.pose.look = -0.8 + 0.8 * CGFloat(smooth(seg(t, 5.3, 5.45)))
                f.pose.blink = t > 5.5 && t < 5.58
            }
            if t > 5.75 {
                f.pose.lifted = true
                f.pose.ear = 1
                f.pose.look = -0.7
            }
            let pokeWobble = t > 5.15 ? max(0, 1 - (t - 5.15) / 0.35) * 0.6 : 0
            let build = seg(t, 5.7, 6.2)
            f.wobble = pokeWobble + build * (tier >= .epic ? 1.0 : 0.7)
            f.leak = seg(t, 5.15, 6.2) * (0.35 + 0.65 * build)
            f.dark = 0.4 * smooth(seg(t, 5.6, 6.2))
            if tier == .secret { f.gold = smooth(seg(t, 5.85, 6.1)) }
        case .pop:
            let pre = seg(t, 6.2, 6.55)
            f.cam = .mix(Camera(x: 244, y: 618, zoom: 2.9), Camera(x: 240, y: 606, zoom: 3.45), pow(pre, 2))
            if t >= 6.55 {
                let after = seg(t, 6.55, 7.1)
                f.cam = .mix(Camera(x: 240, y: 600, zoom: 3.1), Camera(x: 240, y: 590, zoom: 2.6), smooth(after))
            }
            f.capsule = restCapsule; f.capsuleRadius = 17; f.capsuleRoll = 420
            f.capsuleLift = CGFloat(smooth(pre)) * (tier >= .epic ? 12 : 5)
            f.petX = 316; f.petGround = 640; f.petScale = 1.7
            f.pose.lifted = t < 6.6
            f.pose.ear = 1
            f.pose.look = -0.7
            f.wobble = t < 6.55 ? 1.2 : 0
            f.leak = t < 6.55 ? 1 : 0
            f.dark = 0.4 * (1 - smooth(seg(t, 6.6, 7.1)) * 0.5)
            if tier == .secret { f.gold = 1 }
            if t >= 6.55 {
                f.opened = seg(t, 6.55, 7.1)
                f.burst = t - 6.55
                f.orb = smooth(seg(t, 6.7, 7.1))
                f.flash = 0.9 * max(0, 1 - (t - 6.55) / 0.3)
                f.shake = CGFloat(max(0, 1 - (t - 6.55) / 0.35)) * 6
            }
        case .joy:
            let k = seg(t, 7.1, 8.8)
            f.cam = .mix(Camera(x: 280, y: 566, zoom: 1.68), Camera(x: 279, y: 562, zoom: 1.8), smooth(k))
            f.capsule = restCapsule; f.capsuleRadius = 17; f.capsuleLift = tier >= .epic ? 12 : 5
            f.opened = 1; f.burst = 0.55 + (t - 7.1) * 0.6; f.orb = 1
            if tier == .secret { f.gold = 1 }
            f.dark = 0.2 * (1 - k)
            f.petX = 316; f.petGround = 640; f.petScale = 1.7
            f.mood = .happy
            f.pose.tail = CGFloat(sin(t * 14))
            f.pose.look = -0.5
            let hops: [(Double, Double, CGFloat)] = [(7.2, 7.58, 24), (7.7, 8.05, 17), (8.15, 8.4, 8)]
            for (a, b, h) in hops where t >= a && t < b {
                let u = seg(t, a, b)
                f.pose.hop = CGFloat(4 * u * (1 - u)) * h
                f.squashY = u < 0.15 || u > 0.85 ? 0.9 : 1.06; f.squashX = u < 0.15 || u > 0.85 ? 1.07 : 0.96
                f.pose.tilt = (a == 7.7 ? 7 : -7) * sin(u * .pi)
            }
            f.pose.hearts = CGFloat(seg(t, 7.35, 8.6))
            f.confetti = t - 7.15
            f.cream = smooth(seg(t, 8.45, 8.8))
        }
        return f
    }

    /// Độ cao viên nang khi nảy: rơi khỏi máng rồi ba lần chạm sàn (3.15, 3.5, 3.8), lần sau thấp hơn.
    private static func bounceHeight(_ t: Double) -> CGFloat {
        let arcs: [(Double, Double, Double)] = [(2.85, 3.15, 60), (3.15, 3.5, 34), (3.5, 3.8, 14), (3.8, 4.0, 4)]
        for (a, b, h) in arcs where t >= a && t < b {
            let u = (t - a) / (b - a)
            if a == 2.85 { return CGFloat((1 - u * u) * h) }   // rơi từ máng: bắt đầu ở đỉnh
            return CGFloat(4 * u * (1 - u) * h)
        }
        return 0
    }

    private static func impactShake(_ t: Double) -> CGFloat {
        var s = 0.0
        for (hit, power) in [(3.15, 4.0), (3.5, 2.2), (3.8, 1.0)] where t >= hit {
            s += power * max(0, 1 - (t - hit) / 0.16)
        }
        return CGFloat(s)
    }

    // MARK: Tiện ích

    static func color(_ tier: ItemRarity, gold: Double) -> Color {
        let base: Color
        switch tier {
        case .common: base = rgb(0x9FD4A8)
        case .rare: base = rgb(0x8FB6F2)
        case .epic: base = rgb(0xC69BF5)
        case .secret: base = rgb(0xFFD27F)
        }
        return base
    }

    private static func mixColor(_ a: Color, _ b: Color, _ k: Double) -> Color { k <= 0 ? a : k >= 1 ? b : (k < 0.5 ? a : b) }

    private static func seg(_ t: Double, _ a: Double, _ b: Double) -> Double { min(max((t - a) / (b - a), 0), 1) }
    private static func smooth(_ x: Double) -> Double { x * x * (3 - 2 * x) }
}

private extension GachaFilmPainter.Frame {
    mutating func pawLiftReach(lift: CGFloat, reach: CGFloat) {
        pose.pawLift = lift
        pose.pawReach = reach
    }
}
