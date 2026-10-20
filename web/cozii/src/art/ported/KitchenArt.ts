// Chuyển tự động từ Swift (scripts/port/swift2ts.mjs) rồi sửa tay.
import { GC, Color, rgb, pt, R, Path, deg, Pt, Rect, linear, radial } from '../gc'
import { Palette } from '../palette'

// Hình vẽ đồ trong Kitchen. Trả về false nếu không phải ID của phòng này.
export function draw(id: string, ctx: GC): boolean {
    switch (id) {
    // MARK: Tường & sàn (125×100)
    case "kitchenTheme.mint": { themeMint(clipRoom(ctx))
    } break; case "kitchenTheme.gingham": { themeGingham(clipRoom(ctx))
    } break; case "kitchenTheme.lemon": { themeLemon(clipRoom(ctx))
    } break; case "kitchenTheme.wood": { themeWood(clipRoom(ctx))
    // MARK: Bếp
    } break; case "stove.basic": { stoveBasic(ctx)
    } break; case "stove.retro": { stoveRetro(ctx)
    } break; case "stove.oven": { stoveOven(ctx)
    } break; case "stove.hearth": { stoveHearth(ctx)
    // MARK: Tủ lạnh
    } break; case "fridge.mini": { fridgeMini(ctx)
    } break; case "fridge.retro": { fridgeRetro(ctx)
    } break; case "fridge.pink": { fridgePink(ctx)
    } break; case "fridge.magnets": { fridgeMagnets(ctx)
    // MARK: Bàn ăn
    } break; case "dining.stool": { diningStool(ctx)
    } break; case "dining.round": { diningRound(ctx)
    } break; case "dining.picnic": { diningPicnic(ctx)
    } break; case "dining.long": { diningLong(ctx)
    // MARK: Đồ treo tường
    } break; case "kitchenWall.clock": { wallClock(ctx)
    } break; case "kitchenWall.pans": { wallPans(ctx)
    } break; case "kitchenWall.fruit": { wallFruit(ctx)
    } break; case "kitchenWall.jars": { wallJars(ctx)
    // MARK: Món ăn trên bàn
    } break; case "treat.tea": { treatTea(ctx)
    } break; case "treat.bread": { treatBread(ctx)
    } break; case "treat.ramen": { treatRamen(ctx)
    } break; case "treat.pizza": { treatPizza(ctx)
    } break; case "treat.cake": { treatCake(ctx)
    } break; default: { return false
    } }
    return true
}

// MARK: - Màu chung

const ink = rgb(0x5A4E66)
const cream = rgb(0xFFF8EC)
const steel = rgb(0xD9DCE3)
const steelDark = rgb(0xB9BCC8)
const shadow = Color.black.opacity(0.1)
function sparkle(ctx: GC, x: number, y: number, size: number = 6, color: Color = Color.white.opacity(0.8)) {
    ctx.text("✦", size, color, pt(x, y))
}

function steam(ctx: GC, x: number, y: number, h: number, color: Color = Color.white.opacity(0.75), width: number = 2.5) {
    ctx.strokePath(color, width, (p) => {
        p.move(pt(x, y))
        p.addCurve(pt(x, y - h), pt(x - h * 0.35, y - h * 0.33), pt(x + h * 0.35, y - h * 0.66))
    })
}

// MARK: - Tường & sàn

function clipRoom(ctx: GC): GC {
    const c = ctx.copy()
    c.clip(Path.rect(R(0, 0, 125, 100)))
    return c
}

// Cửa sổ ở x 46…72, y 8…30, có rèm ngắn màu `curtain`.
function window(ctx: GC, frame: Color, curtain: Color) {
    ctx.rect(45, 7, 28, 24, frame, 2.5)
    ctx.rect(47.5, 9.5, 23, 19, rgb(0xCFE9F4), 1.5)
    ctx.ellipse(50, 20, 9, 4, Color.white.opacity(0.85))
    ctx.ellipse(54, 18, 7, 4, Color.white.opacity(0.85))
    ctx.circle(66, 14, 2.6, rgb(0xFBE7A6))
    ctx.rect(58.2, 9.5, 1.6, 19, frame)
    ctx.rect(47.5, 18.4, 23, 1.6, frame)
    // rèm ngắn có viền lượn sóng
    ctx.rect(46, 7.5, 26, 4, curtain, 1.5)
    for (let i = 0; i < 6; i++) {
        ctx.circle(48.2 + (i) * 4.3, 11.4, 2.2, curtain)
    }
    ctx.rect(44, 29, 30, 3, frame, 1.2)
    // chậu rau thơm nhỏ trên bậu
    ctx.rect(64, 25, 5, 4, rgb(0xE9A27F), 1)
    ctx.ellipse(63.2, 21.5, 3.6, 4.2, rgb(0x8CC08F))
    ctx.ellipse(65.8, 20.6, 3.6, 4.6, rgb(0x7DB582))
    ctx.ellipse(66.8, 22, 3, 3.6, rgb(0x8CC08F))
}

// Dải gạch men ốp phía sau bếp và tủ lạnh.
function backsplash(ctx: GC, base: Color, grout: Color) {
    ctx.rect(48, 39, 77, 22, base)
    let row = 0
    let y = 40
    while (y < 61) {
        ctx.rect(48, y, 77, 0.6, grout)
        let x = row % 2 == 0 ? 48 : 52
        while (x < 125) {
            ctx.rect(x, y, 0.6, 3.5, grout)
            x += 8
        }
        y += 3.5
        row += 1
    }
    ctx.rect(47, 38, 78, 2, grout, 1)
    ctx.rect(47, 38, 78, 0.7, Color.white.opacity(0.6))
}

function floorChecker(ctx: GC, a: Color, b: Color) {
    ctx.rect(0, 62, 125, 38, a)
    const rows = [62, 69, 77, 87.5]
    const heights = [7, 8, 10.5, 12.5]
    for (let r = 0; r < rows.length; r++) {
        const w = 12.5 + (r) * 1.5
        let x = r % 2 == 0 ? 0 : -w / 2
        let k = 0
        while (x < 125) {
            if (k % 2 == 0) { ctx.rect(x, rows[r], w, heights[r], b) }
            x += w
            k += 1
        }
    }
}

function baseboard(ctx: GC, color: Color) {
    ctx.rect(0, 59.5, 125, 3.5, color)
    ctx.rect(0, 59.5, 125, 0.8, Color.white.opacity(0.5))
    ctx.rect(0, 63, 125, 1.2, Color.black.opacity(0.06))
}

function themeMint(ctx: GC) {
    ctx.rect(0, 0, 125, 62, rgb(0xDDF1E5))
    // gạch men vuông
    const grout = Color.white.opacity(0.55)
    let y = 0
    while (y < 60) { ctx.rect(0, y, 125, 0.6, grout); y += 10 }
    let x = 0
    while (x < 125) { ctx.rect(x, 0, 0.6, 60, grout); x += 10 }
    for (const [cx, cy] of ([[5.0, 5.0], [35.0, 25.0], [95.0, 15.0], [115.0, 35.0], [25.0, 45.0], [85.0, 5.0]] as const)) {
        sparkle(ctx, cx, cy, 4, Color.white.opacity(0.7))
    }
    backsplash(ctx, rgb(0xF6FBF7), rgb(0xD6ECDF))
    window(ctx, rgb(0xFFFDF8), rgb(0xF3B7B3))
    baseboard(ctx, rgb(0xA9D6BC))
    floorChecker(ctx, rgb(0xFAF4E6), rgb(0xCBE7D6))
}

function themeGingham(ctx: GC) {
    ctx.rect(0, 0, 125, 62, rgb(0xFFF5EC))
    const red = rgb(0xEE9E9A).opacity(0.22)
    let x = 0
    while (x < 125) { ctx.rect(x, 0, 4, 60, red); x += 8 }
    let y = 0
    while (y < 60) { ctx.rect(0, y, 125, 4, red); y += 8 }
    backsplash(ctx, rgb(0xFFFBF6), rgb(0xF5DDD6))
    window(ctx, rgb(0xFFFDF8), rgb(0xE88F8C))
    baseboard(ctx, rgb(0xE7A7A2))
    floorChecker(ctx, rgb(0xFCF1E7), rgb(0xF0C3BC))
}

function themeLemon(ctx: GC) {
    ctx.rect(0, 0, 125, 62, rgb(0xFFF3C4))
    // họa tiết trái chanh nhỏ
    let row = 0
    let y = 6
    while (y < 58) {
        let x = row % 2 == 0 ? 6 : 16
        while (x < 125) {
            ctx.ellipse(x - 2.6, y - 1.8, 5.2, 3.6, rgb(0xF6D867).opacity(0.75))
            ctx.ellipse(x + 0.6, y - 3.4, 2.6, 1.4, rgb(0xA8D08D).opacity(0.75))
            x += 20
        }
        y += 11
        row += 1
    }
    backsplash(ctx, rgb(0xFFFDF2), rgb(0xF4E7B8))
    window(ctx, rgb(0xFFFDF8), rgb(0xA8D3A6))
    baseboard(ctx, rgb(0xEDCB6A))
    floorChecker(ctx, rgb(0xFFFCEF), rgb(0xF7E6A6))
}

function themeWood(ctx: GC) {
    ctx.rect(0, 0, 125, 62, rgb(0xE6C39C))
    let x = 0
    let i = 0
    while (x < 125) {
        if (i % 3 == 1) { ctx.rect(x, 0, 9, 60, rgb(0xDDB78E)) }
        ctx.rect(x, 0, 0.7, 60, rgb(0xC99D70))
        ctx.circle(x + 4.5, ((i * 17) % 50) + 6, 0.9, rgb(0xC99D70).opacity(0.7))
        x += 9
        i += 1
    }
    backsplash(ctx, rgb(0xF7EBDD), rgb(0xE3CDB5))
    window(ctx, rgb(0xB98559), rgb(0xE7A39A))
    baseboard(ctx, rgb(0xA87A50))
    // sàn ván gỗ
    ctx.rect(0, 62, 125, 38, rgb(0xC9976A))
    const rows = [62, 70, 79, 89]
    for (const [r, ry] of rows.entries()) {
        ctx.rect(0, ry, 125, 0.8, rgb(0xAD7D52))
        let sx = ((r * 23) % 40) + 8
        while (sx < 125) {
            ctx.rect(sx, ry, 0.8, r == 3 ? 11 : rows[r + 1] - ry, rgb(0xAD7D52))
            sx += 38
        }
        if (r % 2 == 0) { ctx.rect(0, ry + 2, 125, 1, Color.white.opacity(0.12)) }
    }
}

// MARK: - Bếp (ô 100×100, thân bếp x 6…70, đáy ≈ 94)

function knob(ctx: GC, cx: number, cy: number, r: number, color: Color) {
    ctx.circle(cx, cy, r, color)
    ctx.rect(cx - 0.8, cy - r + 0.8, 1.6, r * 0.9, Color.white.opacity(0.8), 0.8)
}

function stoveBasic(ctx: GC) {
    ctx.ellipse(4, 89, 70, 8, shadow)
    // tủ bếp
    ctx.rect(9, 46, 58, 46, rgb(0xF5EFE4), 4)
    ctx.rect(13, 54, 24, 34, rgb(0xFBF7F0), 3)
    ctx.rect(39, 54, 24, 34, rgb(0xFBF7F0), 3)
    ctx.rect(32, 66, 2.5, 8, steelDark, 1.2)
    ctx.rect(41.5, 66, 2.5, 8, steelDark, 1.2)
    ctx.rect(12, 91, 6, 3, rgb(0xB5AFA8), 1)
    ctx.rect(58, 91, 6, 3, rgb(0xB5AFA8), 1)
    // mặt bếp
    ctx.rect(6, 38, 64, 10, steel, 3)
    ctx.rect(6, 38, 64, 2.5, Color.white.opacity(0.6), 1.2)
    knob(ctx, 16, 44, 2.6, rgb(0xE59A7A))
    knob(ctx, 24, 44, 2.6, rgb(0xE59A7A))
    ctx.rect(52, 42.5, 12, 3, rgb(0x8E8899), 1.5)
    // hai bếp
    ctx.ellipse(12, 35.5, 22, 5, rgb(0x6A6274))
    ctx.ellipse(16, 36.3, 14, 3, rgb(0xF3A07A))
    ctx.ellipse(42, 35.5, 22, 5, rgb(0x6A6274))
    // nồi
    ctx.rect(38, 33, 4, 3, rgb(0xD47F64), 1)
    ctx.rect(62, 33, 4, 3, rgb(0xD47F64), 1)
    ctx.rect(41, 18, 22, 20, rgb(0xF0A387), 5)
    ctx.rect(41, 26, 22, 3, rgb(0xFBD3C2))
    ctx.ellipse(39, 14, 26, 7, rgb(0xE08E70))
    ctx.circle(52, 13, 2.5, rgb(0x8E6B5A))
    ctx.rect(44, 20, 3, 12, Color.white.opacity(0.45), 1.5)
    steam(ctx, 46, 9, 9)
    steam(ctx, 56, 8, 8)
}

function stoveRetro(ctx: GC) {
    ctx.ellipse(4, 89, 70, 8, shadow)
    const body = rgb(0xFBF0D9)
    // tấm chắn phía sau có đồng hồ nhỏ
    ctx.rect(10, 20, 56, 16, body, 7)
    ctx.circle(38, 27.5, 4.5, rgb(0xEFE3C8))
    ctx.circle(38, 27.5, 3.3, Color.white)
    ctx.strokePath(ink, 0.9, (p) => {
        p.move(pt(38, 27.5)); p.addLine(pt(38, 25.2))
        p.move(pt(38, 27.5)); p.addLine(pt(39.8, 28.4))
    })
    ctx.rect(14, 33, 48, 2, rgb(0x9FD3C1), 1)
    // thân
    ctx.rect(6, 34, 64, 58, body, 9)
    ctx.rect(6, 34, 64, 4, rgb(0x6A6274).opacity(0.85), 2)
    ctx.ellipse(10, 33, 14, 3, rgb(0x6A6274))
    ctx.ellipse(52, 33, 14, 3, rgb(0x6A6274))
    // núm xoay
    for (const [i, cx] of [18.0, 30.0, 46.0, 58.0].entries()) {
        knob(ctx, cx, 45, 3.6, i % 2 == 0 ? rgb(0xEE8F8F) : rgb(0x8FCDB9))
    }
    // cửa lò
    ctx.rect(12, 53, 52, 33, rgb(0xF3E2C2), 6)
    ctx.rect(17, 54.5, 42, 3, steelDark, 1.5)
    ctx.rect(19, 61, 38, 19, rgb(0x6F6680), 5)
    ctx.rect(22, 63, 10, 3, Color.white.opacity(0.35), 1.5)
    ctx.ellipse(28, 74, 20, 4, rgb(0xF1B36B).opacity(0.6))
    // điểm sáng & chân
    ctx.rect(9, 40, 3, 40, Color.white.opacity(0.55), 1.5)
    ctx.rect(11, 90, 7, 4, steelDark, 1.5)
    ctx.rect(58, 90, 7, 4, steelDark, 1.5)
}

function stoveOven(ctx: GC) {
    ctx.ellipse(4, 89, 70, 8, shadow)
    const body = rgb(0xF4C9AE)
    // thân lò mái vòm
    ctx.rect(6, 40, 64, 52, body, 6)
    ctx.ellipse(6, 26, 64, 34, body)
    ctx.rect(6, 52, 64, 4, rgb(0xE9B293))
    // ô cửa sổ lò đang sáng
    ctx.rect(14, 58, 48, 28, rgb(0xE6A58A), 7)
    ctx.rect(17, 61, 42, 22, rgb(0xFBD98C), 5)
    ctx.ellipse(20, 63, 36, 12, rgb(0xFFF0C2).opacity(0.8))
    ctx.rect(19, 75, 38, 1.4, rgb(0xC98E5E))
    for (const cx of [26.0, 38.0, 50.0]) {
        ctx.ellipse(cx - 5, 70.5, 10, 5, rgb(0xD9A061))
        ctx.circle(cx - 1.5, 72, 0.9, rgb(0x6B4A3A))
        ctx.circle(cx + 2, 71.6, 0.9, rgb(0x6B4A3A))
    }
    ctx.rect(26, 54.5, 24, 2.6, cream, 1.3)
    // núm & đồng hồ hẹn giờ
    knob(ctx, 22, 43, 3.6, rgb(0xFFF4E6))
    knob(ctx, 54, 43, 3.6, rgb(0xFFF4E6))
    ctx.circle(38, 39, 6, cream)
    ctx.heart(pt(38, 39.5), 6, rgb(0xEE8F8F))
    // ống khói nhỏ + mùi bánh
    ctx.rect(52, 18, 9, 14, rgb(0xE3AD90), 2)
    ctx.rect(50.5, 16, 12, 4, rgb(0xD99C7E), 2)
    steam(ctx, 54, 13, 9, Color.white.opacity(0.85))
    ctx.heart(pt(46, 9), 5, rgb(0xF4B0B0))
    ctx.heart(pt(62, 5), 4, rgb(0xF4B0B0))
    ctx.rect(10, 44, 3, 36, Color.white.opacity(0.45), 1.5)
    ctx.ellipse(16, 32, 10, 5, Color.white.opacity(0.5))
    ctx.rect(10, 90, 8, 4, rgb(0xC88E70), 1.5)
    ctx.rect(58, 90, 8, 4, rgb(0xC88E70), 1.5)
}

function stoveHearth(ctx: GC) {
    ctx.ellipse(2, 88, 74, 9, shadow)
    const iron = rgb(0x6E6278)
    const ironDark = rgb(0x584D62)
    // ống khói
    ctx.rect(51, 0, 9, 40, iron)
    ctx.rect(49.5, 10, 12, 3, ironDark, 1.5)
    ctx.rect(49.5, 26, 12, 3, ironDark, 1.5)
    ctx.rect(53, 0, 2, 38, Color.white.opacity(0.2))
    // thân bếp gang
    ctx.rect(8, 38, 60, 6, ironDark, 3)
    ctx.rect(11, 43, 54, 44, iron, 6)
    ctx.rect(14, 86, 6, 8, ironDark, 2)
    ctx.rect(56, 86, 6, 8, ironDark, 2)
    // cửa lửa
    let arch = new Path()
    arch.move(pt(20, 80))
    arch.addLine(pt(20, 62))
    arch.addQuadCurve(pt(56, 62), pt(38, 44))
    arch.addLine(pt(56, 80))
    arch.closeSubpath()
    ctx.fill(arch, (rgb(0x3F3548)))
    // củi + lửa
    ctx.rect(24, 74, 28, 5, rgb(0xB0805F), 2.5)
    ctx.rect(28, 70, 22, 5, rgb(0x9A6C4F), 2.5)
    ctx.polygon([pt(26, 72), pt(30, 60), pt(34, 66), pt(38, 54), pt(43, 65), pt(47, 59), pt(50, 72)], rgb(0xF4A25E))
    ctx.polygon([pt(31, 72), pt(35, 64), pt(38, 61), pt(42, 67), pt(45, 72)], rgb(0xF8D772))
    ctx.circle(38, 69, 2.5, rgb(0xFFF2C8))
    ctx.rect(18, 81, 40, 2.4, ironDark, 1.2)
    // tia lửa tí tách
    sparkle(ctx, 32, 52, 5, rgb(0xF8D772))
    sparkle(ctx, 46, 50, 4, rgb(0xF4A25E))
    // ấm nước trên bếp
    ctx.ellipse(16, 25, 26, 15, rgb(0x8FCDB9))
    ctx.rect(16, 31, 26, 8, rgb(0x8FCDB9), 3)
    ctx.strokePath(rgb(0x6FB09B), 2, (p) => {
        p.move(pt(20, 26)); p.addQuadCurve(pt(38, 26), pt(29, 14))
    })
    ctx.polygon([pt(17, 30), pt(10, 24), pt(12, 22.5), pt(19, 27)], rgb(0x8FCDB9))
    ctx.circle(29, 24.5, 2, rgb(0x6FB09B))
    ctx.rect(20, 28, 3, 8, Color.white.opacity(0.5), 1.5)
    steam(ctx, 10, 20, 8)
    ctx.rect(14, 46, 3, 30, Color.white.opacity(0.18), 1.5)
}

// MARK: - Tủ lạnh (ô 100×100, chỉ dùng x 4…78 vì ô tràn mép phải phòng)

function fridgeBody(ctx: GC, x: number, y: number, w: number, h: number, color: Color, radius: number) {
    ctx.ellipse(x - 4, y + h - 4, w + 8, 8, shadow)
    ctx.rect(x + 5, y + h - 3, 6, 4, steelDark, 1.5)
    ctx.rect(x + w - 11, y + h - 3, 6, 4, steelDark, 1.5)
    ctx.rect(x, y, w, h - 1, color, radius)
}

function fridgeMini(ctx: GC) {
    fridgeBody(ctx, 14, 50, 50, 45, rgb(0xF4F6F8), 7)
    ctx.strokePath(rgb(0xD8DCE4), 1.4, (p) => {
        p.move(pt(16, 62)); p.addLine(pt(62, 62))
    })
    ctx.rect(54, 66, 3.5, 16, steelDark, 1.7)
    ctx.rect(54, 53, 3.5, 6, steelDark, 1.7)
    ctx.rect(18, 54, 3, 30, Color.white.opacity(0.9), 1.5)
    ctx.heart(pt(30, 72), 6, rgb(0xF4B0B0))
    // sữa
    ctx.rect(20, 32, 13, 18, Color.white, 2)
    ctx.polygon([pt(20, 32), pt(26.5, 26), pt(33, 32)], rgb(0x9FC7EC))
    ctx.rect(25, 24, 3, 3, rgb(0x9FC7EC), 1)
    ctx.rect(20, 38, 13, 6, rgb(0x9FC7EC))
    ctx.circle(26.5, 41, 1.6, Color.white)
    // bát trái cây
    ctx.circle(44, 40, 5, rgb(0xEE8B8B))
    ctx.rect(43.6, 33, 1.2, 3.5, rgb(0x8E6B5A))
    ctx.ellipse(50, 33, 9, 12, rgb(0xF6D867))
    ctx.circle(56, 41, 4.5, rgb(0xF4B36E))
    ctx.circle(42.5, 38.5, 1.2, Color.white.opacity(0.7))
    let bowl = new Path()
    bowl.move(pt(38, 42))
    bowl.addQuadCurve(pt(62, 42), pt(50, 58))
    bowl.closeSubpath()
    ctx.fill(bowl, (rgb(0x9FD3C1)))
    ctx.rect(46, 48, 8, 2, rgb(0x8BC5B1), 1)
}

function fridgeRetro(ctx: GC) {
    const body = rgb(0x9FDACB)
    fridgeBody(ctx, 8, 8, 66, 87, body, 18)
    ctx.strokePath(rgb(0x7EC3B2), 1.6, (p) => {
        p.move(pt(9, 36)); p.addLine(pt(73, 36))
    })
    ctx.rect(62, 18, 4.5, 12, rgb(0xEDEBF1), 2.2)
    ctx.rect(62, 42, 4.5, 24, rgb(0xEDEBF1), 2.2)
    ctx.rect(30, 82, 22, 4, rgb(0xEDEBF1), 2)
    ctx.ellipse(33, 46, 16, 6, rgb(0xEDEBF1))
    ctx.ellipse(35, 47.2, 12, 3.6, rgb(0xEE8F8F))
    ctx.rect(14, 16, 4, 16, Color.white.opacity(0.55), 2)
    ctx.rect(14, 42, 4, 32, Color.white.opacity(0.55), 2)
    sparkle(ctx, 24, 22, 7)
}

function fridgePink(ctx: GC) {
    const body = rgb(0xF7C6D0)
    fridgeBody(ctx, 8, 6, 66, 89, body, 11)
    ctx.strokePath(rgb(0xE9A6B5), 1.6, (p) => {
        p.move(pt(9, 34)); p.addLine(pt(73, 34))
    })
    ctx.rect(13, 12, 56, 4, Color.white.opacity(0.5), 2)
    ctx.rect(14, 22, 3.5, 7, Color.white, 1.7)
    ctx.rect(14, 40, 3.5, 22, Color.white, 1.7)
    // nam châm dâu tây + tim
    ctx.heart(pt(52, 23), 9, rgb(0xEE7F95))
    ctx.ellipse(46, 50, 11, 12, rgb(0xEF7B7B))
    ctx.polygon([pt(46.5, 51), pt(51.5, 47), pt(56.5, 51), pt(51.5, 53)], rgb(0x8CC08F))
    for (const [sx, sy] of ([[49.0, 55.0], [53.0, 54.0], [51.0, 58.0]] as const)) {
        ctx.circle(sx, sy, 0.8, rgb(0xFFF1B8))
    }
    // nhãn sữa dâu
    ctx.rect(26, 66, 30, 14, Color.white.opacity(0.85), 4)
    ctx.circle(34, 73, 3.5, rgb(0xF7A7B8))
    ctx.rect(40, 70, 12, 2, rgb(0xE9A6B5), 1)
    ctx.rect(40, 74, 9, 2, rgb(0xE9A6B5), 1)
    ctx.rect(64, 12, 3, 74, Color.white.opacity(0.35), 1.5)
    sparkle(ctx, 24, 20, 7)
}

function fridgeMagnets(ctx: GC) {
    const body = rgb(0xF7F4EE)
    fridgeBody(ctx, 8, 6, 66, 89, body, 11)
    ctx.strokePath(rgb(0xDEDAD3), 1.6, (p) => {
        p.move(pt(9, 32)); p.addLine(pt(73, 32))
    })
    ctx.rect(64, 14, 4, 12, steelDark, 2)
    ctx.rect(64, 38, 4, 24, steelDark, 2)
    // tranh vẽ: mặt trời
    ctx.rotated(-6, pt(26, 46), (c) => {
        c.rect(14, 37, 24, 20, Color.white, 1)
        c.circle(22, 45, 4, rgb(0xF6D867))
        c.strokePath(rgb(0xF6D867), 1, (p) => {
            p.move(pt(22, 38.5)); p.addLine(pt(22, 39.5))
            p.move(pt(15.8, 45)); p.addLine(pt(16.8, 45))
            p.move(pt(28.2, 45)); p.addLine(pt(27.2, 45))
        })
        c.rect(14, 52, 24, 5, rgb(0xA8D3A6))
        c.circle(32, 50, 2.5, rgb(0xEE8F8F))
    })
    ctx.circle(26, 37, 2.3, rgb(0x8D78CF))
    // tranh vẽ: con mèo
    ctx.rotated(5, pt(48, 70), (c) => {
        c.rect(36, 60, 26, 21, rgb(0xFFF8E6), 1)
        c.ellipse(42, 66, 14, 11, rgb(0xF2B27A))
        c.polygon([pt(43, 68), pt(44, 63), pt(47, 66.5)], rgb(0xF2B27A))
        c.polygon([pt(55, 68), pt(54, 63), pt(51, 66.5)], rgb(0xF2B27A))
        c.circle(46.5, 71, 0.9, ink)
        c.circle(51.5, 71, 0.9, ink)
    })
    ctx.circle(49, 60, 2.3, rgb(0x8FCDB9))
    // nam châm nhiều màu
    ctx.heart(pt(52, 15), 8, rgb(0xEE8F8F))
    ctx.circle(22, 16, 3.5, rgb(0xF6D867))
    ctx.circle(40, 22, 3, rgb(0x9FC7EC))
    ctx.text("★", 10, rgb(0xF4B36E), pt(30, 24))
    ctx.circle(56, 46, 3.2, rgb(0xC9B6F0))
    ctx.circle(22, 82, 3, rgb(0xF7A7B8))
    ctx.text("♪", 9, rgb(0x8FCDB9), pt(34, 86))
    ctx.rect(18, 66, 10, 7, rgb(0xF6D867), 2)
    ctx.rect(13, 12, 3, 14, Color.white.opacity(0.9), 1.5)
}

// MARK: - Bàn ăn (ô 100×100, mặt bàn ở y ≈ 41, giữa x = 50)
// Món ăn được vẽ TRƯỚC bàn, nên khoảng x 24…76 phía trên y 41 phải để trống.

function diningStool(ctx: GC) {
    const top = rgb(0xFBEEDC)
    const leg = rgb(0x9DC3E6)
    ctx.ellipse(10, 89, 84, 8, shadow)
    ctx.rect(22, 47, 6, 46, leg, 2)
    ctx.rect(72, 47, 6, 46, leg, 2)
    ctx.rect(22, 58, 56, 3, leg, 1.5)
    ctx.rect(14, 41, 72, 8, rgb(0xE9CFAE), 3)
    ctx.rect(14, 41, 72, 4, top, 2)
    ctx.rect(20, 42, 10, 1.2, Color.white.opacity(0.8), 0.6)
    ctx.rect(18, 48.5, 64, 1.2, Color.black.opacity(0.06))
    // đẩu tròn phía trước
    ctx.ellipse(56, 90, 36, 6, shadow)
    ctx.rect(62, 74, 4.5, 19, rgb(0x86B2DA), 2)
    ctx.rect(81, 74, 4.5, 19, rgb(0x86B2DA), 2)
    ctx.rect(64, 84, 20, 2.5, rgb(0x86B2DA), 1.2)
    ctx.ellipse(57, 69, 34, 10, rgb(0xE59A7A))
    ctx.ellipse(59, 68, 30, 7, rgb(0xF3B79C))
    ctx.ellipse(66, 69, 8, 2.4, Color.white.opacity(0.5))
}

function chair(ctx: GC, x: number, color: Color, cushion: Color) {
    ctx.rect(x + 1, 22, 4, 70, color, 2)
    ctx.rect(x + 15, 22, 4, 70, color, 2)
    ctx.rect(x, 19, 20, 8, color, 4)
    ctx.rect(x + 2, 32, 16, 3, color, 1.5)
    ctx.rect(x + 2, 40, 16, 3, color, 1.5)
    ctx.ellipse(x - 2, 56, 24, 8, cushion)
    ctx.ellipse(x + 2, 56.5, 10, 2.5, Color.white.opacity(0.5))
}

function diningRound(ctx: GC) {
    const wood = rgb(0xC99060)
    const woodDark = rgb(0xA4724A)
    ctx.ellipse(2, 88, 96, 8, shadow)
    chair(ctx, 2, rgb(0x9CCDB6), rgb(0xF3B7B3))
    chair(ctx, 78, rgb(0x9CCDB6), rgb(0xF3B7B3))
    // bàn tròn một chân
    ctx.rect(46, 48, 8, 38, woodDark, 2)
    ctx.ellipse(32, 84, 36, 8, woodDark)
    ctx.ellipse(16, 43, 68, 9, woodDark)
    ctx.ellipse(16, 40.5, 68, 8, wood)
    ctx.ellipse(28, 41.5, 18, 2.4, Color.white.opacity(0.45))
}

function diningPicnic(ctx: GC) {
    const woodDark = rgb(0xB58357)
    ctx.ellipse(6, 88, 88, 8, shadow)
    ctx.rect(16, 60, 6, 33, woodDark, 2)
    ctx.rect(78, 60, 6, 33, woodDark, 2)
    // khăn trải bàn ca rô
    let cloth = new Path()
    cloth.move(pt(10, 41))
    cloth.addLine(pt(90, 41))
    cloth.addLine(pt(93, 64))
    cloth.addLine(pt(7, 64))
    cloth.closeSubpath()
    for (let i = 0; i < 9; i++) { cloth.addEllipse(R(7 + (i) * 9.55, 60, 9.6, 8)) }
    ctx.fill(cloth, (Color.white))
    const c = ctx.copy()
    c.clip(cloth)
    const red = rgb(0xE9817F).opacity(0.5)
    let x = 7
    while (x < 94) { c.rect(x, 41, 4.5, 28, red); x += 9 }
    let y = 45.5
    while (y < 70) { c.rect(0, y, 100, 4.5, red); y += 9 }
    c.rect(0, 41, 100, 4.5, rgb(0xFFFFFF).opacity(0.0))
    // mặt bàn nhìn từ trên
    ctx.rect(10, 41, 80, 4, rgb(0xF6D6D3), 1.5)
    ctx.rect(10, 41, 80, 1.2, Color.white.opacity(0.8), 0.6)
    // lọ hoa cúc nhỏ ở góc
    ctx.rect(81, 33, 6, 8, rgb(0x9FC7EC), 2)
    ctx.rect(83.6, 26, 1, 8, rgb(0x7DB582))
    for (let a = 0; a < 6; a++) {
        const ang = (a) * Math.PI / 3
        ctx.circle(84.1 + (Math.cos(ang)) * 2.4, 25 + (Math.sin(ang)) * 2.4, 1.6, Color.white)
    }
    ctx.circle(84.1, 25, 1.4, rgb(0xF6D867))
}

function diningLong(ctx: GC) {
    const wood = rgb(0xC9976A)
    const woodDark = rgb(0xA87A50)
    ctx.ellipse(0, 88, 100, 8, shadow)
    for (const lx of [6.0, 88.0]) {
        ctx.rect(lx, 48, 6, 45, woodDark, 2)
    }
    ctx.rect(10, 52, 80, 3, woodDark, 1.5)
    // khăn ren trắng
    ctx.rect(2, 41, 96, 7, wood, 3)
    ctx.rect(2, 41, 96, 2.4, rgb(0xDDB088), 1.2)
    ctx.rect(14, 41, 72, 11, rgb(0xFFFBF4), 1.5)
    for (let i = 0; i < 9; i++) { ctx.circle(18 + (i) * 8, 52, 2.4, rgb(0xFFFBF4)) }
    ctx.rect(42, 41, 16, 15, rgb(0xC9B6F0), 1.5)
    ctx.polygon([pt(42, 56), pt(50, 60), pt(58, 56)], rgb(0xC9B6F0))
    // hai cây nến
    for (const cx of [12.0, 88.0]) {
        ctx.ellipse(cx - 6, 39, 12, 3.6, rgb(0xE9C46A))
        ctx.rect(cx - 1.5, 30, 3, 10, rgb(0xE9C46A), 1)
        ctx.ellipse(cx - 4, 28, 8, 3, rgb(0xE9C46A))
        ctx.rect(cx - 2.5, 13, 5, 16, cream, 1.5)
        ctx.circle(cx, 8, 6, rgb(0xF6D867).opacity(0.25))
        ctx.ellipse(cx - 2.2, 4.5, 4.4, 7, rgb(0xF4B36E))
        ctx.ellipse(cx - 1.2, 7, 2.4, 4, rgb(0xFFF2C8))
        ctx.rect(cx - 1.6, 15, 1.4, 10, Color.white.opacity(0.7), 0.7)
    }
}

// MARK: - Đồ treo tường (ô 100×100)

function wallClock(ctx: GC) {
    const lemon = rgb(0xF7D865)
    ctx.ellipse(10, 24, 80, 64, lemon)
    ctx.ellipse(4, 50, 12, 12, lemon)
    ctx.ellipse(84, 50, 12, 12, lemon)
    ctx.ellipse(20, 32, 60, 48, rgb(0xFFF6D2))
    // múi chanh mờ
    ctx.strokePath(rgb(0xF7E59A), 1.4, (p) => {
        for (let a = 0; a < 8; a++) {
            const ang = (a) * Math.PI / 4
            p.move(pt(50, 56))
            p.addLine(pt(50 + (Math.cos(ang)) * 27, 56 + (Math.sin(ang)) * 21))
        }
    })
    for (const [dx, dy] of ([[50.0, 37.0], [73.0, 56.0], [50.0, 75.0], [27.0, 56.0]] as const)) {
        ctx.circle(dx, dy, 2, rgb(0xE5B843))
    }
    ctx.strokePath(ink, 3.2, (p) => {
        p.move(pt(50, 56)); p.addLine(pt(50, 42))
    })
    ctx.strokePath(ink, 2.4, (p) => {
        p.move(pt(50, 56)); p.addLine(pt(63, 62))
    })
    ctx.circle(50, 56, 3, rgb(0xEE8F8F))
    // má hồng
    ctx.ellipse(29, 66, 8, 4, rgb(0xF4B0B0).opacity(0.7))
    ctx.ellipse(63, 66, 8, 4, rgb(0xF4B0B0).opacity(0.7))
    // cuống & lá
    ctx.rect(48, 16, 4, 10, rgb(0x8E6B5A), 2)
    ctx.rotated(-25, pt(60, 18), (c) => {
        c.ellipse(52, 13, 22, 10, rgb(0x8CC08F))
        c.rect(54, 17.4, 16, 1.2, rgb(0x6FA373))
    })
    ctx.ellipse(22, 30, 14, 8, Color.white.opacity(0.55))
}

function wallPans(ctx: GC) {
    // thanh treo
    ctx.rect(4, 16, 92, 5, rgb(0xB58357), 2.5)
    ctx.circle(8, 18.5, 3.5, rgb(0xA07448))
    ctx.circle(92, 18.5, 3.5, rgb(0xA07448))
    ctx.strokePath(steelDark, 1.6, (p) => {
        for (const hx of [26.0, 50.0, 68.0, 84.0]) {
            p.move(pt(hx, 20)); p.addLine(pt(hx, 25))
        }
    })
    // chảo
    ctx.rect(23.5, 24, 5, 26, rgb(0xB58357), 2.5)
    ctx.circle(26, 66, 18, rgb(0x6E6278))
    ctx.circle(26, 66, 13.5, rgb(0x857A90))
    ctx.ellipse(16, 56, 9, 6, Color.white.opacity(0.35))
    // muôi
    ctx.strokePath(rgb(0xC9B6F0), 3.4, (p) => {
        p.move(pt(50, 26)); p.addLine(pt(50, 64))
    })
    let ladle = new Path()
    ladle.move(pt(41, 63))
    ladle.addQuadCurve(pt(59, 63), pt(50, 80))
    ladle.closeSubpath()
    ctx.fill(ladle, (rgb(0xB7A3E6)))
    ctx.circle(50, 26, 2.6, rgb(0xC9B6F0))
    // xẻng
    ctx.strokePath(rgb(0x9CCDB6), 3.4, (p) => {
        p.move(pt(68, 26)); p.addLine(pt(68, 56))
    })
    ctx.rect(61, 54, 14, 18, rgb(0x9CCDB6), 4)
    ctx.strokePath(rgb(0xDDF1E5), 1.4, (p) => {
        for (const sx of [65.0, 68.0, 71.0]) { p.move(pt(sx, 58)); p.addLine(pt(sx, 68)) }
    })
    // nồi nhỏ bằng đồng
    ctx.strokePath(rgb(0xD48B66), 2, (p) => {
        p.move(pt(84, 25)); p.addLine(pt(84, 38))
    })
    ctx.rect(76, 38, 16, 4, rgb(0xD48B66), 2)
    ctx.rect(76, 41, 16, 15, rgb(0xEAA584), 4)
    ctx.rect(79, 44, 3, 8, Color.white.opacity(0.45), 1.5)
}

function wallFruit(ctx: GC) {
    ctx.rect(12, 12, 76, 76, rgb(0xC9976A), 6)
    ctx.rect(17, 17, 66, 66, rgb(0xFFF8EC), 3)
    ctx.ellipse(22, 70, 56, 10, rgb(0xF3E2C6))
    // chùm nho
    for (const [gx, gy] of ([[44.0, 32.0], [52.0, 32.0], [60.0, 32.0], [48.0, 39.0], [56.0, 39.0], [52.0, 46.0]] as const)) {
        ctx.circle(gx, gy, 4.6, rgb(0xB7A3E6))
        ctx.circle(gx - 1.4, gy - 1.6, 1.2, Color.white.opacity(0.7))
    }
    ctx.rect(51, 22, 2, 6, rgb(0x8E6B5A), 1)
    ctx.ellipse(54, 22, 9, 5, rgb(0x8CC08F))
    // quả lê
    ctx.circle(34, 64, 10, rgb(0xD7E28A))
    ctx.circle(34, 51, 6.5, rgb(0xD7E28A))
    ctx.rect(33, 41, 2, 6, rgb(0x8E6B5A), 1)
    ctx.ellipse(28, 60, 4, 6, Color.white.opacity(0.5))
    // quả táo
    ctx.circle(62, 64, 11, rgb(0xEE8686))
    ctx.circle(67, 62, 9, rgb(0xEE8686))
    ctx.rect(63.5, 49, 2, 7, rgb(0x8E6B5A), 1)
    ctx.ellipse(66, 48, 8, 4.5, rgb(0x8CC08F))
    ctx.ellipse(57, 58, 4, 6, Color.white.opacity(0.5))
    sparkle(ctx, 76, 26, 6, rgb(0xF6D867))
}

function jar(ctx: GC, x: number, w: number, h: number, glass: Color, lid: Color, label: Color) {
    const top = 72 - h
    ctx.rect(x, top + 5, w, h - 5, glass, 5)
    ctx.rect(x + 2, top, w - 4, 6, lid, 2.5)
    ctx.rect(x + w * 0.2, top + h * 0.5, w * 0.6, h * 0.24, label, 2)
    ctx.rect(x + 3, top + 9, 2.5, h - 16, Color.white.opacity(0.6), 1.2)
}

function wallJars(ctx: GC) {
    // hũ kẹo
    jar(ctx, 8, 24, 34, rgb(0xE3F1F7), rgb(0xEE8F8F), Color.white)
    for (const [cx, cy, col] of ([[16.0, 52.0, 0xF7A7B8], [24.0, 50.0, 0xF6D867], [14.0, 63.0, 0x8FCDB9], [25.0, 64.0, 0xC9B6F0], [20.0, 58.0, 0xF4B36E]] as const)) {
        ctx.circle(cx, cy, 3, rgb(col))
    }
    ctx.rect(12.8, 54.5, 14.4, 6, Color.white.opacity(0.95), 2)
    ctx.heart(pt(20, 57.5), 4, rgb(0xEE8F8F))
    // hũ bánh quy
    jar(ctx, 37, 28, 42, rgb(0xF6E6D2), rgb(0xC9976A), rgb(0xFFF8EC))
    ctx.circle(51, 28, 3, rgb(0xB58357))
    ctx.circle(48, 56, 5, rgb(0xD9A061))
    ctx.circle(46.5, 55, 0.9, rgb(0x6B4A3A))
    ctx.circle(49.5, 57.5, 0.9, rgb(0x6B4A3A))
    ctx.circle(56, 58, 3.4, rgb(0xD9A061))
    // hộp trà
    jar(ctx, 70, 22, 30, rgb(0xA8D3B3), rgb(0x8BC5A0), rgb(0xFFF8EC))
    ctx.ellipse(77.5, 55, 7, 4, rgb(0x8CC08F))
    ctx.rect(80, 56.5, 1, 3, rgb(0x8E6B5A))
    // kệ gỗ
    ctx.rect(4, 72, 92, 6, rgb(0xC9976A), 2)
    ctx.rect(4, 72, 92, 1.6, rgb(0xDDB088), 0.8)
    ctx.polygon([pt(12, 78), pt(20, 78), pt(12, 88)], rgb(0xA87A50))
    ctx.polygon([pt(88, 78), pt(80, 78), pt(88, 88)], rgb(0xA87A50))
}

// MARK: - Món ăn (ô 100×100, đáy ở y ≈ 94, giữa x = 50 — ngồi trên mặt bàn ăn)

function treatTea(ctx: GC) {
    const pot = rgb(0xA9D8C4)
    const potDark = rgb(0x86C2AA)
    // vòi & quai
    ctx.polygon([pt(24, 74), pt(9, 56), pt(13, 53), pt(30, 66)], pot)
    ctx.strokePath(potDark, 5, (p) => {
        p.move(pt(62, 62)); p.addQuadCurve(pt(62, 84), pt(76, 72))
    })
    // thân ấm
    ctx.rect(30, 88, 28, 6, potDark, 2.5)
    ctx.ellipse(20, 52, 48, 40, pot)
    ctx.ellipse(30, 46, 28, 10, potDark)
    ctx.circle(44, 45, 4, rgb(0xF3B7B3))
    for (const [dx, dy] of ([[32.0, 68.0], [44.0, 76.0], [54.0, 66.0], [38.0, 82.0]] as const)) {
        ctx.circle(dx, dy, 2.2, Color.white.opacity(0.75))
    }
    ctx.ellipse(26, 58, 8, 12, Color.white.opacity(0.45))
    // tách trà
    ctx.ellipse(64, 89, 32, 6, rgb(0xF7E8E4))
    ctx.strokePath(rgb(0xF3B7B3), 2.6, (p) => {
        p.addEllipse(R(85, 79, 7, 7))
    })
    ctx.rect(68, 76, 20, 15, rgb(0xFFFBF6), 6)
    ctx.ellipse(68, 74, 20, 5, rgb(0xF3B7B3))
    ctx.ellipse(70, 75, 16, 3.2, rgb(0xE2AC79))
    ctx.heart(pt(78, 84), 5, rgb(0xF3B7B3))
    steam(ctx, 74, 70, 12)
    steam(ctx, 82, 70, 10)
}

function treatBread(ctx: GC) {
    // bánh mì que & bánh tròn
    ctx.rotated(-28, pt(54, 54), (c) => {
        c.ellipse(26, 46, 60, 16, rgb(0xE2A86A))
        c.strokePath(rgb(0xF6D3A2), 2, (p) => {
            for (const sx of [36.0, 48.0, 60.0, 72.0]) {
                p.move(pt(sx, 50)); p.addLine(pt(sx + 5, 58))
            }
        })
    })
    ctx.ellipse(22, 58, 30, 22, rgb(0xEDB97C))
    ctx.strokePath(rgb(0xF8DDB5), 2, (p) => {
        p.move(pt(30, 64)); p.addQuadCurve(pt(44, 64), pt(37, 60))
    })
    ctx.ellipse(48, 60, 32, 22, rgb(0xE8AE70))
    ctx.strokePath(rgb(0xF8DDB5), 2, (p) => {
        p.move(pt(56, 66)); p.addQuadCurve(pt(72, 66), pt(64, 61))
    })
    // khăn ca rô ló ra
    ctx.polygon([pt(16, 72), pt(30, 66), pt(34, 74)], rgb(0xF3B7B3))
    ctx.polygon([pt(84, 72), pt(70, 66), pt(66, 74)], rgb(0xF3B7B3))
    // giỏ mây
    ctx.rect(14, 70, 72, 24, rgb(0xDAA96E), 9)
    ctx.rect(12, 68, 76, 7, rgb(0xC8915A), 3.5)
    ctx.strokePath(rgb(0xC8915A), 1.4, (p) => {
        p.move(pt(18, 81)); p.addLine(pt(82, 81))
        p.move(pt(20, 87.5)); p.addLine(pt(80, 87.5))
        for (let sx = 24.0; sx < 76.0; sx += 8.0) {
            p.move(pt(sx, 75)); p.addLine(pt(sx, 92))
        }
    })
    ctx.ellipse(28, 60, 8, 5, Color.white.opacity(0.45))
    sparkle(ctx, 76, 46, 7)
}

function treatRamen(ctx: GC) {
    // đũa
    ctx.strokePath(rgb(0xC9976A), 2.6, (p) => {
        p.move(pt(58, 62)); p.addLine(pt(92, 32))
        p.move(pt(62, 63)); p.addLine(pt(96, 38))
    })
    // nước dùng
    ctx.ellipse(12, 54, 76, 16, rgb(0xF7D9A3))
    ctx.strokePath(rgb(0xFCEBC2), 2, (p) => {
        p.move(pt(22, 63)); p.addCurve(pt(44, 62), pt(28, 57), pt(38, 67))
        p.move(pt(40, 60)); p.addCurve(pt(62, 60), pt(46, 55), pt(56, 65))
    })
    // trứng, chả cá, rong biển, hành
    ctx.ellipse(24, 55, 18, 11, Color.white)
    ctx.ellipse(28.5, 57.5, 9, 6, rgb(0xF6B04F))
    ctx.circle(62, 60, 6, Color.white)
    ctx.strokePath(rgb(0xF29BA8), 1.4, (p) => {
        p.addArc(pt(62, 60), 3.2, deg(0), deg(300), false)
    })
    ctx.rect(72, 50, 8, 12, rgb(0x5C7A62), 1.5)
    for (const [gx, gy] of ([[46.0, 58.0], [50.0, 62.0], [54.0, 57.0], [42.0, 63.0], [68.0, 64.0]] as const)) {
        ctx.circle(gx, gy, 1.8, rgb(0x8CC08F))
        ctx.circle(gx, gy, 0.7, rgb(0xDDF1E5))
    }
    // bát
    let bowl = new Path()
    bowl.move(pt(10, 62))
    bowl.addLine(pt(90, 62))
    bowl.addCurve(pt(50, 90), pt(88, 82), pt(70, 90))
    bowl.addCurve(pt(10, 62), pt(30, 90), pt(12, 82))
    bowl.closeSubpath()
    ctx.rect(36, 86, 28, 8, rgb(0xE07F78), 3)
    ctx.fill(bowl, (rgb(0xF29E96)))
    ctx.strokePath(Color.white.opacity(0.85), 2, (p) => {
        p.move(pt(16, 70)); p.addLine(pt(84, 70))
    })
    for (const wx of [28.0, 50.0, 72.0]) {
        ctx.circle(wx, 78, 2.6, Color.white.opacity(0.8))
    }
    ctx.ellipse(10, 60, 80, 4, rgb(0xF6B7AF))
    steam(ctx, 34, 48, 14)
    steam(ctx, 50, 46, 16)
}

function treatPizza(ctx: GC) {
    // thớt gỗ
    ctx.rect(84, 76, 14, 7, rgb(0xB58357), 3.5)
    ctx.ellipse(6, 66, 84, 28, rgb(0xC9976A))
    ctx.ellipse(6, 63, 84, 27, rgb(0xDDB088))
    const pizzaRect = R(12, 62, 72, 24)
    const c = ctx
    c.fill(Path.ellipse(pizzaRect), (rgb(0xE6B26C)))
    c.ellipse(16, 64, 64, 20, rgb(0xF7D67C))
    for (const [px, py] of ([[30.0, 68.0], [44.0, 66.0], [24.0, 75.0], [40.0, 79.0], [58.0, 66.0], [54.0, 81.0]] as const)) {
        c.ellipse(px - 4, py - 2.4, 8, 4.8, rgb(0xE97A6E))
        c.ellipse(px - 2.5, py - 1.8, 2.5, 1.4, Color.white.opacity(0.5))
    }
    for (const [bx, by] of ([[36.0, 73.0], [50.0, 72.0], [30.0, 81.0]] as const)) {
        c.ellipse(bx - 2.5, by - 1.2, 5, 2.6, rgb(0x7DB582))
    }
    // một lát đã bị ăn mất: tô lại màu thớt trong hình quạt
    let wedge = new Path()
    wedge.move(pt(48, 74))
    wedge.addLine(pt(92, 70))
    wedge.addLine(pt(88, 100))
    wedge.closeSubpath()
    const cut = ctx.copy()
    cut.clip(Path.ellipse(pizzaRect))
    cut.fill(wedge, (rgb(0xDDB088)))
    // vụn bánh
    ctx.circle(74, 82, 1.3, rgb(0xE6B26C))
    ctx.circle(80, 78, 1, rgb(0xE6B26C))
    ctx.circle(70, 87, 1, rgb(0xE6B26C))
    sparkle(ctx, 20, 58, 7)
}

function treatCake(ctx: GC) {
    // đĩa có chân
    ctx.ellipse(34, 89, 32, 6, rgb(0xD7CBEF))
    ctx.rect(45, 84, 10, 7, rgb(0xD7CBEF), 2)
    ctx.ellipse(12, 80, 76, 8, rgb(0xECE6FA))
    ctx.ellipse(16, 79, 68, 5, Color.white)
    // thân bánh
    ctx.rect(22, 50, 56, 32, rgb(0xFFF4E8), 6)
    ctx.rect(22, 64, 56, 5, rgb(0xF29BA8))
    ctx.rect(22, 69, 56, 2, rgb(0xFBD3DA))
    // kem phủ chảy
    ctx.rect(20, 46, 60, 10, rgb(0xF7C1CC), 5)
    for (const [dx, dh] of ([[26.0, 6.0], [36.0, 9.0], [47.0, 5.0], [57.0, 8.0], [68.0, 6.0], [75.0, 4.0]] as const)) {
        ctx.rect(dx - 2.6, 52, 5.2, dh + 2, rgb(0xF7C1CC), 2.6)
    }
    // dâu tây
    for (const sx of [32.0, 68.0]) {
        ctx.ellipse(sx - 5, 38, 10, 11, rgb(0xEE6F7C))
        ctx.polygon([pt(sx - 4.5, 39), pt(sx, 35.5), pt(sx + 4.5, 39), pt(sx, 41)], rgb(0x8CC08F))
        ctx.circle(sx - 1.6, 44, 0.7, rgb(0xFFF1B8))
        ctx.circle(sx + 1.8, 45.5, 0.7, rgb(0xFFF1B8))
    }
    ctx.circle(42, 44, 4, Color.white)
    ctx.circle(58, 44, 4, Color.white)
    // nến
    ctx.rect(48, 30, 4, 15, rgb(0xC9B6F0), 1.2)
    ctx.rect(48, 34, 4, 2, Color.white.opacity(0.8))
    ctx.rect(48, 39, 4, 2, Color.white.opacity(0.8))
    ctx.circle(50, 24, 5.5, rgb(0xF6D867).opacity(0.3))
    ctx.ellipse(47.6, 20, 4.8, 8, rgb(0xF4B36E))
    ctx.ellipse(48.8, 23, 2.4, 4, rgb(0xFFF2C8))
    ctx.rect(26, 56, 3, 22, Color.white.opacity(0.6), 1.5)
    sparkle(ctx, 82, 34, 7)
    sparkle(ctx, 18, 40, 5, rgb(0xF6D867))
}

export const KitchenArt = { draw }
