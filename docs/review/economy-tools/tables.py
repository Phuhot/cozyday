"""Sinh các bảng Markdown cho báo cáo từ catalog.json + sim_results.json, và vài phân tích phụ (EV gacha, lỗ hổng).
Chạy: python3 -I tables.py <thư mục>"""
import json, sys, random, statistics
from collections import Counter, defaultdict
S = sys.argv[1]
sys.argv = [sys.argv[0], S, "1"]
import importlib.util
spec = importlib.util.spec_from_file_location("sim", f"{S}/sim.py"); sim = importlib.util.module_from_spec(spec); spec.loader.exec_module(sim)
D = json.load(open(f"{S}/catalog.json")); R = json.load(open(f"{S}/sim_results.json"))
items = D["items"]; byid = {i["id"]: i for i in items}
nd = [i for i in items if not i["isDefault"]]
out = []
P = out.append
ROOMN = {"study": "Phòng học", "bedroom": "Phòng ngủ", "kitchen": "Bếp & bàn ăn", "bath": "Phòng tắm", "garden": "Khu vườn"}
ROOMLV = {r["id"]: r["requiredLevel"] for r in D["rooms"]}

P("### Bảng 1a. Đồ phòng (bán trong cửa hàng)\n")
P("| Phòng (mở ở cấp) | Số món (không tính mặc định) | Miễn phí | Biến thể màu | Tổng giá đồ | Sàn riêng: số món / tổng giá | Tổng cả phòng | Cấp cao nhất cần |")
P("|---|---:|---:|---:|---:|---:|---:|---:|")
tot = Counter()
for r in ROOMN:
    xs = [i for i in nd if i["room"] == r and not i["isFloor"]]
    fl = [i for i in nd if i["room"] == r and i["isFloor"]]
    a = sum(i["price"] for i in xs); b = sum(i["price"] for i in fl)
    P(f"| {ROOMN[r]} (cấp {ROOMLV[r]}) | {len(xs)} | {sum(1 for i in xs if i['price']==0)} | {sum(1 for i in xs if i['variantOf'])} | {a:,} | {len(fl)} / {b:,} | {a+b:,} | {max(i['requiredLevel'] for i in xs+fl)} |")
    tot.update(n=len(xs) + len(fl), s=a + b)
P(f"| **Cộng đồ phòng** | | | | | | **{tot['n']} món / {tot['s']:,} xu** | |")

P("\n### Bảng 1b. Thú cưng\n")
P("| Lớp | Cửa hàng: số món / tổng giá / cấp cao nhất | Chỉ có trong gacha (Quý / Bí mật) | Có trong máy gacha? |")
P("|---|---:|---:|---|")
SL = {"species": "Loài (hình dạng)", "fur": "Màu lông", "hat": "Mũ", "glasses": "Kính", "neck": "Cổ", "outfit": "Áo", "back": "Lưng / phụ kiện"}
pet_tot = Counter()
for s, lab in SL.items():
    xs = [i for i in nd if i["slot"] == s and not i["gachaOnly"]]
    go = [i for i in nd if i["slot"] == s and i["gachaOnly"]]
    c = Counter(i["rarity"] for i in go)
    P(f"| {lab} | {len(xs)} / {sum(i['price'] for i in xs):,} / {max(i['requiredLevel'] for i in xs)} | {c['epic']} / {c['secret']} | {'không' if s=='fur' else 'có'} |")
    pet_tot.update(n=len(xs), s=sum(i["price"] for i in xs))
P(f"| **Cộng thú cưng** | **{pet_tot['n']} món / {pet_tot['s']:,} xu** | **7 / 7** | |")

shop = [i for i in nd if not i["gachaOnly"]]
P(f"\n**Tổng cửa hàng:** {len(shop)} món ({sum(1 for i in shop if i['price']>0)} có giá, {sum(1 for i in shop if i['price']==0)} miễn phí), "
  f"**{sum(i['price'] for i in shop):,} xu**; {sum(1 for i in shop if i['variantOf'])} món là biến thể màu "
  f"({sum(i['price'] for i in shop if i['variantOf']):,} xu = {100*sum(i['price'] for i in shop if i['variantOf'])/sum(i['price'] for i in shop):.0f}% tổng giá). "
  f"Cộng 14 món chỉ-gacha → bộ sưu tập đầy đủ {len(nd)} món (+7 món mặc định = {len(items)}).")
lv = Counter(i["requiredLevel"] for i in shop)
P("\n**Phân bố cấp mở khóa (đồ cửa hàng):** " + ", ".join(f"cấp {k}: {v}" for k, v in sorted(lv.items())) +
  ". Cấp cao nhất cần để mua hết: **8** (700 XP). Phòng: học/ngủ cấp 1, bếp 2, tắm 3, vườn 4.")
ph = Counter()
for i in shop:
    p = i["price"]
    ph["0" if p == 0 else "1–29" if p < 30 else "30–49" if p < 50 else "50–89" if p < 90 else "90–129" if p < 130 else "130–160"] += 1
P("\n**Phân bố giá:** " + ", ".join(f"{k} xu: {ph[k]}" for k in ["0", "1–29", "30–49", "50–89", "90–129", "130–160"]) +
  f". Trung bình món có giá: {statistics.mean(i['price'] for i in shop if i['price']>0):.1f} xu; đắt nhất 160 xu (Tủ lạnh mèo).")

P("\n### Bảng 1c. Máy gacha (pool = mọi món thú cưng không mặc định trừ màu lông)\n")
P("| Bậc (trọng số) | Số món | Trong đó bán ở cửa hàng (tổng giá) | Chỉ-gacha | Hoàn xu khi trùng |")
P("|---|---:|---:|---:|---:|")
W = {"common": 60, "rare": 28, "epic": 10, "secret": 2}
LAB = {"common": "Thường", "rare": "Hiếm", "epic": "Quý", "secret": "Bí mật"}
DUP = {"common": 15, "rare": 25, "epic": 50, "secret": 120}
for t in ["common", "rare", "epic", "secret"]:
    v = D["pool"][t]; sh = [x for x in v if not byid[x]["gachaOnly"]]
    P(f"| {LAB[t]} ({W[t]}%) | {len(v)} | {len(sh)} ({sum(byid[x]['price'] for x in sh):,} xu) | {len(v)-len(sh)} | {DUP[t]} |")
P("\nBậc của món cửa hàng tính theo giá (<50 Thường, 50–89 Hiếm, ≥90 Quý), trừ Ma bông có `rarity: .rare` (120 xu → Hiếm).")

# EV theo tiến trình quay (gacha trước, chưa có gì)
rng = random.Random(9)
bins = defaultdict(list)
for _ in range(2000):
    g = sim.Gacha({"hat.sprout"}, rng)
    for k in range(300):
        price, ref, gained = g.pull(1)
        val = sum(byid[x]["price"] for x in gained if not byid[x]["gachaOnly"]) + ref
        bins[k // 25].append(val)
P("\n**Giá trị nhận được trên mỗi lượt 60 xu** (giá cửa hàng của món mới + xu hoàn; món chỉ-gacha tính 0), mô phỏng 2000 lần, quay lẻ từ tài khoản trắng:\n")
P("| Lượt thứ | " + " | ".join(f"{25*b+1}–{25*b+25}" for b in range(8)) + " |")
P("|---|" + "---:|" * 8)
P("| Giá trị TB (xu) | " + " | ".join(f"{statistics.mean(bins[b]):.0f}" for b in range(8)) + " |")
P("| Xu nhận/xu chi | " + " | ".join(f"{statistics.mean(bins[b])/60:.2f}" for b in range(8)) + " |")

P("\n### Bảng 2. Mười người chơi giả lập\n")
P("Xu/ngày là **ròng** (đã trừ đồ ăn tự mua), trung bình 365 ngày đầu, gồm cả ngày nghỉ. Ngày = ngày thứ mấy kể từ khi cài (trung vị 60 quỹ đạo). "
  "Gacha: trung vị / P90 của 2000 lần Monte Carlo. Số > 3650 là ngoại suy tuyến tính.\n")
P("| # | Người chơi | Xu/ngày (gộp) | XP/ngày | Cấp 5 / 8 / 10 / 20 (ngày) | Mua hết cửa hàng | Đủ 14 món chỉ-gacha (lẻ) | (gói 10) | Đủ cả 124 món máy chỉ bằng gacha (gói 10) | Phá đảo: shop trước (gói 10) | Phá đảo: gacha trước (gói 10) |")
P("|---|---|---:|---:|---|---:|---:|---:|---:|---:|---:|")
def f(x):
    x = float(x)
    return f"{x:,.0f}"
def mp(t): return f"{f(t[0])} / {f(t[1])}"
for r in R["rows"]:
    g = r["gacha"]
    P(f"| {r['key']} | {r['name']} | {r['coins_day']} ({r['gross_day']}) | {r['xp_day']} | {f(r['lv']['5'])} / {f(r['lv']['8'])} / {f(r['lv']['10'])} / {f(r['lv']['20'])} | "
      f"{f(r['shop_day'])} | {mp(g['single']['excl'])} | {mp(g['ten']['excl'])} | {mp(g['ten']['pool'])} | {mp(g['ten']['s1'])} | {mp(g['ten']['s2'])} |")

P("\n### Bảng 3. Cảm giác tiến bộ 2 tuần đầu và cơ cấu thu nhập\n")
P("| # | Món có giá đầu tiên (ngày) — mua rẻ trước / chọn ngẫu nhiên | Số món mua được trong 14 ngày — rẻ trước / ngẫu nhiên | Cơ cấu xu/ngày (việc · tập trung · nhật ký · thở · phiêu lưu · minigame · chăm) | Đồ ăn tự mua (xu/ngày) |")
P("|---|---|---|---|---:|")
for r in R["rows"]:
    b = r["breakdown"]
    parts = " · ".join(str(b.get(k, 0)) for k in ["task", "focus", "journal", "breath", "adventure", "minigame", "care"])
    P(f"| {r['key']} {r['name']} | {r['first_cheap']:.0f} / {r['first_rand']:.0f} | {r['n14_cheap']:.0f} / {r['n14_rand']:.0f} | {parts} | {r['food_day']} |")

P("\n### Chi phí gacha (không phụ thuộc người chơi)\n")
P("| Kịch bản | Số lượt trung vị / P90 | Xu ròng trung vị / P90 | Giá trị đồ cửa hàng nhận kèm |")
P("|---|---:|---:|---:|")
NAMES = {"gacha_first|False|excl": "Tài khoản trắng, quay lẻ tới đủ 14 món độc quyền",
         "gacha_first|True|excl": "Tài khoản trắng, gói 10, tới đủ 14 món độc quyền",
         "gacha_first|False|pool": "Tài khoản trắng, quay lẻ, đủ cả 124 món trong máy",
         "gacha_first|True|pool": "Tài khoản trắng, gói 10, đủ cả 124 món",
         "shop_first|False|excl": "Đã mua hết cửa hàng, quay lẻ lấy 14 món độc quyền",
         "shop_first|True|excl": "Đã mua hết cửa hàng, gói 10 lấy 14 món độc quyền"}
for k, v in R["gacha"].items():
    P(f"| {NAMES[k]} | {v['pulls_med']:.0f} / {v['pulls_p90']:.0f} | {v['net_med']:,.0f} / {v['net_p90']:,.0f} | {v['value_med']:,.0f} |")
open(f"{S}/tables.md", "w").write("\n".join(out) + "\n")
print("\n".join(out))
