import SwiftUI

/// Hiệu ứng ngắn (lấp lánh, "+điểm") — chỉ để vẽ, không ảnh hưởng luật chơi.
struct GameEffect: Identifiable, Equatable {
    enum Kind: Equatable { case sparkle, plus(Int), minus(Int) }
    let id: Int
    let kind: Kind
    /// Vị trí trong tọa độ thế giới của game (rộng 100, y hướng lên).
    let x: Double
    let y: Double
    let start: TimeInterval

    static let lifetime: TimeInterval = 0.7
}

/// Vẽ một khung hình Nhảy Mây từ trạng thái engine.
struct CloudJumpPainter {
    var engine: CloudJumpEngine
    var effects: [GameEffect] = []
    var now: TimeInterval = 0
    var lastBounceAt: TimeInterval = -10
    var reduceMotion = false

    static let petWidth = 18.0

    func draw(in ctx: GraphicsContext, size: CGSize, pet: PetSpriteDrawer) {
        let k = size.width / CloudJumpEngine.worldWidth
        func sy(_ y: Double) -> CGFloat { size.height - CGFloat(y - engine.cameraY) * k }
        GameArt.sky(ctx, size: size, altitude: engine.cameraY, reduceMotion: reduceMotion)
        let ground = sy(0)
        if ground < size.height + 400 { GameArt.hills(ctx, width: size.width, groundY: ground) }

        let t = engine.time
        for p in engine.platforms where p.id != 0 {
            let top = sy(p.y)
            guard top > -30, top < size.height + 30 else { continue }
            let w = CGFloat(p.width) * k
            let x = CGFloat(p.x(at: t)) * k
            GameArt.cloud(ctx, rect: CGRect(x: x - w / 2, y: top - 2 * k, width: w, height: 6 * k), moving: p.isMoving)
        }
        let bob = reduceMotion ? 0 : CGFloat(sin(t * 3)) * 1.2 * k
        for s in engine.stars {
            GameArt.star(ctx, center: CGPoint(x: CGFloat(s.x) * k, y: sy(s.y) + bob), radius: 3.6 * k)
        }

        let w = CGFloat(Self.petWidth) * k
        let feet = sy(engine.petY)
        let kind: PetSpriteKind = engine.isOver ? .surprised : (now - lastBounceAt < 0.25 ? .cheer : (engine.velY > 0 ? .happy : .idle))
        // Hơi co giãn khi vừa nảy (không có khi bật Giảm chuyển động).
        let squash: CGFloat = reduceMotion ? 1 : (now - lastBounceAt < 0.12 ? 0.9 : 1)
        let h = w * squash
        pet(ctx, CGRect(x: CGFloat(engine.petX) * k - w / 2, y: feet - h + w * 0.04, width: w, height: h), kind, engine.facingLeft)

        drawEffects(ctx, k: k, sy: sy)
    }

    private func drawEffects(_ ctx: GraphicsContext, k: CGFloat, sy: (Double) -> CGFloat) {
        for e in effects {
            let p = CGFloat(min(1, max(0, (now - e.start) / GameEffect.lifetime)))
            let c = CGPoint(x: CGFloat(e.x) * k, y: sy(e.y))
            switch e.kind {
            case .sparkle:
                if !reduceMotion { GameArt.sparkle(ctx, at: c, progress: p, color: rgb(0xF6C445)) }
            case .plus(let n):
                ctx.draw(Text("+\(n)").font(.system(size: 6 * k, weight: .heavy, design: .rounded)).foregroundColor(rgb(0xD99A2B).opacity(Double(1 - p))),
                         at: CGPoint(x: c.x, y: c.y - p * 10 * k))
            case .minus(let n):
                ctx.draw(Text("−\(n)").font(.system(size: 6 * k, weight: .heavy, design: .rounded)).foregroundColor(rgb(0x6B5A7A).opacity(Double(1 - p))),
                         at: CGPoint(x: c.x, y: c.y - p * 10 * k))
            }
        }
    }
}

/// Vẽ một khung hình Giỏ Quà từ trạng thái engine.
struct GiftBasketPainter {
    var engine: GiftBasketEngine
    var effects: [GameEffect] = []
    var now: TimeInterval = 0
    var mood: PetSpriteKind = .idle
    var reduceMotion = false

    static let groundY = 4.0
    static let petFeetY = 9.0
    static let petWidth = 30.0

    func draw(in ctx: GraphicsContext, size: CGSize, pet: PetSpriteDrawer) {
        let k = size.width / GiftBasketEngine.worldWidth
        func sy(_ y: Double) -> CGFloat { size.height - CGFloat(y) * k }
        GameArt.garden(ctx, size: size, groundY: sy(Self.groundY))

        for item in engine.items {
            let r = CGFloat(item.kind.radius) * k
            let wobble = reduceMotion ? 0 : CGFloat(sin(engine.time * 4 + Double(item.id))) * 0.8 * k
            GameArt.drop(ctx, kind: item.kind, center: CGPoint(x: CGFloat(item.x) * k + wobble, y: sy(item.y)), radius: r)
        }

        let bx = CGFloat(engine.basketX) * k
        let w = CGFloat(Self.petWidth) * k
        let facingLeft = engine.targetX < engine.basketX - 0.5
        let bw = CGFloat(GiftBasketEngine.basketHalfWidth * 2) * k
        let basket = CGRect(x: bx - bw / 2, y: sy(GiftBasketEngine.basketY), width: bw, height: 9 * k)
        // Bạn nhỏ đứng sau giỏ, mắt cao hơn miệng giỏ; giỏ che phần thân dưới như đang ôm giỏ.
        pet(ctx, CGRect(x: bx - w / 2, y: sy(Self.petFeetY) - w, width: w, height: w), mood, facingLeft)
        GameArt.basket(ctx, rect: basket, handle: false)

        for e in effects {
            let p = CGFloat(min(1, max(0, (now - e.start) / GameEffect.lifetime)))
            let c = CGPoint(x: CGFloat(e.x) * k, y: sy(e.y))
            switch e.kind {
            case .sparkle:
                if !reduceMotion { GameArt.sparkle(ctx, at: c, progress: p, color: rgb(0xF27D9B)) }
            case .plus(let n):
                ctx.draw(Text("+\(n)").font(.system(size: 6 * k, weight: .heavy, design: .rounded)).foregroundColor(rgb(0x6F9A72).opacity(Double(1 - p))),
                         at: CGPoint(x: c.x, y: c.y - p * 12 * k))
            case .minus(let n):
                ctx.draw(Text(n > 0 ? "−\(n)" : "ối!").font(.system(size: 5.5 * k, weight: .heavy, design: .rounded)).foregroundColor(rgb(0x6B5A7A).opacity(Double(1 - p))),
                         at: CGPoint(x: c.x, y: c.y - p * 12 * k))
            }
        }
    }
}
