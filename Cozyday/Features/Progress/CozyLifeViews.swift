import SwiftUI

struct DailyQuestBoard: View {
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(DayClock.self) private var dayClock
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    daySection(dayClock.today)
                    let yesterday = dayClock.today.adding(days: -1, calendar: store.calendar)
                    if !store.dailyQuestsClaimed(on: yesterday), DailyQuests.allDone(store.dailyQuests(on:yesterday),store.activity(on:yesterday)) {
                        daySection(yesterday)
                    }
                    CozyCard {
                        VStack(alignment:.leading,spacing:Spacing.s) {
                            Text("Rương tuần").font(Typography.headline)
                            Text("\(store.weeklyChestDays(weekStart:store.currentWeekStart).count)/4 ngày đã nhận bộ nhiệm vụ")
                            Text("Không cần liên tiếp. Mỗi tuần một rương: 40 xu và 1 vé.").font(Typography.caption)
                            if let week = store.claimableChestWeek {
                                Button("Mở rương tuần \(DateText.short(week))") {
                                    ui.run { _ = try store.claimWeeklyChest(weekStart:week) }
                                }.buttonStyle(PrimaryButtonStyle())
                            }
                            Text("Tuần từ thứ Hai đến Chủ nhật, theo ngày địa phương đã ghi khi nhận nhiệm vụ. Rương còn nhận được trong tuần kế tiếp.")
                                .font(Typography.caption).foregroundStyle(Palette.inkMuted)
                        }
                    }
                    if !store.claimableMilestones.isEmpty {
                        Text("Quà mốc cấp").font(Typography.headline)
                        ForEach(store.claimableMilestones) { milestone in
                            Button("Cấp \(milestone.level): \(milestone.coins) xu + \(milestone.tickets) vé") {
                                ui.run { _ = try store.claimLevelMilestone(milestone.level) }
                            }.buttonStyle(SoftButtonStyle())
                        }
                    }
                    Text("Nghỉ một ngày không mất xu, XP hay huy hiệu. Không cần mua đồ hoặc quay gacha để làm nhiệm vụ.")
                        .font(Typography.caption).foregroundStyle(Palette.inkMuted)
                }.padding(Spacing.l)
            }.cozyBackground().navigationTitle("Ba điều nhỏ").navigationBarTitleDisplayMode(.inline)
                .sheetCloseToolbar { dismiss() }
                .overlay(alignment:.top) { ErrorOverlay() }
        }
    }
    private func daySection(_ day: DayKey) -> some View {
        let activity = store.activity(on:day)
        let quests = store.dailyQuests(on:day)
        return CozyCard {
            VStack(alignment:.leading,spacing:Spacing.m) {
                Text(DateText.full(day,calendar:store.calendar)).font(Typography.headline)
                ForEach(quests) { quest in
                    HStack(alignment:.top) {
                        Image(systemName:activity.isDone(quest) ? "checkmark.circle.fill" : quest.symbol).foregroundStyle(Palette.sage)
                        VStack(alignment:.leading) {
                            Text(quest.title).font(Typography.callout.weight(.semibold))
                            Text(quest.hint).font(Typography.caption).foregroundStyle(Palette.inkMuted)
                        }
                        Spacer()
                        Text("\(activity.progress(quest))/\(quest.target)").font(Typography.caption.monospacedDigit())
                    }.accessibilityElement(children:.combine)
                }
                Button(store.dailyQuestsClaimed(on:day) ? "Đã nhận 15 xu" : "Nhận 15 xu cho cả bộ") {
                    ui.run { _ = try store.claimDailyQuests(day:day) }
                }.buttonStyle(PrimaryButtonStyle(color:Palette.sage))
                    .disabled(store.dailyQuestsClaimed(on:day) || !DailyQuests.allDone(quests,activity))
            }
        }
    }
}

struct CozyLifeView: View {
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:Spacing.l) {
                    if store.hasTestData { TesterModeChip() }
                    Text("\(store.meaningfulDays.count) ngày gắn bó").font(Typography.title)
                    Text("Mỗi ngày có việc hoàn thành, chăm sóc, tập trung hoặc chơi đều là một kỷ niệm. Không cần liên tiếp; các mốc đã nhận luôn còn.")
                        .font(Typography.callout).foregroundStyle(Palette.inkMuted)
                    NavigationLink("Hộp kỷ vật (\(store.keepsakes.count))") { KeepsakeCabinet() }
                        .buttonStyle(SoftButtonStyle())
                    let events = VietnameseEvents.active(at:store.now)
                    if events.isEmpty {
                        Text("Hôm nay không có sự kiện trong lịch. Đồ lễ sẽ trở lại vào những năm sau.")
                            .font(Typography.caption).foregroundStyle(Palette.inkMuted)
                    } else {
                        ForEach(events) { EventCard(event:$0,preview:false) }
                    }
                    Text("Huy hiệu").font(Typography.title)
                    if store.hasTestData {
                        Text("Bộ dữ liệu từng dùng thử nghiệm: chỉ xem tiến độ, không nhận huy hiệu hoặc thưởng sự kiện thật.")
                            .font(Typography.caption).foregroundStyle(Palette.inkMuted)
                    }
                    ForEach(CozyBadge.all) { badge in
                        CozyCard {
                            VStack(alignment:.leading,spacing:Spacing.s) {
                                Label(badge.title,systemImage:store.ledgerKeys.contains(LedgerKeys.badge(badge.id)) ? "seal.fill" : "seal")
                                    .font(Typography.headline)
                                Text(badge.condition).font(Typography.callout)
                                ProgressView(value:Double(min(badge.target,store.badgeProgress(badge))),total:Double(badge.target))
                                Text("\(min(badge.target,store.badgeProgress(badge)))/\(badge.target)").font(Typography.caption)
                                Button(store.ledgerKeys.contains(LedgerKeys.badge(badge.id)) ? "Đã nhận" : "Nhận huy hiệu và \(badge.coins) xu") {
                                    ui.run { try store.claimBadge(badge) }
                                }.disabled(store.hasTestData || store.badgeProgress(badge)<badge.target || store.ledgerKeys.contains(LedgerKeys.badge(badge.id)))
                            }
                        }
                    }
                }.padding(Spacing.l)
            }.cozyBackground().navigationTitle("Cùng bạn nhỏ").navigationBarTitleDisplayMode(.inline)
                .sheetCloseToolbar { dismiss() }.overlay(alignment:.top) { ErrorOverlay() }
        }
    }
}

struct EventCard: View {
    let event: CozyEvent
    let preview: Bool
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    var body: some View {
        CozyCard {
            VStack(alignment:.leading,spacing:Spacing.s) {
                Label(event.title,systemImage:"gift").font(Typography.headline)
                Text("\(event.start.string) – \(event.end.string) · giờ Việt Nam").font(Typography.caption)
                if preview { Text("Xem thử · không ghi tiến độ hoặc phát thưởng").foregroundStyle(Palette.peachInk) }
                KeepsakeArt(artID:event.artID).frame(height:100)
                ForEach(event.quests) { quest in
                    Text("\(quest.title): \(preview ? 0 : store.eventActivity(event).progress(quest))/\(quest.target)")
                        .font(Typography.callout)
                }
                Text("Quà: \(event.keepsakeTitle) để trưng bày và \(event.coins) xu. Chủ đề có thể quay lại năm sau.")
                    .font(Typography.caption)
                Button(store.ledgerKeys.contains(LedgerKeys.event(event.id,"complete")) ? "Đã nhận quà" : "Nhận quà lễ") {
                    ui.run { try store.claimEvent(event) }
                }.buttonStyle(SoftButtonStyle())
                    .disabled(preview || store.hasTestData || !VietnameseEvents.claimable(event,now:store.now,activity:store.eventActivity(event),keys:store.ledgerKeys))
            }
        }
    }
}

struct KeepsakeCabinet: View {
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:Spacing.l) {
                if store.keepsakes.isEmpty { Text("Nghe bạn nhỏ kể chuyến đi để mang về bưu thiếp đầu tiên.") }
                ForEach(store.keepsakes.reversed()) { memory in
                    CozyCard {
                        VStack(alignment:.leading,spacing:Spacing.s) {
                            KeepsakeArt(artID:memory.artID).frame(height:120)
                            Text(memory.title).font(Typography.headline)
                            Text("\(memory.petName) · \(memory.day.string)").font(Typography.caption)
                            Text(memory.story).font(Typography.callout)
                            Menu(memory.placedRoom.flatMap(RoomKind.init(rawValue:))?.name ?? "Đặt trong phòng") {
                                ForEach(RoomKind.allCases) { room in
                                    Button(room.name) { ui.run { try store.placeKeepsake(memory.id,in:room) } }
                                        .disabled(!room.isUnlocked(level:store.wallet.level))
                                }
                                Button("Cất vào hộp") { ui.run { try store.placeKeepsake(memory.id,in:nil) } }
                            }.frame(minHeight:HitTarget.min)
                        }
                    }
                }
            }.padding(Spacing.l)
        }.cozyBackground().navigationTitle("Hộp kỷ vật").overlay(alignment:.top) { ErrorOverlay() }
    }
}

/// Original display objects; reused for holiday gifts and travel postcards.
struct KeepsakeArt: View {
    let artID: String
    var body: some View {
        Canvas { context,size in
            let scale=min(size.width,size.height)/100
            var c=context; c.translateBy(x:(size.width-100*scale)/2,y:0); c.scaleBy(x:scale,y:scale)
            c.ellipse(10,87,80,8,.black.opacity(0.12)); c.rect(13,82,74,6,rgb(0xBC9785),radius:3)
            switch artID {
            case "envelope":
                c.rect(28,20,44,62,rgb(0xC56F66),radius:6)
                c.polygon([CGPoint(x:29,y:23),CGPoint(x:50,y:43),CGPoint(x:71,y:23)],rgb(0xE9987C))
                for i in 0..<5 { let a=Double(i)*2 * .pi/5; c.circle(50+CGFloat(cos(a)*8),58+CGFloat(sin(a)*8),5,rgb(0xF5D484)) }; c.circle(50,58,3,rgb(0xBD8450))
            case "lantern":
                c.strokePath(rgb(0xAA7A63),width:2) { p in p.move(to:CGPoint(x:50,y:8)); p.addLine(to:CGPoint(x:50,y:26)) }
                c.ellipse(23,24,54,48,rgb(0xE9A36D)); c.ellipse(34,25,32,46,rgb(0xF9D58D))
                c.rect(35,21,30,5,rgb(0xBC7066),radius:2); c.rect(35,69,30,5,rgb(0xBC7066),radius:2)
                for x: CGFloat in [45,50,55] { c.rect(x,74,2,9,rgb(0xBC7066)) }
            case "flower":
                c.rect(36,59,28,23,rgb(0xABC9D4),radius:8)
                for i in 0..<3 {
                    let x=CGFloat(30+i*20),y=CGFloat(i==1 ? 28 : 40)
                    c.strokePath(rgb(0x82A385),width:2) { p in p.move(to:CGPoint(x:50,y:65)); p.addLine(to:CGPoint(x:x,y:y)) }
                    for j in 0..<5 { let a=Double(j)*2 * .pi/5; c.circle(x+CGFloat(cos(a)*7),y+CGFloat(sin(a)*7),5,rgb(0xDC9EA7)) }; c.circle(x,y,3,rgb(0xF6D88D))
                }
            default:
                c.rect(16,25,68,51,rgb(0xD1A774),radius:4); c.rect(21,30,58,40,rgb(0xFFF3DB),radius:2)
                c.circle(65,41,6,rgb(0xEAC578))
                c.polygon([CGPoint(x:25,y:65),CGPoint(x:43,y:44),CGPoint(x:61,y:65)],rgb(0xA6C6B1))
                c.polygon([CGPoint(x:45,y:65),CGPoint(x:60,y:51),CGPoint(x:75,y:65)],rgb(0xC3B3D7))
            }
        }.accessibilityLabel("Kỷ vật trưng bày")
    }
}
