"""Kịch bản đề xuất: chạy lại sim.py với luật mới (chỉ đổi số, cùng 10 người chơi, cùng seed).
Chạy: python3 -I proposal.py <thư mục> [MC]"""
import sys, importlib.util
S = sys.argv[1]; MC = sys.argv[2] if len(sys.argv) > 2 else "2000"
sys.argv = [sys.argv[0], S, MC]
spec = importlib.util.spec_from_file_location("sim", f"{S}/sim.py"); sim = importlib.util.module_from_spec(spec); spec.loader.exec_module(sim)

# A) Nhiệm vụ ngày: 3 hoạt động có thưởng bất kỳ (việc / phiên tập trung / nhật ký / bài thở) → +15 xu, +10 XP.
#    Nhiệm vụ tuần: ngày thứ 5 trong tuần đạt nhiệm vụ ngày → +60 xu. Không có chuỗi gãy, không phạt.
def bonus(n, n_self, d, st):
    if n + n_self >= 3:
        w = d // 7
        st[w] = st.get(w, 0) + 1
        return (10, 15 + (60 if st[w] == 5 else 0))
    return (0, 0)
sim.DAILY_BONUS_FN = bonus
# B) Tập trung: 60 phút có thưởng đầu tiên mỗi ngày 3 xu/5 phút, sau đó 2 xu/5 phút, tối đa 240 phút có thưởng/ngày
#    (XP giữ 2/5 phút, cũng dừng ở 240 phút). Phiên vẫn ≥10 phút, ≤120 phút.
def focus_fn(m, used):
    if m < 10: return (0, 0)
    m = min(m, 120); xp = coins = 0
    for k in range(m // 5):
        t = used + 5 * k
        if t >= 240: break
        xp += 2; coins += 3 if t < 60 else 2
    return (xp, coins)
sim.FOCUS_FN = focus_fn
# C) Minigame: trần ngày = 25 + 5 × số việc xong hôm nay (tối đa 40)
sim.MG_CAP_FN = lambda n: min(40, 25 + 5 * n)
# D) Giá biến thể màu × 0,7 (làm tròn 5 xu)
for it in sim.ITEMS:
    if it["variantOf"] and it["price"] > 0:
        it["price"] = max(5, int(round(it["price"] * 0.7 / 5) * 5))
sim.SHOP = [i for i in sim.NONDEF if not i["gachaOnly"]]
sim.SHOP_PAID = [i for i in sim.SHOP if i["price"] > 0]
sim.SHOP_TOTAL = sum(i["price"] for i in sim.SHOP)
# E) Gacha: Bí mật 2% → 3% (Thường 60 → 59), pity Bí mật 60 → 40, hoàn xu trùng 20/30/60/150
sim.WEIGHTS = [("common", 59), ("rare", 28), ("epic", 10), ("secret", 3)]
sim.SECRET_PITY = 40
sim.DUP = {"common": 20, "rare": 30, "epic": 60, "secret": 150}
sim.OUT_NAME = "proposal_results.json"
print("Tổng giá cửa hàng sau đề xuất:", sim.SHOP_TOTAL)
sim.main()
