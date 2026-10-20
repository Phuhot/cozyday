// Chuyển tự động từ Swift (scripts/port/swift2ts.mjs) rồi sửa tay.
import { GC, Color, rgb, pt, R, Path, deg, Pt, Rect, linear, radial } from '../gc'
import { Palette } from '../palette'
import type { PetAppearance } from '../../content/pet'
import { furPalette, type FurPalette } from './PetPainter'

// Trang phục & phụ kiện thêm cho thú cưng (hệ tọa độ 100×100 giống `PetPainter`).
// Mắt ở [37.5, 50] và [62.5, 50]; đỉnh đầu ở y≈28; vùng cổ y≈61–67; chân trước ở [36..46 | 54..64, 80..87].

// MARK: Tiện ích
// Bản lật ngang (x → 100 − x) để vẽ đồ đối xứng một lần cho cả hai bên.
function mirrored(ctx: GC, flip: boolean): GC {
    const c = ctx.copy()
    if (flip) {
        c.translateBy(100, 0)
        c.scaleBy(-1, 1)
    }
    return c
}

// Đa giác bo tròn góc (tô rồi viền cùng màu, đầu nét tròn).
function soft(ctx: GC, pts: Pt[], color: Color, round: number = 2) {
    ctx.polygon(pts, color)
    ctx.strokePath(color, round, (p) => {
        p.addLines(pts)
        p.closeSubpath()
    })
}

function starPoints(cx: number, cy: number, r: number, inner: number): Pt[] {
    const pts: Pt[] = []
    for (let i = 0; i < 10; i++) {
        const ang = -Math.PI / 2 + (i) * Math.PI / 5
        const rr = i % 2 == 0 ? r : inner
        pts.push(pt(cx + rr * (Math.cos(ang)), cy + rr * (Math.sin(ang))))
    }
    return pts
}

function star(ctx: GC, cx: number, cy: number, r: number, color: Color) {
    soft(ctx, starPoints(cx, cy, r, r * 0.48), color, r * 0.3)
}

function sparkle(ctx: GC, x: number, y: number, size: number, color: Color) {
    ctx.text("✦", size, color, pt(x, y))
}

// MARK: Mũ

export function hat(id: string, ctx: GC, a: PetAppearance) {
    switch (id) {
    case "hat.catears": { catEars(ctx, a)
    } break; case "hat.cap": { cap(ctx, a)
    } break; case "hat.beret": { beret(ctx)
    } break; case "hat.santa": { santa(ctx)
    } break; case "hat.antlers": { antlers(ctx)
    } break; case "hat.chef": { chef(ctx)
    } break; case "hat.pumpkin": { pumpkin(ctx)
    } break; case "hat.frog": { frogHat(ctx)
    } break; case "hat.headphones": { headphones(ctx, a)
    } break; case "hat.cowboy": { cowboy(ctx)
    } break; case "hat.cloud": { cloud(ctx)
    } break; case "hat.halo": { halo(ctx)
    } break; case "hat.tiara": { tiara(ctx)
    } break; default: { break
    } }
}

function catEars(ctx: GC, a: PetAppearance) {
    const night = a.fur == 'midnight'
    const band = night ? rgb(0xE77FA0) : rgb(0x544866)
    const inner = night ? rgb(0xFCE0EA) : rgb(0xF4A9C0)
    for (const flip of [false, true]) {
        const c = mirrored(ctx, flip)
        soft(c, [pt(32.5, 34.5), pt(36, 13.5), pt(48, 29)], band, 3)
        soft(c, [pt(36, 30.5), pt(37.6, 20), pt(44, 29)], inner, 1.2)
    }
    ctx.strokePath(band, 3.2, (p) => {
        p.move(pt(25, 41)); p.addQuadCurve(pt(75, 41), pt(50, 15))
    })
    ctx.strokePath(Color.white.opacity(0.35), 0.9, (p) => {
        p.move(pt(30, 33.5)); p.addQuadCurve(pt(40, 28.5), pt(34, 30))
    })
}

function cap(ctx: GC, a: PetAppearance) {
    const blue = rgb(0x7FA6E0), deep = rgb(0x5F86C6)
    // Lưỡi trai quay ra sau, ló lên phía sau đỉnh mũ.
    ctx.rotated(-24, pt(66, 22), (c) => (c.ellipse(54, 16, 32, 8.5, deep)))
    const dome = ctx.copy()
    dome.clip(Path.rect(R(0, 0, 100, 34)))
    dome.ellipse(26, 15, 48, 38, blue)
    ctx.strokePath(deep.opacity(0.55), 0.9, (p) => {
        p.move(pt(50, 16)); p.addQuadCurve(pt(37, 33), pt(39, 19))
        p.move(pt(50, 16)); p.addQuadCurve(pt(63, 33), pt(61, 19))
    })
    // Lỗ khóa cài phía trước (vì đội ngược).
    const hole = ctx.copy()
    hole.clip(Path.rect(R(0, 0, 100, 32)))
    hole.ellipse(42.5, 24.5, 15, 16, furPalette(a.fur).base)
    ctx.rect(42, 28.8, 16, 2.2, deep, 1.1)
    ctx.rect(47.5, 28.4, 3, 3, rgb(0xF0C26A), 0.8)
    ctx.rect(26, 31.5, 48, 3.6, deep, 1.8)
    ctx.circle(50, 15.6, 2.2, deep)
    ctx.ellipse(31, 20, 8, 4, Color.white.opacity(0.35))
}

function beret(ctx: GC) {
    const red = rgb(0xCF5866), deep = rgb(0xA9424F)
    ctx.rotated(-9, pt(54, 26), (c) => {
        c.rect(52.5, 11.5, 3, 6, deep, 1.5)
        c.ellipse(29, 23, 50, 10.5, deep)
        c.ellipse(27, 15, 54, 16, red)
        c.ellipse(36, 17.5, 15, 4.5, Color.white.opacity(0.3))
    })
}

function santa(ctx: GC) {
    const red = rgb(0xE0565B), deep = rgb(0xC4434B)
    const fluff = rgb(0xFFFDFB), fshade = rgb(0xE6DFEC)
    let p = new Path()
    p.move(pt(29, 31))
    p.addQuadCurve(pt(60, 8), pt(33, 11))
    p.addQuadCurve(pt(82, 25), pt(78, 8))
    p.addQuadCurve(pt(71, 31), pt(73, 19))
    p.closeSubpath()
    ctx.fill(p, (red))
    ctx.strokePath(deep, 1.2, (q) => {
        q.move(pt(64, 12)); q.addQuadCurve(pt(74, 24), pt(72, 14))
    })
    ctx.strokePath(Color.white.opacity(0.35), 1.4, (q) => {
        q.move(pt(37, 25)); q.addQuadCurve(pt(48, 13), pt(40, 16))
    })
    ctx.rect(22.5, 28.3, 55, 8.7, fshade, 4.3)
    ctx.rect(22.5, 27.3, 55, 8, fluff, 4)
    for (let x = (28); x < 72; x += 7) {
        ctx.circle(x, 32.5, 1.1, fshade)
    }
    ctx.circle(83.4, 26.6, 5.3, fshade)
    ctx.circle(83, 26, 4.9, fluff)
}

function antlers(ctx: GC) {
    const horn = rgb(0xB98256)
    for (const flip of [false, true]) {
        const c = mirrored(ctx, flip)
        c.strokePath(horn, 3.4, (p) => {
            p.move(pt(40, 30)); p.addQuadCurve(pt(31, 5), pt(29, 21))
            p.move(pt(32.2, 19.3)); p.addQuadCurve(pt(21, 12), pt(25, 18.5))
            p.move(pt(30.8, 12.6)); p.addQuadCurve(pt(37.5, 5.5), pt(34, 10))
        })
        c.strokePath(Color.white.opacity(0.35), 0.9, (p) => {
            p.move(pt(37.5, 27)); p.addQuadCurve(pt(31.5, 12), pt(31, 20))
        })
    }
    // Nhánh nhựa ruồi nhỏ ở giữa.
    const leaf = rgb(0x6FAF72)
    ctx.rotated(-28, pt(47, 27), (c) => (c.ellipse(39.5, 24.5, 9, 5, leaf)))
    ctx.rotated(28, pt(53, 27), (c) => (c.ellipse(51.5, 24.5, 9, 5, leaf)))
    const berry = rgb(0xE0565B)
    ctx.circle(48.2, 28.2, 1.9, berry)
    ctx.circle(51.8, 28.2, 1.9, berry)
    ctx.circle(50, 25.6, 1.9, berry)
    ctx.circle(49.5, 25, 0.6, Color.white.opacity(0.7))
}

function chef(ctx: GC) {
    const white = rgb(0xFFFFFF), line = rgb(0xDAD2E4)
    ctx.circle(38, 17.5, 10.5, line)
    ctx.circle(50, 13, 12, line)
    ctx.circle(62, 17.5, 10.5, line)
    ctx.rect(31, 16, 38, 18.5, line, 4)
    ctx.circle(38, 17.5, 9.5, white)
    ctx.circle(50, 13, 11, white)
    ctx.circle(62, 17.5, 9.5, white)
    ctx.rect(32, 17, 36, 10, white)
    ctx.rect(32, 24.5, 36, 9, rgb(0xF6F2F8), 3)
    ctx.strokePath(line, 1, (p) => {
        p.move(pt(33, 24.5)); p.addLine(pt(67, 24.5))
        p.move(pt(44, 14)); p.addQuadCurve(pt(43, 23), pt(41.5, 18.5))
        p.move(pt(56, 14)); p.addQuadCurve(pt(57, 23), pt(58.5, 18.5))
    })
    ctx.ellipse(43, 6, 7, 4, rgb(0xF4F0F8))
}

function pumpkin(ctx: GC) {
    const o1 = rgb(0xF6A04F), o2 = rgb(0xE5853A)
    ctx.strokePath(rgb(0x7FA052), 1.2, (p) => {
        p.move(pt(52, 9)); p.addQuadCurve(pt(60, 6), pt(54, 3))
        p.addQuadCurve(pt(58, 9.5), pt(62, 9))
    })
    ctx.rect(48.2, 4.5, 3.6, 8, rgb(0x7A8F4E), 1.6)
    ctx.ellipse(30, 12, 24, 22.5, o2)
    ctx.ellipse(46, 12, 24, 22.5, o2)
    ctx.ellipse(37, 10.5, 26, 24, o1)
    ctx.ellipse(40, 12.5, 6, 3.5, Color.white.opacity(0.35))
    ctx.rotated(28, pt(56, 8), (c) => (c.ellipse(53, 5.5, 10, 5, rgb(0x8CBF6E))))
    const carve = rgb(0x8A4A1E)
    soft(ctx, [pt(41, 21.5), pt(46, 21.5), pt(43.5, 17.5)], carve, 1)
    soft(ctx, [pt(54, 21.5), pt(59, 21.5), pt(56.5, 17.5)], carve, 1)
    ctx.strokePath(carve, 1.6, (p) => {
        p.move(pt(44, 25.5)); p.addQuadCurve(pt(56, 25.5), pt(50, 30))
    })
}

function frogHat(ctx: GC) {
    const g = rgb(0x8CCB7E), gd = rgb(0x6FB063)
    const hood = ctx.copy()
    hood.clip(Path.rect(R(0, 0, 100, 35)))
    hood.ellipse(22, 16, 56, 46, g)
    ctx.rect(22.5, 31.5, 55, 5, gd, 2.5)
    for (const x of [(37), 63]) {
        ctx.circle(x, 20, 7.5, g)
        ctx.circle(x, 20.5, 5, Color.white)
        ctx.circle(x, 21.3, 2.7, rgb(0x2E2A36))
        ctx.circle(x - 0.9, 20.3, 0.9, Color.white)
    }
    ctx.strokePath(gd, 1.3, (p) => {
        p.move(pt(45, 27.5)); p.addQuadCurve(pt(55, 27.5), pt(50, 31))
    })
    ctx.ellipse(29.5, 26.5, 5, 2.6, rgb(0xF4A3B4).opacity(0.85))
    ctx.ellipse(65.5, 26.5, 5, 2.6, rgb(0xF4A3B4).opacity(0.85))
}

function headphones(ctx: GC, a: PetAppearance) {
    const hx = a.species == 'hamster' ? 3 : 0
    const band = rgb(0x8E7CC9), cup = rgb(0xF4A6BD), pad = rgb(0xDE8AA3)
    ctx.strokePath(band, 3.6, (p) => {
        p.move(pt(18 - hx, 44))
        p.addCurve(pt(82 + hx, 44), pt(17 - hx, 16), pt(83 + hx, 16))
    })
    ctx.strokePath(Color.white.opacity(0.4), 1, (p) => {
        p.move(pt(40, 24.5)); p.addQuadCurve(pt(56, 24), pt(48, 23))
    })
    for (const flip of [false, true]) {
        const c = mirrored(ctx, flip)
        c.rect(19.5 - hx, 41.5, 5, 14, pad, 2.5)
        c.rect(11.5 - hx, 39, 11, 19, cup, 5.5)
        c.ellipse(13.5 - hx, 42, 3, 7, Color.white.opacity(0.5))
    }
    ctx.text("♪", 7, band, pt(88, 26), 'bold')
}

function cowboy(ctx: GC) {
    const crown = rgb(0xC98F5E), brim = rgb(0xB57D4D), band = rgb(0x7A4E33)
    let cp = new Path()
    cp.move(pt(34, 30))
    cp.addLine(pt(35.5, 14))
    cp.addQuadCurve(pt(50, 13), pt(42, 7.5))
    cp.addQuadCurve(pt(64.5, 14), pt(58, 7.5))
    cp.addLine(pt(66, 30))
    cp.closeSubpath()
    ctx.fill(cp, (crown))
    ctx.strokePath(Color.white.opacity(0.3), 1.6, (p) => {
        p.move(pt(39, 15.5)); p.addLine(pt(38.5, 21.5))
    })
    ctx.rect(34.3, 23.3, 31.4, 4.6, band)
    star(ctx, 50, 25.6, 2.1, rgb(0xF0C26A))
    let bp = new Path()
    bp.move(pt(8, 21))
    bp.addQuadCurve(pt(50, 34), pt(20, 35.5))
    bp.addQuadCurve(pt(92, 21), pt(80, 35.5))
    bp.addQuadCurve(pt(50, 28.5), pt(78, 30))
    bp.addQuadCurve(pt(8, 21), pt(22, 30))
    bp.closeSubpath()
    ctx.fill(bp, (brim))
    ctx.strokePath(Color.white.opacity(0.25), 1, (p) => {
        p.move(pt(14, 25)); p.addQuadCurve(pt(30, 30.5), pt(20, 29.5))
    })
}

function cloud(ctx: GC) {
    const shade = rgb(0xC9D8EE), white = rgb(0xF9FBFF)
    for (const [dy, color] of ([[(1.6), shade], [(0), white]] as const)) {
        ctx.circle(39, 16 + dy, 7, color)
        ctx.circle(50, 12 + dy, 9.5, color)
        ctx.circle(61, 16 + dy, 7, color)
        ctx.rect(32, 14 + dy, 36, 9, color, 4.5)
    }
    const ink = rgb(0x6B6390)
    ctx.strokePath(ink, 1.1, (p) => {
        p.move(pt(43.4, 17)); p.addQuadCurve(pt(47, 17), pt(45.2, 14.6))
        p.move(pt(53, 17)); p.addQuadCurve(pt(56.6, 17), pt(54.8, 14.6))
        p.move(pt(48.8, 18.8)); p.addQuadCurve(pt(51.2, 18.8), pt(50, 20.3))
    })
    ctx.ellipse(39.5, 18, 4, 2, rgb(0xF4A3B4).opacity(0.75))
    ctx.ellipse(56.5, 18, 4, 2, rgb(0xF4A3B4).opacity(0.75))
    sparkle(ctx, 71, 8, 6, rgb(0xF0C26A))
    sparkle(ctx, 28, 9, 4, rgb(0xF0C26A))
}

function halo(ctx: GC) {
    const ring = R(31, 9.5, 38, 11)
    ctx.strokePath(rgb(0xFFE7A0).opacity(0.6), 5.5, (p) => (p.addEllipse(ring)))
    ctx.strokePath(rgb(0xF2C14E), 2.6, (p) => (p.addEllipse(ring)))
    ctx.strokePath(Color.white.opacity(0.75), 1, (p) => {
        p.move(pt(36, 11.8)); p.addQuadCurve(pt(46, 9.8), pt(40, 10))
    })
    sparkle(ctx, 73, 9, 5, rgb(0xF2C14E))
}

function tiara(ctx: GC) {
    const silver = rgb(0xBAC4E2), light = rgb(0xE9EEFB)
    const pts = [pt(29, 33), pt(31, 26), pt(35, 29.5), pt(40, 20), pt(45, 27), pt(50, 13), pt(55, 27), pt(60, 20),
               pt(65, 29.5), pt(69, 26), pt(71, 33), pt(60, 30.5), pt(50, 29.5), pt(40, 30.5)]
    soft(ctx, pts, silver, 1.6)
    ctx.strokePath(light, 1, (p) => {
        p.move(pt(31, 31.5)); p.addQuadCurve(pt(69, 31.5), pt(50, 26.5))
    })
    ctx.circle(40, 19.6, 1.6, light)
    ctx.circle(60, 19.6, 1.6, light)
    ctx.circle(31, 25.6, 1.2, light)
    ctx.circle(69, 25.6, 1.2, light)
    // Viên đá giữa hình giọt nước.
    let gem = new Path()
    gem.move(pt(50, 15.5))
    gem.addQuadCurve(pt(50, 26.5), pt(45, 23))
    gem.addQuadCurve(pt(50, 15.5), pt(55, 23))
    ctx.fill(gem, (rgb(0x7FD1EA)))
    ctx.ellipse(48.4, 20, 1.6, 3, Color.white.opacity(0.75))
    ctx.circle(40.5, 26, 1.9, rgb(0xF59AC0))
    ctx.circle(59.5, 26, 1.9, rgb(0xF59AC0))
    ctx.circle(34, 29.5, 1.2, rgb(0xB79BEA))
    ctx.circle(66, 29.5, 1.2, rgb(0xB79BEA))
    sparkle(ctx, 57, 13, 5, rgb(0xF0C26A))
    sparkle(ctx, 33, 19, 4, rgb(0xF0C26A))
}

// MARK: Kính

export function glasses(id: string, ctx: GC, a: PetAppearance) {
    switch (id) {
    case "glasses.nerd": { 
        const frame = rgb(0x5A4136)
        ctx.rect(28.5, 43, 18, 14, Color.white.opacity(0.22), 3)
        ctx.rect(53.5, 43, 18, 14, Color.white.opacity(0.22), 3)
        ctx.strokePath(frame, 2.4, (p) => {
            p.addRoundedRect(R(28.5, 43, 18, 14), 3)
            p.addRoundedRect(R(53.5, 43, 18, 14), 3)
            p.move(pt(46.5, 48)); p.addLine(pt(53.5, 48))
            p.move(pt(28.5, 47)); p.addLine(pt(21, 46))
            p.move(pt(71.5, 47)); p.addLine(pt(79, 46))
        })
        ctx.rect(47.8, 45.6, 4.4, 5, rgb(0xFBF8F2), 0.8)
        ctx.strokePath(Color.white.opacity(0.6), 1, (p) => {
            p.move(pt(31.5, 46.5)); p.addLine(pt(34, 45.5))
            p.move(pt(56.5, 46.5)); p.addLine(pt(59, 45.5))
        })
    } break; case "glasses.goggles": { 
        const rim = rgb(0x4FA9D6), strap = rgb(0x3F8FBE)
        ctx.strokePath(strap, 3, (p) => {
            p.move(pt(29, 50)); p.addLine(pt(18.5, 48))
            p.move(pt(71, 50)); p.addLine(pt(81.5, 48))
        })
        ctx.strokePath(strap, 2, (p) => {
            p.move(pt(46, 50)); p.addQuadCurve(pt(54, 50), pt(50, 47.5))
        })
        for (const cx of [(37.5), 62.5]) {
            ctx.ellipse(cx - 8.5, 42.5, 17, 15, rgb(0xBFE8F7).opacity(0.4))
            ctx.strokePath(rim, 2.8, (p) => {
                p.addEllipse(R(cx - 8.5, 42.5, 17, 15))
            })
            ctx.strokePath(Color.white.opacity(0.85), 1.2, (p) => {
                p.move(pt(cx - 5, 47.5)); p.addQuadCurve(pt(cx - 1, 45), pt(cx - 4.5, 45))
            })
        }
    } break; case "glasses.star": { 
        const yellow = rgb(0xF6C445), rim = rgb(0xE79A3A)
        for (const cx of [(37.5), 62.5]) {
            soft(ctx, starPoints(cx, 50.5, 10.5, 5.6), rim, 2.4)
            soft(ctx, starPoints(cx, 50.5, 9.2, 4.9), yellow.opacity(0.92), 1.6)
            ctx.circle(cx - 2.5, 47.5, 1.2, Color.white.opacity(0.85))
        }
        ctx.strokePath(rim, 1.4, (p) => {
            p.move(pt(46.5, 48.5)); p.addLine(pt(53.5, 48.5))
            p.move(pt(28, 47.5)); p.addLine(pt(21, 46))
            p.move(pt(72, 47.5)); p.addLine(pt(79, 46))
        })
        sparkle(ctx, 76, 40, 6, rgb(0xF0C26A))
    } break; case "glasses.aviator": { 
        const gold = rgb(0xD9A441), lens = rgb(0x5E7FA3)
        for (const flip of [false, true]) {
            const c = mirrored(ctx, flip)
            let l = new Path()
            l.move(pt(28.5, 44.5))
            l.addLine(pt(46.5, 44.5))
            l.addCurve(pt(38.5, 57.5), pt(47.5, 50.5), pt(44.5, 57.5))
            l.addCurve(pt(28.5, 44.5), pt(31, 57.5), pt(27, 49.5))
            l.closeSubpath()
            c.fill(l, (lens.opacity(0.85)))
            c.stroke(l, (gold), 1.3)
            c.strokePath(Color.white.opacity(0.5), 1.4, (p) => {
                p.move(pt(31.5, 47.5)); p.addLine(pt(35.5, 46.5))
            })
            c.strokePath(gold, 1.2, (p) => {
                p.move(pt(28.5, 45.5)); p.addLine(pt(21, 46))
            })
        }
        ctx.strokePath(gold, 1.2, (p) => {
            p.move(pt(46.5, 44.8)); p.addLine(pt(53.5, 44.8))
            p.move(pt(47, 48)); p.addQuadCurve(pt(53, 48), pt(50, 46.5))
        })
    } break; case "glasses.pixel": { 
        const ink = rgb(0x1F1B26)
        const s = 2.5, ox = 26.25, oy = 44.5
        function cell(col: number, row: number, color: Color) {
            ctx.rect(ox + (col) * s, oy + (row) * s, s + 0.05, s + 0.05, color)
        }
        for (let col = -2; col <= 20; col++) { cell(col, 0, ink) }
        for (const col of [1,2,3,4,5,6,7,11,12,13,14,15,16,17]) { cell(col, 1, ink) }
        for (const col of [2,3,4,5,6,12,13,14,15,16]) { cell(col, 2, ink) }
        for (const col of [3,4,5,13,14,15]) { cell(col, 3, ink) }
        for (const col of [2, 12]) { cell(col, 1, Color.white.opacity(0.85)) }
        for (const col of [3, 13]) { cell(col, 2, Color.white.opacity(0.85)) }
    } break; default: { 
        break
    } }
}

// MARK: Cổ

export function neck(id: string, ctx: GC, a: PetAppearance) {
    switch (id) {
    case "neck.collar": { 
        const band = rgb(0x7FB7D9)
        ctx.rect(26, 61.2, 48, 4.8, band, 2.4)
        ctx.rect(30, 62.1, 40, 1.1, Color.white.opacity(0.45), 0.5)
        ctx.strokePath(rgb(0xD9A441), 1, (p) => {
            p.addEllipse(R(48.4, 65.2, 3.2, 3.2))
        })
        ctx.heart(pt(50, 72.6), 10, rgb(0xE8B23A))
        ctx.heart(pt(50, 72.3), 8.4, rgb(0xF4CB5A))
        ctx.circle(47.6, 70.6, 0.9, Color.white.opacity(0.85))
    } break; case "neck.tie": { 
        for (const flip of [false, true]) {
            const c = mirrored(ctx, flip)
            soft(c, [pt(41, 60.8), pt(48, 62.2), pt(44.5, 67)], rgb(0xFBFAFD), 1.2)
        }
        const navy = rgb(0x5A72C0)
        let blade = new Path()
        blade.addLines([pt(47.6, 66.5), pt(52.4, 66.5), pt(55, 77.5), pt(50, 82), pt(45, 77.5)])
        blade.closeSubpath()
        ctx.fill(blade, (navy))
        const stripes = ctx.copy()
        stripes.clip(blade)
        stripes.strokePath(rgb(0xF0C26A), 1.2, (p) => {
            for (let y = (64); y < 84; y += 4.5) {
                p.move(pt(43, y + 4)); p.addLine(pt(57, y - 2))
            }
        })
        soft(ctx, [pt(46.5, 61.8), pt(53.5, 61.8), pt(52.3, 67), pt(47.7, 67)], rgb(0x4A60AA), 1)
    } break; case "neck.ruff": { 
        // Cổ áo bèo kiểu chú hề: các cánh bèo trắng xòe quanh cổ.
        const white = rgb(0xFFFFFF), edge = rgb(0xD3C8E2), crease = rgb(0xE6DFEE)
        const angles = [28, 43, 58, 74, 90, 106, 122, 137, 152]
        for (let layer = 0; layer < 2; layer++) {
            for (const [i, deg] of angles.entries()) {
                const rad = deg * Math.PI / 180
                const x = 50 + 22 * (Math.cos(rad)), y = 59 + 6.5 * (Math.sin(rad))
                const rot = (deg - 90) * 0.9
                const tone = i % 2 == 0 ? white : rgb(0xFBF8FD)
                ctx.rotated(rot, pt(x, y), (c) => {
                    if (layer == 0) {
                        c.ellipse(x - 4.4, y - 2.8, 8.8, 10.4, edge)
                    } else {
                        c.ellipse(x - 3.8, y - 2.6, 7.6, 9.4, tone)
                        c.strokePath(crease, 0.8, (p) => {
                            p.move(pt(x, y + 0.5)); p.addLine(pt(x, y + 5))
                        })
                    }
                })
            }
        }
    } break; case "neck.pearls": { 
        const rim = rgb(0xD8CCC2), pearl = rgb(0xFFF9F3), shade = rgb(0xEFE4DA)
        for (let i = 0; i < 11; i++) {
            const x = 27 + (i) * 4.6
            const y = 61.8 + 6.5 * (1 - Math.pow((x - 50) / 23, 2))
            ctx.circle(x, y, 2.7, rim)
            ctx.circle(x, y, 2.3, pearl)
            ctx.circle(x + 0.6, y + 0.7, 1.3, shade)
            ctx.circle(x - 0.8, y - 0.8, 0.7, Color.white)
        }
        ctx.circle(50, 73, 3.3, rgb(0xE9A9BC))
        ctx.circle(50, 73, 2.8, rgb(0xF8CBD8))
        ctx.circle(49, 72, 0.9, Color.white)
    } break; case "neck.medal": { 
        soft(ctx, [pt(36.5, 61), pt(42.5, 61), pt(52, 72.5), pt(47.5, 74)], rgb(0x6FA3D9), 1)
        soft(ctx, [pt(63.5, 61), pt(57.5, 61), pt(48, 72.5), pt(52.5, 74)], rgb(0xE56B6B), 1)
        ctx.circle(50, 76, 6.3, rgb(0xDDA332))
        ctx.circle(50, 76, 4.9, rgb(0xF6CF5A))
        star(ctx, 50, 76.2, 3, rgb(0xE5AE3C))
        ctx.circle(47.3, 73.6, 1, Color.white.opacity(0.85))
    } break; default: { 
        break
    } }
}

// MARK: Áo

export function outfit(id: string, ctx: GC, clipped: GC, a: PetAppearance) {
    switch (id) {
    case "outfit.apron": { 
        const pink = rgb(0xF6BCCB), deep = rgb(0xE38FA6)
        ctx.strokePath(deep, 2.2, (p) => {
            p.move(pt(38.5, 63.5)); p.addLine(pt(32.5, 60.5))
            p.move(pt(61.5, 63.5)); p.addLine(pt(67.5, 60.5))
        })
        clipped.rect(37, 62.5, 26, 14, pink, 3)
        clipped.rect(29, 71, 42, 30, pink, 5)
        clipped.rect(0, 70.5, 100, 3.4, deep)
        clipped.rect(37.5, 63.4, 25, 1.4, Color.white.opacity(0.75), 0.7)
        ctx.heart(pt(50, 80.5), 10, rgb(0xE07F98))
        ctx.circle(47.8, 78.8, 0.8, Color.white.opacity(0.7))
        for (const [x, y] of ([[31.5, 76], [31.5, 81], [68.5, 76], [68.5, 81]] as const)) {
            clipped.circle(x, y, 0.8, Color.white.opacity(0.85))
        }
    } break; case "outfit.pajamas": { 
        const navy = rgb(0x5468A8), light = rgb(0x8C9CD8)
        clipped.rect(0, 62, 100, 40, navy)
        for (const [x, y, r] of ([[27, 70, 2.2], [40, 79, 2], [60, 73, 2.2], [72, 81, 2],
                          [24, 81, 1.8], [77, 69, 1.8], [55, 84, 1.8], [36, 69.5, 1.5]] as const)) {
            star(clipped, x, y, r, rgb(0xF6D36B))
        }
        clipped.rect(49.3, 66, 1.4, 30, light)
        ctx.circle(50, 72, 1.3, rgb(0xFBF8F2))
        ctx.circle(50, 78, 1.3, rgb(0xFBF8F2))
        soft(ctx, [pt(35.5, 61.2), pt(49.5, 62), pt(43, 68.5)], light, 1.4)
        soft(ctx, [pt(64.5, 61.2), pt(50.5, 62), pt(57, 68.5)], light, 1.4)
    } break; case "outfit.hoodie": { 
        const blue = rgb(0x9FB4E3), deep = rgb(0x8098D2)
        clipped.rect(0, 62, 100, 40, blue)
        clipped.rect(0, 85, 100, 4, deep)
        let pocket = new Path()
        pocket.move(pt(36, 75))
        pocket.addLine(pt(64, 75))
        pocket.addLine(pt(68.5, 86))
        pocket.addLine(pt(31.5, 86))
        pocket.closeSubpath()
        clipped.fill(pocket, (deep))
        clipped.strokePath(blue, 1, (p) => {
            p.move(pt(37.5, 77)); p.addLine(pt(34, 85))
            p.move(pt(62.5, 77)); p.addLine(pt(66, 85))
        })
        ctx.strokePath(deep, 4.6, (p) => {
            p.move(pt(25, 61.5)); p.addQuadCurve(pt(75, 61.5), pt(50, 72))
        })
        ctx.strokePath(rgb(0xFBF8F2), 1, (p) => {
            p.move(pt(45.5, 66)); p.addQuadCurve(pt(44.5, 74), pt(44.5, 70))
            p.move(pt(54.5, 66)); p.addQuadCurve(pt(55.5, 74), pt(55.5, 70))
        })
        ctx.rect(43.5, 73.5, 2, 2.6, rgb(0xE8E2EE), 0.8)
        ctx.rect(54.5, 73.5, 2, 2.6, rgb(0xE8E2EE), 0.8)
    } break; case "outfit.dress": { 
        const yellow = rgb(0xF6D36B), pink = rgb(0xF29BB0)
        clipped.rect(0, 62, 100, 40, yellow)
        let skirt = new Path()
        skirt.move(pt(22, 71))
        skirt.addLine(pt(78, 71))
        skirt.addQuadCurve(pt(88, 87), pt(85, 78))
        for (let i = 0; i < 6; i++) {
            const x0 = 88 - (i) * 12.67
            skirt.addQuadCurve(pt(x0 - 12.67, 87), pt(x0 - 6.33, 90.5))
        }
        skirt.addQuadCurve(pt(22, 71), pt(15, 78))
        skirt.closeSubpath()
        ctx.fill(skirt, (yellow))
        clipped.rect(0, 69.2, 100, 3.4, pink)
        const flowers = [[30, 66], [44, 65.5], [58, 66], [70, 66.5], [24, 78], [37, 77],
                                             [50, 79], [63, 77], [76, 78], [30, 84], [44, 85], [57, 85], [70, 84]] as const
        for (const [i, f] of flowers.entries()) {
            const petal = i % 3 == 1 ? rgb(0xF6A9BE) : Color.white
            for (let k = 0; k < 4; k++) {
                const ang = (k) * Math.PI / 2 + 0.4
                ctx.circle(f[0] + 1.1 * (Math.cos(ang)), f[1] + 1.1 * (Math.sin(ang)), 1, petal)
            }
            ctx.circle(f[0], f[1], 0.7, rgb(0xE88A4E))
        }
        ctx.ellipse(38, 60.5, 12, 6.5, rgb(0xFFFDFB))
        ctx.ellipse(50, 60.5, 12, 6.5, rgb(0xFFFDFB))
        ctx.heart(pt(50, 64.5), 4.5, pink)
    } break; case "outfit.tutu": { 
        const leo = rgb(0xF4AFC8), tulle = rgb(0xF9C9DA), top = rgb(0xFDE2EC)
        clipped.rect(0, 62.5, 100, 40, leo)
        for (let i = 0; i < 9; i++) {
            ctx.circle(14 + (i) * 9, 79.5, 6, tulle)
        }
        ctx.ellipse(9, 69.5, 82, 14, tulle)
        ctx.ellipse(15, 68.5, 70, 9, top)
        ctx.rect(21, 67.5, 58, 3.4, rgb(0xEC8FB0), 1.7)
        for (const [x, y] of ([[20, 75], [34, 79], [66, 79], [80, 75], [48, 76], [27, 82], [73, 82]] as const)) {
            ctx.circle(x, y, 0.8, Color.white.opacity(0.9))
        }
        sparkle(ctx, 88, 70, 5, rgb(0xF0C26A))
        ctx.heart(pt(50, 66.2), 4.5, rgb(0xEC8FB0))
    } break; case "outfit.sailor": { 
        const shirt = rgb(0xF5F7FD), blue = rgb(0x4F7CC9), red = rgb(0xE05A5A)
        clipped.rect(0, 62, 100, 40, shirt)
        clipped.rect(0, 81, 100, 2.2, blue)
        clipped.rect(0, 85, 100, 2.2, blue)
        soft(ctx, [pt(23.5, 61.5), pt(76.5, 61.5), pt(73, 67.5), pt(50, 80), pt(27, 67.5)], blue, 1.5)
        soft(ctx, [pt(38, 61.5), pt(62, 61.5), pt(50, 73.5)], shirt, 1)
        ctx.strokePath(Color.white.opacity(0.9), 0.8, (p) => {
            p.move(pt(27, 64.5)); p.addLine(pt(50, 77.2)); p.addLine(pt(73, 64.5))
        })
        soft(ctx, [pt(50, 74), pt(43, 70.5), pt(43, 77)], red, 1)
        soft(ctx, [pt(50, 74), pt(57, 70.5), pt(57, 77)], red, 1)
        soft(ctx, [pt(48.5, 75), pt(45.5, 82), pt(48.8, 81)], red, 0.8)
        soft(ctx, [pt(51.5, 75), pt(54.5, 82), pt(51.2, 81)], red, 0.8)
        ctx.circle(50, 74, 2.2, rgb(0xC94848))
    } break; case "outfit.yukata": { 
        const indigo = rgb(0x5B6FB3), trim = rgb(0x3F4F8F), under = rgb(0xF4EEE6)
        clipped.rect(0, 62, 100, 40, indigo)
        for (const [i, d] of ([[26, 68], [40, 66], [62, 67], [74, 69], [30, 85], [45, 84], [60, 86], [72, 84],
                       [22, 77], [78, 77]] as const).entries()) {
            if (i % 2 == 0) {
                for (let k = 0; k < 5; k++) {
                    const ang = (k) * 2 * Math.PI / 5
                    clipped.circle(d[0] + 1.3 * (Math.cos(ang)), d[1] + 1.3 * (Math.sin(ang)), 0.9, rgb(0xF8C6D6))
                }
                clipped.circle(d[0], d[1], 0.6, rgb(0xF6D36B))
            } else {
                clipped.circle(d[0], d[1], 1, Color.white.opacity(0.75))
            }
        }
        soft(clipped, [pt(39, 61.5), pt(61, 61.5), pt(50, 72)], under, 1)
        ctx.strokePath(trim, 2.6, (p) => {
            p.move(pt(36.5, 61.5)); p.addLine(pt(54, 76))
            p.move(pt(63.5, 61.5)); p.addLine(pt(50, 73))
        })
        clipped.rect(0, 73.5, 100, 6.5, rgb(0xF2A3B8))
        clipped.rect(0, 76.2, 100, 1.1, rgb(0xE07F98))
        ctx.circle(62, 76.7, 1.8, rgb(0xF6D36B))
    } break; case "outfit.tux": { 
        const jacket = rgb(0x434A6B), lapel = rgb(0x2F3550), shirt = rgb(0xFBFAFD)
        clipped.rect(0, 62, 100, 40, jacket)
        clipped.polygon([pt(40, 61), pt(60, 61), pt(50, 88)], shirt)
        soft(clipped, [pt(40, 61.5), pt(34, 64), pt(47, 80), pt(48.2, 84)], lapel, 1)
        soft(clipped, [pt(60, 61.5), pt(66, 64), pt(53, 80), pt(51.8, 84)], lapel, 1)
        ctx.circle(50, 72, 1, jacket)
        ctx.circle(50, 77, 1, jacket)
        clipped.rect(24, 70, 9, 1.4, lapel, 0.7)
        soft(ctx, [pt(25, 70.2), pt(28, 66.5), pt(30, 70.2)], rgb(0xF29BB0), 0.8)
        soft(ctx, [pt(28.5, 70.2), pt(31, 67.2), pt(32.5, 70.2)], rgb(0xF6BCCB), 0.8)
        soft(ctx, [pt(50, 64), pt(44.5, 61.5), pt(44.5, 66.5)], rgb(0x2A2A3A), 0.8)
        soft(ctx, [pt(50, 64), pt(55.5, 61.5), pt(55.5, 66.5)], rgb(0x2A2A3A), 0.8)
        ctx.circle(50, 64, 1.6, rgb(0x2A2A3A))
    } break; case "outfit.astronaut": { 
        const suit = rgb(0xF2F4FA), seam = rgb(0xCBD2E2), metal = rgb(0xB7C0D6)
        clipped.rect(0, 62, 100, 40, suit)
        clipped.strokePath(seam, 1, (p) => {
            p.move(pt(28, 64)); p.addQuadCurve(pt(24, 88), pt(22, 76))
            p.move(pt(72, 64)); p.addQuadCurve(pt(76, 88), pt(78, 76))
        })
        clipped.rect(0, 82, 100, 3, metal)
        clipped.rect(40.5, 68.5, 19, 11, rgb(0xD9DFEC), 2.2)
        ctx.circle(45, 72.2, 1.5, rgb(0xE56B6B))
        ctx.circle(50, 72.2, 1.5, rgb(0xF6C445))
        ctx.circle(55, 72.2, 1.5, rgb(0x6FC2A8))
        ctx.rect(43.5, 75.7, 13, 1.6, rgb(0x6FA3D9), 0.8)
        ctx.circle(30.5, 71.5, 4.3, rgb(0x4F7CC9))
        ctx.strokePath(Color.white.opacity(0.9), 0.7, (p) => {
            p.addEllipse(R(26.8, 70.2, 7.4, 2.6))
        })
        ctx.circle(30.5, 71.5, 1.1, rgb(0xF6D36B))
        ctx.rect(65, 68.8, 7.5, 5, rgb(0xFBFAFD), 0.6)
        ctx.rect(65, 68.8, 7.5, 1.4, rgb(0xE56B6B), 0.6)
        ctx.rect(65, 71.4, 7.5, 1.1, rgb(0xE56B6B))
        ctx.rect(24.5, 60.5, 51, 6, metal, 3)
        ctx.rect(26.5, 61.5, 47, 1.4, Color.white.opacity(0.55), 0.7)
    } break; default: { 
        break
    } }
}

// MARK: Phụ kiện sau lưng / cầm tay

export function back(id: string, ctx: GC, a: PetAppearance, front: boolean) {
    const w = a.species == 'hamster' ? 3 : 0
    switch (id) {
    case "back.lollipop": { 
        if ((!(front))) { return }
        ctx.strokePath(rgb(0xDCD3CC), 2.8, (p) => {
            p.move(pt(60.5, 83)); p.addLine(pt(79, 60))
        })
        ctx.strokePath(rgb(0xFBF8F2), 2, (p) => {
            p.move(pt(60.5, 83)); p.addLine(pt(79, 60))
        })
        lollipopCandy(ctx, pt(82, 53), 9.5)
        pawGrip(ctx, a, 58.5, 80.3)
    } break; case "back.balloon": { 
        if (front) {
            ctx.strokePath(rgb(0x9A8FB0), 0.9, (p) => {
                p.move(pt(60.5, 82)); p.addQuadCurve(pt(80, 25.5), pt(90, 60))
            })
            pawGrip(ctx, a, 58.5, 80)
        } else {
            ctx.heart(pt(80, 15), 23, rgb(0xF27D9B))
            ctx.rotated(-35, pt(73.5, 10.5), (c) => (c.ellipse(71, 8.5, 5, 3.2, Color.white.opacity(0.6))))
            ctx.polygon([pt(80, 22.5), pt(78.3, 25.6), pt(81.7, 25.6)], rgb(0xE0607F))
        }
    } break; case "back.backpack": { 
        const bag = rgb(0x6FC2A8), deep = rgb(0x529E87)
        if (front) {
            for (const flip of [false, true]) {
                const c = mirrored(ctx, flip)
                c.strokePath(deep, 3.4, (p) => {
                    p.move(pt(21 - w, 56)); p.addQuadCurve(pt(33, 82), pt(24 - w, 74))
                })
                c.rect(23.2 - w * 0.5, 70, 4.2, 3.4, rgb(0xF0C26A), 1)
            }
        } else {
            ctx.rect(7 - w, 48, 86 + w * 2, 38, bag, 14)
            ctx.rect(4.5 - w, 62, 9, 18, deep, 4)
            ctx.rect(86.5 + w, 62, 9, 18, deep, 4)
            ctx.rect(6 - w, 66, 6, 1.2, Color.white.opacity(0.6))
            ctx.rect(88 + w, 66, 6, 1.2, Color.white.opacity(0.6))
            ctx.strokePath(deep, 2.6, (p) => {
                p.move(pt(40, 50)); p.addQuadCurve(pt(60, 50), pt(50, 36))
            })
        }
    } break; case "back.umbrella": { 
        if (front) {
            ctx.strokePath(rgb(0x8A5A3C), 1.8, (p) => {
                p.move(pt(60, 85)); p.addLine(pt(76, 18))
            })
            ctx.strokePath(rgb(0xC94F5C), 2.6, (p) => {
                p.move(pt(60.2, 84.2)); p.addLine(pt(61.4, 79.2))
            })
            pawGrip(ctx, a, 58.5, 80.5)
        } else {
            parasol(ctx)
        }
    } break; case "back.bat": { 
        if ((!(!front))) { return }
        const wing = rgb(0x6A5A9A), bone = rgb(0x8E7EC0)
        for (const flip of [false, true]) {
            let c = mirrored(ctx, flip)
            c.translateBy(-w, 0)
            let p = new Path()
            p.move(pt(28, 46))
            p.addQuadCurve(pt(2, 30), pt(12, 32))
            p.addQuadCurve(pt(6, 47), pt(7, 40))
            p.addQuadCurve(pt(13, 55), pt(12, 49))
            p.addQuadCurve(pt(22, 61), pt(20, 54))
            p.addQuadCurve(pt(30, 66), pt(28, 59))
            p.closeSubpath()
            c.fill(p, (wing))
            c.strokePath(bone, 1, (q) => {
                q.move(pt(26, 52)); q.addLine(pt(4, 31))
                q.move(pt(26, 52)); q.addLine(pt(6.5, 46))
                q.move(pt(26, 52)); q.addLine(pt(13, 54.5))
                q.move(pt(26, 52)); q.addLine(pt(22, 60.5))
            })
        }
    } break; case "back.guitar": { 
        if (front) {
            ctx.strokePath(rgb(0x8A5A3C), 2.4, (p) => {
                p.move(pt(81, 60)); p.addQuadCurve(pt(20, 78), pt(52, 76))
            })
            ctx.strokePath(rgb(0xF0C26A), 0.7, (p) => {
                p.move(pt(76, 63.5)); p.addLine(pt(73, 64.8))
                p.move(pt(64, 68.5)); p.addLine(pt(61, 69.4))
                p.move(pt(36, 73.6)); p.addLine(pt(33, 74.2))
            })
        } else {
            guitar(ctx, w)
        }
    } break; case "back.fairy": { 
        if ((!(!front))) { return }
        for (const flip of [false, true]) {
            let c = mirrored(ctx, flip)
            c.translateBy(-w, 0)
            c.rotated(-38, pt(26, 52), (r) => {
                r.ellipse(2, 36, 28, 18, rgb(0xBFE3F7).opacity(0.75))
                r.ellipse(7, 40, 18, 10, rgb(0xF7CBE6).opacity(0.55))
                r.strokePath(Color.white.opacity(0.95), 1, (p) => {
                    p.addEllipse(R(2, 36, 28, 18))
                    p.move(pt(26, 46)); p.addQuadCurve(pt(8, 42), pt(16, 41))
                })
            })
            c.rotated(28, pt(26, 60), (r) => {
                r.ellipse(6, 56, 22, 12, rgb(0xD8C9F4).opacity(0.75))
                r.strokePath(Color.white.opacity(0.95), 1, (p) => {
                    p.addEllipse(R(6, 56, 22, 12))
                })
            })
        }
        sparkle(ctx, 8 - w, 24, 6, rgb(0xF0C26A))
        sparkle(ctx, 93 + w, 30, 5, rgb(0xF0C26A))
        sparkle(ctx, 6 - w, 74, 4, rgb(0xB59FDB))
    } break; case "back.wings": { 
        if ((!(!front))) { return }
        for (const flip of [false, true]) {
            let c = mirrored(ctx, flip)
            c.translateBy(-w, 0)
            let sh = c
            sh.translateBy(0.8, 1.3)
            angelWing(sh, rgb(0xDCD6E8))
            angelWing(c, rgb(0xFFFFFF))
            c.strokePath(rgb(0xE4DFEE), 0.9, (p) => {
                p.move(pt(10, 44)); p.addQuadCurve(pt(24, 47), pt(16, 48))
                p.move(pt(10, 53)); p.addQuadCurve(pt(24, 54), pt(17, 56))
                p.move(pt(14, 60)); p.addQuadCurve(pt(25, 60), pt(19, 62))
            })
        }
    } break; default: { 
        break
    } }
}

// "Ngón tay" nhỏ cùng màu lông che lên cán để trông như đang cầm.
function pawGrip(ctx: GC, a: PetAppearance, x: number, y: number) {
    ctx.ellipse(x - 1, y - 0.5, 7, 5, furPalette(a.fur).base)
}

function lollipopCandy(ctx: GC, c: Pt, r: number) {
    const colors = [rgb(0xF27D9B), rgb(0xF6A85B), rgb(0xF6D36B), rgb(0x8CCB7E), rgb(0x6FA3D9), rgb(0xA98BE0)]
    ctx.circle(c.x, c.y, r + 0.8, rgb(0xFBF8F2))
    for (const [i, color] of colors.entries()) {
        let p = new Path()
        p.move(c)
        p.addArc(c, r, deg((i) * 60 - 90), deg((i + 1) * 60 - 90), false)
        p.closeSubpath()
        ctx.fill(p, (color))
    }
    ctx.strokePath(Color.white.opacity(0.95), 1.3, (p) => {
        p.move(c)
        for (let k = 1; k <= 40; k++) {
            const t = (k) / 40
            const ang = t * 4.2 * Math.PI
            const rr = r * 0.92 * (t)
            p.addLine(pt(c.x + rr * (Math.cos(ang)), c.y + rr * (Math.sin(ang))))
        }
    })
    ctx.ellipse(c.x - r * 0.65, c.y - r * 0.7, r * 0.5, r * 0.32, Color.white.opacity(0.6))
}

function parasol(ctx: GC) {
    const hub = pt(76, 18)
    ctx.rotated(17, hub, (c) => {
        const canopy = rgb(0xEC8E9D), panel = rgb(0xF6B7C2), rib = rgb(0xC96676)
        const left = hub.x - 25, right: number = hub.x + 25, rim = hub.y + 6
        let p = new Path()
        p.move(pt(left, rim))
        p.addQuadCurve(pt(hub.x, hub.y - 12), pt(left + 6, hub.y - 9))
        p.addQuadCurve(pt(right, rim), pt(right - 6, hub.y - 9))
        for (let i = 0; i < 6; i++) {
            const x0 = right - (i) * 50 / 6
            p.addQuadCurve(pt(x0 - 50 / 6, rim), pt(x0 - 25 / 6, rim - 3))
        }
        p.closeSubpath()
        c.fill(p, (canopy))
        let inner = c
        inner.clip(p)
        for (let i = 0; i < 6; i += 2) {
            const x0 = left + (i) * 50 / 6
            inner.polygon([pt(hub.x, hub.y - 12), pt(x0, rim + 2), pt(x0 + 50 / 6, rim + 2)], panel)
        }
        c.strokePath(rib, 0.8, (q) => {
            for (let i = 0; i <= 6; i++) {
                q.move(pt(hub.x, hub.y - 12)); q.addLine(pt(left + (i) * 50 / 6, rim - 1.5))
            }
        })
        c.strokePath(Color.white.opacity(0.85), 1.2, (q) => {
            q.addEllipse(R(hub.x - 7, hub.y - 10.5, 14, 5))
        })
        c.circle(hub.x, hub.y - 12.5, 1.5, rib)
    })
}

function guitar(ctx: GC, w: number) {
    const wood = rgb(0xE3A866), woodDeep = rgb(0xC98A4E), neckColor = rgb(0x8A5A3C)
    const origin = pt(11 - w, 77)
    const c = ctx.copy()
    c.translateBy(origin.x, origin.y)
    c.rotate(deg(-28))
    // Hệ tọa độ cục bộ: trục đàn nằm ngang, thân ở gốc.
    c.rect(16, -2.3, 62, 4.6, neckColor, 1.5)
    c.rect(76, -3.8, 12, 7.6, woodDeep, 2.4)
    for (const x of [(79), 82.5, 86]) {
        c.circle(x, -4.6, 1.2, rgb(0xF0C26A))
        c.circle(x, 4.6, 1.2, rgb(0xF0C26A))
    }
    c.circle(14, 0, 8.5, woodDeep)
    c.circle(0, 0, 11, woodDeep)
    c.circle(14, 0, 7.6, wood)
    c.circle(0, 0, 10.1, wood)
    c.circle(2.5, 0, 3.4, rgb(0x5A3B2A))
    c.rect(-7, -3.2, 2.2, 6.4, rgb(0x8A5A3C), 0.8)
    c.ellipse(-6, -8, 6, 3.4, Color.white.opacity(0.35))
}

function angelWing(c: GC, color: Color) {
    c.rotated(-22, pt(24, 48), (r) => {
        r.ellipse(1, 36, 28, 17, color)
    })
    c.rotated(-12, pt(24, 54), (r) => {
        r.ellipse(3, 47, 22, 9.5, color)
    })
    c.rotated(-4, pt(24, 60), (r) => {
        r.ellipse(7, 55, 18, 8.5, color)
    })
    c.ellipse(11, 61, 15, 7.5, color)
}

export const CostumeArt = { hat, glasses, neck, outfit, back }
