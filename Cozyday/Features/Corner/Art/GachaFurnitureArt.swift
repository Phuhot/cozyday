import SwiftUI

enum GachaFurnitureArt {
    static func draw(_ id: String, in c: GraphicsContext) -> Bool {
        switch id {
        case "lamp.g_jellyfish":
            c.ellipse(20, 85, 60, 8, rgb(0x7DA8BC).opacity(0.2))
            for i in 0..<5 {
                let x = CGFloat(30+i*10)
                c.strokePath(rgb(0xA4CADF), width: 3) { p in
                    p.move(to: CGPoint(x:x,y:42)); p.addCurve(to: CGPoint(x:x+2,y:82), control1: CGPoint(x:x-12,y:57), control2: CGPoint(x:x+12,y:68))
                }
            }
            c.ellipse(18, 16, 64, 40, rgb(0xB9A7DC)); c.ellipse(23, 20, 54, 30, rgb(0xCBE6EC).opacity(0.85))
            c.ellipse(30, 22, 18, 5, .white.opacity(0.8)); c.circle(43, 40, 2, rgb(0x66608E)); c.circle(58, 40, 2, rgb(0x66608E))
        case "nightstand.g_musicbox":
            c.ellipse(10, 87, 80, 8, .black.opacity(0.12))
            c.rect(16, 58, 68, 29, rgb(0x744D6A), radius: 8); c.rect(19, 61, 62, 5, rgb(0xE6C380), radius: 2)
            c.rect(22, 69, 56, 13, rgb(0xA77A90), radius: 3); c.circle(50, 75, 3, rgb(0xE6C380))
            c.ellipse(18, 50, 64, 15, rgb(0xE6C380)); c.ellipse(23, 52, 54, 9, rgb(0xF6E8CA))
            c.rect(48, 42, 4, 14, rgb(0xD8B472)); c.ellipse(39, 31, 22, 18, rgb(0xF6D3C8))
            c.circle(50, 25, 12, rgb(0xFFF1D9)); c.polygon([CGPoint(x:39,y:20),CGPoint(x:39,y:8),CGPoint(x:48,y:15)],rgb(0xFFF1D9))
            c.polygon([CGPoint(x:53,y:15),CGPoint(x:62,y:8),CGPoint(x:62,y:21)],rgb(0xFFF1D9))
            c.circle(46,25,1.5,rgb(0x775268)); c.circle(55,25,1.5,rgb(0x775268))
            c.polygon([CGPoint(x:38,y:44),CGPoint(x:50,y:34),CGPoint(x:64,y:44)],rgb(0xC39BC3))
        case "bed.g_moon":
            c.ellipse(4, 86, 91, 10, .black.opacity(0.13))
            // Crescent is a concave path, so the room shows through its opening.
            c.fill(Path { p in
                p.move(to: CGPoint(x:73,y:5)); p.addCurve(to: CGPoint(x:77,y:87),control1: CGPoint(x:-20,y:-12),control2: CGPoint(x:-18,y:107))
                p.addCurve(to: CGPoint(x:73,y:5),control1: CGPoint(x:29,y:89),control2: CGPoint(x:30,y:25)); p.closeSubpath()
            }, with: .linearGradient(Gradient(colors:[rgb(0xFFE4A0),rgb(0xDBA956)]), startPoint:CGPoint(x:15,y:5),endPoint:CGPoint(x:60,y:90)))
            c.ellipse(32, 69, 60, 17, rgb(0xA79BD4)); c.ellipse(40, 68, 26, 10, rgb(0xE7DCED))
            c.strokePath(rgb(0xD4B987),width:1) { p in p.move(to:CGPoint(x:72,y:7)); p.addLine(to:CGPoint(x:75,y:36)) }
            GachaMachineArt.star(c,center:CGPoint(x:75,y:43),r:9,color:rgb(0xF6D17B))
            for x: CGFloat in [34,48,62] { c.circle(x, 80, 1.5, rgb(0xF6D17B)) }
        default: return false
        }
        return true
    }
}
