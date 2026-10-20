"""Mô phỏng kinh tế CozyDay theo ngày cho 10 người chơi giả lập.

Số liệu đọc từ catalog.json (xuất thẳng từ code Swift Core bằng run_dump.sh).
Luật thưởng/chăm sóc/gacha chép đúng từ RewardConfig, Adventure, CareConfig/CarePolicy,
MinigameConfig, GachaConfig/GachaPolicy.

Chạy: python3 -I sim.py <thư mục chứa catalog.json> [số lần MC]
"""
import json, random, statistics, sys, math, bisect
from collections import Counter

S = sys.argv[1]
MC = int(sys.argv[2]) if len(sys.argv) > 2 else 2000
D = json.load(open(f"{S}/catalog.json"))
ITEMS = D["items"]
BYID = {i["id"]: i for i in ITEMS}
NONDEF = [i for i in ITEMS if not i["isDefault"]]
SHOP = [i for i in NONDEF if not i["gachaOnly"]]
SHOP_PAID = [i for i in SHOP if i["price"] > 0]
SHOP_TOTAL = sum(i["price"] for i in SHOP)
SHOP_MAXLV = max(i["requiredLevel"] for i in SHOP)
POOL = {k: list(v) for k, v in D["pool"].items()}
TIERS = ["common", "rare", "epic", "secret"]
TORD = {t: n for n, t in enumerate(TIERS)}
EXCL = [i["id"] for i in NONDEF if i["gachaOnly"]]
POOL_SHOP = [x for t in TIERS for x in POOL[t] if not BYID[x]["gachaOnly"]]
POOL_SHOP_VALUE = sum(BYID[x]["price"] for x in POOL_SHOP)

# ---------- Luật thưởng (RewardConfig) ----------
TASK_XP, TASK_C, TASK_CAP = 10, 8, 10
JOUR = (5, 5); BREATH = (3, 3); ADV = (5, 10)
def focus_reward(m):
    if m < 10: return (0, 0)
    b = min(m, 120) // 5
    return (2 * b, 2 * b)
MG_CAP, MG_RUN = 40, 8
# Móc cho kịch bản đề xuất (proposal.py); None = luật hiện tại.
FOCUS_DAY_CAP_MIN = None      # trần phút tập trung có thưởng mỗi ngày
MG_CAP_FN = None              # hàm(số việc xong hôm nay) -> trần xu minigame
FOCUS_FN = None               # hàm(số phút phiên, số phút có thưởng đã dùng hôm nay) -> (xp, xu)
DAILY_BONUS_FN = None         # hàm(n_tasks, n_self, day_index, state) -> (xp, xu)
# ---------- Chăm sóc (CareConfig) ----------
RATE = {"full": 3.0, "clean": 2.0, "happy": 2.5}
FLOOR, NEED, MAXDECAY = 20.0, 35.0, 24.0
CARE_REW = {"feed": (2, 1), "clean": (3, 2), "cuddle": (2, 1)}
CARE_XP_CAP, CARE_C_CAP, CARE_PER_KIND = 12, 6, 2
APPLE = (3, 18, 0)  # giá, no, vui
# ---------- Gacha ----------
SINGLE, TEN = 60, 540
WEIGHTS = [("common", 60), ("rare", 28), ("epic", 10), ("secret", 2)]
EPIC_PITY, SECRET_PITY = 10, 60
DUP = {"common": 15, "rare": 25, "epic": 50, "secret": 120}

def level(xp): return max(0, xp) // 100 + 1


class Persona:
    def __init__(self, key, name, desc, **kw):
        self.key, self.name, self.desc = key, name, desc
        self.p_open = kw.get("p_open", 0.9)          # xác suất mở app trong ngày thường
        self.weekend = kw.get("weekend")             # dict ghi đè cho T7/CN
        self.tasks = kw.get("tasks", (0, 0))         # (min,max) việc xong / ngày mở app
        self.focus = kw.get("focus", [])             # danh sách số phút mỗi phiên
        self.focus_ok = kw.get("focus_ok", 0.92)     # xác suất chạy hết giờ
        self.journal = kw.get("journal", 0.0)
        self.breath = kw.get("breath", 0.0)
        self.mg_runs = kw.get("mg_runs", (0, 0))
        self.mg_mu = kw.get("mg_mu", 5.0)
        self.checkins = kw.get("checkins", [20])     # giờ mở app trong ngày (chăm sóc)
        self.buys_food = kw.get("buys_food", False)
        self.cuddle_always = kw.get("cuddle_always", False)

    def day_plan(self, dow, rng):
        cfg = dict(p_open=self.p_open, tasks=self.tasks, focus=self.focus, journal=self.journal,
                   breath=self.breath, mg_runs=self.mg_runs, checkins=self.checkins)
        if self.weekend and dow >= 5:
            cfg.update(self.weekend)
        return cfg


P = [
    Persona("P1", "Rất lười", "Mở app ~3 ngày/tuần, 2 việc/ngày, không gì khác; chăm 1 lần khi mở",
            p_open=3 / 7, tasks=(1, 3), checkins=[21]),
    Persona("P2", "Lười", "~6 ngày/tuần, 3 việc, không tập trung; chăm 1 lần/ngày",
            p_open=0.85, tasks=(2, 4), checkins=[21], journal=0.1),
    Persona("P3", "Nhẹ nhàng", "5 việc + nhật ký; chăm 2 lần/ngày; đủ năng lượng phiêu lưu",
            p_open=0.9, tasks=(4, 6), journal=0.9, checkins=[8, 21]),
    Persona("P4", "Cân bằng", "5 việc + 1 pomodoro 25' + nhật ký + bài thở",
            p_open=0.9, tasks=(4, 6), focus=[25], journal=0.85, breath=0.7, checkins=[8, 21]),
    Persona("P5", "Học sinh", "6 việc + 2 pomodoro 25' + minigame 1–2 lượt, nhật ký 30%",
            p_open=0.9, tasks=(5, 7), focus=[25, 25], journal=0.3, mg_runs=(1, 2), mg_mu=5, checkins=[7, 17, 22]),
    Persona("P6", "Chăm chỉ", "8 việc + 3 pomodoro 25' + nhật ký + thở + minigame đạt trần, mua táo cho ăn",
            p_open=0.95, tasks=(7, 9), focus=[25, 25, 25], journal=0.95, breath=0.9, mg_runs=(7, 9), mg_mu=6,
            checkins=[7, 12, 18, 22], buys_food=True),
    Persona("P7", "Đi làm bận", "Ngày thường 3 việc (80% mở app); cuối tuần 7 việc + 2×50' + nhật ký + thở + 3 lượt minigame",
            p_open=0.8, tasks=(2, 4), journal=0.4, checkins=[22],
            weekend=dict(p_open=0.95, tasks=(6, 8), focus=[50, 50], journal=0.9, breath=0.9, mg_runs=(3, 4),
                         checkins=[9, 15, 22])),
    Persona("P8", "Hay bỏ dở", "5 việc, 3 phiên 25' nhưng 50% kết thúc sớm, nhật ký/thở 50%",
            p_open=0.85, tasks=(3, 6), focus=[25, 25, 25], journal=0.5, breath=0.5, checkins=[9, 21]),
    Persona("P9", "Cày tối đa hợp lệ", "10 việc + 4 giờ tập trung (2×120') + mọi thứ đạt trần, mỗi ngày",
            p_open=1.0, tasks=(10, 10), focus=[120, 120], focus_ok=1.0, journal=1, breath=1, mg_runs=(9, 9), mg_mu=7,
            checkins=[6, 9, 12, 15, 18, 21, 23]),
    Persona("P10", "Chỉ minigame + chăm", "Không việc/tập trung; 5–7 lượt minigame, chăm 4 lần/ngày, mua táo",
            p_open=0.9, mg_runs=(5, 7), mg_mu=6, checkins=[8, 13, 18, 22], buys_food=True),
]
P[7].focus_ok = 0.5


def simulate(persona, days, seed):
    """Trả về danh sách (xu_ròng_tích_lũy, xp_tích_lũy, chi_đồ_ăn_tích_lũy) cuối mỗi ngày (ngày 1..days)."""
    rng = random.Random(seed)
    needs = {"full": 80.0, "clean": 85.0, "happy": 80.0}
    apples = 3  # gói chào mừng: 3 táo + 1 cơm nắm (cơm nắm coi như 1 táo cho đơn giản)
    rice = 1
    coins = xp = food_spent = 0
    out = []
    t_last = 0.0
    breakdown = Counter()
    qstate = {}
    for d in range(days):
        dow = d % 7
        cfg = persona.day_plan(dow, rng)
        opened = rng.random() < cfg["p_open"]
        counted = 0
        if opened:
            n = min(TASK_CAP, rng.randint(*cfg["tasks"])) if cfg["tasks"][1] else 0
            xp += n * TASK_XP; coins += n * TASK_C; counted += n
            breakdown["task"] += n * TASK_C
            fmin = 0; n_self = 0
            for m in cfg["focus"]:
                if rng.random() < persona.focus_ok:
                    if FOCUS_FN:
                        fx, fc = FOCUS_FN(m, fmin); fmin += min(m, 120)
                    else:
                        mm = m if FOCUS_DAY_CAP_MIN is None else max(0, min(m, FOCUS_DAY_CAP_MIN - fmin))
                        fmin += mm
                        fx, fc = focus_reward(mm)
                    xp += fx; coins += fc; counted += 1; breakdown["focus"] += fc; n_self += 1
            if rng.random() < cfg["journal"]:
                xp += JOUR[0]; coins += JOUR[1]; counted += 1; breakdown["journal"] += JOUR[1]; n_self += 1
            if rng.random() < cfg["breath"]:
                xp += BREATH[0]; coins += BREATH[1]; counted += 1; breakdown["breath"] += BREATH[1]; n_self += 1
            if counted >= 4:
                xp += ADV[0]; coins += ADV[1]; breakdown["adventure"] += ADV[1]
            if DAILY_BONUS_FN:
                bx, bc = DAILY_BONUS_FN(n, n_self, d, qstate)
                xp += bx; coins += bc; breakdown["quest"] += bc
            runs = rng.randint(*cfg["mg_runs"]) if cfg["mg_runs"][1] else 0
            got = 0
            cap = MG_CAP if MG_CAP_FN is None else MG_CAP_FN(n)
            for _ in range(runs):
                c = max(1, min(MG_RUN, round(rng.gauss(persona.mg_mu, 1.6))))
                c = min(c, cap - got); got += c
            coins += got; breakdown["minigame"] += got
            # chăm sóc tại các giờ mở app
            kind_n = Counter(); cxp = cc = 0
            for h in cfg["checkins"]:
                t = d * 24 + h + rng.uniform(-0.7, 0.7)
                hours = min(max(0, t - t_last), MAXDECAY)
                for k in needs:
                    if needs[k] > FLOOR:
                        needs[k] = max(FLOOR, needs[k] - RATE[k] * hours)
                t_last = t
                def reward(kind, before):
                    nonlocal cxp, cc
                    if before >= NEED or kind_n[kind] >= CARE_PER_KIND: return
                    bx, bc = CARE_REW[kind]
                    x = min(bx, CARE_XP_CAP - cxp); c = min(bc, CARE_C_CAP - cc)
                    if x <= 0 and c <= 0: return
                    kind_n[kind] += 1; cxp += x; cc += c
                if needs["clean"] < 95:
                    if needs["clean"] < NEED or persona.cuddle_always:
                        reward("clean", needs["clean"]); needs["clean"] = 100.0
                if needs["happy"] < NEED or persona.cuddle_always:
                    reward("cuddle", needs["happy"]); needs["happy"] = min(100.0, needs["happy"] + 35)
                if needs["full"] < NEED:
                    if persona.buys_food:
                        # cho ăn tới khi qua ngưỡng ổn (mua táo nếu hết)
                        first = True
                        while needs["full"] < 70:
                            if rice: rice -= 1; gain = 35
                            elif apples: apples -= 1; gain = 18
                            elif coins >= APPLE[0]:
                                coins -= APPLE[0]; food_spent += APPLE[0]; gain = 18
                            else: break
                            if first: reward("feed", needs["full"]); first = False
                            needs["full"] = min(100.0, needs["full"] + gain)
                        if needs["full"] < NEED: needs["full"] = 55.0
                    else:
                        needs["full"] = max(needs["full"], 55.0)  # bữa cơ bản miễn phí
            xp += cxp; coins += cc; breakdown["care"] += cc
        out.append((coins, xp, food_spent))
    return out, breakdown


# ---------- Gacha (chép đúng GachaPolicy.pull) ----------
def roll_tier(since_epic, since_secret, minimum, rng):
    if since_secret + 1 >= SECRET_PITY: return "secret"
    r = rng.randrange(100); tier = "common"
    for t, w in WEIGHTS:
        if r < w: tier = t; break
        r -= w
    if since_epic + 1 >= EPIC_PITY and TORD[tier] < TORD["epic"]: tier = "epic"
    return tier if TORD[tier] >= TORD[minimum] else minimum


class Gacha:
    def __init__(self, owned, rng):
        self.owned = set(owned); self.rng = rng; self.se = self.ss = 0

    def pull(self, count):
        price = TEN if count >= 10 else SINGLE * count
        res = []; refund_total = 0; got_rare = False; gained = []
        for i in range(count):
            gr = count >= 10 and i == count - 1 and not got_rare
            tier = roll_tier(self.se, self.ss, "rare" if gr else "common", self.rng)
            group = POOL[tier]
            fresh = [x for x in group if x not in self.owned]
            pick = fresh if fresh else group
            item = pick[self.rng.randrange(len(pick))]
            if not fresh: refund_total += DUP[tier]
            else: gained.append(item)
            self.owned.add(item)
            if TORD[tier] >= TORD["rare"]: got_rare = True
            self.se = 0 if TORD[tier] >= TORD["epic"] else self.se + 1
            self.ss = 0 if tier == "secret" else self.ss + 1
        return price, refund_total, gained


def gacha_run(strategy, ten, rng, target="excl"):
    """Trả về (đỉnh xu cần, xu ròng, số lượt, giá trị shop nhận được).
    strategy 'gacha_first': chưa có gì, quay tới khi đủ mục tiêu.
    strategy 'shop_first': đã mua hết đồ cửa hàng (gồm 110 món trong pool), chỉ còn 14 món độc quyền.
    target 'excl' = 14 món chỉ-gacha; 'pool' = cả 124 món trong máy."""
    owned = set(POOL_SHOP) if strategy == "shop_first" else set(["hat.sprout"])  # món 0 xu nhận miễn phí
    g = Gacha(owned, rng)
    goal = set(EXCL) if target == "excl" else set(x for t in TIERS for x in POOL[t])
    spent = refunds = peak = 0; pulls = 0; value = 0
    while not goal <= g.owned:
        n = 10 if ten else 1
        price, ref, gained = g.pull(n)
        spent += price
        peak = max(peak, spent - refunds)
        refunds += ref; pulls += n
        value += sum(BYID[x]["price"] for x in gained if not BYID[x]["gachaOnly"])
    return peak, spent - refunds, pulls, value


def ev_first_pull():
    """Giá trị shop kỳ vọng của 1 lượt khi chưa có gì."""
    ev = 0
    for t, w in WEIGHTS:
        grp = POOL[t]
        ev += w / 100 * statistics.mean(BYID[x]["price"] for x in grp)
    return ev


def day_reach(curve_coins, curve_xp, need_coins, need_level=1):
    for d, (c, x) in enumerate(zip(curve_coins, curve_xp)):
        if c >= need_coins and level(x) >= need_level:
            return d + 1
    # quá chân trời mô phỏng: ngoại suy tuyến tính theo 365 ngày cuối (kết quả > chân trời là số ngoại suy)
    n = len(curve_coins); slope = (curve_coins[-1] - curve_coins[-366]) / 365
    if slope <= 0 or level(curve_xp[-1]) < need_level: return None
    return n + (need_coins - curve_coins[-1]) / slope


def pct(xs, q):
    xs = sorted(xs); k = (len(xs) - 1) * q; f = math.floor(k); c = math.ceil(k)
    return xs[f] if f == c else xs[f] + (xs[c] - xs[f]) * (k - f)


def early_purchases(persona, seed, policy, days=14):
    """Mua đồ cửa hàng trong 'days' ngày đầu. policy: 'cheap' (rẻ nhất trước) hoặc 'random' (chọn ngẫu nhiên một món
    đã mở khóa rồi để dành). Trả về (ngày mua món có giá đầu tiên, số món có giá mua được trong 14 ngày)."""
    curve, _ = simulate(persona, days, seed)
    rng = random.Random(seed * 7 + 1)
    owned = set(); spent = 0; first = None; target = None
    for d, (c, x, _) in enumerate(curve):
        lv = level(x)
        while True:
            avail = [i for i in SHOP_PAID if i["id"] not in owned and i["requiredLevel"] <= lv]
            if not avail: break
            if policy == "cheap":
                it = min(avail, key=lambda i: i["price"])
            else:
                if target is None or target["id"] in owned or target["requiredLevel"] > lv:
                    target = rng.choice(avail)
                it = target
            if c - spent >= it["price"]:
                spent += it["price"]; owned.add(it["id"]); first = first or d + 1; target = None
            else:
                break
    return first, len(owned)


OUT_NAME = "sim_results.json"


def main():
    out = {}
    HORIZON = 3650
    TRAJ = 60
    print(f"Catalog: {len(ITEMS)} món, mặc định {len(ITEMS)-len(NONDEF)}, cửa hàng {len(SHOP)} (có giá {len(SHOP_PAID)}), "
          f"tổng giá cửa hàng {SHOP_TOTAL}, cấp cao nhất {SHOP_MAXLV}; chỉ-gacha {len(EXCL)}; pool {sum(len(v) for v in POOL.values())}"
          f" (trong đó {len(POOL_SHOP)} món bán ở cửa hàng, tổng giá {POOL_SHOP_VALUE})")
    print("EV giá trị cửa hàng của 1 lượt đầu tiên:", round(ev_first_pull(), 1), "xu / 60 xu")

    # MC chi phí gacha (không phụ thuộc người chơi)
    rng = random.Random(12345)
    gacha = {}
    for strat in ["gacha_first", "shop_first"]:
        for ten in [False, True]:
            for target in (["excl", "pool"] if strat == "gacha_first" else ["excl"]):
                runs = [gacha_run(strat, ten, rng, target) for _ in range(MC)]
                gacha[(strat, ten, target)] = runs
                peaks = [r[0] for r in runs]; nets = [r[1] for r in runs]; pulls = [r[2] for r in runs]
                vals = [r[3] for r in runs]
                print(f"gacha {strat:11s} ten={ten!s:5s} target={target:4s}: lượt trung vị {pct(pulls,.5):.0f} P90 {pct(pulls,.9):.0f}; "
                      f"xu ròng trung vị {pct(nets,.5):.0f} P90 {pct(nets,.9):.0f}; giá trị shop nhận {pct(vals,.5):.0f}")
    # Kỳ vọng xu cho mỗi món Bí mật
    out["gacha"] = {f"{k[0]}|{k[1]}|{k[2]}": {"pulls_med": pct([r[2] for r in v], .5), "pulls_p90": pct([r[2] for r in v], .9),
                                               "net_med": pct([r[1] for r in v], .5), "net_p90": pct([r[1] for r in v], .9),
                                               "value_med": pct([r[3] for r in v], .5)} for k, v in gacha.items()}

    rows = []
    for p in P:
        trajs = [simulate(p, HORIZON, 1000 + s) for s in range(TRAJ)]
        curves_c = [[c for c, x, f in t[0]] for t in trajs]
        curves_x = [[x for c, x, f in t[0]] for t in trajs]
        bd = Counter()
        for t in trajs: bd.update(t[1])
        cpd = statistics.mean(cc[364] for cc in curves_c) / 365
        food = statistics.mean(t[0][364][2] for t in trajs) / 365
        gross = cpd + food
        xpd = statistics.mean(cx[364] for cx in curves_x) / 365
        def med_day(fn):
            ds = [fn(cc, cx) for cc, cx in zip(curves_c, curves_x)]
            ds = [d if d is not None else 99999 for d in ds]
            return statistics.median(ds)
        lv = {L: med_day(lambda cc, cx, L=L: day_reach([1e18] * len(cx), cx, 0, L)) for L in (5, 8, 10, 20)}
        shop_day = med_day(lambda cc, cx: day_reach(cc, cx, SHOP_TOTAL, SHOP_MAXLV))
        prng = random.Random(77)
        res = {}
        for key, ten in [("single", False), ("ten", True)]:
            # (a) chỉ quay gacha từ ngày 1 tới khi đủ 14 món độc quyền
            ex = []
            for r in gacha[("gacha_first", ten, "excl")]:
                k = prng.randrange(TRAJ); ex.append(day_reach(curves_c[k], curves_x[k], r[0]) or 99999)
            # (a2) quay đủ cả 124 món trong máy chỉ bằng gacha
            pl = []
            for r in gacha[("gacha_first", ten, "pool")]:
                k = prng.randrange(TRAJ); pl.append(day_reach(curves_c[k], curves_x[k], r[0]) or 99999)
            # (b) phá đảo: S1 mua hết cửa hàng rồi quay; S2 quay trước rồi mua phần còn lại
            s1 = []; s2 = []
            for r in gacha[("shop_first", ten, "excl")]:
                k = prng.randrange(TRAJ)
                s1.append(day_reach(curves_c[k], curves_x[k], SHOP_TOTAL + r[0], SHOP_MAXLV) or 99999)
            for r in gacha[("gacha_first", ten, "excl")]:
                k = prng.randrange(TRAJ)
                need = max(r[0], r[1] + SHOP_TOTAL - r[3])
                s2.append(day_reach(curves_c[k], curves_x[k], need, SHOP_MAXLV) or 99999)
            res[key] = dict(excl=(pct(ex, .5), pct(ex, .9)), pool=(pct(pl, .5), pct(pl, .9)),
                            s1=(pct(s1, .5), pct(s1, .9)), s2=(pct(s2, .5), pct(s2, .9)))
        ep = [early_purchases(p, 500 + s, "cheap") for s in range(200)]
        er = [early_purchases(p, 900 + s, "random") for s in range(200)]
        row = dict(key=p.key, name=p.name, desc=p.desc, coins_day=round(cpd, 1), gross_day=round(gross, 1),
                   food_day=round(food, 2), xp_day=round(xpd, 1), lv=lv, shop_day=shop_day, gacha=res,
                   first_cheap=statistics.median([e[0] or 99 for e in ep]), n14_cheap=statistics.median([e[1] for e in ep]),
                   first_rand=statistics.median([e[0] or 99 for e in er]), n14_rand=statistics.median([e[1] for e in er]),
                   breakdown={k: round(v / TRAJ / HORIZON, 1) for k, v in bd.items()})
        rows.append(row)
        print(json.dumps(row, ensure_ascii=False))
    out["rows"] = rows
    out["meta"] = dict(SHOP_TOTAL=SHOP_TOTAL, SHOP_N=len(SHOP), SHOP_PAID=len(SHOP_PAID), EXCL=EXCL, MC=MC, TRAJ=TRAJ,
                       POOL_SHOP_VALUE=POOL_SHOP_VALUE, ev_first=ev_first_pull())
    json.dump(out, open(f"{S}/{OUT_NAME}", "w"), ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
