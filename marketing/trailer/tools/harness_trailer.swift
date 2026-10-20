import SwiftUI
import Foundation

// trailer <jobs.txt>: mỗi dòng (tách bằng tab) là một khung hình SVG.
//   pet    out W  petspec pose
//   avatar out W  bg,scene,fx,mood  petspec pose time
//   room   out W  room  id1,id2,...  petspec pose petx   (petx = "-" để không vẽ thú cưng)
func parsePet(_ spec: String) -> (PetAppearance, PetMood) {
    var a = PetAppearance()
    var mood = PetMood.happy
    for kv in spec.split(separator: ",") {
        let p = kv.split(separator: "=", maxSplits: 1).map(String.init)
        guard p.count == 2 else { continue }
        switch p[0] {
        case "species": a.species = PetSpecies(rawValue: p[1]) ?? a.species
        case "fur": a.fur = FurColor(rawValue: p[1]) ?? a.fur
        case "hat": a.hat = p[1]
        case "glasses": a.glasses = p[1]
        case "neck": a.neck = p[1]
        case "outfit": a.outfit = p[1]
        case "back": a.back = p[1]
        case "stage": a.stage = ["little": .little, "growing": .growing, "grown": .grown][p[1]] ?? a.stage
        case "mood": mood = ["idle": .idle, "happy": .happy, "focus": .focus, "rest": .rest, "low": .low][p[1]] ?? mood
        default: break
        }
    }
    return (a, mood)
}
func parsePose(_ spec: String) -> PetPose {
    var p = PetPose()
    for kv in spec.split(separator: ",") {
        let q = kv.split(separator: "=", maxSplits: 1).map(String.init)
        guard q.count == 2, let v = Double(q[1]) else { continue }
        switch q[0] {
        case "breath": p.breath = v
        case "blink": p.blink = v > 0
        case "tail": p.tail = v
        case "ear": p.ear = v
        case "hop": p.hop = v
        case "tilt": p.tilt = v
        case "look": p.look = v
        case "walk": p.walk = v
        case "hearts": p.hearts = v
        case "z": p.z = v
        case "petted": p.petted = v
        case "lifted": p.lifted = v > 0
        default: break
        }
    }
    return p
}

let jobs = try! String(contentsOfFile: CommandLine.arguments[1], encoding: .utf8)
for line in jobs.split(separator: "\n") {
    let f = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
    guard f.count >= 3, let w = Double(f[2]) else { continue }
    switch f[0] {
    case "pet":
        let rec = SVGRecorder(width: Int(w), height: Int(w))
        var ctx = GraphicsContext(recorder: rec)
        ctx.scaleBy(x: w / 100, y: w / 100)
        let (a, mood) = parsePet(f[3])
        PetPainter(mood: mood, appearance: a, pose: parsePose(f.count > 4 ? f[4] : "")).draw(in: ctx)
        try! rec.svg.write(toFile: f[1], atomically: true, encoding: .utf8)
    case "avatar":
        let rec = SVGRecorder(width: Int(w), height: Int(w))
        var ctx = GraphicsContext(recorder: rec)
        ctx.scaleBy(x: w / 100, y: w / 100)
        var clipped = ctx
        clipped.clip(to: Path(CGRect(x: 0, y: 0, width: 100, height: 100)))
        let o = f[3].split(separator: ",").map(String.init)
        let (a, _) = parsePet(f[4])
        AvatarPainter(background: o[0], scene: o[1], effect: o[2], mood: PetMood(avatarID: o[3]), appearance: a, caption: nil,
                      pose: parsePose(f[5]), time: Double(f[6]) ?? 0).draw(in: clipped)
        try! rec.svg.write(toFile: f[1], atomically: true, encoding: .utf8)
    case "room":
        guard let room = RoomKind(rawValue: f[3]) else { continue }
        let h = w / 125 * 100
        let rec = SVGRecorder(width: Int(w), height: Int(h))
        var ctx = GraphicsContext(recorder: rec)
        ctx.scaleBy(x: w / 125, y: w / 125)
        var clipped = ctx
        clipped.clip(to: Path(CGRect(x: 0, y: 0, width: 125, height: 100)))
        var equipped: [ItemSlot: String] = [:]
        for id in f[4].split(separator: ",").map(String.init) {
            if let item = Catalog.item(id), room.slots.contains(item.slot) || item.slot == room.themeSlot { equipped[item.slot] = id }
        }
        ItemPainter.draw(equipped[room.themeSlot] ?? Catalog.defaultItem(for: room.themeSlot)?.id ?? "", in: clipped)
        if let floor = equipped[room.floorSlot] { ItemPainter.draw(floor, in: clipped) }
        for slot in RoomLayout.drawOrder(room) {
            guard let id = equipped[slot], let s = RoomLayout.spot(slot) else { continue }
            var c = clipped
            c.translateBy(x: s.x, y: s.y); c.scaleBy(x: s.size / 100, y: s.size / 100)
            ItemPainter.draw(id, in: c)
        }
        if f.count > 7, let px = Double(f[7]) {
            let (a, mood) = parsePet(f[5])
            var p = clipped
            let size = 125 * 0.30
            p.translateBy(x: 125 * px, y: 86 - size); p.scaleBy(x: size / 100, y: size / 100)
            PetPainter(mood: mood, appearance: a, pose: parsePose(f[6])).draw(in: p)
        }
        try! rec.svg.write(toFile: f[1], atomically: true, encoding: .utf8)
    default: break
    }
}
