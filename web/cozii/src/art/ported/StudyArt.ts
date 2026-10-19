// Chuyển tự động từ Swift (scripts/port/swift2ts.mjs) rồi sửa tay.
import { GC, Color, rgb, pt, R, Path, deg, Pt, Rect, linear, radial } from '../gc'
import { Palette } from '../palette'

// Hình vẽ đồ trong phòng học (tường & sàn + đồ mới). Đồ cũ của phòng học nằm trong ItemPainter.
// Trả về false nếu không phải ID của phòng này.
export function draw(id: string, ctx: GC): boolean {
    switch (id) {
    // MARK: Tường & sàn (125×100)
    case "studyTheme.cream": { drawCream(ctx)
    } break; case "studyTheme.mint": { drawMint(ctx)
    } break; case "studyTheme.night": { drawNight(ctx)
    } break; case "studyTheme.sakura": { drawSakura(ctx)
    // MARK: Đồ mới
    } break; case "wall.corkboard": { drawCorkboard(ctx)
    } break; case "lamp.mushroom": { drawMushroomLamp(ctx)
    } break; case "desk.computer": { drawComputerDesk(ctx)
    } break; case "plant.bonsai": { drawBonsai(ctx)
    } break; case "seat.beanbag": { drawBeanbag(ctx)
    } break; default: { return false
    } }
    return true
}

// MARK: - Khung phòng dùng chung

// Cửa sổ chung vị trí: x 57.5…87.5, y 8…34.
const win = R(57.5, 8, 30, 26)

function floorPlanks(ctx: GC, base: Color, line: Color, top: number = 62) {
    ctx.rect(0, top, 125, 100 - top, base)
    const rows = [70.5, 80, 90.5]
    ctx.strokePath(line, 0.6, (p) => {
        for (const y of rows) {
            p.move(pt(0, y)); p.addLine(pt(125, y))
        }
        // mối nối ván so le
        const seams = [
            [34, top + 0.5, 70.5], [96, top + 0.5, 70.5],
            [12, 70.5, 80], [66, 70.5, 80], [116, 70.5, 80],
            [42, 80, 90.5], [98, 80, 90.5],
            [20, 90.5, 100], [74, 90.5, 100]
        ] as const
        for (const s of seams) {
            p.move(pt(s[0], s[1])); p.addLine(pt(s[0], s[2]))
        }
    })
}

function baseboard(ctx: GC, color: Color, highlight: Color) {
    ctx.rect(0, 59, 125, 3.5, color)
    ctx.rect(0, 59, 125, 0.7, highlight)
}

// Viền gỗ ngoài cửa sổ (vẽ trước kính).
function windowBase(ctx: GC, frame: Color) {
    ctx.rect(win.minX, win.minY, win.width, win.height, frame, 5)
}

// Song cửa + bậu cửa (vẽ sau nội dung kính).
function windowBars(ctx: GC, sill: Color, bar: Color) {
    const r = win
    ctx.rect(r.midX - 0.7, r.minY + 2, 1.4, r.height - 4, bar)
    ctx.rect(r.minX + 2, r.midY - 0.7, r.width - 4, 1.4, bar)
    ctx.rect(r.minX - 3, r.maxY - 1, r.width + 6, 3, sill, 1.5)
}

function glass(ctx: GC, color: Color) {
    ctx.rect(win.minX + 2.5, win.minY + 2.5, win.width - 5, win.height - 5, color, 2.5)
}

// Vùng kính để clip nội dung bên ngoài cửa sổ.
const glassPath = (
    Path.roundedRect(win.insetBy(2.5, 2.5), 2.5)
)

function glassShine(ctx: GC) {
    ctx.strokePath(Color.white.opacity(0.6), 1.2, (p) => {
        p.move(pt(61.5, 17)); p.addLine(pt(66, 12))
        p.move(pt(62, 21)); p.addLine(pt(64, 19))
    })
}

// Rèm hai bên + diềm lượn sóng phía trên.
function curtains(ctx: GC, color: Color, shade: Color, valance: Color) {
    const r = win
    for (const left of [true, false]) {
        const x0 = left ? r.minX - 3.5 : r.maxX + 3.5
        const dir = left ? 1 : -1
        let p = new Path()
        p.move(pt(x0, r.minY - 1))
        p.addLine(pt(x0 + dir * 10, r.minY - 1))
        p.addQuadCurve(pt(x0 + dir * 4.2, r.minY + 15), pt(x0 + dir * 9.5, r.minY + 10))
        p.addQuadCurve(pt(x0 + dir * 7, r.maxY + 1), pt(x0 + dir * 3, r.minY + 21))
        p.addLine(pt(x0, r.maxY + 1))
        p.closeSubpath()
        ctx.fill(p, (color))
        // dây buộc rèm
        ctx.rect(left ? x0 - 0.5 : x0 - 5.5, r.minY + 14, 6, 2, shade, 1)
        ctx.strokePath(shade, 0.6, (q) => {
            q.move(pt(x0 + dir * 2.4, r.minY + 1)); q.addLine(pt(x0 + dir * 2, r.minY + 13))
            q.move(pt(x0 + dir * 2.2, r.minY + 17)); q.addLine(pt(x0 + dir * 2.8, r.maxY))
        })
    }
    // diềm
    ctx.rect(r.minX - 4.5, r.minY - 3, r.width + 9, 3.6, valance, 1.5)
    let x = r.minX - 4.5
    while (x < r.maxX + 4) {
        ctx.ellipse(x, r.minY - 0.6, 4.3, 3, valance)
        x += 4.3
    }
}

// MARK: - Theme: Kem ấm (mặc định)

function drawCream(ctx: GC) {
    ctx.rect(0, 0, 125, 62, Palette.roomWall)
    // chấm nhỏ trên tường
    for (let row = 0; row < 5; row++) {
        for (let col = 0; col < 11; col++) {
            const x = (col) * 12 + (row % 2 == 0 ? 4 : 10)
            const y = (row) * 11 + 5
            if (x > 52 && x < 93 && y < 40) { continue }
            ctx.circle(x, y, 0.55, Palette.lavender.opacity(0.13))
        }
    }
    floorPlanks(ctx, Palette.roomFloor, Palette.woodDark.opacity(0.11))
    baseboard(ctx, Palette.wood.opacity(0.45), Color.white.opacity(0.35))
    windowBase(ctx, Palette.wood)
    glass(ctx, Palette.lavenderSoft)
    ctx.ellipse(73, 13, 9, 4, Color.white.opacity(0.7))
    ctx.ellipse(76, 11, 6, 4, Color.white.opacity(0.7))
    glassShine(ctx)
    windowBars(ctx, Palette.woodDark.opacity(0.85), Palette.wood)
    curtains(ctx, Palette.blush.opacity(0.55), Palette.peach.opacity(0.7), Palette.blush.opacity(0.75))
}

// MARK: - Theme: Sọc bạc hà

function drawMint(ctx: GC) {
    ctx.rect(0, 0, 125, 62, rgb(0xE6F4EC))
    let x = 0
    while (x < 125) {
        ctx.rect(x, 0, 6, 62, rgb(0xD3EBDD))
        x += 12
    }
    ctx.strokePath(Color.white.opacity(0.55), 0.5, (p) => {
        let sx = 9
        while (sx < 125) {
            p.move(pt(sx, 0)); p.addLine(pt(sx, 59))
            sx += 12
        }
    })
    floorPlanks(ctx, rgb(0xEBD5B7), rgb(0xB88D62).opacity(0.25))
    baseboard(ctx, rgb(0xFFFFFF).opacity(0.85), rgb(0xBFDCCB))
    windowBase(ctx, rgb(0xFFFFFF))
    glass(ctx, rgb(0xDDF0F7))
    ctx.ellipse(62, 23, 10, 5, Color.white.opacity(0.85))
    ctx.ellipse(65, 21, 6, 4, Color.white.opacity(0.85))
    ctx.circle(81, 13.5, 3, rgb(0xF6D58A))
    glassShine(ctx)
    windowBars(ctx, rgb(0xF4F8F5), rgb(0xFFFFFF))
    curtains(ctx, rgb(0xA9D5BC).opacity(0.85), rgb(0x7FB898), rgb(0x8EC7A8))
}

// MARK: - Theme: Đêm sao

function drawNight(ctx: GC) {
    ctx.rect(0, 0, 125, 62, rgb(0x34406A))
    // sao trên tường
    const stars = [
        [8, 8, 1.0], [22, 18, 0.7], [40, 6, 0.9], [48, 26, 0.6], [14, 34, 0.8], [34, 44, 0.6],
        [100, 10, 0.9], [112, 24, 0.7], [96, 36, 0.6], [118, 46, 0.8], [6, 50, 0.6], [50, 52, 0.7],
        [104, 52, 0.6], [30, 30, 0.5], [118, 6, 0.6]
    ] as const
    for (const s of stars) {
        ctx.circle(s[0], s[1], s[2], rgb(0xFFF1C2).opacity(0.75))
    }
    const big = [[28, 12], [108, 18], [20, 42], [52, 40]] as const
    for (const s of big) {
        ctx.text("✦", 5, rgb(0xF6D58A).opacity(0.85), pt(s[0], s[1]))
    }
    floorPlanks(ctx, rgb(0x5B4E6E), rgb(0x2E2640).opacity(0.35))
    // vệt sáng trăng trên sàn
    ctx.polygon([pt(60, 62), pt(86, 62), pt(96, 76), pt(66, 76)], rgb(0xC9D3FF).opacity(0.10))
    baseboard(ctx, rgb(0x262F52), rgb(0x5A6698).opacity(0.6))
    windowBase(ctx, rgb(0x8E6E57))
    glass(ctx, rgb(0x1F2650))
    // trăng khuyết
    ctx.circle(79, 16, 4.6, rgb(0xFBE7A6))
    ctx.circle(81.6, 14.4, 4.0, rgb(0x1F2650))
    ctx.circle(63, 13, 0.6, Color.white.opacity(0.85))
    ctx.circle(68, 27, 0.5, Color.white.opacity(0.8))
    ctx.circle(83, 28, 0.6, Color.white.opacity(0.8))
    ctx.text("✦", 3.6, Color.white.opacity(0.9), pt(66, 19))
    windowBars(ctx, rgb(0x6E523F), rgb(0x8E6E57))
    curtains(ctx, rgb(0x7B6FB8).opacity(0.9), rgb(0xF0C26A), rgb(0x6A5EA8))
}

// MARK: - Theme: Hoa anh đào

function petal(ctx: GC, x: number, y: number, s: number, angle: number, color: Color) {
    ctx.rotated(angle, pt(x, y), (c) => {
        c.ellipse(x - s, y - s * 0.55, s * 2, s * 1.1, color)
    })
}

function blossom(ctx: GC, cx: number, cy: number, r: number) {
    for (let i = 0; i < 5; i++) {
        const a = (i) * 72.0 * Math.PI / 180
        ctx.circle(cx + (Math.cos(a)) * r * 0.8, cy + (Math.sin(a)) * r * 0.8, r * 0.62, rgb(0xF7B9CB))
    }
    ctx.circle(cx, cy, r * 0.45, rgb(0xFCE1E8))
    ctx.circle(cx, cy, r * 0.2, rgb(0xE88AA5))
}

function drawSakura(ctx: GC) {
    ctx.rect(0, 0, 125, 62, rgb(0xFCEBEF))
    // họa tiết hoa nhỏ mờ
    for (let row = 0; row < 4; row++) {
        for (let col = 0; col < 7; col++) {
            const x = (col) * 19 + (row % 2 == 0 ? 6 : 15)
            const y = (row) * 14 + 7
            if (x > 50 && x < 95 && y < 40) { continue }
            for (let i = 0; i < 5; i++) {
                const a = (i) * 72.0 * Math.PI / 180
                ctx.circle(x + (Math.cos(a)) * 0.9, y + (Math.sin(a)) * 0.9, 0.6, rgb(0xF4C3D0).opacity(0.4))
            }
        }
    }
    floorPlanks(ctx, rgb(0xF0DCC6), rgb(0xC39C78).opacity(0.25))
    baseboard(ctx, rgb(0xEFC6D2), Color.white.opacity(0.5))
    windowBase(ctx, Palette.wood)
    glass(ctx, rgb(0xE4F0FA))
    const g = ctx.copy()
    g.clip(glassPath)
    g.strokePath(rgb(0x8B6A5A), 1.4, (p) => {
        p.move(pt(88, 12)); p.addQuadCurve(pt(66, 16), pt(76, 10))
        p.move(pt(76, 12)); p.addQuadCurve(pt(70, 24), pt(72, 17))
    })
    blossom(g, 67, 16, 2.4)
    blossom(g, 74, 11, 2.2)
    blossom(g, 70, 23.5, 2.2)
    blossom(g, 82, 14, 2.0)
    petal(g, 64, 28, 1.0, 30, rgb(0xF7B9CB))
    petal(g, 80, 26, 0.9, -20, rgb(0xF7B9CB))
    glassShine(ctx)
    windowBars(ctx, Palette.woodDark.opacity(0.85), Palette.wood)
    curtains(ctx, Color.white.opacity(0.85), rgb(0xF2A7BC), rgb(0xF6C2D0))
    // cánh hoa bay vào phòng
    const petals = [
        [98, 14, 1.3, 20], [104, 24, 1.1, -30], [112, 12, 1.0, 50], [96, 34, 1.2, 70],
        [50, 18, 1.1, -40], [44, 30, 1.0, 10], [118, 32, 1.1, -10], [108, 42, 0.9, 40]
    ] as const
    for (const p of petals) {
        petal(ctx, p[0], p[1], p[2], p[3], rgb(0xF4A9BE).opacity(0.85))
    }
    petal(ctx, 74, 70, 1.2, 15, rgb(0xF4A9BE).opacity(0.6))
    petal(ctx, 100, 82, 1.1, -25, rgb(0xF4A9BE).opacity(0.6))
}

// MARK: - Đồ mới

function drawCorkboard(ctx: GC) {
    ctx.rect(10, 20, 80, 60, Palette.woodDark, 5)
    ctx.rect(14, 24, 72, 52, rgb(0xDDB585), 3)
    // lỗ chấm vân bần
    const dots = [[20, 30], [34, 70], [48, 28], [62, 72], [80, 44], [22, 56], [56, 50], [78, 68], [40, 46]] as const
    for (const d of dots) { ctx.circle(d[0], d[1], 0.9, rgb(0xC09668)) }
    // ảnh polaroid 1 (đồi xanh)
    ctx.rotated(-8, pt(32, 44), (c) => {
        c.rect(21, 31, 22, 26, Color.white, 1.5)
        c.rect(23.5, 33.5, 17, 15, rgb(0xCFE6F4))
        let cc = c
        cc.clip(Path.rect(R(23.5, 33.5, 17, 15)))
        cc.ellipse(19, 42, 18, 12, Palette.sage)
        cc.ellipse(29, 44, 16, 10, rgb(0x8DB88F))
        c.circle(36.5, 37, 2.2, Palette.honey)
    })
    // ảnh polaroid 2 (trái tim)
    ctx.rotated(7, pt(60, 40), (c) => {
        c.rect(49, 28, 22, 25, Color.white, 1.5)
        c.rect(51.5, 30.5, 17, 14, rgb(0xFBE3EA))
        c.heart(pt(60, 37.5), 9, Palette.blush)
    })
    // giấy nhớ
    ctx.rotated(-5, pt(31, 66), (c) => {
        c.rect(23, 59, 16, 14, rgb(0xF8DC86), 1)
        c.rect(26, 63, 10, 1.2, Palette.catInk.opacity(0.35), 0.6)
        c.rect(26, 66.5, 7, 1.2, Palette.catInk.opacity(0.35), 0.6)
    })
    ctx.rotated(6, pt(76, 61), (c) => {
        c.rect(68, 54, 16, 14, rgb(0xBFE3CF), 1)
        c.strokePath(Palette.sage, 1.4, (p) => {
            p.move(pt(72, 61)); p.addLine(pt(75, 64)); p.addLine(pt(80, 58))
        })
    })
    ctx.rect(47, 58, 14, 12, rgb(0xF7C6D3), 1)
    ctx.text("♪", 7, Palette.catInk.opacity(0.45), pt(54, 64))
    // đinh ghim
    const pins = [
        [31, 31, Palette.peach], [60, 29.5, Palette.lavender], [31, 58.5, Palette.sage],
        [76, 54, Palette.blush], [54, 57.5, Palette.honey]
    ] as const
    for (const p of pins) {
        ctx.circle(p[0], p[1], 2, p[2])
        ctx.circle(p[0] - 0.6, p[1] - 0.6, 0.6, Color.white.opacity(0.7))
    }
    ctx.rect(15, 24.8, 70, 1, Color.white.opacity(0.25), 0.5)
}

function drawMushroomLamp(ctx: GC) {
    // quầng sáng
    ctx.circle(50, 44, 40, rgb(0xFFD98A).opacity(0.14))
    ctx.circle(50, 44, 31, rgb(0xFFD98A).opacity(0.16))
    // bóng đổ
    ctx.ellipse(26, 88, 48, 8, Color.black.opacity(0.1))
    // chân nấm
    let stem = new Path()
    stem.move(pt(40, 56))
    stem.addQuadCurve(pt(34, 90), pt(34, 76))
    stem.addQuadCurve(pt(66, 90), pt(50, 94))
    stem.addQuadCurve(pt(60, 56), pt(66, 76))
    stem.closeSubpath()
    ctx.fill(stem, (rgb(0xFBEFD9)))
    ctx.ellipse(40, 54, 20, 10, rgb(0xFFF6D6))
    ctx.rect(53, 64, 3, 20, Color.white.opacity(0.6), 1.5)
    // mũ nấm
    let cap = new Path()
    cap.move(pt(12, 58))
    cap.addCurve(pt(88, 58), pt(10, 14), pt(90, 14))
    cap.addQuadCurve(pt(12, 58), pt(50, 66))
    cap.closeSubpath()
    ctx.fill(cap, (rgb(0xE8736F)))
    // vành sáng dưới mũ
    let rim = new Path()
    rim.move(pt(14, 57))
    rim.addQuadCurve(pt(86, 57), pt(50, 66))
    rim.addQuadCurve(pt(14, 57), pt(50, 60))
    ctx.fill(rim, (rgb(0xFFE2A8)))
    // chấm bi
    ctx.ellipse(24, 40, 12, 9, rgb(0xFFF6EE))
    ctx.ellipse(44, 26, 13, 9, rgb(0xFFF6EE))
    ctx.ellipse(64, 38, 14, 10, rgb(0xFFF6EE))
    ctx.ellipse(76, 50, 7, 5, rgb(0xFFF6EE))
    ctx.ellipse(36, 50, 7, 5, rgb(0xFFF6EE))
    ctx.strokePath(Color.white.opacity(0.55), 2.4, (p) => {
        p.move(pt(22, 32)); p.addQuadCurve(pt(32, 24), pt(24, 26))
    })
    // tia sáng nhỏ
    ctx.text("✦", 8, Palette.honey, pt(86, 22))
    ctx.text("✦", 5, Palette.honey.opacity(0.8), pt(12, 30))
}

function drawComputerDesk(ctx: GC) {
    const top = rgb(0xF4EEE6)
    const side = rgb(0xE2D6C8)
    // màn hình
    ctx.rect(46, 30, 8, 7, Palette.catShade, 1)
    ctx.ellipse(37, 35, 26, 6, Palette.catShade)
    ctx.rect(20, 2, 60, 30, rgb(0xFBF4E8), 6)
    ctx.rect(25, 6, 50, 22, rgb(0x6F86C7), 3)
    // nội dung màn hình: cửa sổ nhỏ + tim
    ctx.rect(28, 9, 26, 15, rgb(0xEAF0FF), 1.5)
    ctx.rect(28, 9, 26, 3, rgb(0xB7C6F0), 1.5)
    ctx.rect(30, 14.5, 14, 1.4, rgb(0x6F86C7).opacity(0.6), 0.7)
    ctx.rect(30, 17.5, 18, 1.4, rgb(0x6F86C7).opacity(0.6), 0.7)
    ctx.rect(30, 20.5, 10, 1.4, rgb(0x6F86C7).opacity(0.6), 0.7)
    ctx.heart(pt(64, 16), 9, Palette.blush)
    ctx.strokePath(Color.white.opacity(0.35), 1.6, (p) => {
        p.move(pt(66, 25)); p.addLine(pt(72, 19))
    })
    // sticker trên viền màn hình
    ctx.rotated(-15, pt(23, 6), (c) => {
        c.text("★", 9, Palette.honey, pt(23, 6))
    })
    ctx.circle(76.5, 29, 3.2, Palette.sage)
    ctx.circle(76.5, 29, 1.3, Color.white.opacity(0.8))
    ctx.heart(pt(24, 28.5), 6, Palette.peach)
    ctx.rect(71, 2.5, 8, 4, Palette.lavender, 2)
    ctx.circle(49.5, 30.2, 0.8, Palette.sage)
    // cốc
    ctx.rect(78, 30, 9, 10, Palette.lavender, 2)
    ctx.strokePath(Palette.lavender, 1.6, (p) => {
        p.addEllipse(R(85, 32.5, 5, 5))
    })
    ctx.strokePath(Color.white.opacity(0.7), 1, (p) => {
        p.move(pt(81, 27)); p.addQuadCurve(pt(82, 22), pt(79, 25))
    })
    // bàn phím + chuột
    ctx.rect(26, 37, 34, 3.4, rgb(0xFFFFFF), 1.5)
    ctx.rect(28, 37.8, 30, 0.8, Palette.catShade, 0.4)
    ctx.ellipse(64, 36.6, 6, 3.6, rgb(0xFFFFFF))
    // mặt bàn + chân (giống bàn cũ: mặt 40…49, chân tới 91)
    ctx.rect(8, 40, 84, 9, top, 3)
    ctx.rect(8, 40, 84, 2, Color.white.opacity(0.6), 1)
    ctx.rect(14, 49, 6, 42, side, 2)
    ctx.rect(56, 49, 30, 42, side, 2)
    ctx.rect(59, 53, 24, 16, top, 2)
    ctx.rect(59, 72, 24, 16, top, 2)
    ctx.rect(67, 59.5, 8, 2.4, Palette.lavender, 1.2)
    ctx.rect(67, 78.5, 8, 2.4, Palette.lavender, 1.2)
}

function drawBonsai(ctx: GC) {
    ctx.ellipse(18, 89, 64, 8, Color.black.opacity(0.1))
    // chậu thấp
    ctx.polygon([pt(18, 76), pt(82, 76), pt(76, 92), pt(24, 92)], rgb(0x7E9CC4))
    ctx.rect(14, 73, 72, 6, rgb(0x93B0D4), 3)
    ctx.rect(28, 92, 8, 3, rgb(0x5F7EA6), 1)
    ctx.rect(64, 92, 8, 3, rgb(0x5F7EA6), 1)
    ctx.rect(24, 82, 14, 1.6, Color.white.opacity(0.45), 0.8)
    // đất rêu
    ctx.ellipse(20, 70, 60, 7, rgb(0x8DB88F))
    // thân cây uốn
    ctx.strokePath(rgb(0x8A6448), 7, (p) => {
        p.move(pt(52, 74))
        p.addCurve(pt(46, 40), pt(40, 62), pt(62, 52))
    })
    ctx.strokePath(rgb(0x8A6448), 3.5, (p) => {
        p.move(pt(49, 54)); p.addQuadCurve(pt(26, 48), pt(36, 56))
        p.move(pt(52, 46)); p.addQuadCurve(pt(72, 38), pt(64, 46))
    })
    // tán lá dạng mây
    function pad(x: number, y: number, w: number, h: number) {
        ctx.ellipse(x, y, w, h, Palette.sage)
        ctx.ellipse(x + w * 0.15, y - h * 0.25, w * 0.45, h * 0.8, Palette.sage)
        ctx.ellipse(x + w * 0.45, y - h * 0.3, w * 0.42, h * 0.85, Palette.sage)
        ctx.ellipse(x + w * 0.22, y - h * 0.1, w * 0.4, h * 0.42, rgb(0x9CC39E))
    }
    pad(10, 42, 28, 11)
    pad(60, 32, 30, 11)
    pad(30, 26, 36, 13)
    // điểm sáng
    ctx.circle(40, 23, 1.6, Color.white.opacity(0.55))
    ctx.circle(68, 29, 1.3, Color.white.opacity(0.55))
    // viên đá nhỏ
    ctx.ellipse(62, 69, 9, 5, rgb(0xD8D2CC))
}

function drawBeanbag(ctx: GC) {
    const main = rgb(0xF4C978)
    const shade = rgb(0xE5B25E)
    ctx.ellipse(6, 86, 88, 10, Color.black.opacity(0.1))
    // thân ghế lười
    let body = new Path()
    body.move(pt(12, 90))
    body.addCurve(pt(34, 42), pt(2, 72), pt(12, 46))
    body.addCurve(pt(72, 40), pt(46, 30), pt(62, 30))
    body.addCurve(pt(88, 90), pt(90, 50), pt(98, 74))
    body.addQuadCurve(pt(12, 90), pt(50, 96))
    body.closeSubpath()
    ctx.fill(body, (main))
    // lõm chỗ ngồi
    ctx.ellipse(22, 58, 56, 22, shade.opacity(0.6))
    ctx.ellipse(26, 56, 48, 18, main)
    // đường may
    ctx.strokePath(shade, 1.4, (p) => {
        p.move(pt(50, 36)); p.addQuadCurve(pt(44, 54), pt(44, 44))
        p.move(pt(18, 78)); p.addQuadCurve(pt(30, 92), pt(20, 88))
        p.move(pt(82, 78)); p.addQuadCurve(pt(72, 92), pt(80, 88))
    })
    // nhãn nhỏ
    ctx.rect(70, 70, 9, 6, Palette.peach, 1.5)
    ctx.heart(pt(74.5, 73), 3.5, Color.white.opacity(0.85))
    // điểm sáng
    ctx.strokePath(Color.white.opacity(0.55), 3, (p) => {
        p.move(pt(20, 66)); p.addQuadCurve(pt(30, 48), pt(20, 54))
    })
    ctx.circle(62, 40, 1.8, Color.white.opacity(0.6))
}

export const StudyArt = { draw }
