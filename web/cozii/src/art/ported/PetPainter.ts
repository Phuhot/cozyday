// Chuyển tự động từ Swift (scripts/port/swift2ts.mjs) rồi sửa tay.
import { GC, Color, rgb, pt, R, Path, deg, Rect } from '../gc'
import { Palette } from '../palette'
import type { FurColor, PetAppearance, PetMood, PetPose } from '../../content/pet'
import { CostumeArt } from './CostumeArt'

export interface FurPalette {
  base: Color
  shade: Color
  belly: Color
  inner: Color
  eye: Color
}

function FP(base: Color, shade: Color, belly: Color, inner: Color, eye: Color): FurPalette {
  return { base, shade, belly, inner, eye }
}

// Bảng màu của từng màu lông. Màu nhân vật cố định để giữ nhận diện.
export const FUR_PALETTES: Record<FurColor, FurPalette> = {
  cream: FP(Palette.catCream, Palette.catShade, Palette.catShade, Palette.blush, Palette.catInk),
  snow: FP(rgb(0xFBFAF8), rgb(0xE4DFEA), rgb(0xEDE9F1), Palette.blush, Palette.catInk),
  ginger: FP(rgb(0xF2B27A), rgb(0xE0925A), rgb(0xFBE3C8), rgb(0xF4A9A0), Palette.catInk),
  smoke: FP(rgb(0xBDB9C8), rgb(0x9F9AAE), rgb(0xE0DDE7), rgb(0xF0B4BC), Palette.catInk),
  cocoa: FP(rgb(0xB0805F), rgb(0x8E6247), rgb(0xDDBFA6), rgb(0xE9A9A0), rgb(0x2E2430)),
  peach: FP(rgb(0xF8CBC4), rgb(0xEDA9A2), rgb(0xFCE5E1), rgb(0xF08C9A), Palette.catInk),
  midnight: FP(rgb(0x433D50), rgb(0x302B3B), rgb(0x5C5669), rgb(0xC98A9A), rgb(0xF0C26A)),
  lilac: FP(rgb(0xD3C1EE), rgb(0xB59FDB), rgb(0xEBE1F8), rgb(0xF2A9C4), Palette.catInk),
  honey: FP(rgb(0xF7D27A), rgb(0xE8B44E), rgb(0xFCEBC0), rgb(0xF4A9A0), Palette.catInk),
  mint: FP(rgb(0xA9DDB8), rgb(0x82C497), rgb(0xDDF3E2), rgb(0xF2A9B4), Palette.catInk),
  sky: FP(rgb(0xAFCFF2), rgb(0x88B2E3), rgb(0xDDEBFA), rgb(0xF2A9C4), Palette.catInk),
}

export function furPalette(fur: FurColor): FurPalette {
  return FUR_PALETTES[fur]
}

// Vẽ thú cưng trong hệ tọa độ 100×100, theo lớp:
// đuôi → đồ sau lưng → áo choàng → tai → thân → áo → mặt → kính → cổ → mũ → chân → đồ cầm trước → hiệu ứng.
export function drawPet(base0: GC, mood: PetMood, appearance: PetAppearance, pose: PetPose) {
    const stageScale = ((): number => {
        switch (appearance.stage) {
        case 'little': { return 0.80
        } break; case 'growing': { return 0.91
        } break; case 'grown': { return 1.0
        } }
    })()

    const eyeScale = ((): number => {
        switch (appearance.stage) {
        case 'little': { return 1.22
        } break; case 'growing': { return 1.08
        } break; case 'grown': { return 1.0
        } }
    })()

    function draw(base: GC) {
        const fur = furPalette(appearance.fur)
        const anchor = pt(50, 88)

        // Bóng: nhỏ lại khi nhảy lên.
        const shadowW = 56 * stageScale * Math.max(0.6, 1 - pose.hop / 30)
        base.ellipse(50 - shadowW / 2, 84, shadowW, 9, Color.black.opacity(0.10))

        const ctx = base.copy()
        ctx.translateBy(0, -pose.hop)
        ctx.translateBy(anchor.x, anchor.y)
        ctx.rotate(deg(pose.tilt))
        ctx.scaleBy(stageScale * (1 - pose.breath * 0.008), stageScale * (1 + pose.breath * 0.022))
        ctx.translateBy(-anchor.x, -anchor.y)

        drawTail(ctx, fur)
        { const back = appearance.back; if (back) { CostumeArt.back(back, ctx, appearance, false) } }
        if (appearance.outfit == "outfit.cape") { drawCapeBack(ctx) }
        drawEars(ctx, fur)
        const bodyFrame = bodyRect
        ctx.fill(Path.ellipse(bodyFrame), (fur.base))
        drawBelly(ctx, fur)
        { const outfit = appearance.outfit; if (outfit) { drawOutfit(ctx, outfit, bodyFrame) } }
        drawSideParts(ctx, fur)
        drawFace(ctx, fur)
        { const glasses = appearance.glasses; if (glasses) { drawGlasses(ctx, glasses) } }
        { const neck = appearance.neck; if (neck) { drawNeck(ctx, neck) } }
        const hat = appearance.hat
        if (hat) {
            drawHat(ctx, hat)
            // Tai thỏ dài: thò ra ngoài mũ len / mũ cói thay vì bị che mất.
            if (appearance.species == 'bunny' && (hat == "hat.beanie" || hat == "hat.straw")) { drawEars(ctx, fur) }
        }
        drawPaws(ctx, fur)
        { const back = appearance.back; if (back) { CostumeArt.back(back, ctx, appearance, true) } }
        drawMoodExtras(ctx)
        drawHearts(base)
    }

    const bodyRect = (
        appearance.species == 'hamster' ? R(13, 32, 74, 56) : R(16, 28, 68, 60)
    )

    // MARK: Đuôi

    function drawTail(ctx: GC, fur: FurPalette) {
        const t = pose.tail
        switch (appearance.species) {
        case 'cat': { 
            ctx.strokePath(fur.shade, 7, (p) => {
                p.move(pt(74, 78))
                p.addQuadCurve(pt(88 + t * 5, 56 - Math.abs(t) * 2), pt(95 + t * 2, 76))
            })
        } break; case 'fox': { 
            ctx.rotated(-38 + (t) * 9, pt(72, 80), (c) => {
                c.ellipse(70, 46, 22, 40, fur.base)
                c.ellipse(74, 44, 14, 14, rgb(0xFFF8F0))
            })
        } break; case 'bunny': { 
            ctx.circle(80 + t * 1.5, 78, 8, fur.belly)
        } break; case 'bear': { 
            ctx.circle(81 + t, 80, 5, fur.shade)
        } break; case 'hamster': { 
            break
        } break; case 'puppy': { 
            // Đuôi ngắn dựng lên, ngoáy qua lại.
            ctx.rotated(28 + (t) * 22, pt(77, 77), (c) => {
                c.ellipse(72.5, 54, 9.5, 26, fur.shade)
                c.circle(77.25, 57.5, 3, Color.white.opacity(0.18))
            })
        } break; case 'duck': { 
            // Đuôi vểnh nhọn.
            ctx.rotated((t) * 12, pt(78, 76), (c) => {
                let p = new Path()
                p.move(pt(72, 82))
                p.addQuadCurve(pt(93, 62), pt(88, 80))
                p.addQuadCurve(pt(74, 68), pt(84, 64))
                p.closeSubpath()
                c.fill(p, (fur.base))
            })
        } break; case 'frog': case 'capybara': { 
            break // không có đuôi — ếch phản ứng bằng mắt lồi, capybara bằng tai & chỏm lông.
        } break; case 'panda': { 
            ctx.circle(81 + t, 80, 5, fur.base)
        } break; case 'penguin': { 
            ctx.rotated((t) * 10, pt(76, 82), (c) => {
                c.polygon([pt(70, 80), pt(87, 87), pt(72, 87)], fur.shade)
            })
        } }
    }

    // MARK: Bụng

    function drawBelly(ctx: GC, fur: FurPalette) {
        switch (appearance.species) {
        case 'fox': { 
            ctx.ellipse(31, 56, 38, 30, rgb(0xFFF8F0))
        } break; case 'penguin': { 
            // Mặt hình trái tim liền với bụng trắng.
            const white = rgb(0xFFFDF9)
            if (appearance.fur == 'snow' || appearance.fur == 'cream') {
                ctx.stroke(penguinBib, (fur.shade), 2)
            }
            ctx.fill(penguinBib, (white))
        } break; case 'capybara': { 
            ctx.ellipse(34, 63, 32, 23, fur.belly.opacity(0.7))
        } break; default: { 
            ctx.ellipse(33, 58, 34, 27, fur.belly)
        } }
    }

    const penguinBib = ((): Path => {
        let p = new Path()
        const s = 46, c = pt(50, 51)
        p.move(pt(c.x, c.y + s * 0.35))
        p.addCurve(pt(c.x - s * 0.5, c.y - s * 0.1), pt(c.x - s * 0.1, c.y + s * 0.1), pt(c.x - s * 0.5, c.y + s * 0.15))
        p.addArc(pt(c.x - s * 0.25, c.y - s * 0.12), s * 0.25, deg(180), deg(0), false)
        p.addArc(pt(c.x + s * 0.25, c.y - s * 0.12), s * 0.25, deg(180), deg(0), false)
        p.addCurve(pt(c.x, c.y + s * 0.35), pt(c.x + s * 0.5, c.y + s * 0.15), pt(c.x + s * 0.1, c.y + s * 0.1))
        p.closeSubpath()
        p.addEllipse(R(28, 55, 44, 32))
        return p
    })()

    // MARK: Tay, cánh, tai cụp (vẽ trước thân, sau áo)

    function drawSideParts(ctx: GC, fur: FurPalette) {
        switch (appearance.species) {
        case 'puppy': { 
            // Tai cụp mềm rủ hai bên má.
            const lift = (pose.ear) * -16 - (pose.petted) * 8
            ctx.rotated(14 + lift, pt(28, 34), (c) => {
                c.ellipse(16, 30, 14, 30, fur.shade)
            })
            ctx.rotated(-14 + (pose.petted) * 8, pt(72, 34), (c) => {
                c.ellipse(70, 30, 14, 30, fur.shade)
            })
        } break; case 'duck': { 
            const flap = (Math.abs(pose.tail)) * 30 + (pose.petted) * 18
            ctx.rotated(14 + flap, pt(21, 62), (c) => {
                c.ellipse(12, 60, 12, 20, fur.shade)
            })
            ctx.rotated(-14 - flap, pt(79, 62), (c) => {
                c.ellipse(76, 60, 12, 20, fur.shade)
            })
        } break; case 'penguin': { 
            const flap = (Math.abs(pose.tail)) * 26 + (pose.petted) * 22
            ctx.rotated(16 + flap, pt(20, 58), (c) => {
                c.ellipse(12, 56, 10, 25, fur.shade)
            })
            ctx.rotated(-16 - flap, pt(80, 58), (c) => {
                c.ellipse(78, 56, 10, 25, fur.shade)
            })
        } break; case 'panda': { 
            const dark = pandaDark
            const wave = (pose.petted) * 14
            ctx.rotated(-24 - wave, pt(22, 64), (c) => {
                c.ellipse(15, 59, 14, 20, dark)
            })
            ctx.rotated(24 + wave, pt(78, 64), (c) => {
                c.ellipse(71, 59, 14, 20, dark)
            })
        } break; default: { 
            break
        } }
    }

    const pandaDark = (
        appearance.fur == 'midnight' ? rgb(0x1E1A24) : rgb(0x3A3442)
    )

    // MARK: Tai

    function drawEars(ctx: GC, fur: FurPalette) {
        const twitch = (pose.ear) * -10 + (pose.petted) * 12
        switch (appearance.species) {
        case 'cat': { 
            ctx.rotated(twitch, pt(34, 40), (c) => {
                c.polygon([pt(24, 44), pt(27, 18), pt(45, 32)], fur.base)
                c.polygon([pt(29, 38), pt(30, 25), pt(40, 32)], fur.inner)
            })
            ctx.polygon([pt(76, 44), pt(73, 18), pt(55, 32)], fur.base)
            ctx.polygon([pt(71, 38), pt(70, 25), pt(60, 32)], fur.inner)
        } break; case 'bunny': { 
            ctx.rotated(-14 + twitch * 1.4, pt(38, 36), (c) => {
                c.ellipse(30, 2, 14, 38, fur.base)
                c.ellipse(34, 8, 6, 26, fur.inner)
            })
            ctx.rotated(14, pt(62, 36), (c) => {
                c.ellipse(56, 2, 14, 38, fur.base)
                c.ellipse(60, 8, 6, 26, fur.inner)
            })
        } break; case 'hamster': { 
            ctx.rotated(twitch, pt(27, 36), (c) => {
                c.circle(27, 33, 7, fur.base)
                c.circle(27, 33, 4, fur.inner)
            })
            ctx.circle(73, 33, 7, fur.base)
            ctx.circle(73, 33, 4, fur.inner)
        } break; case 'bear': { 
            ctx.rotated(twitch, pt(27, 36), (c) => {
                c.circle(27, 32, 10, fur.base)
                c.circle(27, 32, 5.5, fur.shade)
            })
            ctx.circle(73, 32, 10, fur.base)
            ctx.circle(73, 32, 5.5, fur.shade)
        } break; case 'fox': { 
            const tip = rgb(0x5A4038)
            ctx.rotated(twitch, pt(32, 40), (c) => {
                c.polygon([pt(19, 46), pt(21, 10), pt(46, 31)], fur.base)
                c.polygon([pt(20.4, 21), pt(21, 10), pt(29, 17)], tip)
                c.polygon([pt(25, 39), pt(25, 22), pt(39, 32)], fur.inner)
            })
            ctx.polygon([pt(81, 46), pt(79, 10), pt(54, 31)], fur.base)
            ctx.polygon([pt(79.6, 21), pt(79, 10), pt(71, 17)], tip)
            ctx.polygon([pt(75, 39), pt(75, 22), pt(61, 32)], fur.inner)
        } break; case 'puppy': { 
            break // tai cụp vẽ phía trước đầu (drawSideParts)
        } break; case 'duck': { 
            // Chỏm lông trên đỉnh đầu.
            ctx.rotated(twitch * 1.2, pt(50, 30), (c) => {
                c.rotated(24, pt(50, 30), (r) => (r.ellipse(47.5, 17, 5.5, 15, fur.shade)))
                c.rotated(-12, pt(50, 30), (r) => (r.ellipse(46.5, 13, 7, 19, fur.base)))
            })
        } break; case 'frog': { 
            // Hai mắt lồi tròn trên đỉnh đầu; giật/nựng thì "nháy" gò mắt.
            const bob = pose.ear * -3 + pose.petted * 2
            ctx.circle(35.5, 39 + bob, 14, fur.base)
            ctx.circle(64.5, 39 + pose.petted * 2, 14, fur.base)
            ctx.strokePath(Color.white.opacity(0.55), 1.6, (p) => {
                p.addArc(pt(35.5, 39 + bob), 10.5, deg(205), deg(245), false)
                p.move(pt(64.5 + 10.5 * Math.cos(Math.PI * 205 / 180), 39 + pose.petted * 2 + 10.5 * Math.sin(Math.PI * 205 / 180)))
                p.addArc(pt(64.5, 39 + pose.petted * 2), 10.5, deg(205), deg(245), false)
            })
        } break; case 'capybara': { 
            ctx.rotated(twitch + (pose.tail) * 6, pt(28, 36), (c) => {
                c.ellipse(21, 27, 11, 10, fur.base)
                c.ellipse(23.5, 29.5, 6, 5.5, fur.shade)
            })
            ctx.rotated(-(pose.tail) * 6, pt(72, 36), (c) => {
                c.ellipse(68, 27, 11, 10, fur.base)
                c.ellipse(70.5, 29.5, 6, 5.5, fur.shade)
            })
            // Chỏm lông nhỏ trên đỉnh đầu, lắc theo nhịp "đuôi".
            ctx.strokePath(fur.shade, 1.4, (p) => {
                const sway = pose.tail * 1.5
                for (const [x, lean] of ([[46.5, -1.5], [50.0, 0.0], [53.5, 1.5]] as const)) {
                    p.move(pt(x, 29.5)); p.addLine(pt(x + lean + sway, 24.5))
                }
            })
        } break; case 'panda': { 
            const dark = pandaDark
            ctx.rotated(twitch, pt(27, 36), (c) => {
                c.circle(27, 31.5, 9.5, dark)
            })
            ctx.circle(73, 31.5, 9.5, dark)
        } break; case 'penguin': { 
            break // không có tai
        } }
    }

    // MARK: Mặt

    function drawFace(ctx: GC, fur: FurPalette) {
        const ink = fur.eye
        const line = appearance.fur == 'midnight' ? rgb(0xF4E6CF) : Palette.catInk
        switch (appearance.species) {
        case 'fox': { 
            ctx.ellipse(17, 53, 24, 16, rgb(0xFFF8F0))
            ctx.ellipse(59, 53, 24, 16, rgb(0xFFF8F0))
        } break; case 'bear': { 
            ctx.ellipse(39, 52, 22, 15, fur.belly)
        } break; case 'hamster': { 
            ctx.ellipse(13, 50, 22, 18, fur.belly)
            ctx.ellipse(65, 50, 22, 18, fur.belly)
        } break; case 'puppy': { 
            // Đốm quanh mắt phải + mõm sáng.
            ctx.ellipse(52.5, 41, 19, 17, fur.shade)
            ctx.ellipse(39.5, 52, 21, 13, fur.belly)
        } break; case 'capybara': { 
            ctx.fill(capybaraMuzzle, (fur.shade))
            ctx.fill(capybaraMuzzle, (rgb(0x6B4A3A).opacity(0.2)))
            ctx.ellipse(44, 50.5, 7, 3, Color.white.opacity(0.18))
        } break; case 'panda': { 
            const dark = pandaDark
            ctx.rotated(28, pt(37.5, 51), (c) => (c.ellipse(30.5, 42, 14, 18.5, dark)))
            ctx.rotated(-28, pt(62.5, 51), (c) => (c.ellipse(55.5, 42, 14, 18.5, dark)))
            ctx.ellipse(41.5, 52, 17, 10, fur.belly)
        } break; default: { 
            break
        } }

        const f = eyeScale
        const dx = pose.look * 1.3
        const left = pt(37.5 + dx, 50)
        const right = pt(62.5 + dx, 50)
        const closed = pose.blink && (mood == 'idle' || mood == 'happy')
        const faceMood = pose.petted > 0.15 ?  'happy' : mood
        // Gấu trúc: mắt nằm trên quầng đen nên nét mắt nhắm/cười dùng màu sáng.
        const eyeLine = appearance.species == 'panda' ? rgb(0xFFFDF8) : line
        const panda = appearance.species == 'panda'
        if (pose.lifted) {
            for (const c of [left, right]) {
                if (panda) { ctx.circle(c.x, c.y, 4.6 * f, rgb(0xFFFDF8)) }
                ctx.circle(c.x, c.y, 3.4 * f, ink)
                ctx.circle(c.x - 0.9 * f, c.y - 1.2 * f, 1.1 * f, Color.white)
            }
        } else {
            if (faceMood == 'idle' && !closed && appearance.species == 'capybara') {
                // Mắt nhỏ tròn hiền lành.
                for (const c of [left, right]) {
                    ctx.ellipse(c.x - 2.1 * f, c.y - 2.2 * f, 4.2 * f, 4.6 * f, ink)
                    ctx.circle(c.x - 0.6 * f, c.y - 0.9 * f, 0.75 * f, Color.white)
                }
            } else if (faceMood == 'idle' && !closed) {
                for (const c of [left, right]) {
                    if (panda) { ctx.circle(c.x, c.y, 4.4 * f, rgb(0xFFFDF8)) }
                    ctx.ellipse(c.x - 2.5 * f, c.y - 3.3 * f, 5 * f, 6.5 * f, ink)
                    ctx.circle(c.x - 0.6 * f, c.y - 1.6 * f, 0.9 * f, Color.white)
                }
            } else if (faceMood == 'low' && !pose.blink) {
                for (const c of [left, right]) {
                    if (panda) { ctx.circle(c.x, c.y, 4.4 * f, rgb(0xFFFDF8)) }
                    ctx.ellipse(c.x - 2.6 * f, c.y - 2.6 * f, 5.2 * f, 6 * f, ink)
                    ctx.circle(c.x - 0.7 * f, c.y - 1.2 * f, 1.1 * f, Color.white)
                    ctx.circle(c.x + 1 * f, c.y + 1.2 * f, 0.55 * f, Color.white)
                }
                // Lông mày hơi xếch lên ở giữa.
                ctx.strokePath(line.opacity(0.8), 1.5, (p) => {
                    p.move(pt(left.x - 4, left.y - 6)); p.addLine(pt(left.x + 3, left.y - 7.8))
                    p.move(pt(right.x + 4, right.y - 6)); p.addLine(pt(right.x - 3, right.y - 7.8))
                })
            } else if (faceMood == 'idle' || faceMood == 'low') {
                ctx.strokePath(eyeLine, 2.2, (p) => {
                    for (const c of [left, right]) {
                        p.move(pt(c.x - 3.5, c.y)); p.addLine(pt(c.x + 3.5, c.y))
                    }
                })
            } else if (faceMood == 'happy') {
                ctx.strokePath(eyeLine, 2.4, (p) => {
                    for (const c of [left, right]) {
                        p.move(pt(c.x - 4.5, c.y + 2)); p.addQuadCurve(pt(c.x + 4.5, c.y + 2), pt(c.x, c.y - 6 * f))
                    }
                })
            } else if (faceMood == 'focus') {
                ctx.strokePath(eyeLine, 2.4, (p) => {
                    p.move(pt(left.x - 4.5, 51)); p.addLine(pt(left.x + 4.5, 52))
                    p.move(pt(right.x - 4.5, 52)); p.addLine(pt(right.x + 4.5, 51))
                })
            } else if (faceMood == 'rest') {
                ctx.strokePath(eyeLine, 2.4, (p) => {
                    for (const c of [left, right]) {
                        p.move(pt(c.x - 4.5, c.y)); p.addQuadCurve(pt(c.x + 4.5, c.y), pt(c.x, c.y + 5))
                    }
                })
            }
        }
        // má hồng
        const blush = Palette.blush.opacity(Math.min(1, (mood == 'happy' ? 1 : 0.75) + (pose.petted) * 0.4))
        const grow = pose.petted * 2
        ctx.ellipse(26 - grow / 2, 55 - grow / 4, 8 + grow, 4.5 + grow / 2, blush)
        ctx.ellipse(66 - grow / 2, 55 - grow / 4, 8 + grow, 4.5 + grow / 2, blush)
        // mũi + miệng
        switch (appearance.species) {
        case 'duck': { 
            drawDuckBill(ctx)
        } break; case 'penguin': { 
            const orange = rgb(0xF4A04F)
            if (pose.lifted) {
                ctx.polygon([pt(46.5, 54), pt(53.5, 54), pt(50, 57)], orange)
                ctx.polygon([pt(47.5, 58.5), pt(52.5, 58.5), pt(50, 61)], rgb(0xE0823A))
            } else {
                let p = new Path()
                p.move(pt(46, 54.5))
                p.addQuadCurve(pt(54, 54.5), pt(50, 52.5))
                p.addQuadCurve(pt(50, 59.5), pt(53.5, 57))
                p.addQuadCurve(pt(46, 54.5), pt(46.5, 57))
                p.closeSubpath()
                ctx.fill(p, (orange))
                ctx.circle(48.6, 54.6, 0.8, Color.white.opacity(0.6))
            }
        } break; case 'frog': { 
            ctx.circle(47.5, 54.5, 0.8, line)
            ctx.circle(52.5, 54.5, 0.8, line)
            if (pose.lifted) {
                ctx.ellipse(45, 57, 10, 5.5, line)
                ctx.ellipse(47, 59.5, 6, 2.5, rgb(0xF08C9A))
            } else {
                ctx.strokePath(line, 1.5, (p) => {
                    p.move(pt(39, 57)); p.addQuadCurve(pt(61, 57), pt(50, 64))
                })
                if (mood == 'happy' || pose.petted > 0.15) {
                    let mouth = new Path()
                    mouth.move(pt(42, 58.5)); mouth.addQuadCurve(pt(58, 58.5), pt(50, 65))
                    mouth.closeSubpath()
                    ctx.fill(mouth, (line))
                    ctx.ellipse(46.5, 60, 7, 2.6, rgb(0xF08C9A))
                }
            }
        } break; case 'capybara': { 
            const nostril = rgb(0x4A3530)
            ctx.strokePath(nostril, 1.3, (p) => {
                p.move(pt(47, 52.4)); p.addLine(pt(46.2, 54.4))
                p.move(pt(53, 52.4)); p.addLine(pt(53.8, 54.4))
            })
            if (pose.lifted) {
                ctx.ellipse(48, 57.5, 4, 3.8, nostril)
            } else {
                ctx.strokePath(nostril.opacity(0.85), 1.3, (p) => {
                    p.move(pt(45.5, 57.5)); p.addQuadCurve(pt(50, 58), pt(47.5, 60.5))
                    p.addQuadCurve(pt(54.5, 57.5), pt(52.5, 60.5))
                })
            }
        } break; default: { 
            const nose = appearance.species == 'bear' || appearance.species == 'puppy' ? 1.6 : (appearance.species == 'panda' ? 1.3 : 1)
            ctx.polygon([pt(50 - 1.5 * nose, 55), pt(50 + 1.5 * nose, 55), pt(50, 55 + 2 * nose)], line)
            if (pose.lifted) {
                ctx.ellipse(48, 58, 4, 4.5, line)
            } else {
                if (appearance.species == 'puppy' && (mood == 'happy' || pose.petted > 0.15)) {
                    ctx.rect(47.6, 58.6, 4.8, 4.6, rgb(0xF08C9A), 2.4)
                }
                ctx.strokePath(line, 1.4, (p) => {
                    p.move(pt(46, 58)); p.addQuadCurve(pt(50, 58), pt(48, 61))
                    p.addQuadCurve(pt(54, 58), pt(52, 61))
                })
            }
        } }
        if (appearance.species == 'bunny' || appearance.species == 'hamster') {
            ctx.rect(48.4, 59.5, 3.2, 3, Color.white, 0.8)
        }
    }

    const capybaraMuzzle = ((): Path => {
        let p = new Path()
        p.move(pt(50, 46.5))
        p.addCurve(pt(62.5, 58.5), pt(57.5, 46.5), pt(62.5, 51))
        p.addCurve(pt(50, 65.5), pt(62.5, 64), pt(57, 65.5))
        p.addCurve(pt(37.5, 58.5), pt(43, 65.5), pt(37.5, 64))
        p.addCurve(pt(50, 46.5), pt(37.5, 51), pt(42.5, 46.5))
        p.closeSubpath()
        return p
    })()

    function drawDuckBill(ctx: GC) {
        const orange = rgb(0xF6A24E), dark = rgb(0xDF7E36)
        if (pose.lifted) {
            ctx.rect(41, 52, 18, 5.5, orange, 2.8)
            ctx.rect(43, 58.5, 14, 4, dark, 2)
        } else {
            ctx.rect(42.5, 56, 15, 5, dark, 2.5)
            ctx.rect(40.5, 52.5, 19, 6.5, orange, 3.25)
            ctx.ellipse(43, 53.5, 6, 2, Color.white.opacity(0.45))
        }
        ctx.circle(47, 54.5, 0.7, dark)
        ctx.circle(53, 54.5, 0.7, dark)
    }

    // MARK: Kính

    function drawGlasses(ctx: GC, id: string) {
        const frame = rgb(0x3E3550)
        switch (id) {
        case "glasses.round": { 
            ctx.strokePath(frame, 1.5, (p) => {
                p.addEllipse(R(30, 42.5, 15, 15))
                p.addEllipse(R(55, 42.5, 15, 15))
                p.move(pt(45, 49)); p.addQuadCurve(pt(55, 49), pt(50, 46))
                p.move(pt(30, 48)); p.addLine(pt(21, 46))
                p.move(pt(70, 48)); p.addLine(pt(79, 46))
            })
        } break; case "glasses.sun": { 
            ctx.rect(28, 44, 19, 11, rgb(0x2B2833), 4.5)
            ctx.rect(53, 44, 19, 11, rgb(0x2B2833), 4.5)
            ctx.strokePath(rgb(0x2B2833), 1.6, (p) => {
                p.move(pt(47, 47)); p.addLine(pt(53, 47))
            })
            ctx.strokePath(Color.white.opacity(0.45), 1.2, (p) => {
                p.move(pt(31, 47)); p.addLine(pt(35, 46))
                p.move(pt(56, 47)); p.addLine(pt(60, 46))
            })
        } break; case "glasses.heart": { 
            ctx.heart(pt(37.5, 50), 17, rgb(0xF27D9B).opacity(0.85))
            ctx.heart(pt(62.5, 50), 17, rgb(0xF27D9B).opacity(0.85))
            ctx.strokePath(rgb(0xD9667A), 1.4, (p) => {
                p.move(pt(45, 48)); p.addLine(pt(55, 48))
            })
        } break; case "glasses.monocle": { 
            ctx.strokePath(rgb(0xD9A441), 1.8, (p) => {
                p.addEllipse(R(54.5, 42, 16, 16))
            })
            ctx.strokePath(rgb(0xD9A441), 0.9, (p) => {
                p.move(pt(69, 55)); p.addQuadCurve(pt(72, 72), pt(76, 62))
            })
        } break; default: { 
            CostumeArt.glasses(id, ctx, appearance)
        } }
    }

    // MARK: Cổ

    function drawNeck(ctx: GC, id: string) {
        switch (id) {
        case "neck.scarf": { 
            const red = rgb(0xD9667A)
            ctx.rect(22, 62, 56, 8, red, 4)
            ctx.rotated(8, pt(60, 66), (c) => {
                c.rect(56, 65, 9, 17, red, 3)
                c.rect(56, 76, 9, 2, Color.white.opacity(0.7))
            })
            ctx.rect(30, 64.5, 2, 3, Color.white.opacity(0.7))
            ctx.rect(42, 64.5, 2, 3, Color.white.opacity(0.7))
        } break; case "neck.bowtie": { 
            const c = Palette.lavender
            ctx.polygon([pt(39, 61), pt(39, 72), pt(50, 66.5)], c)
            ctx.polygon([pt(61, 61), pt(61, 72), pt(50, 66.5)], c)
            ctx.circle(50, 66.5, 2.8, rgb(0x6F5AB8))
        } break; case "neck.bell": { 
            ctx.rect(26, 62, 48, 4.5, rgb(0xC2565A), 2.2)
            ctx.circle(50, 70, 4.2, rgb(0xF0C26A))
            ctx.rect(46.5, 70, 7, 1, rgb(0xB8862E))
            ctx.circle(50, 72.3, 0.9, rgb(0xB8862E))
        } break; case "neck.bandana": { 
            const blue = rgb(0x6FA3D9)
            ctx.polygon([pt(29, 62), pt(71, 62), pt(50, 80)], blue)
            for (const [x, y] of ([[40.0, 66.0], [50.0, 65.0], [60.0, 66.0], [45.0, 71.0], [55.0, 71.0], [50.0, 76.0]] as const)) {
                ctx.circle(x, y, 1.1, Color.white.opacity(0.9))
            }
        } break; case "neck.lei": { 
            const colors = [rgb(0xF2A3B8), rgb(0xF0C26A), Color.white, rgb(0xC8A6F0)]
            for (let i = 0; i < 9; i++) {
                const x = 27 + (i) * 5.75
                const y = 62 + 5 * (1 - Math.pow((x - 50) / 23, 2))
                ctx.circle(x, y, 3.3, colors[i % colors.length])
                ctx.circle(x, y, 1, rgb(0xE0925A))
            }
        } break; default: { 
            CostumeArt.neck(id, ctx, appearance)
        } }
    }

    // MARK: Áo

    function drawCapeBack(ctx: GC) {
        ctx.polygon([pt(22, 60), pt(78, 60), pt(93, 90), pt(7, 90)], rgb(0xC2565A))
    }

    function drawOutfit(ctx: GC, id: string, body: Rect) {
        const clipped = ctx.copy()
        clipped.clip(Path.ellipse(body))
        switch (id) {
        case "outfit.sweater": { 
            const green = rgb(0x8DB890)
            clipped.rect(0, 64, 100, 40, green)
            clipped.rect(0, 64, 100, 3.5, rgb(0x6F9A72))
            clipped.rect(0, 73, 100, 3, Color.white.opacity(0.55))
            clipped.rect(0, 80, 100, 3, Color.white.opacity(0.55))
        } break; case "outfit.overalls": { 
            const denim = rgb(0x6F8FC9)
            clipped.rect(0, 77, 100, 20, denim)
            clipped.rect(36, 65, 28, 16, denim, 3)
            clipped.rect(44, 69, 12, 7, rgb(0x5A78B0), 1.5)
            ctx.strokePath(denim, 3, (p) => {
                p.move(pt(38, 67)); p.addLine(pt(31, 61))
                p.move(pt(62, 67)); p.addLine(pt(69, 61))
            })
            ctx.circle(39, 67, 1.4, rgb(0xF0C26A))
            ctx.circle(61, 67, 1.4, rgb(0xF0C26A))
        } break; case "outfit.raincoat": { 
            const yellow = rgb(0xF2C14E)
            clipped.rect(0, 62, 100, 40, yellow)
            ctx.polygon([pt(36, 61), pt(50, 61), pt(43, 68)], rgb(0xE0A92E))
            ctx.polygon([pt(64, 61), pt(50, 61), pt(57, 68)], rgb(0xE0A92E))
            ctx.circle(50, 71, 1.6, rgb(0x3E3550))
            ctx.circle(50, 77, 1.6, rgb(0x3E3550))
        } break; case "outfit.cape": { 
            ctx.circle(50, 64, 3, rgb(0xF0C26A))
            ctx.strokePath(rgb(0xC2565A), 3, (p) => {
                p.move(pt(47, 64)); p.addLine(pt(27, 60))
                p.move(pt(53, 64)); p.addLine(pt(73, 60))
            })
        } break; default: { 
            CostumeArt.outfit(id, ctx, clipped, appearance)
        } }
    }

    // MARK: Mũ

    function drawHat(ctx: GC, id: string) {
        const top = appearance.species == 'hamster' ? 32 : 28
        const dy = top - 28
        const c = ctx.copy()
        c.translateBy(0, dy)
        switch (id) {
        case "hat.sprout": { 
            c.strokePath(rgb(0x5E8A61), 1.4, (p) => {
                p.move(pt(50, 30)); p.addLine(pt(50, 22))
            })
            c.rotated(-20, pt(50, 22), (r) => (r.ellipse(46, 10, 8, 13, Palette.sage)))
            c.rotated(35, pt(50, 24), (r) => (r.ellipse(50, 17, 5, 8, Palette.sage.opacity(0.85))))
        } break; case "hat.bow": { 
            const pink = rgb(0xF2A3B8)
            c.polygon([pt(24, 26), pt(24, 38), pt(33, 32)], pink)
            c.polygon([pt(42, 26), pt(42, 38), pt(33, 32)], pink)
            c.circle(33, 32, 2.8, rgb(0xE07F98))
        } break; case "hat.party": { 
            c.polygon([pt(38, 33), pt(50, 4), pt(62, 33)], Palette.lavender)
            c.strokePath(rgb(0xF0C26A), 2, (p) => {
                p.move(pt(43, 22)); p.addLine(pt(55, 18))
                p.move(pt(40, 30)); p.addLine(pt(59, 25))
            })
            c.circle(50, 4.5, 3.5, rgb(0xF2A3B8))
        } break; case "hat.beanie": { 
            let dome = c
            dome.clip(Path.rect(R(0, 0, 100, 34)))
            dome.ellipse(24, 13, 52, 44, rgb(0xD9667A))
            c.rect(23, 29, 54, 7, rgb(0xC2565A), 3.5)
            c.circle(50, 13, 5, Color.white)
        } break; case "hat.flower": { 
            const spots = [[28, 36], [34, 30], [42, 26.5], [50, 25.5], [58, 26.5], [66, 30], [72, 36]] as const
            for (const [i, s] of spots.entries()) {
                c.circle(s[0], s[1], 4, i % 2 == 0 ? Color.white : rgb(0xF0C26A))
                c.circle(s[0], s[1], 1.4, i % 2 == 0 ? rgb(0xF0C26A) : rgb(0xE0925A))
            }
        } break; case "hat.straw": { 
            const straw = rgb(0xE8C77E)
            c.ellipse(12, 27, 76, 11, straw)
            c.rect(30, 12, 40, 21, rgb(0xDDB766), 9)
            c.rect(30, 25, 40, 4, rgb(0xD9667A))
        } break; case "hat.wizard": { 
            const purple = rgb(0x5B4B8A)
            c.ellipse(24, 27, 52, 8, purple)
            c.polygon([pt(35, 31), pt(60, -2), pt(66, 31)], purple)
            c.text("✦", 6, rgb(0xF0C26A), pt(53, 20))
            c.text("✦", 4, rgb(0xF0C26A), pt(58, 10))
        } break; case "hat.crown": { 
            const gold = rgb(0xF0C26A)
            c.polygon([pt(33, 32), pt(33, 18), pt(39.5, 25), pt(45, 13),
                       pt(50, 22), pt(55, 13), pt(60.5, 25), pt(67, 18), pt(67, 32)], gold)
            c.circle(45, 13, 1.8, rgb(0xF27D9B))
            c.circle(55, 13, 1.8, rgb(0x6FA3D9))
            c.circle(50, 28, 2.2, rgb(0xD9667A))
        } break; default: { 
            CostumeArt.hat(id, c, appearance)
        } }
    }

    // MARK: Chân & hiệu ứng

    function drawPaws(ctx: GC, fur: FurPalette) {
        const step = pose.walk != null ? Math.sin(pose.walk) * 2.2 : 0
        const dangle = pose.lifted ? 4 : 0
        const feet = [{ x: 41, y: 80 - step + dangle, side: -1 }, { x: 59, y: 80 + step + dangle, side: 1 }] as const
        switch (appearance.species) {
        case 'duck': case 'penguin': { 
            // Chân màng màu cam.
            const orange = rgb(0xF6A24E), dark = rgb(0xDF7E36)
            const w = appearance.species == 'duck' ? 13 : 11
            for (const foot of feet) {
                ctx.rotated((foot.side) * 10, pt(foot.x, foot.y + 3), (c) => {
                    let p = new Path()
                    p.move(pt(foot.x - 2, foot.y + 1))
                    p.addLine(pt(foot.x - w / 2, foot.y + 6.5))
                    p.addQuadCurve(pt(foot.x, foot.y + 6.5), pt(foot.x - w / 4, foot.y + 8.5))
                    p.addQuadCurve(pt(foot.x + w / 2, foot.y + 6.5), pt(foot.x + w / 4, foot.y + 8.5))
                    p.addLine(pt(foot.x + 2, foot.y + 1))
                    p.addQuadCurve(pt(foot.x - 2, foot.y + 1), pt(foot.x, foot.y - 1))
                    p.closeSubpath()
                    c.fill(p, (orange))
                    c.strokePath(dark, 0.9, (s) => {
                        s.move(pt(foot.x - w / 4, foot.y + 4.5)); s.addLine(pt(foot.x - w / 4, foot.y + 6.8))
                        s.move(pt(foot.x + w / 4, foot.y + 4.5)); s.addLine(pt(foot.x + w / 4, foot.y + 6.8))
                    })
                })
            }
        } break; case 'frog': { 
            for (const foot of feet) {
                ctx.ellipse(foot.x - 7, foot.y + 0.5, 14, 6.5 + dangle / 2, fur.base)
                for (const k of [-1, 0, 1]) {
                    ctx.circle(foot.x + k * 5, foot.y + 6.3 + dangle / 2 - Math.abs(k) * 0.6, 2, fur.base)
                }
            }
        } break; case 'panda': { 
            for (const foot of feet) {
                ctx.ellipse(foot.x - 5.5, foot.y - 0.5, 11, 7.5 + dangle / 2, pandaDark)
            }
        } break; case 'capybara': { 
            for (const foot of feet) {
                ctx.ellipse(foot.x - 5.5, foot.y, 11, 7 + dangle / 2, fur.shade)
            }
        } break; default: { 
            ctx.ellipse(36, 80 - step + dangle, 10, 7 + dangle / 2, fur.base)
            ctx.ellipse(54, 80 + step + dangle, 10, 7 + dangle / 2, fur.base)
        } }
    }

    function drawMoodExtras(ctx: GC) {
        switch (mood) {
        case 'focus': { 
            ctx.rect(36, 70, 28, 13, Palette.lavender, 2)
            ctx.rect(49.5, 70, 1, 13, Color.white.opacity(0.7))
        } break; case 'rest': { 
            const z = pose.z
            ctx.text("z", 9, Palette.lavender.opacity((1 - z * 0.6)), pt(80 + z * 4, 26 - z * 8), 'bold')
            ctx.text("z", 6, Palette.lavender.opacity((0.4 + z * 0.6)), pt(86 + z * 3, 16 - z * 6), 'bold')
        } break; case 'happy': { 
            ctx.text("✦", 8, Palette.honey, pt(15, 26))
            ctx.text("✦", 6, Palette.honey, pt(86, 34))
        } break; case 'idle': case 'low': { 
            break
        } }
    }

    function drawHearts(ctx: GC) {
        const p = pose.hearts; if (p == null) { return }
        const fade = (Math.max(0, 1 - p))
        const xs = [36, 50, 64]
        for (const [i, x] of xs.entries()) {
            const k = (i)
            const rise = p * 26 + (i % 2) * 4
            const sway = Math.sin(p * 6 + k) * 2
            const size = 7 + (i % 2) * 2
            ctx.heart(pt(x + sway, 26 - rise), size, rgb(0xF27D9B).opacity(fade))
        }
    }
    draw(base0)
}
