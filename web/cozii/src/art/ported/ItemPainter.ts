// Chuyển tự động từ Swift (scripts/port/swift2ts.mjs) rồi sửa tay.
import { GC, Color, rgb, pt, R, Path, deg, Pt, Rect, linear, radial } from '../gc'
import { Palette } from '../palette'
import { StudyArt } from './StudyArt'
import { BedroomArt } from './BedroomArt'
import { KitchenArt } from './KitchenArt'
import { BathArt } from './BathArt'
import { GardenArt } from './GardenArt'

// Vẽ một món đồ theo ID: đồ thường trong 100×100, tường & sàn / bầu trời trong 125×100.
export function draw(id: string, ctx: GC) {
    if (StudyArt.draw(id, ctx) || BedroomArt.draw(id, ctx) || KitchenArt.draw(id, ctx)
        || BathArt.draw(id, ctx) || GardenArt.draw(id, ctx)) {
        return
    }
    const wood = Palette.wood
    const woodDark = Palette.woodDark
    switch (id) {
    // MARK: Bàn
    case "desk.pine": case "desk.lavender": case "desk.sage": { 
        const top = id == "desk.pine" ? wood : (id == "desk.lavender" ? Palette.lavender : Palette.sage)
        const leg = id == "desk.pine" ? woodDark : top.opacity(0.75)
        ctx.rect(8, 40, 84, 9, top, 3)
        ctx.rect(14, 49, 6, 42, leg, 2)
        ctx.rect(80, 49, 6, 42, leg, 2)
        if (id == "desk.sage") {
            ctx.rect(56, 50, 26, 18, top.opacity(0.85), 2)
            ctx.rect(66, 57, 6, 2.5, Color.white.opacity(0.8), 1)
        }
        if (id == "desk.lavender") {
            ctx.rect(26, 34, 18, 6, Palette.peach, 1.5) // sổ
            ctx.rect(28, 30, 14, 4, Palette.sage, 1.5)
        } else {
            ctx.rect(30, 33, 16, 7, Palette.lavenderSoft, 1.5)
        }
    // MARK: Ghế / thảm
    } break; case "seat.rug": { 
        ctx.ellipse(4, 70, 92, 24, Palette.catShade)
        ctx.ellipse(14, 74, 72, 16, Palette.catCream)
    } break; case "seat.cushion": { 
        ctx.ellipse(10, 66, 80, 28, Palette.lavender)
        ctx.ellipse(18, 66, 64, 18, Palette.lavenderSoft)
        ctx.ellipse(47, 72, 6, 6, Palette.lavender)
    } break; case "seat.armchair": { 
        ctx.rect(10, 34, 80, 44, Palette.peach, 14)
        ctx.rect(4, 50, 18, 34, Palette.peach.opacity(0.85), 8)
        ctx.rect(78, 50, 18, 34, Palette.peach.opacity(0.85), 8)
        ctx.rect(20, 58, 60, 18, Palette.catCream, 6)
        ctx.rect(14, 84, 5, 10, woodDark, 1)
        ctx.rect(81, 84, 5, 10, woodDark, 1)
    // MARK: Cây
    } break; case "plant.cactus": { 
        ctx.rect(32, 68, 36, 26, Palette.peach, 4)
        ctx.rect(42, 34, 16, 38, Palette.sage, 8)
        ctx.rect(28, 46, 10, 18, Palette.sage, 5)
        ctx.rect(62, 40, 10, 16, Palette.sage, 5)
        ctx.ellipse(47, 28, 6, 6, rgb(0xF4B0B0))
    } break; case "plant.monstera": { 
        ctx.rect(30, 70, 40, 24, Palette.catShade, 5)
        for (const [x, y, w, h] of ([[16.0, 30.0, 34.0, 26.0], [48.0, 22.0, 36.0, 28.0], [30.0, 46.0, 40.0, 26.0]] as const)) {
            ctx.ellipse(x, y, w, h, Palette.sage)
        }
        ctx.strokePath(Palette.sageSoft, 1.5, (p) => {
            p.move(pt(50, 70)); p.addLine(pt(34, 42))
            p.move(pt(50, 70)); p.addLine(pt(66, 36))
        })
    } break; case "plant.tulip": { 
        ctx.rect(30, 70, 40, 24, Palette.lavender, 5)
        for (const x of [36.0, 50.0, 64.0]) {
            ctx.rect(x - 1, 40, 2.5, 32, Palette.sage)
            ctx.ellipse(x - 6, 30, 12, 14, x == 50 ? Palette.peach : Palette.blush)
        }
    // MARK: Đèn
    } break; case "lamp.candle": { 
        ctx.rect(36, 56, 28, 38, Palette.catCream, 4)
        ctx.rect(49, 48, 2, 8, Palette.catInk)
        ctx.ellipse(44, 32, 12, 18, Palette.honey)
        ctx.ellipse(47, 38, 6, 10, Color.white.opacity(0.8))
    } break; case "lamp.desk": { 
        ctx.ellipse(28, 86, 44, 9, woodDark)
        ctx.strokePath(Palette.catInk, 3, (p) => {
            p.move(pt(50, 88)); p.addLine(pt(40, 52)); p.addLine(pt(58, 30))
        })
        ctx.polygon([pt(50, 18), pt(80, 36), pt(66, 46)], Palette.lavender)
        ctx.ellipse(66, 40, 10, 8, Palette.honey.opacity(0.9))
    } break; case "lamp.paper": { 
        ctx.rect(49, 30, 2, 64, woodDark)
        ctx.ellipse(40, 90, 20, 6, woodDark)
        ctx.ellipse(22, 6, 56, 50, Palette.catCream)
        ctx.ellipse(30, 14, 40, 34, Palette.honey.opacity(0.35))
    // MARK: Đồ treo tường
    } break; case "wall.clock": { 
        ctx.ellipse(20, 20, 60, 60, Palette.lavender)
        ctx.ellipse(26, 26, 48, 48, Palette.catCream)
        ctx.strokePath(Palette.catInk, 3, (p) => {
            p.move(pt(50, 50)); p.addLine(pt(50, 34))
            p.move(pt(50, 50)); p.addLine(pt(62, 56))
        })
    } break; case "wall.poster": { 
        ctx.rect(14, 18, 72, 60, woodDark, 3)
        ctx.rect(18, 22, 64, 52, Palette.lavenderSoft)
        ctx.polygon([pt(18, 74), pt(42, 44), pt(62, 74)], Palette.sage)
        ctx.polygon([pt(40, 74), pt(64, 50), pt(82, 74)], Palette.sage.opacity(0.7))
        ctx.ellipse(62, 28, 10, 10, Palette.honey)
    } break; case "wall.shelf": { 
        ctx.rect(8, 64, 84, 6, woodDark, 2)
        ctx.rect(16, 36, 9, 28, Palette.lavender, 1)
        ctx.rect(26, 40, 8, 24, Palette.peach, 1)
        ctx.rect(35, 34, 9, 30, Palette.sage, 1)
        ctx.rect(62, 50, 16, 14, Palette.catShade, 3)
        ctx.ellipse(60, 36, 20, 16, Palette.sage)
    } break; default: { 
        ctx.rect(20, 20, 60, 60, Palette.surfaceMuted, 8)
    } }
}

export const ItemPainter = { draw }
