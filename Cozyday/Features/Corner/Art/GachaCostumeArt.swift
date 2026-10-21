import SwiftUI

/// Original capsule designs in the pet's 100×100 coordinate system.
extension CostumeArt {
    static func gachaHat(_ id: String, _ c: GraphicsContext, _ a: PetAppearance) {
        switch id {
        case "hat.g_teacup":
            c.ellipse(26, 26, 48, 7, rgb(0x91BBAA))
            c.stroke(Path(ellipseIn: CGRect(x: 64, y: 13, width: 14, height: 12)), with: .color(rgb(0xDAB66B)), lineWidth: 3)
            c.rect(32, 10, 35, 18, rgb(0xFFF8ED), radius: 7)
            c.ellipse(32, 8, 35, 7, rgb(0xDAB66B)); c.ellipse(36, 10, 27, 3, rgb(0x986953))
            c.heart(center: CGPoint(x: 49, y: 21), size: 8, rgb(0xD7859A))
            c.strokePath(.white.opacity(0.8), width: 2) { p in p.move(to: CGPoint(x: 48, y: 7)); p.addQuadCurve(to: CGPoint(x: 49, y: -2), control: CGPoint(x: 56, y: 2)) }
        case "hat.g_duckling":
            c.ellipse(33, 14, 32, 17, rgb(0xFFD76D)); c.circle(58, 12, 10, rgb(0xFFE58B))
            c.ellipse(36, 19, 16, 8, rgb(0xE9B957)); c.circle(61, 10, 1.5, rgb(0x523C3F))
            c.ellipse(65, 13, 9, 4, rgb(0xEE9756)); c.ellipse(40, 28, 10, 3, rgb(0xEE9756))
        default: break
        }
    }
    static func gachaGlasses(_ id: String, _ c: GraphicsContext, _ a: PetAppearance) {
        guard ["glasses.g_lemon", "glasses.g_bubble"].contains(id) else { return }
        c.rect(44, 49, 12, 2, rgb(0xE0BA65), radius: 1)
        for x: CGFloat in [37, 63] {
            if id == "glasses.g_lemon" {
                c.circle(x, 50, 11, rgb(0xD9AA32)); c.circle(x, 50, 9, rgb(0xFFE58A).opacity(0.8))
                for i in 0..<6 {
                    let angle = Double(i) * .pi / 3
                    c.strokePath(rgb(0xFFF8CF), width: 1) { p in
                        p.move(to: CGPoint(x: x, y: 50)); p.addLine(to: CGPoint(x: x + CGFloat(cos(angle)) * 9, y: 50 + CGFloat(sin(angle)) * 9))
                    }
                }
            } else {
                c.circle(x, 50, 12, rgb(0xA4D8E9).opacity(0.35))
                c.stroke(Path(ellipseIn: CGRect(x: x-12, y: 38, width: 24, height: 24)), with: .color(rgb(0xBC9CD8)), lineWidth: 1.6)
                c.ellipse(x-7, 41, 9, 3, .white.opacity(0.9)); c.circle(x+6, 56, 2, rgb(0xF3B9D8))
            }
        }
    }
    static func gachaNeck(_ id: String, _ c: GraphicsContext, _ a: PetAppearance) {
        guard ["neck.g_shell", "neck.g_cherry"].contains(id) else { return }
        c.strokePath(rgb(0xD3B478), width: 1.5) { p in p.move(to: CGPoint(x: 32, y: 61)); p.addQuadCurve(to: CGPoint(x: 68, y: 61), control: CGPoint(x: 50, y: 79)) }
        if id == "neck.g_cherry" {
            c.strokePath(rgb(0x65956B), width: 1.4) { p in p.move(to: CGPoint(x: 51, y: 65)); p.addLine(to: CGPoint(x: 46, y: 73)); p.move(to: CGPoint(x: 51, y: 65)); p.addLine(to: CGPoint(x: 55, y: 74)) }
            c.circle(45, 74, 4, rgb(0xC65E71)); c.circle(55, 75, 4, rgb(0xDB7585)); c.circle(44, 72, 1, .white)
        } else {
            for x: CGFloat in [34, 40, 60, 66] { c.circle(x, 65 + (x == 40 || x == 60 ? 3 : 0), 2, rgb(0xFFF3DF)) }
            c.ellipse(44, 67, 12, 10, rgb(0xEEC5BE))
            for dx: CGFloat in [-4, 0, 4] { c.strokePath(.white.opacity(0.8), width: 1) { p in p.move(to: CGPoint(x: 50, y: 76)); p.addLine(to: CGPoint(x: 50+dx, y: 69)) } }
        }
    }
    static func gachaOutfit(_ id: String, _ c: GraphicsContext, clipped: GraphicsContext, _ a: PetAppearance) {
        switch id {
        case "outfit.g_teadress":
            clipped.rect(20, 63, 60, 25, rgb(0x80AFA3), radius: 8)
            for x: CGFloat in [30, 38, 46, 54, 62, 70] { clipped.circle(x, 83, 4, rgb(0xFFF9EF)); clipped.circle(x, 64, 4, rgb(0xFFF9EF)) }
            clipped.rect(43, 67, 14, 15, rgb(0xFFF9EF), radius: 3)
            clipped.heart(center: CGPoint(x: 50, y: 73), size: 7, rgb(0xD68B99))
        case "outfit.g_strawberry":
            clipped.rect(19, 62, 62, 25, rgb(0xDB687C), radius: 10)
            for x: CGFloat in [29, 39, 50, 61, 71] { clipped.ellipse(x, 71, 1.8, 3, rgb(0xFFE9AC)); clipped.ellipse(x+3, 80, 1.8, 3, rgb(0xFFE9AC)) }
            clipped.polygon([CGPoint(x: 29,y: 61), CGPoint(x: 39,y: 72), CGPoint(x: 49,y: 63), CGPoint(x: 59,y: 72), CGPoint(x: 70,y: 61)], rgb(0x7DA66C))
        case "outfit.g_pirate":
            // A structured, asymmetric coat: ivory lining, brocade cuffs and a real belt silhouette.
            clipped.rect(17, 60, 66, 29, rgb(0x713C54), radius: 5)
            clipped.polygon([CGPoint(x: 42,y: 61),CGPoint(x: 58,y: 61),CGPoint(x: 62,y: 87),CGPoint(x: 38,y: 87)], rgb(0xFFF0D7))
            clipped.polygon([CGPoint(x: 26,y: 60),CGPoint(x: 43,y: 61),CGPoint(x: 37,y: 73),CGPoint(x: 28,y: 69)], rgb(0xC28B52))
            clipped.polygon([CGPoint(x: 58,y: 61),CGPoint(x: 76,y: 60),CGPoint(x: 72,y: 69),CGPoint(x: 63,y: 73)], rgb(0xC28B52))
            for y: CGFloat in [68, 74] { clipped.circle(32,y,1.7,rgb(0xF4D58A)); clipped.circle(68,y,1.7,rgb(0xF4D58A)) }
            clipped.rect(20, 78, 60, 6, rgb(0x342D3F)); clipped.rect(44, 77, 12, 8, rgb(0xDAB45E), radius: 2)
            clipped.rect(47, 79, 6, 4, rgb(0x342D3F), radius: 1)
        default: break
        }
    }
    static func gachaBack(_ id: String, _ c: GraphicsContext, _ a: PetAppearance, front: Bool) {
        if id == "back.g_snail", !front {
            c.circle(73, 64, 24, rgb(0xC5A0C7)); c.circle(73, 64, 19, rgb(0xEFCCD9))
            c.strokePath(rgb(0xA37BAF), width: 3) { p in
                p.move(to: CGPoint(x: 86,y: 65))
                for i in 0...80 { let t = Double(i)/80 * .pi * 3.5; let r = 14 * (1-Double(i)/95); p.addLine(to: CGPoint(x: 73+cos(t)*r,y: 64+sin(t)*r)) }
            }
        }
        if id == "back.g_starlantern", front {
            c.strokePath(rgb(0x916645), width: 2) { p in p.move(to: CGPoint(x: 76,y: 75)); p.addLine(to: CGPoint(x: 88,y: 32)) }
            c.strokePath(rgb(0xDA795F), width: 1) { p in p.move(to: CGPoint(x: 87,y: 36)); p.addLine(to: CGPoint(x: 89,y: 48)) }
            GachaMachineArt.star(c, center: CGPoint(x: 88,y: 59), r: 14, color: rgb(0xD67263))
            GachaMachineArt.star(c, center: CGPoint(x: 88,y: 59), r: 10, color: rgb(0xFFDE87))
            for x: CGFloat in [84, 88, 92] { c.rect(x, 71, 1.5, 8, rgb(0xDA795F), radius: 1) }
        }
    }
}
