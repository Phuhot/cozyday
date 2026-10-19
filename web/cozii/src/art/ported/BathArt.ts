// Chuyển tự động từ Swift (scripts/port/swift2ts.mjs) rồi sửa tay.
import { GC, Color, rgb, pt, R, Path, deg, Pt, Rect, linear, radial } from '../gc'
import { Palette } from '../palette'

// Hình vẽ đồ trong phòng tắm. Trả về false nếu không phải ID của phòng này.
export function draw(id: string, ctx: GC): boolean {
    switch (id) {
    // MARK: Tường & sàn (125×100)
    case "bathTheme.aqua": { drawAqua(ctx)
    } break; case "bathTheme.pink": { drawPink(ctx)
    } break; case "bathTheme.ocean": { drawOcean(ctx)
    } break; case "bathTheme.marble": { drawMarble(ctx)
    // MARK: Bồn tắm
    } break; case "tub.basin": { drawTubBasin(ctx)
    } break; case "tub.shower": { drawShower(ctx)
    } break; case "tub.claw": { drawClawTub(ctx)
    } break; case "tub.bubble": { drawBubbleTub(ctx)
    // MARK: Bồn rửa
    } break; case "sink.basic": { drawSink(ctx, rgb(0xFFFFFF), rgb(0xDDE7EC))
    } break; case "sink.mirror": { 
        drawRoundMirror(ctx)
        drawSink(ctx, rgb(0xFFFFFF), rgb(0xDDE7EC))
    } break; case "sink.shell": { 
        drawShellMirror(ctx)
        drawShellSink(ctx)
    // MARK: Kệ
    } break; case "bathShelf.towels": { drawTowelShelf(ctx)
    } break; case "bathShelf.bottles": { drawBottleShelf(ctx)
    } break; case "bathShelf.fern": { drawFernShelf(ctx)
    // MARK: Thảm
    } break; case "bathMat.basic": { drawMatBasic(ctx)
    } break; case "bathMat.duck": { drawMatDuck(ctx)
    } break; case "bathMat.wave": { drawMatWave(ctx)
    // MARK: Đồ chơi
    } break; case "bathToy.duck": { drawRubberDuck(ctx)
    } break; case "bathToy.boat": { drawBoat(ctx)
    } break; case "bathToy.bubbles": { drawBubbles(ctx)
    } break; case "bathToy.whale": { drawWhale(ctx)
    } break; default: { return false
    } }
    return true
}

// MARK: - Màu dùng chung

const porcelain = rgb(0xFFFFFF)
const porcelainShade = rgb(0xDCE6EC)
const chrome = rgb(0xC6D2DA)
const chromeDark = rgb(0xA3B3BF)
const duckYellow = rgb(0xF8D35E)
const duckShade = rgb(0xEDB840)
const beak = rgb(0xF29A5B)

// MARK: - Khung phòng dùng chung

// Cửa sổ nhỏ chung vị trí: x 54…76, y 8…28.
const win = R(54, 8, 22, 20)

function wallTiles(ctx: GC, base: Color, grout: Color, w: number, h: number, top: number = 0, bottom: number = 62) {
    ctx.rect(0, top, 125, bottom - top, base)
    ctx.strokePath(grout, 0.6, (p) => {
        let y = top + h
        while (y < bottom) {
            p.move(pt(0, y)); p.addLine(pt(125, y))
            y += h
        }
        let x = w
        while (x < 125) {
            p.move(pt(x, top)); p.addLine(pt(x, bottom))
            x += w
        }
    })
}

// Điểm sáng nhỏ ở góc vài viên gạch.
function tileShine(ctx: GC, w: number, h: number, top: number, bottom: number) {
    let row = 0
    let y = top
    while (y + h <= bottom + 0.1) {
        let col = 0
        let x = 0
        while (x + w <= 125.1) {
            if ((row * 3 + col * 2) % 5 == 0) {
                ctx.rect(x + 1.2, y + 1.2, w * 0.28, 0.8, Color.white.opacity(0.55), 0.4)
            }
            x += w
            col += 1
        }
        y += h
        row += 1
    }
}

function floorChecker(ctx: GC, a: Color, b: Color, grout: Color) {
    ctx.rect(0, 62, 125, 38, a)
    const tw = 12.5
    const rows = [[62, 8], [70, 9], [79, 10], [89, 11]] as const
    for (const [i, r] of rows.entries()) {
        for (let col = 0; col < 10; col++) { if (!((col + i) % 2 == 0)) continue;
            ctx.rect((col) * tw, r[0], tw, r[1], b)
        }
    }
    ctx.strokePath(grout, 0.5, (p) => {
        for (const r of rows) {
            p.move(pt(0, r[0])); p.addLine(pt(125, r[0]))
        }
    })
}

function baseboard(ctx: GC, color: Color) {
    ctx.rect(0, 59.5, 125, 3, color)
    ctx.rect(0, 59.5, 125, 0.7, Color.white.opacity(0.5))
}

function band(ctx: GC, y: number, color: Color, dot: Color) {
    ctx.rect(0, y, 125, 3.2, color)
    let x = 3
    while (x < 125) {
        ctx.circle(x, y + 1.6, 0.7, dot)
        x += 6
    }
}

// Cửa sổ vuông: khung, kính trời, nửa dưới kính mờ, song dọc.
function squareWindow(ctx: GC, frame: Color, sky: Color, sill: Color) {
    const r = win
    ctx.rect(r.minX, r.minY, r.width, r.height, frame, 4)
    ctx.rect(r.minX + 2.2, r.minY + 2.2, r.width - 4.4, r.height - 4.4, sky, 2.2)
    ctx.ellipse(r.minX + 4, r.minY + 5, 8, 3.4, Color.white.opacity(0.85))
    ctx.ellipse(r.minX + 6, r.minY + 3.8, 5, 3, Color.white.opacity(0.85))
    // kính mờ nửa dưới
    ctx.rect(r.minX + 2.2, r.midY, r.width - 4.4, r.height / 2 - 2.2, Color.white.opacity(0.55), 1.5)
    for (let i = 0; i < 4; i++) {
        ctx.circle(r.minX + 5 + (i) * 4, r.midY + 4, 0.6, Color.white.opacity(0.9))
    }
    ctx.rect(r.midX - 0.7, r.minY + 2, 1.4, r.height - 4, frame)
    ctx.rect(r.minX + 2, r.midY - 0.7, r.width - 4, 1.4, frame)
    ctx.rect(r.minX - 2.5, r.maxY - 1, r.width + 5, 2.6, sill, 1.3)
    // chậu cây nhỏ trên bậu cửa
    ctx.rect(r.maxX - 7, r.maxY - 5, 4.4, 4, rgb(0xE59A7A), 1)
    ctx.ellipse(r.maxX - 8, r.maxY - 8.5, 3.6, 4.4, Palette.sage)
    ctx.ellipse(r.maxX - 5.4, r.maxY - 9.5, 3.6, 5, Palette.sage)
}

// MARK: - Theme: Gạch xanh nước (mặc định)

function drawAqua(ctx: GC) {
    wallTiles(ctx, rgb(0xDFF2F2), rgb(0xC3E2E4).opacity(0.75), 10.42, 10, 0, 62)
    tileShine(ctx, 10.42, 10, 0, 60)
    band(ctx, 38.4, rgb(0x9FD3D6), Color.white.opacity(0.8))
    floorChecker(ctx, rgb(0xE8F3F2), rgb(0xCDE6E6), rgb(0xB7D8D9).opacity(0.6))
    baseboard(ctx, rgb(0xA9D7DA))
    squareWindow(ctx, rgb(0xFFFFFF), rgb(0xCBE9F5), rgb(0xF4FAFA))
}

// MARK: - Theme: Gạch hồng

function drawPink(ctx: GC) {
    wallTiles(ctx, rgb(0xFCE8ED), rgb(0xF2D0DA).opacity(0.8), 10.42, 10, 0, 62)
    tileShine(ctx, 10.42, 10, 0, 60)
    band(ctx, 38.4, rgb(0xF4B8C8), Color.white.opacity(0.85))
    // tim nhỏ lác đác
    const hearts = [[15.6, 15], [36.5, 25], [98.9, 15], [109.4, 45], [26, 55], [88.5, 55], [46.9, 5]] as const
    for (const h of hearts) {
        ctx.heart(pt(h[0], h[1]), 3, rgb(0xF4B8C8).opacity(0.7))
    }
    floorChecker(ctx, rgb(0xFFF6F7), rgb(0xF6D9E0), rgb(0xEBC3CD).opacity(0.6))
    baseboard(ctx, rgb(0xEFB3C3))
    squareWindow(ctx, rgb(0xFFFFFF), rgb(0xD6EBF7), rgb(0xFFF7F9))
}

// MARK: - Theme: Đại dương

function drawOcean(ctx: GC) {
    ctx.rect(0, 0, 125, 62, rgb(0xE2F3FA))
    // hai lớp sóng
    function wave(y: number, color: Color) {
        let p = new Path()
        p.move(pt(0, 62))
        p.addLine(pt(0, y))
        let x = 0
        while (x < 125) {
            p.addQuadCurve(pt(x + 8, y), pt(x + 4, y - 4))
            p.addQuadCurve(pt(x + 16, y), pt(x + 12, y + 3))
            x += 16
        }
        p.addLine(pt(125, 62))
        p.closeSubpath()
        ctx.fill(p, (color))
    }
    wave(34, rgb(0xB5DEEE))
    wave(44, rgb(0x93CDE5))
    ctx.strokePath(Color.white.opacity(0.6), 0.8, (p) => {
        let x = 0
        while (x < 125) {
            p.move(pt(x + 1.5, 33)); p.addQuadCurve(pt(x + 6.5, 32.5), pt(x + 4, 30.6))
            x += 16
        }
    })
    // bong bóng
    const bubbles = [
        [10, 12, 2.4], [16, 22, 1.4], [30, 8, 1.8], [40, 18, 2.6], [92, 10, 2.2], [104, 20, 1.6],
        [116, 8, 2.8], [112, 30, 1.4], [22, 40, 1.8], [50, 50, 2.2], [86, 46, 1.6], [106, 54, 2.4], [8, 54, 1.4]
    ] as const
    for (const b of bubbles) {
        ctx.circle(b[0], b[1], b[2], Color.white.opacity(0.35))
        ctx.strokePath(Color.white.opacity(0.9), 0.5, (p) => {
            p.addEllipse(R(b[0] - b[2], b[1] - b[2], b[2] * 2, b[2] * 2))
        })
        ctx.circle(b[0] - b[2] * 0.35, b[1] - b[2] * 0.35, b[2] * 0.28, Color.white.opacity(0.9))
    }
    floorChecker(ctx, rgb(0xD8ECF3), rgb(0xBFDFEC), rgb(0xA7CFE0).opacity(0.6))
    baseboard(ctx, rgb(0x7DBBD6))
    // cửa sổ tròn kiểu tàu thủy
    const c = pt(win.midX, win.midY)
    ctx.circle(c.x, c.y, 10.5, rgb(0xE0B866))
    ctx.circle(c.x, c.y, 8.2, rgb(0xBFE5F5))
    const g = ctx.copy()
    g.clip(Path.ellipse(R(c.x - 8.2, c.y - 8.2, 16.4, 16.4)))
    g.rect(c.x - 9, c.y + 2, 18, 8, rgb(0x6FB5D6))
    g.strokePath(Color.white.opacity(0.8), 0.7, (p) => {
        p.move(pt(c.x - 7, c.y + 4)); p.addQuadCurve(pt(c.x - 2, c.y + 4), pt(c.x - 4.5, c.y + 2.6))
        p.move(pt(c.x + 1, c.y + 6)); p.addQuadCurve(pt(c.x + 6, c.y + 6), pt(c.x + 3.5, c.y + 4.6))
    })
    g.ellipse(c.x - 5, c.y - 5, 7, 3, Color.white.opacity(0.9))
    ctx.strokePath(Color.white.opacity(0.7), 1, (p) => {
        p.addArc(c, 6.5, deg(200), deg(250), false)
    })
    for (let i = 0; i < 8; i++) {
        const a = (i) * 45.0 * Math.PI / 180
        ctx.circle(c.x + (Math.cos(a)) * 9.4, c.y + (Math.sin(a)) * 9.4, 0.55, rgb(0xB48A3E))
    }
}

// MARK: - Theme: Đá cẩm thạch

function drawMarble(ctx: GC) {
    wallTiles(ctx, rgb(0xF7F4F1), rgb(0xE4DDD6), 25, 20.67, 0, 62)
    const vein = rgb(0xC9C0BA).opacity(0.55)
    ctx.strokePath(vein, 0.5, (p) => {
        p.move(pt(2, 4)); p.addCurve(pt(22, 18), pt(10, 6), pt(12, 16))
        p.move(pt(28, 30)); p.addCurve(pt(48, 38), pt(36, 26), pt(40, 40))
        p.move(pt(80, 2)); p.addCurve(pt(98, 16), pt(86, 10), pt(92, 8))
        p.move(pt(102, 26)); p.addCurve(pt(122, 38), pt(110, 32), pt(116, 28))
        p.move(pt(4, 46)); p.addCurve(pt(22, 58), pt(12, 44), pt(14, 56))
        p.move(pt(78, 44)); p.addCurve(pt(96, 56), pt(84, 52), pt(90, 46))
        p.move(pt(54, 46)); p.addQuadCurve(pt(70, 58), pt(66, 48))
    })
    ctx.strokePath(vein.opacity(0.6), 0.3, (p) => {
        p.move(pt(12, 8)); p.addLine(pt(8, 14))
        p.move(pt(38, 32)); p.addLine(pt(36, 38))
        p.move(pt(110, 31)); p.addLine(pt(114, 36))
    })
    // viền vàng
    ctx.rect(0, 41, 125, 1.6, rgb(0xE2C27A))
    // sàn đá
    ctx.rect(0, 62, 125, 38, rgb(0xEAE5DF))
    ctx.strokePath(rgb(0xD6CEC6), 0.6, (p) => {
        p.move(pt(0, 76)); p.addLine(pt(125, 76))
        p.move(pt(0, 91)); p.addLine(pt(125, 91))
        for (const x of [31.0, 62.5, 94.0]) {
            p.move(pt(x, 62)); p.addLine(pt(x, 76))
        }
        for (const x of [15.0, 47.0, 78.0, 110.0]) {
            p.move(pt(x, 76)); p.addLine(pt(x, 91))
        }
        for (const x of [31.0, 62.5, 94.0]) {
            p.move(pt(x, 91)); p.addLine(pt(x, 100))
        }
    })
    ctx.strokePath(vein, 0.5, (p) => {
        p.move(pt(4, 66)); p.addCurve(pt(26, 72), pt(12, 64), pt(16, 74))
        p.move(pt(52, 80)); p.addCurve(pt(74, 88), pt(60, 78), pt(64, 90))
        p.move(pt(98, 64)); p.addQuadCurve(pt(120, 72), pt(110, 64))
    })
    baseboard(ctx, rgb(0xDCCFBF))
    ctx.rect(0, 59.5, 125, 0.8, rgb(0xE2C27A))
    // cửa sổ vòm viền vàng
    const r = win
    let arch = new Path()
    arch.move(pt(r.minX, r.maxY))
    arch.addLine(pt(r.minX, r.minY + r.width / 2))
    arch.addArc(pt(r.midX, r.minY + r.width / 2), r.width / 2, deg(180), deg(0), false)
    arch.addLine(pt(r.maxX, r.maxY))
    arch.closeSubpath()
    ctx.fill(arch, (rgb(0xE2C27A)))
    const inR = r.width / 2 - 2
    let glassP = new Path()
    glassP.move(pt(r.minX + 2, r.maxY - 1))
    glassP.addLine(pt(r.minX + 2, r.minY + r.width / 2))
    glassP.addArc(pt(r.midX, r.minY + r.width / 2), inR, deg(180), deg(0), false)
    glassP.addLine(pt(r.maxX - 2, r.maxY - 1))
    glassP.closeSubpath()
    ctx.fill(glassP, (rgb(0xDCEEF6)))
    ctx.ellipse(r.minX + 4, r.minY + 9, 8, 3.2, Color.white.opacity(0.9))
    ctx.rect(r.midX - 0.6, r.minY + 2, 1.2, r.height - 3, rgb(0xE2C27A))
    ctx.rect(r.minX + 2, r.minY + 13, r.width - 4, 1.2, rgb(0xE2C27A))
    ctx.rect(r.minX - 2.5, r.maxY - 1, r.width + 5, 2.6, rgb(0xF4EFEA), 1.3)
    // nến thơm trên bậu
    ctx.rect(r.minX + 1, r.maxY - 5, 4, 4, rgb(0xFFF8EC), 0.8)
    ctx.ellipse(r.minX + 2.3, r.maxY - 8, 1.6, 2.6, Palette.honey)
}

// MARK: - Bồn tắm (ô 60, đáy ~94)

function steam(ctx: GC, xs: number[], top: number, bottom: number) {
    ctx.strokePath(Color.white.opacity(0.85), 2.4, (p) => {
        for (const x of xs) {
            p.move(pt(x, bottom))
            p.addCurve(pt(x, top), pt(x - 6, bottom - (bottom - top) * 0.35), pt(x + 6, bottom - (bottom - top) * 0.65))
        }
    })
}

function drawTubBasin(ctx: GC) {
    const wood = rgb(0xDDB485)
    const woodLine = rgb(0xB98A5C)
    ctx.ellipse(8, 86, 84, 10, Color.black.opacity(0.1))
    steam(ctx, [34, 50, 66], 20, 42)
    // thân chậu tròn
    let body = new Path()
    body.move(pt(12, 52))
    body.addLine(pt(16, 84))
    body.addQuadCurve(pt(84, 84), pt(50, 96))
    body.addLine(pt(88, 52))
    body.closeSubpath()
    ctx.fill(body, (wood))
    const g = ctx.copy()
    g.clip(body)
    g.strokePath(woodLine.opacity(0.5), 0.8, (p) => {
        for (let x = 21.0; x < 85.0; x += 9.0) {
            p.move(pt((x), 50)); p.addLine(pt((x) + ((x) - 50) * 0.06, 96))
        }
    })
    // đai
    g.strokePath(rgb(0x8C6B4E), 3, (p) => {
        p.move(pt(10, 62)); p.addQuadCurve(pt(90, 62), pt(50, 70))
        p.move(pt(10, 80)); p.addQuadCurve(pt(90, 80), pt(50, 89))
    })
    g.rect(16, 54, 3, 30, Color.white.opacity(0.25), 1.5)
    // miệng chậu + nước
    ctx.ellipse(10, 44, 80, 16, rgb(0xE9C79C))
    ctx.ellipse(15, 47, 70, 11, rgb(0x9ED8E2))
    ctx.ellipse(26, 48.5, 18, 3.4, Color.white.opacity(0.6))
    ctx.circle(68, 51, 1.5, Color.white.opacity(0.7))
    // khăn nhỏ vắt miệng chậu
    ctx.rect(62, 44, 12, 12, Palette.blush, 2)
    ctx.rect(62, 49, 12, 1.4, Color.white.opacity(0.7))
    // gáo/xô gỗ nhỏ
    ctx.ellipse(76, 89, 20, 5, Color.black.opacity(0.08))
    ctx.rect(78, 74, 16, 17, wood, 3)
    ctx.rect(77, 72, 18, 4, rgb(0xE9C79C), 2)
    ctx.rect(78, 82, 16, 2, rgb(0x8C6B4E))
    ctx.strokePath(rgb(0x8C6B4E), 1.6, (p) => {
        p.move(pt(80, 73)); p.addQuadCurve(pt(92, 73), pt(86, 62))
    })
}

function drawShower(ctx: GC) {
    // ống & vòi sen
    ctx.rect(84, 12, 3.4, 60, chrome, 1.7)
    ctx.strokePath(chrome, 3.4, (p) => {
        p.move(pt(85.7, 13)); p.addQuadCurve(pt(72, 14), pt(84, 6))
    })
    ctx.polygon([pt(64, 16), pt(78, 16), pt(75, 13), pt(67, 13)], chromeDark)
    ctx.ellipse(63, 15, 16, 4, chrome)
    // giọt nước
    for (const [i, x] of [65.0, 69.0, 73.0, 77.0].entries()) {
        const y = 23.0 + (i % 2) * 6
        ctx.ellipse((x) - 0.8, (y), 1.6, 3, rgb(0x8FCDE6))
        ctx.ellipse((x) - 0.4 + 1.5, (y) + 10, 1.6, 3, rgb(0x8FCDE6))
    }
    // bồn đứng (khay)
    ctx.ellipse(6, 86, 88, 10, Color.black.opacity(0.1))
    // thanh rèm
    ctx.rect(8, 6, 84, 2.6, chromeDark, 1.3)
    // rèm chấm bi (kéo sang trái)
    let cur = new Path()
    cur.move(pt(10, 8))
    cur.addLine(pt(52, 8))
    cur.addQuadCurve(pt(46, 72), pt(44, 40))
    let x = 46
    while (x > 12) {
        cur.addQuadCurve(pt(x - 7, 72), pt(x - 3.5, 76))
        x -= 7
    }
    cur.addLine(pt(10, 72))
    cur.closeSubpath()
    ctx.fill(cur, (rgb(0xFFFDF8)))
    const g = ctx.copy()
    g.clip(cur)
    g.strokePath(rgb(0xE6E0EA), 1, (p) => {
        for (const fx of [18.0, 27.0, 36.0]) {
            p.move(pt(fx, 10)); p.addQuadCurve(pt(fx - 2, 72), pt(fx + 2, 40))
        }
    })
    const dots = [Palette.blush, rgb(0x8FCDE6), Palette.honey]
    let k = 0
    for (let row = 0; row < 7; row++) {
        for (let col = 0; col < 5; col++) {
            const dx = row % 2 == 0 ? 0 : 4.5
            g.circle(15 + (col) * 9 + dx, 15 + (row) * 9, 2, dots[k % 3])
            k += 1
        }
    }
    // khoen treo
    for (const rx of [12.0, 22.0, 32.0, 42.0, 50.0]) {
        ctx.strokePath(chromeDark, 0.9, (p) => (p.addEllipse(R(rx - 1.6, 5, 3.2, 4.4))))
    }
    // bồn tắm phía dưới
    ctx.rect(6, 66, 88, 6, porcelain, 3)
    ctx.rect(9, 70, 82, 20, porcelain, 8)
    ctx.rect(9, 82, 82, 8, porcelainShade, 6)
    ctx.rect(14, 73, 30, 2, rgb(0x8FCDE6).opacity(0.6), 1)
    ctx.rect(14, 89, 8, 5, chromeDark, 1.5)
    ctx.rect(78, 89, 8, 5, chromeDark, 1.5)
    ctx.rect(12, 67, 30, 1.4, Color.white.opacity(0.9), 0.7)
}

function clawTubBody(ctx: GC, color: Color, shade: Color, feet: boolean) {
    ctx.ellipse(6, 86, 88, 10, Color.black.opacity(0.1))
    let body = new Path()
    body.move(pt(8, 50))
    body.addCurve(pt(30, 86), pt(8, 74), pt(16, 86))
    body.addLine(pt(70, 86))
    body.addCurve(pt(92, 50), pt(84, 86), pt(92, 74))
    body.closeSubpath()
    if (feet) {
        for (const fx of [22.0, 70.0]) {
            ctx.rect(fx, 82, 8, 9, rgb(0xE2C27A), 3)
            ctx.ellipse(fx - 1.5, 89, 11, 5, rgb(0xD4AE5E))
        }
    }
    ctx.fill(body, (color))
    const g = ctx.copy()
    g.clip(body)
    g.ellipse(4, 72, 92, 24, shade)
    g.strokePath(Color.white.opacity(0.8), 2.4, (p) => {
        p.move(pt(16, 56)); p.addQuadCurve(pt(24, 76), pt(16, 70))
    })
    ctx.rect(4, 46, 92, 7, color, 3.5)
    ctx.rect(8, 47, 84, 2, shade.opacity(0.8), 1)
}

function drawClawTub(ctx: GC) {
    // vòi
    ctx.rect(83, 30, 3.4, 18, chrome, 1.7)
    ctx.strokePath(chrome, 3.4, (p) => {
        p.move(pt(84.7, 31)); p.addQuadCurve(pt(74, 36), pt(82, 24))
    })
    ctx.circle(80, 40, 2.4, chromeDark)
    ctx.circle(90, 40, 2.4, chromeDark)
    clawTubBody(ctx, porcelain, porcelainShade, true)
    // vài bong bóng nhỏ
    ctx.circle(30, 43, 4, Color.white)
    ctx.circle(37, 41, 5, Color.white)
    ctx.circle(44, 44, 3.4, Color.white)
    ctx.strokePath(rgb(0xBFE3EF), 0.8, (p) => {
        p.addEllipse(R(26, 39, 8, 8))
        p.addEllipse(R(32, 36, 10, 10))
    })
    ctx.strokePath(rgb(0xA9D7E6), 0.8, (p) => {
        p.addEllipse(R(48, 28, 5, 5))
    })
}

function drawBubbleTub(ctx: GC) {
    const pink = rgb(0xF7C6D3)
    const pinkShade = rgb(0xEBA9BC)
    clawTubBody(ctx, pink, pinkShade, true)
    // bọt tràn
    const foam = [
        [10, 46, 7], [20, 40, 9], [32, 36, 10], [46, 34, 11], [60, 36, 10], [72, 39, 9], [84, 44, 8], [92, 48, 5],
        [26, 46, 7], [40, 44, 8], [54, 44, 8], [68, 46, 7], [40, 28, 6], [56, 26, 7]
    ] as const
    for (const f of foam) {
        ctx.circle(f[0], f[1], f[2], rgb(0xFFFFFF))
    }
    // bọt chảy xuống thành bồn
    ctx.rect(6, 48, 8, 16, Color.white, 4)
    ctx.circle(10, 66, 4, Color.white)
    ctx.rect(84, 48, 7, 10, Color.white, 3.5)
    ctx.circle(87.5, 59, 3.5, Color.white)
    ctx.rect(56, 50, 6, 8, Color.white, 3)
    // bóng nhẹ trên bọt
    for (const f of [[32.0, 36.0, 10.0], [60.0, 36.0, 10.0], [20.0, 40.0, 9.0]]) {
        ctx.circle(f[0] + f[2] * 0.25, f[1] + f[2] * 0.3, f[2] * 0.45, rgb(0xEAF4F8))
    }
    // bong bóng bay
    const bubbles = [
        [18, 18, 5, rgb(0xBFE3EF)], [32, 8, 3.4, rgb(0xF4B8C8)], [74, 16, 6, rgb(0xCDBDF0)],
        [88, 28, 3.6, rgb(0xBFE3EF)], [60, 10, 2.6, rgb(0xF6D58A)]
    ] as const
    for (const b of bubbles) {
        ctx.circle(b[0], b[1], b[2], b[3].opacity(0.3))
        ctx.strokePath(b[3], 1, (p) => {
            p.addEllipse(R(b[0] - b[2], b[1] - b[2], b[2] * 2, b[2] * 2))
        })
        ctx.circle(b[0] - b[2] * 0.35, b[1] - b[2] * 0.35, b[2] * 0.3, Color.white.opacity(0.9))
    }
    // vịt nhỏ trên bọt
    ctx.ellipse(66, 25, 14, 10, duckYellow)
    ctx.circle(70, 23, 5, duckYellow)
    ctx.ellipse(64.5, 22.6, 4, 2.4, beak)
    ctx.circle(69, 21.8, 0.9, Palette.catInk)
}

// MARK: - Bồn rửa (ô 44, đáy ~94)

function drawSink(ctx: GC, basin: Color, shade: Color) {
    ctx.ellipse(24, 89, 52, 8, Color.black.opacity(0.1))
    // chân bồn
    ctx.polygon([pt(41, 58), pt(59, 58), pt(63, 92), pt(37, 92)], basin)
    ctx.polygon([pt(52, 58), pt(59, 58), pt(63, 92), pt(55, 92)], shade.opacity(0.7))
    ctx.rect(35, 89, 30, 4, shade, 2)
    // vòi
    ctx.rect(46.5, 33, 7, 12, chrome, 2)
    ctx.rect(42, 31, 16, 3.4, chromeDark, 1.7)
    ctx.rect(49, 37, 2, 5, Color.white.opacity(0.6), 1)
    // chậu
    ctx.rect(14, 44, 72, 6, basin, 3)
    let bowl = new Path()
    bowl.move(pt(17, 49))
    bowl.addQuadCurve(pt(83, 49), pt(50, 76))
    bowl.closeSubpath()
    ctx.fill(bowl, (basin))
    const g = ctx.copy()
    g.clip(bowl)
    g.ellipse(20, 54, 60, 16, shade)
    ctx.rect(18, 45, 22, 1.6, Color.white.opacity(0.9), 0.8)
    // xà phòng
    ctx.ellipse(20, 40, 12, 5.4, Palette.blush)
    ctx.ellipse(22, 40.6, 5, 1.6, Color.white.opacity(0.7))
    // cốc & bàn chải
    ctx.rect(72, 27, 2.4, 14, Palette.blush, 1.2)
    ctx.rect(76.5, 25, 2.4, 16, rgb(0x8FCDE6), 1.2)
    ctx.rect(71.6, 25.5, 3.2, 4, Color.white, 1)
    ctx.rect(76.1, 23.5, 3.2, 4, Color.white, 1)
    ctx.rect(68, 33, 16, 11.5, rgb(0xA9D7DA), 2.5)
    ctx.rect(70, 35, 2, 7, Color.white.opacity(0.6), 1)
}

function drawRoundMirror(ctx: GC) {
    ctx.circle(50, 16, 15.5, Palette.wood)
    ctx.circle(50, 16, 12, rgb(0xDDEFF5))
    ctx.strokePath(Color.white.opacity(0.85), 2, (p) => {
        p.move(pt(42, 18)); p.addLine(pt(49, 8))
        p.move(pt(46, 21)); p.addLine(pt(48, 18.4))
    })
    ctx.strokePath(Palette.woodDark.opacity(0.4), 0.8, (p) => {
        p.addEllipse(R(36, 2, 28, 28))
    })
    ctx.circle(50, 0.8, 1.4, Palette.woodDark)
}

function drawShellMirror(ctx: GC) {
    // vỏ sò hình quạt
    const c = pt(50, 32)
    let shell = new Path()
    shell.move(c)
    const n = 7
    for (let i = 0; i <= n; i++) {
        const a = Math.PI + (i) / (n) * Math.PI
        const pp = pt(c.x + (Math.cos(a)) * 28, c.y + (Math.sin(a)) * 28)
        if (i == 0) {
            shell.addLine(pp)
        } else {
            const mid = Math.PI + ((i) - 0.5) / (n) * Math.PI
            const ctrl = pt(c.x + (Math.cos(mid)) * 33, c.y + (Math.sin(mid)) * 33)
            shell.addQuadCurve(pp, ctrl)
        }
    }
    shell.closeSubpath()
    ctx.fill(shell, (rgb(0xF7C3C3)))
    ctx.strokePath(rgb(0xEC9FA6), 1, (p) => {
        for (let i = 1; i < n; i++) {
            const a = Math.PI + (i) / (n) * Math.PI
            p.move(c)
            p.addLine(pt(c.x + (Math.cos(a)) * 27, c.y + (Math.sin(a)) * 27))
        }
    })
    // gương bên trong
    let mirror = new Path()
    mirror.move(pt(c.x - 19, c.y - 0.5))
    mirror.addArc(c, 19, deg(180), deg(360), false)
    mirror.closeSubpath()
    ctx.fill(mirror, (rgb(0xE2F1F7)))
    ctx.strokePath(Color.white.opacity(0.85), 1.8, (p) => {
        p.move(pt(38, 28)); p.addLine(pt(45, 18))
        p.move(pt(43, 29)); p.addLine(pt(45, 26.4))
    })
    // ngọc trai
    ctx.circle(50, 33.5, 3.4, rgb(0xFFF8F2))
    ctx.circle(49, 32.5, 1.1, Color.white)
    ctx.text("✦", 6, rgb(0xF2A7BC), pt(82, 8))
}

function drawShellSink(ctx: GC) {
    const basin = rgb(0xFFF4EE)
    const shade = rgb(0xF6D3CF)
    ctx.ellipse(24, 89, 52, 8, Color.black.opacity(0.1))
    ctx.polygon([pt(41, 58), pt(59, 58), pt(63, 92), pt(37, 92)], basin)
    ctx.polygon([pt(52, 58), pt(59, 58), pt(63, 92), pt(55, 92)], shade.opacity(0.7))
    ctx.rect(35, 89, 30, 4, shade, 2)
    // vòi vàng
    ctx.rect(46.5, 36, 7, 9, rgb(0xE2C27A), 2)
    ctx.rect(43, 35, 14, 3, rgb(0xD4AE5E), 1.5)
    // chậu vỏ sò mép lượn
    let bowl = new Path()
    bowl.move(pt(14, 46))
    let x = 14
    while (x < 86) {
        bowl.addQuadCurve(pt(x + 9, 46), pt(x + 4.5, 41))
        x += 9
    }
    bowl.addQuadCurve(pt(14, 46), pt(50, 82))
    bowl.closeSubpath()
    ctx.fill(bowl, (rgb(0xF9D2D0)))
    const g = ctx.copy()
    g.clip(bowl)
    g.strokePath(rgb(0xEFAFB2), 0.9, (p) => {
        for (let i = 0; i < 7; i++) {
            const tx = 20 + (i) * 10
            p.move(pt(tx, 46)); p.addLine(pt(50 + (tx - 50) * 0.3, 68))
        }
    })
    ctx.rect(18, 45.2, 20, 1.4, Color.white.opacity(0.8), 0.7)
    // sao biển nhỏ
    ctx.text("★", 9, rgb(0xF2A57E), pt(78, 38))
    ctx.circle(22, 41, 2.2, rgb(0xFFF8F2))
    ctx.circle(26.5, 42, 1.6, rgb(0xFFF8F2))
}

// MARK: - Kệ treo tường (ô 30)

function shelfBoard(ctx: GC) {
    ctx.polygon([pt(18, 82), pt(26, 82), pt(18, 92)], Palette.woodDark)
    ctx.polygon([pt(82, 82), pt(74, 82), pt(82, 92)], Palette.woodDark)
    ctx.rect(8, 76, 84, 6, Palette.wood, 2)
    ctx.rect(9, 76.5, 82, 1.4, Color.white.opacity(0.35), 0.7)
}

function towel(ctx: GC, x: number, y: number, w: number, h: number, c: Color, stripe: Color) {
    ctx.rect(x, y, w, h, c, h * 0.4)
    ctx.rect(x + 4, y + h * 0.55, w - 8, 2, stripe, 1)
    ctx.rect(x + w - 10, y + 1.5, 7, h - 3, Color.white.opacity(0.18), 3)
    ctx.ellipse(x - 1, y + 1, h * 0.7, h - 2, c)
}

function drawTowelShelf(ctx: GC) {
    shelfBoard(ctx)
    towel(ctx, 18, 62, 64, 14, rgb(0x9FD3D6), Color.white.opacity(0.75))
    towel(ctx, 21, 48, 58, 14, Palette.blush, Color.white.opacity(0.75))
    towel(ctx, 24, 34, 52, 14, rgb(0xF6D58A), Color.white.opacity(0.75))
    ctx.heart(pt(68, 40.5), 5, Color.white.opacity(0.85))
    ctx.text("✦", 7, Palette.honey, pt(84, 30))
}

function drawBottleShelf(ctx: GC) {
    shelfBoard(ctx)
    // chai dầu gội có vòi bơm
    ctx.rect(14, 46, 20, 30, rgb(0x9FD3D6), 6)
    ctx.rect(20.5, 38, 7, 9, rgb(0xFFFFFF), 1.5)
    ctx.rect(20.5, 36, 13, 3, rgb(0xFFFFFF), 1.5)
    ctx.rect(17, 55, 14, 12, Color.white.opacity(0.8), 2)
    ctx.circle(24, 61, 2.4, rgb(0x6FB5D6))
    ctx.rect(16, 49, 2.4, 22, Color.white.opacity(0.4), 1.2)
    // chai sữa tắm
    ctx.rect(38, 52, 18, 24, Palette.blush, 5)
    ctx.rect(42, 45, 10, 8, rgb(0xE88AA5), 2)
    ctx.heart(pt(47, 64), 7, Color.white.opacity(0.85))
    ctx.rect(40, 55, 2.2, 16, Color.white.opacity(0.4), 1.1)
    // nến thơm
    ctx.circle(71, 54, 10, rgb(0xFFD98A).opacity(0.25))
    ctx.rect(61, 60, 20, 16, rgb(0xFFF6E6), 3)
    ctx.rect(61, 66, 20, 4, Palette.lavender.opacity(0.5))
    ctx.rect(70.4, 55, 1.4, 5, Palette.catInk)
    ctx.ellipse(68, 46, 6, 10, Palette.honey)
    ctx.ellipse(69.5, 50, 3, 5, Color.white.opacity(0.8))
}

function drawFernShelf(ctx: GC) {
    shelfBoard(ctx)
    // chậu
    ctx.rect(32, 56, 36, 20, rgb(0xFFFFFF), 5)
    ctx.rect(30, 54, 40, 6, rgb(0xF2F6F7), 3)
    ctx.rect(36, 66, 28, 2, rgb(0x9FD3D6), 1)
    // lá dương xỉ rủ
    function frond(from: Pt, to: Pt, ctrl: Pt) {
        ctx.strokePath(rgb(0x5E8C61), 1.2, (p) => {
            p.move(from); p.addQuadCurve(to, ctrl)
        })
        for (let i = 1; i <= 6; i++) {
            const t = (i) / 7
            const x = (1 - t) * (1 - t) * from.x + 2 * (1 - t) * t * ctrl.x + t * t * to.x
            const y = (1 - t) * (1 - t) * from.y + 2 * (1 - t) * t * ctrl.y + t * t * to.y
            const s = 5.5 * (1 - t * 0.6)
            ctx.ellipse(x - s, y - s * 0.4, s * 0.9, s * 0.8, Palette.sage)
            ctx.ellipse(x + s * 0.1, y - s * 0.4, s * 0.9, s * 0.8, rgb(0x8DB88F))
        }
    }
    frond(pt(42, 54), pt(12, 86), pt(18, 50))
    frond(pt(58, 54), pt(90, 88), pt(84, 50))
    frond(pt(46, 54), pt(30, 18), pt(34, 40))
    frond(pt(54, 54), pt(72, 20), pt(68, 40))
    frond(pt(50, 54), pt(52, 12), pt(48, 30))
    // giọt nước
    ctx.ellipse(84, 36, 3, 4.4, rgb(0x8FCDE6))
    ctx.ellipse(16, 30, 2.4, 3.6, rgb(0x8FCDE6))
}

// MARK: - Thảm (ô 40)

function drawMatBasic(ctx: GC) {
    const main = rgb(0xBFE3E6)
    ctx.ellipse(6, 72, 88, 24, Color.black.opacity(0.06))
    // viền bông
    let x = 12
    while (x <= 84) {
        ctx.circle(x, 70, 3, main)
        ctx.circle(x, 92, 3, main)
        x += 6
    }
    ctx.rect(8, 68, 84, 26, main, 10)
    ctx.rect(14, 72, 72, 18, rgb(0xDDF1F1), 7)
    ctx.rect(14, 79.5, 72, 3, rgb(0x9FD3D6), 1.5)
    ctx.heart(pt(50, 80.5), 7, Color.white)
}

function drawMatDuck(ctx: GC) {
    ctx.ellipse(8, 76, 84, 20, Color.black.opacity(0.06))
    // thân
    let body = new Path()
    body.move(pt(10, 76))
    body.addQuadCurve(pt(20, 70), pt(10, 66))
    body.addQuadCurve(pt(66, 72), pt(44, 74))
    body.addQuadCurve(pt(84, 84), pt(86, 70))
    body.addQuadCurve(pt(20, 93), pt(70, 96))
    body.addQuadCurve(pt(10, 76), pt(8, 90))
    body.closeSubpath()
    ctx.fill(body, (duckYellow))
    // đầu
    ctx.ellipse(56, 58, 30, 24, duckYellow)
    ctx.polygon([pt(84, 66), pt(96, 70), pt(84, 74)], beak)
    ctx.circle(76, 66, 2, Palette.catInk)
    ctx.circle(75.4, 65.3, 0.7, Color.white)
    ctx.ellipse(66, 70, 7, 3.6, Palette.blush.opacity(0.8))
    // cánh
    ctx.strokePath(duckShade, 2, (p) => {
        p.move(pt(30, 80)); p.addQuadCurve(pt(54, 82), pt(42, 90))
    })
    ctx.strokePath(Color.white.opacity(0.6), 2, (p) => {
        p.move(pt(16, 76)); p.addQuadCurve(pt(26, 72), pt(18, 72))
    })
}

function drawMatWave(ctx: GC) {
    ctx.ellipse(6, 72, 88, 24, Color.black.opacity(0.06))
    const mat = Path.roundedRect(R(8, 68, 84, 26), 12)
    ctx.fill(mat, (rgb(0x8CC8E0)))
    const g = ctx.copy()
    g.clip(mat)
    function waveLine(y: number, color: Color, w: number) {
        g.strokePath(color, w, (p) => {
            p.move(pt(4, y))
            let x = 4
            while (x < 96) {
                p.addQuadCurve(pt(x + 6, y), pt(x + 3, y - 3.4))
                p.addQuadCurve(pt(x + 12, y), pt(x + 9, y + 3.4))
                x += 12
            }
        })
    }
    g.rect(8, 84, 84, 12, rgb(0x6FB5D6))
    waveLine(75, Color.white.opacity(0.85), 1.8)
    waveLine(84, rgb(0xDDF1F8), 1.8)
    g.circle(80, 74, 1.6, Color.white.opacity(0.85))
    g.circle(22, 89, 1.4, Color.white.opacity(0.85))
}

// MARK: - Đồ chơi (ô 20)

function drawRubberDuck(ctx: GC) {
    ctx.ellipse(14, 86, 72, 10, Color.black.opacity(0.1))
    // thân
    let body = new Path()
    body.move(pt(10, 60))
    body.addQuadCurve(pt(30, 54), pt(14, 50))
    body.addLine(pt(70, 56))
    body.addQuadCurve(pt(82, 76), pt(86, 60))
    body.addQuadCurve(pt(22, 90), pt(70, 94))
    body.addQuadCurve(pt(10, 60), pt(8, 84))
    body.closeSubpath()
    ctx.fill(body, (duckYellow))
    // đầu
    ctx.circle(56, 38, 20, duckYellow)
    ctx.ellipse(70, 40, 22, 10, beak)
    ctx.ellipse(72, 44, 16, 4, rgb(0xE07F45))
    ctx.circle(62, 32, 3.2, Palette.catInk)
    ctx.circle(61, 31, 1.1, Color.white)
    ctx.ellipse(52, 42, 8, 4.4, Palette.blush.opacity(0.85))
    // cánh
    ctx.strokePath(duckShade, 3, (p) => {
        p.move(pt(28, 66)); p.addQuadCurve(pt(56, 72), pt(40, 82))
    })
    ctx.strokePath(Color.white.opacity(0.65), 3, (p) => {
        p.move(pt(44, 28)); p.addQuadCurve(pt(52, 22), pt(46, 23))
    })
    ctx.text("♪", 14, Palette.lavender, pt(26, 26))
}

function drawBoat(ctx: GC) {
    ctx.ellipse(6, 80, 88, 14, rgb(0x8FCDE6).opacity(0.5))
    ctx.strokePath(Color.white.opacity(0.85), 1.6, (p) => {
        p.move(pt(14, 87)); p.addQuadCurve(pt(26, 87), pt(20, 84))
        p.move(pt(72, 88)); p.addQuadCurve(pt(86, 88), pt(79, 85))
    })
    // buồm (mũ giấy)
    ctx.polygon([pt(50, 14), pt(26, 60), pt(74, 60)], rgb(0xFFFDF8))
    ctx.polygon([pt(50, 14), pt(50, 60), pt(74, 60)], rgb(0xE9EEF2))
    // thân thuyền
    ctx.polygon([pt(8, 58), pt(92, 58), pt(76, 84), pt(24, 84)], rgb(0xFFFFFF))
    ctx.polygon([pt(8, 58), pt(30, 58), pt(38, 84), pt(24, 84)], rgb(0xEEF2F5))
    ctx.polygon([pt(92, 58), pt(70, 58), pt(62, 84), pt(76, 84)], rgb(0xEEF2F5))
    ctx.strokePath(rgb(0xD5DDE3), 0.9, (p) => {
        p.move(pt(50, 16)); p.addLine(pt(50, 58))
    })
    ctx.heart(pt(50, 70), 8, Palette.blush)
    // cờ nhỏ
    ctx.strokePath(Palette.woodDark, 1.2, (p) => {
        p.move(pt(50, 14)); p.addLine(pt(50, 4))
    })
    ctx.polygon([pt(50, 4), pt(62, 7), pt(50, 10)], Palette.peach)
}

function drawBubbles(ctx: GC) {
    // lọ nước xà phòng + que thổi
    ctx.ellipse(10, 88, 34, 6, Color.black.opacity(0.1))
    ctx.rect(14, 62, 24, 28, rgb(0xCDBDF0), 5)
    ctx.rect(18, 56, 16, 7, rgb(0x8D78CF), 2)
    ctx.rect(17, 66, 3, 18, Color.white.opacity(0.5), 1.5)
    ctx.heart(pt(26, 76), 7, Color.white.opacity(0.85))
    ctx.strokePath(rgb(0xF29A5B), 2, (p) => {
        p.move(pt(36, 58)); p.addLine(pt(52, 44))
        p.addEllipse(R(50, 34, 11, 11))
    })
    const bubbles = [
        [70, 30, 14, rgb(0xBFE3EF)], [44, 16, 9, rgb(0xF4B8C8)], [84, 62, 9, rgb(0xCDBDF0)],
        [24, 34, 6, rgb(0xF6D58A)], [66, 80, 6, rgb(0xBFE3EF)], [88, 10, 5, rgb(0xF4B8C8)]
    ] as const
    for (const b of bubbles) {
        ctx.circle(b[0], b[1], b[2], b[3].opacity(0.3))
        ctx.strokePath(b[3], 1.6, (p) => {
            p.addEllipse(R(b[0] - b[2], b[1] - b[2], b[2] * 2, b[2] * 2))
        })
        ctx.circle(b[0] - b[2] * 0.38, b[1] - b[2] * 0.38, b[2] * 0.26, Color.white.opacity(0.9))
    }
}

function drawWhale(ctx: GC) {
    const blue = rgb(0x84B8E6)
    const belly = rgb(0xDDEEFA)
    ctx.ellipse(10, 86, 80, 10, Color.black.opacity(0.1))
    // tia nước
    ctx.strokePath(rgb(0x8FCDE6), 2.6, (p) => {
        p.move(pt(40, 40)); p.addLine(pt(40, 24))
        p.move(pt(40, 26)); p.addQuadCurve(pt(28, 22), pt(32, 14))
        p.move(pt(40, 26)); p.addQuadCurve(pt(52, 22), pt(48, 14))
    })
    ctx.circle(26, 26, 2.2, rgb(0x8FCDE6))
    ctx.circle(54, 26, 2.2, rgb(0x8FCDE6))
    ctx.circle(40, 12, 2.6, rgb(0x8FCDE6))
    // đuôi
    ctx.polygon([pt(72, 70), pt(86, 48), pt(80, 66), pt(96, 54), pt(84, 76)], blue)
    // thân
    let body = new Path()
    body.move(pt(10, 70))
    body.addCurve(pt(78, 70), pt(8, 36), pt(70, 36))
    body.addQuadCurve(pt(10, 70), pt(50, 98))
    body.closeSubpath()
    ctx.fill(body, (blue))
    const g = ctx.copy()
    g.clip(body)
    g.ellipse(4, 70, 70, 30, belly)
    g.strokePath(rgb(0xB9D8F1), 1, (p) => {
        p.move(pt(20, 78)); p.addLine(pt(60, 78))
        p.move(pt(24, 84)); p.addLine(pt(56, 84))
    })
    ctx.circle(26, 62, 2.6, Palette.catInk)
    ctx.circle(25.2, 61.2, 0.9, Color.white)
    ctx.ellipse(28, 67, 8, 4, Palette.blush.opacity(0.85))
    ctx.strokePath(Palette.catInk, 1.2, (p) => {
        p.move(pt(16, 70)); p.addQuadCurve(pt(22, 70), pt(19, 73))
    })
    ctx.strokePath(Color.white.opacity(0.6), 2.4, (p) => {
        p.move(pt(40, 48)); p.addQuadCurve(pt(56, 48), pt(48, 45))
    })
    // vây
    ctx.ellipse(44, 74, 12, 7, rgb(0x6FA2D2))
}

export const BathArt = { draw }
