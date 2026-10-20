import SwiftUI

/// Vẽ một món đồ theo ID: đồ thường trong 100×100, tường & sàn / bầu trời trong 125×100.
enum ItemPainter {
    static func isScene(_ id: String) -> Bool { Catalog.item(id)?.slot.isTheme ?? false }

    static func draw(_ id: String, in ctx: GraphicsContext) {
        // Biến thể màu: vẽ lại món gốc qua bộ lọc xoay sắc độ.
        if let item = Catalog.item(id), let base = item.variantOf {
            var tinted = ctx
            tinted.addFilter(.hueRotation(.degrees(item.hue)))
            draw(base, in: tinted)
            return
        }
        if StudyArt.draw(id, in: ctx) || BedroomArt.draw(id, in: ctx) || KitchenArt.draw(id, in: ctx)
            || BathArt.draw(id, in: ctx) || GardenArt.draw(id, in: ctx) {
            return
        }
        let wood = Palette.wood
        let woodDark = Palette.woodDark
        switch id {
        // MARK: Bàn
        case "desk.pine", "desk.lavender", "desk.sage":
            let top: Color = id == "desk.pine" ? wood : (id == "desk.lavender" ? Palette.lavender : Palette.sage)
            let leg: Color = id == "desk.pine" ? woodDark : top.opacity(0.75)
            ctx.rect(8, 40, 84, 9, top, radius: 3)
            ctx.rect(14, 49, 6, 42, leg, radius: 2)
            ctx.rect(80, 49, 6, 42, leg, radius: 2)
            if id == "desk.sage" {
                ctx.rect(56, 50, 26, 18, top.opacity(0.85), radius: 2)
                ctx.rect(66, 57, 6, 2.5, Color.white.opacity(0.8), radius: 1)
            }
            if id == "desk.lavender" {
                ctx.rect(26, 34, 18, 6, Palette.peach, radius: 1.5) // sổ
                ctx.rect(28, 30, 14, 4, Palette.sage, radius: 1.5)
            } else {
                ctx.rect(30, 33, 16, 7, Palette.lavenderSoft, radius: 1.5)
            }
        // MARK: Ghế / thảm
        case "seat.rug":
            ctx.ellipse(4, 70, 92, 24, Palette.catShade)
            ctx.ellipse(14, 74, 72, 16, Palette.catCream)
        case "seat.cushion":
            ctx.ellipse(10, 66, 80, 28, Palette.lavender)
            ctx.ellipse(18, 66, 64, 18, Palette.lavenderSoft)
            ctx.ellipse(47, 72, 6, 6, Palette.lavender)
        case "seat.armchair":
            ctx.rect(10, 34, 80, 44, Palette.peach, radius: 14)
            ctx.rect(4, 50, 18, 34, Palette.peach.opacity(0.85), radius: 8)
            ctx.rect(78, 50, 18, 34, Palette.peach.opacity(0.85), radius: 8)
            ctx.rect(20, 58, 60, 18, Palette.catCream, radius: 6)
            ctx.rect(14, 84, 5, 10, woodDark, radius: 1)
            ctx.rect(81, 84, 5, 10, woodDark, radius: 1)
        // MARK: Cây
        case "plant.cactus":
            ctx.rect(32, 68, 36, 26, Palette.peach, radius: 4)
            ctx.rect(42, 34, 16, 38, Palette.sage, radius: 8)
            ctx.rect(28, 46, 10, 18, Palette.sage, radius: 5)
            ctx.rect(62, 40, 10, 16, Palette.sage, radius: 5)
            ctx.ellipse(47, 28, 6, 6, Color.dynamic(light: 0xF4B0B0, dark: 0xF4B0B0))
        case "plant.monstera":
            ctx.rect(30, 70, 40, 24, Palette.catShade, radius: 5)
            for (x, y, w, h) in [(16.0, 30.0, 34.0, 26.0), (48.0, 22.0, 36.0, 28.0), (30.0, 46.0, 40.0, 26.0)] {
                ctx.ellipse(x, y, w, h, Palette.sage)
            }
            ctx.strokePath(Palette.sageSoft, width: 1.5) { p in
                p.move(to: CGPoint(x: 50, y: 70)); p.addLine(to: CGPoint(x: 34, y: 42))
                p.move(to: CGPoint(x: 50, y: 70)); p.addLine(to: CGPoint(x: 66, y: 36))
            }
        case "plant.tulip":
            ctx.rect(30, 70, 40, 24, Palette.lavender, radius: 5)
            for x in [36.0, 50.0, 64.0] {
                ctx.rect(x - 1, 40, 2.5, 32, Palette.sage)
                ctx.ellipse(x - 6, 30, 12, 14, x == 50 ? Palette.peach : Palette.blush)
            }
        // MARK: Đèn
        case "lamp.candle":
            ctx.rect(36, 56, 28, 38, Palette.catCream, radius: 4)
            ctx.rect(49, 48, 2, 8, Palette.catInk)
            ctx.ellipse(44, 32, 12, 18, Palette.honey)
            ctx.ellipse(47, 38, 6, 10, Color.white.opacity(0.8))
        case "lamp.desk":
            ctx.ellipse(28, 86, 44, 9, woodDark)
            ctx.strokePath(Palette.catInk, width: 3) { p in
                p.move(to: CGPoint(x: 50, y: 88)); p.addLine(to: CGPoint(x: 40, y: 52)); p.addLine(to: CGPoint(x: 58, y: 30))
            }
            ctx.polygon([CGPoint(x: 50, y: 18), CGPoint(x: 80, y: 36), CGPoint(x: 66, y: 46)], Palette.lavender)
            ctx.ellipse(66, 40, 10, 8, Palette.honey.opacity(0.9))
        case "lamp.paper":
            ctx.rect(49, 30, 2, 64, woodDark)
            ctx.ellipse(40, 90, 20, 6, woodDark)
            ctx.ellipse(22, 6, 56, 50, Palette.catCream)
            ctx.ellipse(30, 14, 40, 34, Palette.honey.opacity(0.35))
        // MARK: Đồ treo tường
        case "wall.clock":
            ctx.ellipse(20, 20, 60, 60, Palette.lavender)
            ctx.ellipse(26, 26, 48, 48, Palette.catCream)
            ctx.strokePath(Palette.catInk, width: 3) { p in
                p.move(to: CGPoint(x: 50, y: 50)); p.addLine(to: CGPoint(x: 50, y: 34))
                p.move(to: CGPoint(x: 50, y: 50)); p.addLine(to: CGPoint(x: 62, y: 56))
            }
        case "wall.poster":
            ctx.rect(14, 18, 72, 60, woodDark, radius: 3)
            ctx.rect(18, 22, 64, 52, Palette.lavenderSoft)
            ctx.polygon([CGPoint(x: 18, y: 74), CGPoint(x: 42, y: 44), CGPoint(x: 62, y: 74)], Palette.sage)
            ctx.polygon([CGPoint(x: 40, y: 74), CGPoint(x: 64, y: 50), CGPoint(x: 82, y: 74)], Palette.sage.opacity(0.7))
            ctx.ellipse(62, 28, 10, 10, Palette.honey)
        case "wall.shelf":
            ctx.rect(8, 64, 84, 6, woodDark, radius: 2)
            ctx.rect(16, 36, 9, 28, Palette.lavender, radius: 1)
            ctx.rect(26, 40, 8, 24, Palette.peach, radius: 1)
            ctx.rect(35, 34, 9, 30, Palette.sage, radius: 1)
            ctx.rect(62, 50, 16, 14, Palette.catShade, radius: 3)
            ctx.ellipse(60, 36, 20, 16, Palette.sage)
        default:
            ctx.rect(20, 20, 60, 60, Palette.surfaceMuted, radius: 8)
        }
    }
}
