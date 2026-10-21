import SwiftUI

/// One 9-second scene per batch, using the player's actual pet. No inventory writes occur here.
struct GachaCutsceneView: View {
    let appearance: PetAppearance
    let tier: ItemRarity
    let short: Bool
    let finished: () -> Void
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("playground.sound") private var soundOn = true
    @State private var elapsed = 0.0
    @State private var ended = false
    @State private var sound: GameSound?

    private var duration: Double { reduceMotion || short ? 1.8 : 9.0 }
    var body: some View {
        VStack(spacing: Spacing.m) {
            HStack {
                Text("Một món quà cho bạn nhỏ").font(Typography.headline)
                Spacer()
                Button("Bỏ qua", action: finish).frame(minHeight: HitTarget.min)
            }
            Canvas { context, size in
                CapsuleScenePainter.draw(context, size: size, time: reduceMotion || short ? 7 + elapsed : elapsed,
                                         pet: appearance, tier: tier, still: reduceMotion)
            }
            .aspectRatio(1.15, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: Radius.l))
            .accessibilityLabel(elapsed < duration * 0.75 ? "Bạn nhỏ đang mở viên nang" : "Đã mở món \(tier.label)")
            Text("Kết quả đã được lưu. Bạn có thể bỏ qua bất cứ lúc nào.")
                .font(Typography.caption).foregroundStyle(Palette.inkMuted)
        }
        .padding(Spacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cozyBackground()
        .task {
            // Do not change the focus audio session's playback policy just for this scene.
            let audio = GameSound(enabled: soundOn && !FocusAudio.inUse)
            sound = audio
            audio.prepare()
            let reveal: GameCue = tier == .secret ? .merge4 : tier == .epic ? .merge3 : tier == .rare ? .merge2 : .merge1
            let cues: [(Double, GameCue)] = duration < 2
                ? [(0.2, .place), (0.8, reveal)]
                : [(0.2,.whoosh),(1,.tick),(1.5,.tick),(2.1,.place),(2.5,.bounce),(2.9,.bounce),
                   (3.3,.whoosh),(4.6,.pickup),(5,.tick),(5.5,.tick),(6.3,.refill),(7.2,reveal),(8,.star)]
            let started = ProcessInfo.processInfo.systemUptime
            var nextCue = 0
            while !Task.isCancelled && !ended {
                elapsed = ProcessInfo.processInfo.systemUptime - started
                while nextCue < cues.count && elapsed >= cues[nextCue].0 {
                    audio.play(cues[nextCue].1); nextCue += 1
                }
                if elapsed >= duration { finish(); return }
                do { try await Task.sleep(nanoseconds: 33_333_333) } catch { return }
            }
        }
        .onChange(of: phase) { _, value in if value != .active { finish() } }
        .onDisappear { sound?.stop() }
    }
    private func finish() {
        guard !ended else { return }
        ended = true
        sound?.stop()
        finished()
    }
}

/// Original layered 2D set: perspective floor, camera tracking, a bouncing capsule, and pet acting.
/// This is 2.5D staging, not a 3D model. Coordinates are in a 360×310 room.
enum CapsuleScenePainter {
    static func draw(_ original: GraphicsContext, size: CGSize, time t: Double, pet: PetAppearance,
                     tier: ItemRarity, still: Bool) {
        let unit = min(size.width / 360, size.height / 310)
        var c = original
        c.translateBy(x: (size.width-360*unit)/2, y: (size.height-310*unit)/2)
        c.scaleBy(x: unit, y: unit)
        c.rect(0,0,360,310,rgb(0xEEE5F2))
        let zoom = still ? 1 : 1 + 0.09 * smooth(min(t/2,1)) + 0.08 * smooth(min(max((t-4)/3,0),1))
        let pan = still ? 0 : 12 * smooth(min(max((t-2)/2,0),1))
        // Far wall follows only a fraction of the camera movement.
        var back = c
        back.translateBy(x: -pan*0.3, y: 0)
        back.rect(20,30,100,85,rgb(0xFFF8EF),radius:16)
        back.rect(27,37,86,71,rgb(0xB7D6DF),radius:12)
        back.circle(90,55,13,rgb(0xFFE3A0))
        back.rect(65,37,4,71,rgb(0xFFF8EF)); back.rect(27,73,86,4,rgb(0xFFF8EF))
        back.rect(241,57,77,5,rgb(0xAC849C),radius:2)
        back.rect(251,36,17,20,rgb(0xDDB478),radius:3); back.ellipse(250,23,20,20,rgb(0x96B89C))
        c.translateBy(x: 180-pan, y: 180)
        c.scaleBy(x: zoom,y: zoom); c.translateBy(x:-180,y:-180)
        c.rect(-80,151,520,220,rgb(0xE2C9BA))
        for i in 0..<8 { let x=CGFloat(i)*65-80; c.strokePath(rgb(0xCAAC9F),width:1) { p in p.move(to:CGPoint(x:180+(x-180)*0.45,y:151)); p.addLine(to:CGPoint(x:x,y:340)) } }
        for y: CGFloat in [179,217,270,330] { c.rect(-80,y,520,1,rgb(0xCAAC9F)) }
        var machine = c
        machine.translateBy(x:18,y:15)
        GachaMachineArt.draw(machine,size:CGSize(width:150,height:195),spin:t<2 ? max(0,t-0.8) : -1,dropsCapsule:false)
        var pose = PetPose()
        if !still {
            pose.breath = CGFloat(sin(t*2))*0.6
            pose.lookDown = t > 3.8 && t < 7.2 ? 1 : 0
            pose.headTilt = t > 4 && t < 5 ? -10 * sin((t-4) * .pi) : 0
            let paw = max(0,sin((t-4.6)*.pi*2))
            pose.pawLift = t > 4.6 && t < 5.8 ? CGFloat(paw) : 0
            pose.pawReach = pose.pawLift
            pose.hop = t > 7.4 ? CGFloat(abs(sin((t-7.4)*4))*7*max(0,1-(t-7.4)/2)) : 0
        }
        var pc = c; pc.translateBy(x:200,y:180)
        PetPainter(mood:t>7.2 ? .happy : .idle,appearance:pet,pose:pose).draw(in:pc)
        if t >= 2 {
            let progress = min(max((t-2)/2,0),1)
            let x = CGFloat(83 + 129*smooth(progress))
            let fall = min((t-2)/0.4,1)
            let bounce = t < 2.4 ? 78*(1-fall*fall) : abs(sin((t-2.4)*9))*17*max(0,1-(t-2.4)/1.3)
            let nudge = t>5 && t<5.8 && !still ? sin((t-5)*12)*2 : 0
            let y = CGFloat(258-bounce)
            c.ellipse(x-12,267,24,4,.black.opacity(0.16))
            if t < 7.2 {
                GachaMachineArt.capsule(c,center:CGPoint(x:x+CGFloat(nudge),y:y),radius:11,
                                       color:rgb(0xECA4B9),tilt:still ? 0 : progress*300+nudge*4)
                if t>6 {
                    c.strokePath(tier.color,width:2) { p in p.move(to:CGPoint(x:x-6,y:y-5)); p.addLine(to:CGPoint(x:x+1,y:y)); p.addLine(to:CGPoint(x:x-2,y:y+6)) }
                }
            } else {
                let opened = min((t-7.2)/0.7,1)
                c.ellipse(x-13,y+5,26,10,rgb(0xFFF8EF))
                c.ellipse(x-13-CGFloat(opened*18),y-CGFloat(opened*22),25,12,rgb(0xECA4B9))
                let glow = CGFloat(18+opened*43)
                c.fill(Path(ellipseIn:CGRect(x:x-glow,y:y-glow,width:glow*2,height:glow*2)),
                       with:.radialGradient(Gradient(colors:[tier.color.opacity(0.45),tier.color.opacity(0)]),center:CGPoint(x:x,y:y),startRadius:0,endRadius:glow))
                let count = tier == .secret ? 24 : tier == .epic ? 18 : tier == .rare ? 12 : 7
                for i in 0..<count {
                    let angle=Double(i)*2 * .pi/Double(count)
                    let distance=still ? 25 : 18+opened*Double(24+i%4*6)
                    let point=CGPoint(x:x+CGFloat(cos(angle)*distance),y:y+CGFloat(sin(angle)*distance)-20)
                    GachaMachineArt.star(c,center:point,r:tier>=ItemRarity.epic ? 3.5 : 2.5,color:tier.color)
                }
            }
        }
        // Foreground leaves frame the scene and move more than the distant wall.
        var front = original; front.scaleBy(x:unit,y:unit)
        front.ellipse(-25-CGFloat(pan),280,80,55,rgb(0x89AC9B))
        front.ellipse(320-CGFloat(pan),288,85,40,rgb(0xB7A0BD))
    }
    private static func smooth(_ x: Double) -> Double { x*x*(3-2*x) }
}
