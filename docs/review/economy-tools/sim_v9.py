#!/usr/bin/env python3
"""Mô phỏng kinh tế CozyDay trước và sau phiên 9, cho ba kiểu người chơi.

Chạy:  python3 sim_v9.py catalog.json catalog_v9.json > ../../ECONOMY_V9_VI.tables.md
- catalog.json      : danh mục + luật gacha bản trước phiên 9 (xuất từ commit 87371c9)
- catalog_v9.json   : danh mục + luật gacha hiện tại (xuất bằng dump_catalog.sh)

Luật thưởng được chép lại từ code Swift:
  RewardConfig (việc, tập trung, nhật ký, thở, phiêu lưu), CareConfig (trần 12 XP/6 xu),
  MinigameConfig (≤8 xu/lượt, ≤40 xu/ngày), LevelCurve + LevelMilestones, DailyQuests + WeeklyChest,
  GachaPolicy.pull (bảo đảm, ưu tiên món chưa có trong nhóm, hoàn xu khi trùng, gói 10 bảo đảm Hiếm).
Không tính tài khoản thử nghiệm (phuhotdz) và mã quà t3ster: đó là xu thử, không phải thu nhập khi chơi.
"""
import json, random, statistics, sys, datetime

RUNS = 300          # số quỹ đạo thu nhập mỗi người chơi
GACHA_RUNS = 2000   # số lần Monte Carlo cho gacha
HORIZON = 3650      # 10 năm
START = datetime.date(2026, 11, 2)  # một thứ Hai, để tuần đầu đủ 7 ngày

# ---------------------------------------------------------------- luật thưởng
TASK_XP, TASK_COINS, TASK_PER_DAY = 10, 8, 10
JOURNAL = (5, 5)
BREATH = (3, 3)
ADVENTURE = (5, 10)
MINIGAME_RUN_CAP, MINIGAME_DAY_CAP = 8, 40


def focus_reward(minutes):
    if minutes < 10:
        return 0, 0
    blocks = min(minutes, 120) // 5
    return blocks * 2, blocks * 2


# Đường cấp mới (Progression.swift)
def level_cost(level):
    if level < 10: return 100
    if level < 15: return 150
    if level < 20: return 200
    if level < 25: return 250
    return 300


THRESH = [0, 0]  # THRESH[n] = XP cần để đạt cấp n
for n in range(2, 31):
    THRESH.append(THRESH[-1] + level_cost(n - 1))
assert THRESH[30] == 5400, THRESH[30]


def level_new(xp):
    lv = 1
    while lv < 30 and xp >= THRESH[lv + 1]:
        lv += 1
    return lv


def level_old(xp):
    return xp // 100 + 1


MILESTONES = {12: (40, 1), 15: (50, 1), 18: (60, 1), 21: (70, 2), 24: (80, 2), 27: (90, 2), 30: (150, 3)}
QUEST_COINS = 15
CHEST = (40, 1)


def stable_hash(s):
    h = 1469598103934665603
    for b in s.encode():
        h ^= b
        h = (h * 1099511628211) & 0xFFFFFFFFFFFFFFFF
    return h % 1_000_003


def quests_for(day):
    seed = stable_hash(day.isoformat())
    planner = ("focus", 25) if seed % 3 == 0 else ("tasks", 2)
    relax = [("minigame", 1), ("journal", 1), ("breathing", 1)][(seed // 3) % 3]
    return [planner, ("care", 2), relax]


# ---------------------------------------------------------------- người chơi
# Mỗi người chơi: xác suất mở app trong ngày và hành vi khi mở.
PERSONAS = {
    "light": dict(
        name="Nhẹ nhàng (~10 phút/ngày)", open=0.85,
        tasks=(1, 3), focus=[], focus_done=0.9, journal=0.5, breathing=0.3,
        care_actions=(1, 3), care_coins=(1, 3), care_xp=(2, 5),
        minigame_runs=(0, 1), minigame_mu=4.5),
    "regular": dict(
        name="Đều đặn (~30 phút/ngày)", open=0.92,
        tasks=(3, 6), focus=[25], focus_done=0.9, journal=0.8, breathing=0.5,
        care_actions=(2, 4), care_coins=(3, 6), care_xp=(5, 10),
        minigame_runs=(1, 2), minigame_mu=5.0),
    "gamer": dict(
        name="Mê Sân chơi (~40 phút/ngày, ít việc)", open=0.92,
        tasks=(0, 2), focus=[], focus_done=0.9, journal=0.3, breathing=0.2,
        care_actions=(3, 5), care_coins=(4, 6), care_xp=(8, 12),
        minigame_runs=(6, 9), minigame_mu=6.0),
}


def simulate_days(p, rng, new_rules, catalog):
    """Trả về danh sách (xu, xp, vé) theo từng ngày, đã gồm nhiệm vụ/rương/quà mốc nếu new_rules."""
    out = []
    xp_total = 0
    week_days = 0
    paid_levels = set()
    paid_badges, paid_events = set(), set()
    totals = dict(care=0, focus=0, games=0, adventures=0, days=0)
    event_progress = {}
    for d in range(HORIZON):
        day = START + datetime.timedelta(days=d)
        coins = xp = tickets = 0
        if day.weekday() == 0:
            week_days = 0
        if rng.random() < p["open"]:
            entries = 0
            n_tasks = min(rng.randint(*p["tasks"]), TASK_PER_DAY)
            xp += n_tasks * TASK_XP; coins += n_tasks * TASK_COINS; entries += n_tasks
            focus_min = 0
            for m in p["focus"]:
                if rng.random() < p["focus_done"]:
                    fx, fc = focus_reward(m); xp += fx; coins += fc; entries += 1; focus_min += m
            journal = rng.random() < p["journal"]
            if journal: xp += JOURNAL[0]; coins += JOURNAL[1]; entries += 1
            breath = rng.random() < p["breathing"]
            if breath: xp += BREATH[0]; coins += BREATH[1]; entries += 1
            if entries >= 4: xp += ADVENTURE[0]; coins += ADVENTURE[1]
            totals["adventures"] += int(entries >= 4)
            care = rng.randint(*p["care_actions"])
            coins += min(6, rng.randint(*p["care_coins"])); xp += min(12, rng.randint(*p["care_xp"]))
            runs = rng.randint(*p["minigame_runs"])
            mg = sum(max(1, min(MINIGAME_RUN_CAP, round(rng.gauss(p["minigame_mu"], 1.6)))) for _ in range(runs))
            coins += min(MINIGAME_DAY_CAP, mg)
            if new_rules:
                totals["days"] += 1
                totals["care"] += care
                totals["focus"] += focus_min
                totals["games"] += runs
                for badge in catalog.get("badges", []):
                    # Collection needs a purchasing schedule, excluded from this income-only model.
                    if badge["metric"] != "collection" and totals[badge["metric"]] >= badge["target"] and badge["id"] not in paid_badges:
                        coins += badge["coins"]; paid_badges.add(badge["id"])
                for event in catalog.get("events", []):
                    if event["start"] <= day.isoformat() <= event["end"] and event["id"] not in paid_events:
                        progress = event_progress.setdefault(event["id"], [0, 0, 0])
                        progress[0] += care; progress[1] += focus_min; progress[2] += int(journal)
                        if progress[0] >= 2 and progress[1] >= 10 and progress[2] >= 1:
                            coins += event["coins"]; paid_events.add(event["id"])
                have = {"tasks": n_tasks, "focus": focus_min, "care": care, "minigame": runs,
                        "journal": int(journal), "breathing": int(breath)}
                if all(have[k] >= t for k, t in quests_for(day)):
                    coins += QUEST_COINS
                    week_days += 1
                    if week_days == 4:  # nhận rương ngay khi đủ ngày thứ tư
                        coins += CHEST[0]; tickets += CHEST[1]
        xp_total += xp
        if new_rules:
            lv = level_new(xp_total)
            for m, (c, t) in MILESTONES.items():
                if lv >= m and m not in paid_levels:
                    paid_levels.add(m); coins += c; tickets += t
        out.append((coins, xp, tickets))
    return out


def first_day(series, pred):
    acc = [0, 0, 0]
    for i, (c, x, t) in enumerate(series):
        acc[0] += c; acc[1] += x; acc[2] += t
        if pred(acc):
            return i + 1
    return None


# ---------------------------------------------------------------- gacha
TIERS = ["common", "rare", "epic", "secret"]


class Gacha:
    def __init__(self, cat):
        g = cat["gacha"]
        self.weights = [(list(w.keys())[0], list(w.values())[0]) for w in g["weights"]]
        self.epic_pity, self.secret_pity = g["epicPity"], g["secretPity"]
        self.refund = {list(x.keys())[0]: list(x.values())[0] for x in g["dup"]}
        self.single, self.ten = g["single"], g["ten"]
        self.pool = {t: list(cat["pool"].get(t, [])) for t in TIERS}
        self.size = sum(len(v) for v in self.pool.values())

    def nearest(self, tier):
        i = TIERS.index(tier)
        for t in list(reversed(TIERS[:i + 1])) + TIERS[i + 1:]:
            if self.pool[t]:
                return t

    def roll(self, rng, since_e, since_s, minimum):
        if since_s + 1 >= self.secret_pity:
            return "secret"
        r = rng.randrange(sum(w for _, w in self.weights))
        tier = "common"
        for t, w in self.weights:
            if r < w: tier = t; break
            r -= w
        if since_e + 1 >= self.epic_pity and TIERS.index(tier) < 2:
            tier = "epic"
        return max(tier, minimum, key=TIERS.index)

    def complete(self, rng, ten_pack, tickets_free=0, starting_owned=()):
        """Quay tới khi có đủ cả pool. Trả về (số lượt, xu đỉnh cần có = tổng chi ròng lớn nhất)."""
        target = {item for group in self.pool.values() for item in group}
        owned = set(starting_owned); since_e = since_s = 0; net = 0; peak = 0; pulls = 0; free = tickets_free
        while not target.issubset(owned):
            n = 10 if ten_pack else 1
            if not ten_pack and free > 0:
                free -= 1; price = 0
            else:
                price = self.ten if ten_pack else self.single
            net += price; peak = max(peak, net)
            got_rare = False
            for i in range(n):
                minimum = "rare" if ten_pack and i == n - 1 and not got_rare else "common"
                tier = self.nearest(self.roll(rng, since_e, since_s, minimum))
                group = self.pool[tier]
                fresh = [x for x in group if x not in owned]
                pick = rng.choice(fresh or group)
                if not fresh:
                    net -= self.refund[tier]
                owned.add(pick)
                got_rare = got_rare or TIERS.index(tier) >= 1
                since_e = 0 if TIERS.index(tier) >= 2 else since_e + 1
                since_s = 0 if tier == "secret" else since_s + 1
                pulls += 1
        return pulls, peak


# ---------------------------------------------------------------- bảng
def shop_stats(cat):
    shop = [i for i in cat["items"] if not i["isDefault"] and not i["gachaOnly"]]
    return sum(i["price"] for i in shop), max(i["requiredLevel"] for i in shop), len(shop)


def pct(xs, q):
    xs = sorted(x for x in xs if x is not None)
    if not xs:
        return None
    return xs[min(len(xs) - 1, int(q * len(xs)))]


def fmt(x):
    return "—" if x is None else (f"{x:,}" if isinstance(x, int) else f"{x:,.1f}")


def main():
    old, new = (json.load(open(f)) for f in sys.argv[1:3])
    g_old, g_new = Gacha(old), Gacha(new)
    shop_old, shop_new = shop_stats(old), shop_stats(new)
    rng = random.Random(9)

    print("## Danh mục và gacha\n")
    print("| | Trước phiên 9 | Sau phiên 9 |\n|---|---:|---:|")
    print(f"| Món bán trong cửa hàng | {shop_old[2]} | {shop_new[2]} |")
    print(f"| Tổng giá cửa hàng (xu) | {shop_old[0]:,} | {shop_new[0]:,} |")
    print(f"| Cấp cao nhất cần để mua | {shop_old[1]} | {shop_new[1]} |")
    print(f"| Món trong máy gacha | {g_old.size} | {g_new.size} |")
    for label, g in (("Trước", g_old), ("Sau", g_new)):
        pass
    print("| Món trong máy theo nhóm (Thường/Hiếm/Quý/Bí mật) | " + " / ".join(str(len(g_old.pool[t])) for t in TIERS)
          + " | " + " / ".join(str(len(g_new.pool[t])) for t in TIERS) + " |")
    print("| Tỉ lệ (Thường/Hiếm/Quý/Bí mật) | " + "/".join(str(w) for _, w in g_old.weights)
          + " | " + "/".join(str(w) for _, w in g_new.weights) + " |")
    print(f"| Bảo đảm Quý / Bí mật | lượt {g_old.epic_pity} / {g_old.secret_pity} | lượt {g_new.epic_pity} / {g_new.secret_pity} |")
    print()

    gacha_cost = {}
    for label, g in (("old", g_old), ("new", g_new)):
        for ten in (False, True):
            res = [g.complete(rng, ten) for _ in range(GACHA_RUNS)]
            gacha_cost[(label, ten)] = res
    print("### Gom đủ máy gacha (tài khoản trắng, chỉ dùng xu, 2000 lần thử)\n")
    print("| Cách quay | Trước: lượt (trung vị / P90) | Trước: xu cần | Sau: lượt | Sau: xu cần |\n|---|---:|---:|---:|---:|")
    for ten in (False, True):
        o, n = gacha_cost[("old", ten)], gacha_cost[("new", ten)]
        print(f"| {'Gói 10 (540 xu)' if ten else 'Quay lẻ (60 xu)'} | {pct([x[0] for x in o], .5)} / {pct([x[0] for x in o], .9)}"
              f" | {fmt(pct([x[1] for x in o], .5))} / {fmt(pct([x[1] for x in o], .9))}"
              f" | {pct([x[0] for x in n], .5)} / {pct([x[0] for x in n], .9)}"
              f" | {fmt(pct([x[1] for x in n], .5))} / {fmt(pct([x[1] for x in n], .9))} |")
    print("\nGhi chú: trước phiên 9 máy gacha còn chứa đồ bán trong cửa hàng, nên \"gom đủ máy\" gồm cả những món mua được bằng xu.\n")

    print("## Ba kiểu người chơi\n")
    for key, p in PERSONAS.items():
        rows = {}
        for label, new_rules in (("old", False), ("new", True)):
            series = [simulate_days(p, random.Random(1000 + i), new_rules, new if new_rules else old) for i in range(RUNS)]
            lvl = level_new if new_rules else level_old
            shop_total, shop_lv, _ = shop_new if new_rules else shop_old
            g = g_new if new_rules else g_old
            cat = new if new_rules else old
            shop_ids = [item["id"] for item in cat["items"] if not item["gachaOnly"]]
            gpeaks = [g.complete(random.Random(9000+i), False, starting_owned=shop_ids)[1] for i in range(RUNS)]
            r = {}
            r["coins30"] = statistics.mean(sum(c for c, _, _ in s[:30]) / 30 for s in series)
            r["coins90"] = statistics.mean(sum(c for c, _, _ in s[:90]) / 90 for s in series)
            r["extra30"] = 0
            r["tickets90"] = statistics.mean(sum(t for _, _, t in s[:90]) for s in series)
            for L in (10, 20, 30):
                r[f"lv{L}"] = pct([first_day(s, lambda a, L=L: lvl(a[1]) >= L) for s in series], .5)
            r["shop"] = pct([first_day(s, lambda a: a[0] >= shop_total and lvl(a[1]) >= shop_lv) for s in series], .5)
            # Phá đảo: mua hết cửa hàng rồi quay lẻ tới khi đủ máy; mỗi quỹ đạo ghép một lần Monte Carlo ngẫu nhiên.
            done = []
            for i, s in enumerate(series):
                need = shop_total + gpeaks[i % len(gpeaks)]
                done.append(first_day(s, lambda a: a[0] >= shop_total + max(0, need - shop_total - 60 * a[2]) and lvl(a[1]) >= shop_lv))
            r["all"] = pct(done, .5)
            r["all90"] = pct(done, .9)
            rows[label] = r
        print(f"### {p['name']}\n")
        print("| Chỉ số | Trước phiên 9 | Sau phiên 9 |\n|---|---:|---:|")
        o, n = rows["old"], rows["new"]
        print(f"| Xu trung bình/ngày, 30 ngày đầu | {o['coins30']:.1f} | {n['coins30']:.1f} |")
        print(f"| Xu trung bình/ngày, 90 ngày đầu | {o['coins90']:.1f} | {n['coins90']:.1f} |")
        print(f"| Vé quay nhận được trong 90 ngày | 0 | {n['tickets90']:.1f} |")
        print(f"| Ngày đạt cấp 10 (trung vị) | {fmt(o['lv10'])} | {fmt(n['lv10'])} |")
        print(f"| Ngày đạt cấp 20 | {fmt(o['lv20'])} | {fmt(n['lv20'])} |")
        print(f"| Ngày đạt cấp 30 | {fmt(o['lv30'])} | {fmt(n['lv30'])} |")
        print(f"| Ngày mua hết cửa hàng | {fmt(o['shop'])} | {fmt(n['shop'])} |")
        print(f"| Ngày tích đủ ngân sách cửa hàng + gacha (ước tính), trung vị / P90 | {fmt(o['all'])} / {fmt(o['all90'])} | {fmt(n['all'])} / {fmt(n['all90'])} |")
        print()


if __name__ == "__main__":
    main()
