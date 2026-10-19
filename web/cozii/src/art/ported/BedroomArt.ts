// Chuyển tự động từ Swift (scripts/port/swift2ts.mjs) rồi sửa tay.
import { GC, Color, rgb, pt, R, Path, deg, Pt, Rect, linear, radial } from '../gc'
import { Palette } from '../palette'

// Hình vẽ đồ trong Bedroom. Trả về false nếu không phải ID của phòng này.
export function draw(id: string, ctx: GC): boolean {
    switch (id) {
    case "bedroomTheme.lilac": case "bedroomTheme.cloud": case "bedroomTheme.candy": case "bedroomTheme.galaxy": { 
        theme(id, ctx)
    } break; case "bed.mat": { bedMat(ctx)
    } break; case "bed.wood": { bedWood(ctx)
    } break; case "bed.canopy": { bedCanopy(ctx)
    } break; case "bed.cloud": { bedCloud(ctx)
    } break; case "nightstand.crate": { standCrate(ctx)
    } break; case "nightstand.lamp": { standLamp(ctx)
    } break; case "nightstand.radio": { standRadio(ctx)
    } break; case "nightstand.moon": { standMoon(ctx)
    } break; case "bedroomWall.garland": { wallGarland(ctx)
    } break; case "bedroomWall.fairy": { wallFairy(ctx)
    } break; case "bedroomWall.moon": { wallMoon(ctx)
    } break; case "bedroomWall.dreamcatcher": { wallDreamcatcher(ctx)
    } break; case "closet.dresser": { closetDresser(ctx)
    } break; case "closet.mirror": { closetMirror(ctx)
    } break; case "closet.wardrobe": { closetWardrobe(ctx)
    } break; case "closet.vanity": { closetVanity(ctx)
    } break; case "bedroomRug.round": { rugRound(rugSpace(ctx))
    } break; case "bedroomRug.heart": { rugHeart(rugSpace(ctx))
    } break; case "bedroomRug.cloud": { rugCloud(rugSpace(ctx))
    } break; case "bedroomRug.rainbow": { rugRainbow(rugSpace(ctx))
    } break; case "plush.yarn": { plushYarn(ctx)
    } break; case "plush.ball": { plushBall(ctx)
    } break; case "plush.teddy": { plushTeddy(ctx)
    } break; case "plush.dino": { plushDino(ctx)
    } break; default: { return false
    } }
    return true
}

// MARK: - Tiện ích

const shine = Color.white.opacity(0.65)
const ink = rgb(0x4A3C5C)

function shadow(ctx: GC, x: number, y: number, w: number, h: number) {
    ctx.ellipse(x, y, w, h, Color.black.opacity(0.1))
}
// Điểm trên đường cong bậc hai.
function quad(a: Pt, c: Pt, b: Pt, t: number): Pt {
    const u = 1 - t
    return pt(u * u * a.x + 2 * u * t * c.x + t * t * b.x, u * u * a.y + 2 * u * t * c.y + t * t * b.y)
}

function sparkle(ctx: GC, x: number, y: number, size: number, color: Color) {
    ctx.text("✦", size, color, pt(x, y))
}

// Đám mây nhỏ gồm ba vòng tròn; [x, y] là góc trên-trái, s là tỉ lệ.
function puff(ctx: GC, x: number, y: number, s: number, color: Color) {
    ctx.ellipse(x, y + 4 * s, 18 * s, 7 * s, color)
    ctx.circle(x + 6 * s, y + 4.5 * s, 4 * s, color)
    ctx.circle(x + 11 * s, y + 3.5 * s, 5 * s, color)
}

// MARK: - Tường & sàn

function theme(id: string, ctx: GC) {
    let wall = rgb(0xEFE6F8)
    let deco = rgb(0xDCCDF1)
    let trim = rgb(0xD5C4EC)
    let floor = rgb(0xEDD8BE)
    let plank = rgb(0xDDC3A3)
    let curtain = rgb(0xC9B6EC)
    let curtainFold = rgb(0xB49FE0)
    let tie = rgb(0xF4B0C0)
    let frame = rgb(0xFFFCF7)
    let sky = rgb(0xCFE7F8)
    const night = id == "bedroomTheme.galaxy"
    switch (id) {
    case "bedroomTheme.cloud": { 
        wall = rgb(0xD8EAFA); deco = rgb(0xF7FBFF); trim = rgb(0xBCD6EF)
        floor = rgb(0xEBDDC9); plank = rgb(0xDCC9B0)
        curtain = rgb(0xFFFFFF); curtainFold = rgb(0xD9E8F6); tie = rgb(0xA9CBEB)
    } break; case "bedroomTheme.candy": { 
        wall = rgb(0xFFF3F5); deco = rgb(0xFAD3DE); trim = rgb(0xF4B6C8)
        floor = rgb(0xF3DCCB); plank = rgb(0xE6C6B1)
        curtain = rgb(0xF6AFC4); curtainFold = rgb(0xEC93AE); tie = rgb(0xFFFFFF)
    } break; case "bedroomTheme.galaxy": { 
        wall = rgb(0x3D3770); deco = rgb(0xFFF1C2); trim = rgb(0x2F2A5C)
        floor = rgb(0x544C86); plank = rgb(0x463F78)
        curtain = rgb(0x9C8BDB); curtainFold = rgb(0x8473CC); tie = rgb(0xF7D27A)
        frame = rgb(0xE6E0F7); sky = rgb(0x241F4A)
    } break; default: { break
    } }

    // Tường + hoa văn
    ctx.rect(0, 0, 125, 62, wall)
    switch (id) {
    case "bedroomTheme.cloud": { 
        for (const [x, y, s] of ([[4, 6, 1.0], [26, 16, 0.8], [98, 4, 0.95], [80, 26, 0.7],
                          [106, 36, 0.8], [16, 40, 0.75], [72, 46, 0.6], [40, 44, 0.55]] as const)) {
            puff(ctx, x, y, s, deco)
        }
    } break; case "bedroomTheme.candy": { 
        for (let i = 0; i < 13; i++) {
            ctx.rect((i) * 10 + 2, 0, 5, 62, deco)
        }
        // Viền ren phía trên
        ctx.rect(0, 0, 125, 3, trim)
        for (let i = 0; i < 26; i++) {
            ctx.circle((i) * 5 + 2.5, 3, 2.5, trim)
        }
    } break; case "bedroomTheme.galaxy": { 
        const dots = [[8, 6, 0.7], [20, 14, 0.5], [33, 5, 0.6], [14, 30, 0.5], [6, 46, 0.6],
                                                   [36, 26, 0.45], [78, 6, 0.6], [92, 18, 0.5], [118, 8, 0.6],
                                                   [104, 28, 0.45], [120, 44, 0.6], [84, 40, 0.5], [30, 52, 0.45],
                                                   [98, 52, 0.5], [74, 30, 0.4], [112, 20, 0.4]] as const
        for (const [x, y, r] of dots) {
            ctx.circle(x, y, r, deco.opacity(0.85))
        }
        for (const [x, y, s] of ([[26, 18, 5], [100, 10, 6], [86, 46, 4.5], [12, 54, 4], [116, 36, 5]] as const)) {
            sparkle(ctx, x, y, s, deco)
        }
        // Hành tinh nhỏ có vành
        ctx.circle(110, 52, 3.6, rgb(0xF4B0C0))
        ctx.strokePath(rgb(0xF7D27A), 0.8, (p) => {
            p.addEllipse(R(104, 50.6, 12, 3))
        })
        ctx.circle(109, 51, 0.9, shine)
        // Sao băng
        ctx.strokePath(deco.opacity(0.5), 0.7, (p) => {
            p.move(pt(4, 20)); p.addLine(pt(12, 24))
        })
        ctx.circle(12.5, 24.2, 0.9, deco)
    } break; default: { 
        for (let row = 0; row < 6; row++) {
            for (let col = 0; col < 12; col++) {
                const x = (col) * 11 + 4 + (row % 2 == 0 ? 0 : 5.5)
                const y = (row) * 10 + 5
                if ((row + col) % 2 == 0) {
                    for (const [dx, dy] of ([[0, -1.3], [1.3, 0], [0, 1.3], [-1.3, 0]] as const)) {
                        ctx.circle(x + dx, y + dy, 1, deco)
                    }
                    ctx.circle(x, y, 0.7, Color.white.opacity(0.8))
                } else {
                    ctx.circle(x, y, 0.6, deco)
                }
            }
        }
    } }

    // Len chân tường
    ctx.rect(0, 57.5, 125, 4.5, trim)
    ctx.rect(0, 57.5, 125, 0.8, Color.white.opacity(night ? 0.12 : 0.45))

    // Sàn gỗ
    ctx.rect(0, 62, 125, 38, floor)
    ctx.rect(0, 62, 125, 1.6, Color.black.opacity(0.06))
    const rows = [62, 70.5, 80, 90.5]
    for (const [i, y] of rows.entries()) {
        if (i > 0) { ctx.rect(0, y, 125, 0.7, plank) }
        const next = i + 1 < rows.length ? rows[i + 1] : 100
        const offset = i % 2 == 0 ? 0 : 14
        let x = offset + 10
        while (x < 125) {
            ctx.rect(x, y, 0.7, next - y, plank)
            x += 28
        }
    }
    if (night) {
        for (const [x, y] of ([[14, 76], [60, 94], [96, 68], [112, 86], [40, 66]] as const)) {
            sparkle(ctx, x, y, 3.5, deco.opacity(0.45))
        }
    }

    // Cửa sổ
    ctx.rect(39, 6.8, 34, 1.8, night ? rgb(0xCFC4F0) : rgb(0xB89170), 0.9)
    ctx.circle(39, 7.7, 1.6, night ? rgb(0xF7D27A) : rgb(0xA07448))
    ctx.circle(73, 7.7, 1.6, night ? rgb(0xF7D27A) : rgb(0xA07448))
    ctx.rect(44, 10, 24, 22, frame, 2.5)
    ctx.rect(46, 12, 20, 18, sky, 1.5)
    if (night) {
        ctx.circle(61, 17, 3.6, rgb(0xFFF1C2))
        ctx.circle(62.8, 15.8, 3.2, sky)
        ctx.circle(50, 15, 0.5, rgb(0xFFF1C2))
        ctx.circle(53, 25, 0.5, rgb(0xFFF1C2))
        ctx.circle(63, 26, 0.5, rgb(0xFFF1C2))
        sparkle(ctx, 50.5, 24, 3, rgb(0xFFF1C2))
    } else {
        puff(ctx, 47.5, 13, 0.45, Color.white)
        puff(ctx, 57, 22, 0.4, Color.white.opacity(0.9))
        ctx.circle(62.5, 15.5, 2, rgb(0xFFE7A0))
    }
    ctx.rect(55.3, 12, 1.4, 18, frame)
    ctx.rect(46, 20.3, 20, 1.4, frame)
    ctx.strokePath(Color.white.opacity(night ? 0.18 : 0.6), 0.8, (p) => {
        p.move(pt(47.5, 18)); p.addLine(pt(51, 13.5))
        p.move(pt(57.8, 28)); p.addLine(pt(61, 23.5))
    })
    ctx.rect(42.5, 31, 27, 3, frame, 1.5)
    ctx.rect(43.5, 34, 25, 1, Color.black.opacity(0.07), 0.5)

    // Rèm hai bên
    for (const flip of [false, true]) {
        const fx = (x: number) => (flip ? 112 - x : x)
        let p = new Path()
        p.move(pt(fx(39.5), 8.5))
        p.addLine(pt(fx(48.5), 8.5))
        p.addQuadCurve(pt(fx(44.5), 23), pt(fx(48.5), 17))
        p.addQuadCurve(pt(fx(47.5), 37), pt(fx(42.5), 30))
        p.addLine(pt(fx(39), 37))
        p.addQuadCurve(pt(fx(39.5), 8.5), pt(fx(40.5), 22))
        p.closeSubpath()
        ctx.fill(p, (curtain))
        ctx.strokePath(curtainFold, 0.7, (q) => {
            q.move(pt(fx(42), 10)); q.addQuadCurve(pt(fx(42), 22), pt(fx(43), 16))
            q.move(pt(fx(42.5), 25)); q.addQuadCurve(pt(fx(43), 36), pt(fx(41.5), 31))
        })
        ctx.rect(flip ? fx(46.5) : 40.5, 21.8, 6, 2.4, tie, 1.2)
    }
}

// MARK: - Giường (đầu giường bên trái, cạnh tủ đầu giường)

// Nệm + gối + chăn dùng chung cho các giường có khung.
function mattress(ctx: GC, blanket: Color, blanketTop: Color, cuff: Color, pattern?: (g: GC) => void) {
    // Nệm
    ctx.rect(12, 54, 80, 24, rgb(0xEFE4DA), 5)
    ctx.rect(12, 50, 80, 10, rgb(0xFFFBF5), 5)
    // Gối
    ctx.ellipse(15, 39, 28, 17, rgb(0xFFFDFB))
    ctx.ellipse(18, 47, 22, 6, rgb(0xEEE6F2))
    ctx.ellipse(20, 42, 8, 3.5, shine)
    // Chăn
    const b = ctx.copy()
    b.clip(Path.roundedRect(R(36, 48, 56, 33), 6))
    b.rect(36, 48, 56, 33, blanket)
    b.rect(36, 48, 56, 9, blanketTop)
    pattern?.(b)
    b.rect(36, 79, 56, 2, Color.black.opacity(0.06))
    // Mép chăn gập
    ctx.rect(33, 47, 9, 34, cuff, 4.5)
    ctx.rect(35, 49, 2, 28, Color.white.opacity(0.45), 1)
}

function bedMat(ctx: GC) {
    shadow(ctx, 4, 85, 92, 11)
    ctx.rect(6, 70, 88, 20, rgb(0xE9DCEC), 8)
    ctx.rect(6, 66, 88, 11, rgb(0xFBF6FC), 6)
    // Đường may nệm
    for (const x of [(28), 50, 72]) {
        ctx.circle(x, 83, 1.2, rgb(0xD6C4DD))
    }
    // Chăn gập
    ctx.rect(46, 63, 44, 17, rgb(0xB9DCC4), 6)
    ctx.rect(46, 63, 44, 6, rgb(0xD3EBDA), 5)
    ctx.rect(46, 72, 44, 2.2, rgb(0xF6FBF7).opacity(0.9))
    // Gối tròn
    ctx.circle(22, 61, 11, rgb(0xFCE5C8))
    ctx.circle(22, 61, 4, rgb(0xF4C9A0))
    ctx.circle(22, 61, 1.5, rgb(0xFCE5C8))
    ctx.circle(17, 56, 2.4, shine)
}

function bedWood(ctx: GC) {
    const wood = rgb(0xCFA175)
    const woodDark = rgb(0xB3845A)
    shadow(ctx, 2, 89, 98, 9)
    // Đầu giường
    ctx.rect(3, 22, 14, 72, wood, 6)
    ctx.rect(6, 28, 8, 20, woodDark.opacity(0.55), 3)
    ctx.rect(5, 24, 3, 18, Color.white.opacity(0.3), 1.5)
    // Thanh giường
    ctx.rect(10, 74, 82, 8, woodDark, 3)
    mattress(ctx, rgb(0xF2A890), rgb(0xF6BEA9), rgb(0xFFF4E8), (b) => {
        for (let x = (44); x < 92; x += 10) {
            b.rect(x, 48, 2.4, 33, Color.white.opacity(0.45))
        }
        for (let y = (52); y < 82; y += 8) {
            b.rect(36, y, 56, 2.4, rgb(0xD9806B).opacity(0.45))
        }
    })
    // Chân cuối giường
    ctx.rect(86, 46, 11, 48, wood, 5)
    ctx.rect(88, 52, 7, 14, woodDark.opacity(0.55), 2.5)
    ctx.circle(91.5, 44.5, 4, wood)
    ctx.circle(90, 43, 1.3, Color.white.opacity(0.35))
    ctx.circle(10, 21, 5, wood)
    ctx.circle(8.5, 19.5, 1.6, Color.white.opacity(0.35))
}

function bedCanopy(ctx: GC) {
    const post = rgb(0xF2C6D6)
    const postDark = rgb(0xE3A9BF)
    const voile = rgb(0xFFF6FA)
    shadow(ctx, 2, 89, 98, 9)
    // Cột màn
    ctx.rect(5, 6, 5, 88, post, 2.5)
    ctx.rect(90, 6, 5, 88, post, 2.5)
    // Đầu giường hình vòm có trái tim
    ctx.rect(3, 32, 15, 62, post, 7)
    ctx.heart(pt(10.5, 44), 8, Color.white.opacity(0.8))
    ctx.rect(10, 74, 82, 8, postDark, 3)
    mattress(ctx, rgb(0xF7BDD0), rgb(0xFBD3E0), rgb(0xFFFFFF), (b) => {
        for (let i = 0; i < 12; i++) {
            const x = 40 + (i % 4) * 14 + ((i / 4) % 2) * 7
            const y = 60 + (i / 4) * 7
            b.circle(x, y, 1.1, Color.white.opacity(0.8))
        }
    })
    ctx.rect(86, 50, 10, 44, post, 5)
    ctx.heart(pt(91, 60), 5, Color.white.opacity(0.75))
    // Mái rèm + diềm lượn sóng
    ctx.rect(3, 3, 94, 6, post, 3)
    for (let i = 0; i < 10; i++) {
        ctx.circle(8 + (i) * 9.4, 9, 4.8, voile)
    }
    ctx.rect(3, 3, 94, 2, Color.white.opacity(0.4), 1)
    // Voan buộc ở hai cột (trong suốt)
    for (const flip of [false, true]) {
        const fx = (x: number) => (flip ? 100 - x : x)
        let p = new Path()
        p.move(pt(fx(4), 9))
        p.addLine(pt(fx(22), 9))
        p.addQuadCurve(pt(fx(9), 48), pt(fx(20), 34))
        p.addQuadCurve(pt(fx(15), 84), pt(fx(6), 66))
        p.addLine(pt(fx(3), 84))
        p.addQuadCurve(pt(fx(4), 9), pt(fx(1), 46))
        p.closeSubpath()
        ctx.fill(p, (voile.opacity(0.62)))
        ctx.rect(flip ? fx(12) : 3, 46, 9, 4, rgb(0xF4A9C0), 2)
        ctx.circle(fx(7.5), 48, 2.2, rgb(0xEC8FAE))
    }
    ctx.circle(7.5, 3, 3, postDark)
    ctx.circle(92.5, 3, 3, postDark)
}

function bedCloud(ctx: GC) {
    const cloud = rgb(0xFBFDFF)
    const cloudShade = rgb(0xD7E6F6)
    shadow(ctx, 12, 91, 80, 7)
    // Thân mây (lớp bóng rồi lớp trắng)
    for (const [dy, color] of ([[(2.5), cloudShade], [0, cloud]] as const)) {
        ctx.rect(8, 54 + dy, 86, 26, color, 13)
        for (const [x, r] of ([[16, 8], [31, 9], [49, 9.5], [67, 9], [84, 8]] as const)) {
            ctx.circle(x, 80 + dy, r, color)
        }
        ctx.circle(92, 66 + dy, 9, color)
    }
    // Đầu giường: cụm mây
    for (const [dx, color] of ([[(1.5), cloudShade], [0, cloud]] as const)) {
        ctx.circle(13 + dx, 44, 11, color)
        ctx.circle(22 + dx, 30, 10, color)
        ctx.circle(10 + dx, 58, 9, color)
        ctx.circle(30 + dx, 40, 7, color)
    }
    ctx.circle(18, 26, 3, shine)
    // Gối
    ctx.ellipse(18, 42, 26, 15, rgb(0xE6DEF8))
    ctx.ellipse(22, 44, 8, 3.5, shine)
    // Chăn vàng nhạt có sao
    ctx.rect(40, 48, 52, 24, rgb(0xFFE6A6), 11)
    ctx.rect(40, 48, 52, 8, rgb(0xFFF0C8), 8)
    ctx.rect(37, 47, 8, 26, rgb(0xFFF7E2), 4)
    for (const [x, y] of ([[54, 62], [68, 57], [82, 64]] as const)) {
        sparkle(ctx, x, y, 7, rgb(0xF2C25E))
    }
    // Lấp lánh quanh giường
    for (const [x, y, s] of ([[48, 32, 7], [90, 40, 6], [4, 78, 5]] as const)) {
        sparkle(ctx, x, y, s, rgb(0xB9D4F2))
    }
}

// MARK: - Tủ đầu giường (sàn ở y ≈ 77, chân chạm y ≈ 96)

function cabinet(ctx: GC, body: Color, top: Color, front: Color, knob: Color) {
    shadow(ctx, 14, 91, 72, 8)
    ctx.rect(24, 88, 5, 7, top, 1.5)
    ctx.rect(71, 88, 5, 7, top, 1.5)
    ctx.rect(20, 50, 60, 40, body, 5)
    ctx.rect(16, 46, 68, 7, top, 3)
    ctx.rect(18, 46.8, 30, 1.6, Color.white.opacity(0.35), 0.8)
    ctx.rect(25, 58, 50, 12, front, 3)
    ctx.rect(25, 73, 50, 12, front, 3)
    ctx.circle(50, 64, 2.4, knob)
    ctx.circle(50, 79, 2.4, knob)
    ctx.circle(49.3, 63.3, 0.8, shine)
    ctx.circle(49.3, 78.3, 0.8, shine)
}

function standCrate(ctx: GC) {
    const wood = rgb(0xD9B087)
    const dark = rgb(0xBE915F)
    shadow(ctx, 12, 90, 76, 8)
    ctx.rect(18, 50, 64, 44, wood, 3)
    ctx.rect(18, 64, 64, 1.6, dark)
    ctx.rect(18, 79, 64, 1.6, dark)
    ctx.rect(18, 50, 7, 44, dark, 2)
    ctx.rect(75, 50, 7, 44, dark, 2)
    ctx.rect(26, 52, 40, 1.4, Color.white.opacity(0.35))
    for (const [x, y] of ([[21.5, 55], [78.5, 55], [21.5, 89], [78.5, 89]] as const)) {
        ctx.circle(x, y, 1, rgb(0x8E6247))
    }
    // Sách
    ctx.rect(24, 42, 30, 8, rgb(0xB9A6EA), 1.5)
    ctx.rect(26, 44, 26, 2.4, rgb(0xFFFBF5))
    ctx.rect(27, 35, 24, 7, rgb(0xA9D8BA), 1.5)
    ctx.rect(29, 37, 20, 2, rgb(0xFFFBF5))
    // Cốc nước
    ctx.rect(58, 26, 15, 24, rgb(0xE4F2FB), 3.5)
    ctx.rect(59.5, 35, 12, 13.5, rgb(0xAED7F2), 2.5)
    ctx.ellipse(58, 24, 15, 4.5, rgb(0xF4FAFE))
    ctx.rect(60.5, 29, 2.2, 16, Color.white.opacity(0.75), 1.1)
}

function standLamp(ctx: GC) {
    cabinet(ctx, rgb(0xF0DCC6), rgb(0xDDBB97), rgb(0xF9EBDB), rgb(0xC48F64))
    // Quầng sáng
    ctx.circle(50, 20, 24, rgb(0xFFE08A).opacity(0.22))
    ctx.circle(50, 20, 17, rgb(0xFFE08A).opacity(0.22))
    // Đèn
    ctx.ellipse(38, 41, 24, 7, rgb(0xB9A6EA))
    ctx.rect(48.5, 24, 3, 19, rgb(0xB9A6EA), 1.5)
    ctx.polygon([pt(32, 28), pt(68, 28), pt(61, 6), pt(39, 6)], rgb(0xF7D27A))
    ctx.rect(32, 26, 36, 4, rgb(0xEFC260), 2)
    ctx.rect(39, 5, 22, 3, rgb(0xFBE3A4), 1.5)
    ctx.polygon([pt(42, 10), pt(46, 10), pt(42, 24), pt(37.5, 24)], Color.white.opacity(0.5))
}

function standRadio(ctx: GC) {
    cabinet(ctx, rgb(0xC9A27C), rgb(0xA97F58), rgb(0xD9B791), rgb(0xFCEBD0))
    // Ăng-ten
    ctx.strokePath(rgb(0x9A93A8), 1.6, (p) => {
        p.move(pt(66, 24)); p.addLine(pt(80, 6))
    })
    ctx.circle(80, 6, 2.4, rgb(0xF4A9A0))
    // Radio
    ctx.rect(22, 20, 56, 27, rgb(0xEFA289), 8)
    ctx.rect(22, 20, 56, 6, rgb(0xF5BBA6), 6)
    ctx.circle(37, 34, 9, rgb(0xFBE3D4))
    for (const [dx, dy] of ([[-4, -4], [0, -4], [4, -4], [-4, 0], [0, 0], [4, 0], [-4, 4], [0, 4], [4, 4]] as const)) {
        ctx.circle(37 + dx, 34 + dy, 1.1, rgb(0xDB8A70))
    }
    ctx.rect(51, 28, 21, 8, rgb(0xFFF4E2), 2)
    for (let i = 0; i < 5; i++) {
        ctx.rect(53.5 + (i) * 4, 30, 0.8, 3, rgb(0xC9A27C))
    }
    ctx.rect(62, 28.5, 1.2, 7, rgb(0xE0625A))
    ctx.circle(56, 41, 2.8, rgb(0xFFF4E2))
    ctx.circle(67, 41, 2.8, rgb(0xFFF4E2))
    ctx.rect(26, 22, 14, 1.8, shine, 0.9)
    // Nốt nhạc
    ctx.text("♪", 13, rgb(0x9F8BDB), pt(13, 18))
    ctx.text("♫", 11, rgb(0xE48FAE), pt(90, 22))
}

function standMoon(ctx: GC) {
    cabinet(ctx, rgb(0xD9CCF2), rgb(0xC0AEE8), rgb(0xEAE2FA), rgb(0xF7D27A))
    // Quầng sáng trăng
    ctx.circle(50, 22, 25, rgb(0xFFF1C2).opacity(0.3))
    ctx.circle(50, 22, 19, rgb(0xFFF1C2).opacity(0.35))
    // Đế + mặt trăng
    ctx.ellipse(36, 41, 28, 7, rgb(0xCFA175))
    ctx.rect(47.5, 34, 5, 9, rgb(0xCFA175), 1.5)
    ctx.circle(50, 21, 15, rgb(0xFFF1C2))
    ctx.circle(43, 15, 3, rgb(0xF4DFA2))
    ctx.circle(58, 27, 2.4, rgb(0xF4DFA2))
    ctx.circle(56, 13, 1.6, rgb(0xF4DFA2))
    // Mặt ngủ
    ctx.strokePath(ink, 1.3, (p) => {
        p.move(pt(42, 22)); p.addQuadCurve(pt(47, 22), pt(44.5, 24.5))
        p.move(pt(53, 22)); p.addQuadCurve(pt(58, 22), pt(55.5, 24.5))
    })
    ctx.ellipse(39, 25, 5, 3, Palette.blush.opacity(0.8))
    ctx.ellipse(56, 25, 5, 3, Palette.blush.opacity(0.8))
    ctx.circle(44, 11, 2, shine)
    sparkle(ctx, 76, 10, 7, rgb(0xF7D27A))
    sparkle(ctx, 22, 20, 5, rgb(0xF7D27A))
}

// MARK: - Trang trí tường (phía trên giường)

function wallGarland(ctx: GC) {
    const a = pt(4, 22), c = pt(50, 50), b = pt(96, 22)
    ctx.strokePath(rgb(0xA593B8), 1.4, (p) => {
        p.move(a); p.addQuadCurve(b, c)
    })
    const colors = [rgb(0xF4A9A0), rgb(0xF7D27A), rgb(0xA9DDB8), rgb(0xB9A6EA), rgb(0xF6AFC4), rgb(0xAFCFF2), rgb(0xF7C59F)]
    for (let i = 0; i < 7; i++) {
        const t = 0.1 + (i) * 0.8 / 6
        const m = quad(a, c, b, t)
        ctx.polygon([pt(m.x - 6, m.y - 0.5), pt(m.x + 6, m.y - 0.5), pt(m.x, m.y + 15)], colors[i])
        ctx.polygon([pt(m.x - 4, m.y + 0.5), pt(m.x - 1, m.y + 0.5), pt(m.x - 1.6, m.y + 7)], Color.white.opacity(0.4))
    }
    ctx.circle(a.x, a.y, 2.6, rgb(0xCFA175))
    ctx.circle(b.x, b.y, 2.6, rgb(0xCFA175))
}

function wallFairy(ctx: GC) {
    const swags = [[pt(4, 18), pt(27, 44), pt(50, 22)], [pt(50, 22), pt(73, 44), pt(96, 18)]] as const
    for (const [a, c, b] of swags) {
        ctx.strokePath(rgb(0x8F86A8), 1.2, (p) => {
            p.move(a); p.addQuadCurve(b, c)
        })
    }
    const colors = [rgb(0xFFE08A), rgb(0xF9B8C8), rgb(0xB8E6C4), rgb(0xFFE08A), rgb(0xF9B8C8), rgb(0xB8E6C4)]
    let k = 0
    for (const [a, c, b] of swags) {
        for (const t of [(0.22), 0.5, 0.78]) {
            const m = quad(a, c, b, t)
            ctx.circle(m.x, m.y + 6, 8, colors[k].opacity(0.25))
            ctx.circle(m.x, m.y + 6, 5, colors[k].opacity(0.3))
            ctx.rect(m.x - 1.8, m.y - 0.5, 3.6, 3.5, rgb(0x8F86A8), 1)
            ctx.ellipse(m.x - 3, m.y + 2, 6, 8.5, colors[k])
            ctx.ellipse(m.x - 1.6, m.y + 3.5, 1.8, 3, Color.white.opacity(0.75))
            k += 1
        }
    }
    for (const [x, y, s] of ([[16, 44, 7], [50, 40, 6], [84, 46, 7], [34, 12, 5], [68, 10, 5]] as const)) {
        sparkle(ctx, x, y, s, rgb(0xF7D27A))
    }
    ctx.circle(4, 18, 2.4, rgb(0xCFA175))
    ctx.circle(50, 22, 2.4, rgb(0xCFA175))
    ctx.circle(96, 18, 2.4, rgb(0xCFA175))
}

function wallMoon(ctx: GC) {
    const navy = rgb(0x3F3A78)
    // Dây treo
    ctx.strokePath(rgb(0xA593B8), 1.2, (p) => {
        p.move(pt(26, 14)); p.addLine(pt(50, 3)); p.addLine(pt(74, 14))
    })
    ctx.circle(50, 3, 2.2, rgb(0xCFA175))
    // Khung
    ctx.rect(12, 12, 76, 66, rgb(0xF2D7B6), 5)
    ctx.rect(17, 17, 66, 56, navy, 2.5)
    // Sao
    for (const [x, y] of ([[26, 26], [72, 24], [64, 42], [30, 50], [76, 54]] as const)) {
        ctx.circle(x, y, 1, rgb(0xFFF1C2))
    }
    sparkle(ctx, 70, 33, 8, rgb(0xFFE08A))
    sparkle(ctx, 25, 36, 6, rgb(0xFFE08A))
    // Trăng khuyết đang ngủ
    ctx.circle(46, 40, 15, rgb(0xFFE7A0))
    ctx.circle(54, 34, 13, navy)
    ctx.strokePath(ink, 1.4, (p) => {
        p.move(pt(37, 41)); p.addQuadCurve(pt(42, 43), pt(39, 44.5))
    })
    ctx.ellipse(36, 45, 5, 2.8, Palette.blush.opacity(0.85))
    ctx.circle(37, 31, 1.8, shine)
    ctx.text("z", 8, rgb(0xD9CCF2), pt(58, 30), 'bold')
    ctx.text("z", 6, rgb(0xD9CCF2), pt(64, 24), 'bold')
    // Mây
    const cl = ctx.copy()
    cl.clip(Path.roundedRect(R(17, 17, 66, 56), 2.5))
    cl.ellipse(18, 58, 66, 22, rgb(0xE9E4F8))
    cl.circle(36, 60, 9, rgb(0xE9E4F8))
    cl.circle(52, 56, 10, rgb(0xE9E4F8))
    cl.circle(68, 61, 8, rgb(0xE9E4F8))
    cl.circle(48, 52, 2.5, Color.white.opacity(0.6))
    ctx.rect(14, 13.5, 30, 1.6, Color.white.opacity(0.5), 0.8)
}

function wallDreamcatcher(ctx: GC) {
    const hoop = rgb(0xCFA175)
    const web = rgb(0xFFF6EC)
    const center = pt(50, 34)
    ctx.strokePath(rgb(0xA593B8), 1.2, (p) => {
        p.move(pt(50, 3)); p.addLine(pt(50, 13))
    })
    ctx.circle(50, 3, 2.2, hoop)
    // Lưới
    const pts: Pt[] = []
    for (let i = 0; i < 7; i++) {
        const a = (i) / 7 * 2 * Math.PI - Math.PI / 2
        pts.push(pt(center.x + 20 * (Math.cos(a)), center.y + 20 * (Math.sin(a))))
    }
    ctx.strokePath(web, 0.9, (p) => {
        for (let i = 0; i < 7; i++) {
            p.move(pts[i]); p.addLine(pts[(i + 3) % 7])
        }
        p.addEllipse(R(center.x - 9, center.y - 9, 18, 18))
    })
    ctx.circle(center.x, center.y, 3, rgb(0xB9A6EA))
    ctx.strokePath(hoop, 4, (p) => {
        p.addEllipse(R(center.x - 20, center.y - 20, 40, 40))
    })
    ctx.strokePath(Color.white.opacity(0.45), 1, (p) => {
        p.addArc(center, 20, deg(200), deg(250), false)
    })
    // Lông vũ
    const feathers = [[34, 52, rgb(0xF6AFC4), 10], [50, 56, rgb(0xB9A6EA), 0], [66, 52, rgb(0xA9DDB8), -10]] as const
    for (const [x, y, color, tilt] of feathers) {
        const end = y + 16
        ctx.strokePath(web.opacity(0.9), 0.9, (p) => {
            p.move(pt(x, y)); p.addLine(pt(x, end))
        })
        ctx.circle(x, y + 8, 2.2, rgb(0xF7D27A))
        ctx.rotated(tilt, pt(x, end), (c) => {
            c.ellipse(x - 4.5, end, 9, 20, color)
            c.strokePath(Color.white.opacity(0.6), 0.8, (p) => {
                p.move(pt(x, end + 2)); p.addLine(pt(x, end + 18))
            })
        })
    }
}

// MARK: - Tủ [chân chạm y ≈ 99, ngay đường tường–sàn]

function closetDresser(ctx: GC) {
    const body = rgb(0xEBC9A8)
    const top = rgb(0xD6AB84)
    const drawer = rgb(0xF6DEC4)
    const knob = rgb(0xB98A62)
    shadow(ctx, 6, 95, 88, 7)
    ctx.rect(14, 92, 6, 7, top, 1.5)
    ctx.rect(80, 92, 6, 7, top, 1.5)
    ctx.rect(10, 40, 80, 54, body, 5)
    ctx.rect(6, 36, 88, 7, top, 3)
    ctx.rect(9, 37, 40, 1.6, Color.white.opacity(0.35), 0.8)
    for (let i = 0; i < 3; i++) {
        const y = 47 + (i) * 15
        ctx.rect(16, y, 68, 12, drawer, 3)
        ctx.circle(36, y + 6, 2.6, knob)
        ctx.circle(64, y + 6, 2.6, knob)
        ctx.circle(35.2, y + 5.2, 0.9, shine)
        ctx.circle(63.2, y + 5.2, 0.9, shine)
    }
    // Chậu cây nhỏ
    ctx.rect(18, 26, 14, 10, rgb(0xF4B0C0), 3)
    ctx.ellipse(14, 14, 12, 14, rgb(0x8FC79C))
    ctx.ellipse(23, 10, 12, 17, rgb(0xA9DDB8))
    // Khung ảnh có trái tim
    ctx.rect(58, 18, 20, 18, rgb(0xFFFBF5), 2.5)
    ctx.rect(61, 21, 14, 12, rgb(0xD9E8F6), 1.5)
    ctx.heart(pt(68, 27), 7, rgb(0xF4A9C0))
}

function closetMirror(ctx: GC) {
    const frame = rgb(0xF2C6D6)
    const frameDark = rgb(0xE3A9BF)
    shadow(ctx, 18, 94, 64, 7)
    // Chân đế
    ctx.polygon([pt(44, 78), pt(56, 78), pt(70, 97), pt(62, 97)], frameDark)
    ctx.polygon([pt(44, 78), pt(56, 78), pt(38, 97), pt(30, 97)], frameDark)
    ctx.rect(46, 74, 8, 22, frame, 3)
    // Khung + gương
    ctx.ellipse(24, 6, 52, 76, frame)
    ctx.ellipse(29, 11, 42, 66, rgb(0xDDEEF8))
    const g = ctx.copy()
    g.clip(Path.ellipse(R(29, 11, 42, 66)))
    g.ellipse(26, 52, 50, 34, rgb(0xC9E2F3))
    g.polygon([pt(34, 40), pt(54, 14), pt(60, 14), pt(36, 48)], Color.white.opacity(0.65))
    g.polygon([pt(40, 54), pt(62, 26), pt(65, 30), pt(42, 58)], Color.white.opacity(0.45))
    ctx.heart(pt(50, 6), 12, rgb(0xF4A9C0))
    ctx.circle(28, 44, 2, Color.white.opacity(0.6))
    ctx.circle(72, 44, 2, Color.white.opacity(0.6))
    ctx.circle(50, 81.5, 2, Color.white.opacity(0.6))
}

function closetWardrobe(ctx: GC) {
    const body = rgb(0xD5C4EF)
    const door = rgb(0xE8DFF8)
    const top = rgb(0xBEA9E6)
    shadow(ctx, 4, 95, 92, 7)
    ctx.rect(14, 92, 7, 7, top, 1.5)
    ctx.rect(79, 92, 7, 7, top, 1.5)
    ctx.rect(8, 10, 84, 84, body, 5)
    ctx.rect(4, 4, 92, 9, top, 4)
    ctx.rect(7, 5, 40, 2, Color.white.opacity(0.35), 1)
    ctx.rect(13, 17, 36, 72, door, 4)
    ctx.rect(51, 17, 36, 72, door, 4)
    ctx.rect(18, 23, 26, 26, body.opacity(0.55), 3)
    ctx.rect(18, 55, 26, 28, body.opacity(0.55), 3)
    ctx.rect(56, 55, 26, 28, body.opacity(0.55), 3)
    ctx.circle(45, 52, 2.6, rgb(0xF7D27A))
    ctx.circle(55, 52, 2.6, rgb(0xF7D27A))
    ctx.circle(44.3, 51.3, 0.9, shine)
    ctx.circle(54.3, 51.3, 0.9, shine)
    // Móc treo khăn
    ctx.rect(64, 24, 12, 3, rgb(0xCFA175), 1.5)
    ctx.rect(63, 25, 14, 26, rgb(0xF4B0B0), 3)
    ctx.rect(63, 25, 14, 5, rgb(0xF8C8C8), 3)
    ctx.rect(63, 41, 14, 2.4, Color.white.opacity(0.8))
    ctx.rect(63, 45, 14, 1.4, Color.white.opacity(0.8))
    ctx.heart(pt(50, 8.5), 6, rgb(0xF4A9C0))
}

function closetVanity(ctx: GC) {
    const wood = rgb(0xF6D2DD)
    const woodDark = rgb(0xE9B3C5)
    shadow(ctx, 6, 95, 88, 7)
    // Chân bàn
    ctx.rect(14, 66, 6, 32, woodDark, 3)
    ctx.rect(80, 66, 6, 32, woodDark, 3)
    ctx.rect(16, 86, 68, 3, woodDark, 1.5)
    // Mặt bàn + ngăn kéo
    ctx.rect(10, 60, 80, 16, wood, 4)
    ctx.rect(6, 55, 88, 7, woodDark, 3)
    ctx.rect(9, 56, 40, 1.5, Color.white.opacity(0.4), 0.8)
    ctx.rect(32, 64, 36, 9, rgb(0xFCE8EE), 2.5)
    ctx.circle(50, 68.5, 1.8, rgb(0xF7D27A))
    // Gương tròn viền đèn
    ctx.rect(45, 46, 10, 10, woodDark, 2)
    ctx.circle(50, 29, 24, rgb(0xFFF6FA))
    ctx.circle(50, 29, 18, rgb(0xDDEEF8))
    const g = ctx.copy()
    g.clip(Path.ellipse(R(32, 11, 36, 36)))
    g.polygon([pt(36, 30), pt(52, 12), pt(58, 12), pt(38, 36)], Color.white.opacity(0.65))
    for (let i = 0; i < 12; i++) {
        const a = (i) / 12 * 2 * Math.PI
        const x = 50 + 21 * (Math.cos(a)), y = 29 + 21 * (Math.sin(a))
        ctx.circle(x, y, 3.6, rgb(0xFFE08A).opacity(0.3))
        ctx.circle(x, y, 2.2, rgb(0xFFF1C2))
    }
    // Lọ nước hoa & son
    ctx.rect(15, 44, 10, 11, rgb(0xB9A6EA), 3)
    ctx.rect(18, 40, 4, 4, rgb(0xF7D27A), 1)
    ctx.rect(17, 46, 2, 6, Color.white.opacity(0.6), 1)
    ctx.rect(78, 45, 5, 10, rgb(0xF4A9C0), 1.5)
    ctx.rect(78.5, 41, 4, 4, rgb(0xE0625A), 1.8)
    ctx.ellipse(64, 51, 10, 4.5, rgb(0xA9DDB8))
}

// MARK: - Thảm (vẽ trong x 18…88, y 58…96 rồi phóng to quanh đáy để nằm dưới chân thú cưng)

function rugSpace(ctx: GC): GC {
    const c = ctx.copy()
    c.translateBy(52, 95)
    c.scaleBy(1.12, 1.25)
    c.translateBy(-53, -96)
    return c
}

function rugRound(ctx: GC) {
    ctx.ellipse(18, 61, 70, 35, rgb(0xE8D3B8))
    ctx.ellipse(18, 58, 70, 35, rgb(0xF8ECDB))
    ctx.ellipse(24, 61, 58, 29, rgb(0xD9CCF2))
    ctx.ellipse(29, 63.5, 48, 24, rgb(0xF8ECDB))
    ctx.ellipse(39, 68.5, 28, 14, rgb(0xF6C3C3))
    ctx.ellipse(45, 71.5, 16, 8, rgb(0xFBDDDA))
    // Hạt len
    for (let i = 0; i < 10; i++) {
        const a = (i) / 10 * 2 * Math.PI
        ctx.circle(53 + 26.5 * (Math.cos(a)), 75.5 + 13 * (Math.sin(a)), 1.2, Color.white.opacity(0.75))
    }
}

function rugHeart(ctx: GC) {
    const c = ctx.copy()
    c.translateBy(53, 78)
    c.scaleBy(1, 0.58)
    c.heart(pt(0, 6), 70, rgb(0xEC97AF))
    c.heart( pt(0, 0), 70, rgb(0xF6B3C6))
    c.heart(pt(0, 1), 52, rgb(0xFAC9D6))
    c.heart(pt(0, 2), 30, rgb(0xFDE0E8))
    for (const [x, y] of ([[-22, -12], [18, -14], [-8, 8], [10, 4], [0, -6], [-26, -2], [26, -4]] as const)) {
        c.circle(x, y, 1.6, Color.white.opacity(0.7))
    }
}

function rugCloud(ctx: GC) {
    const shade = rgb(0xCFE0F3)
    const white = rgb(0xFBFDFF)
    for (const [dy, color] of ([[(3), shade], [0, white]] as const)) {
        ctx.ellipse(22, 74 + dy, 62, 18, color)
        ctx.ellipse(18, 70 + dy, 26, 18, color)
        ctx.ellipse(32, 61 + dy, 30, 22, color)
        ctx.ellipse(52, 60 + dy, 28, 22, color)
        ctx.ellipse(66, 68 + dy, 22, 20, color)
    }
    ctx.ellipse(38, 65, 14, 5, Color.white)
    ctx.ellipse(36, 64, 9, 3, rgb(0xE6F0FA))
    for (const [x, y] of ([[30, 80], [52, 84], [72, 78]] as const)) {
        ctx.circle(x, y, 1.4, shade)
    }
}

function rugRainbow(ctx: GC) {
    const colors = [rgb(0xF4A3A8), rgb(0xF7C59F), rgb(0xF9E3A0), rgb(0xBFE3B4), rgb(0xAFD3F2), rgb(0xB9B4EE), rgb(0xD8B9EE)]
    const c = ctx.copy()
    c.clip(Path.rect(R(0, 0, 100, 90)))
    const cx = 53, cy: number = 90
    for (const [i, color] of colors.entries()) {
        const rx = 34 - (i) * 3.6
        const ry = rx * 0.82
        c.ellipse(cx - rx, cy - ry, rx * 2, ry * 2, color)
    }
    const rx = 34 - 7 * 3.6
    c.ellipse(cx - rx, cy - rx * 0.82, rx * 2, rx * 1.64, rgb(0xFFF6EC))
    ctx.rect(19, 89, 68, 3, Color.black.opacity(0.07), 1.5)
    // Mây hai chân cầu vồng
    for (const x of [(17), 68]) {
        ctx.ellipse(x, 84, 22, 10, rgb(0xDDE8F5))
        ctx.ellipse(x, 82, 22, 9, Color.white)
        ctx.circle(x + 7, 82, 5, Color.white)
        ctx.circle(x + 14, 81, 6, Color.white)
    }
}

// MARK: - Đồ chơi (góc trái phía trước, chân chạm y ≈ 94)

function plushYarn(ctx: GC) {
    const yarn = rgb(0xF4A9C0)
    const line = rgb(0xDE86A4)
    shadow(ctx, 14, 86, 72, 10)
    // Sợi len lòng thòng
    ctx.strokePath(yarn, 3, (p) => {
        p.move(pt(68, 80))
        p.addQuadCurve(pt(84, 88), pt(76, 92))
        p.addQuadCurve(pt(92, 78), pt(96, 86))
        p.addQuadCurve(pt(86, 90), pt(84, 80))
    })
    ctx.circle(46, 62, 28, yarn)
    const c = ctx.copy()
    c.clip(Path.ellipse(R(18, 34, 56, 56)))
    c.strokePath(line, 2.2, (p) => {
        for (let i = 0; i < 5; i++) {
            const o = (i) * 9
            p.move(pt(14, 46 + o)); p.addQuadCurve(pt(78, 30 + o), pt(40, 26 + o))
        }
        for (let i = 0; i < 3; i++) {
            const o = (i) * 10
            p.move(pt(30 + o, 92)); p.addQuadCurve(pt(58 + o, 34), pt(30 + o, 54))
        }
    })
    ctx.ellipse(28, 44, 12, 8, Color.white.opacity(0.45))
    // Que đan
    ctx.rect(56, 22, 3.5, 44, rgb(0xCFA175), 1.75)
    ctx.circle(57.7, 22, 3.4, rgb(0xB9A6EA))
}

function plushBall(ctx: GC) {
    shadow(ctx, 16, 86, 68, 10)
    ctx.circle(50, 62, 28, rgb(0xFFF6EC))
    const c = ctx.copy()
    c.clip(Path.ellipse(R(22, 34, 56, 56)))
    c.rotated(-24, pt(50, 62), (r) => {
        r.rect(10, 38, 80, 10, rgb(0xF4A3A8))
        r.rect(10, 57, 80, 10, rgb(0xAFD3F2))
        r.rect(10, 76, 80, 10, rgb(0xF9D98A))
    })
    c.ellipse(22, 74, 56, 22, Color.black.opacity(0.05))
    ctx.ellipse(32, 42, 14, 9, Color.white.opacity(0.6))
    ctx.circle(47, 40, 2, Color.white.opacity(0.6))
}

function plushTeddy(ctx: GC) {
    const fur = rgb(0xCFA27A)
    const furDark = rgb(0xB8875F)
    const light = rgb(0xF1D8BE)
    shadow(ctx, 14, 86, 72, 10)
    // Chân
    ctx.ellipse(20, 72, 26, 20, fur)
    ctx.ellipse(54, 72, 26, 20, fur)
    ctx.ellipse(24, 76, 14, 12, light)
    ctx.ellipse(62, 76, 14, 12, light)
    // Thân + tay
    ctx.ellipse(28, 48, 44, 40, fur)
    ctx.ellipse(37, 58, 26, 26, light)
    ctx.ellipse(16, 52, 18, 24, furDark)
    ctx.ellipse(66, 52, 18, 24, furDark)
    // Đầu
    ctx.circle(31, 18, 9, fur)
    ctx.circle(69, 18, 9, fur)
    ctx.circle(31, 18, 4.5, light)
    ctx.circle(69, 18, 4.5, light)
    ctx.circle(50, 34, 23, fur)
    ctx.ellipse(40, 36, 20, 15, light)
    ctx.ellipse(46.5, 37.5, 7, 5, ink)
    ctx.strokePath(ink, 1.3, (p) => {
        p.move(pt(50, 42)); p.addLine(pt(50, 45))
        p.move(pt(46.5, 46)); p.addQuadCurve(pt(53.5, 46), pt(50, 48.5))
    })
    ctx.circle(41, 30, 2.8, ink)
    ctx.circle(59, 30, 2.8, ink)
    ctx.circle(40.2, 29.2, 0.9, Color.white.opacity(0.8))
    ctx.circle(58.2, 29.2, 0.9, Color.white.opacity(0.8))
    ctx.ellipse(32, 38, 7, 4, Palette.blush.opacity(0.85))
    ctx.ellipse(61, 38, 7, 4, Palette.blush.opacity(0.85))
    ctx.ellipse(40, 16, 10, 6, Color.white.opacity(0.3))
    // Nơ cổ
    ctx.polygon([pt(50, 56), pt(38, 50), pt(38, 62)], rgb(0xF4A9C0))
    ctx.polygon([pt(50, 56), pt(62, 50), pt(62, 62)], rgb(0xF4A9C0))
    ctx.circle(50, 56, 3, rgb(0xEC8FAE))
}

function plushDino(ctx: GC) {
    const green = rgb(0xA9DDB8)
    const shade = rgb(0x86C79A)
    const belly = rgb(0xE2F4E6)
    const spike = rgb(0xF7C59F)
    shadow(ctx, 6, 86, 84, 10)
    // Đuôi
    let tail = new Path()
    tail.move(pt(30, 64))
    tail.addQuadCurve(pt(4, 86), pt(10, 68))
    tail.addQuadCurve(pt(34, 88), pt(18, 92))
    tail.closeSubpath()
    ctx.fill(tail, (green))
    // Gai lưng
    for (const [x, y] of ([[24, 56], [32, 46], [44, 40], [14, 70]] as const)) {
        ctx.polygon([pt(x - 6, y + 4), pt(x, y - 7), pt(x + 6, y + 4)], spike)
    }
    // Chân sau
    ctx.ellipse(26, 76, 18, 16, shade)
    ctx.ellipse(54, 76, 18, 16, shade)
    // Thân
    ctx.ellipse(22, 44, 52, 46, green)
    ctx.ellipse(42, 56, 26, 30, belly)
    // Đầu
    ctx.polygon([pt(56, 14), pt(62, 4), pt(67, 13)], spike)
    ctx.polygon([pt(68, 14), pt(76, 6), pt(78, 16)], spike)
    ctx.ellipse(50, 12, 42, 34, green)
    ctx.ellipse(70, 24, 24, 20, green)
    ctx.circle(84, 30, 1.2, shade)
    ctx.circle(88, 28, 1.2, shade)
    // Mặt
    ctx.circle(68, 24, 3.4, ink)
    ctx.circle(67, 23, 1.1, Color.white.opacity(0.85))
    ctx.ellipse(70, 31, 8, 4.5, Palette.blush.opacity(0.85))
    ctx.strokePath(ink, 1.4, (p) => {
        p.move(pt(78, 36)); p.addQuadCurve(pt(90, 34), pt(84, 39))
    })
    ctx.polygon([pt(81, 36.5), pt(84.5, 36.8), pt(82.6, 40.5)], Color.white)
    // Tay nhỏ
    ctx.ellipse(64, 52, 12, 8, shade)
    ctx.ellipse(56, 18, 12, 7, Color.white.opacity(0.35))
}

export const BedroomArt = { draw }
