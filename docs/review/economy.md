# Đánh giá kinh tế xu/XP của CozyDay

Nhánh `claude/ios-project-section-12-4bpxn7` (commit `87371c9`). Chỉ đọc code, không sửa repo.

## 0. Cách làm và nguồn số liệu

- **Danh mục lấy thẳng từ code Swift**: `run_dump.sh` chép `Cozyday/Core` vào chroot Swift (`/opt/swiftimg/root`), biên dịch cùng một `main.swift` nhỏ và xuất `Catalog.items`, `GachaPolicy.pool()`, `PetLooks.all`, `FoodCatalog`, `RoomKind.requiredLevel`, `GachaConfig` và `RewardConfig` ra `catalog.json`. Không dùng regex nên không sót món nào trong các file `Catalog+*.swift` hay biến thể `.variant(of:)`.
- **Luật thưởng, chăm sóc và gacha** được chép lại bằng Python, khớp từng dòng với `RewardConfig`, `RewardPolicy`, `Adventure` (25%/hoạt động, chỉ tính việc/tập trung/nhật ký/thở), `CareConfig`/`CarePolicy`, `MinigameConfig` và `GachaPolicy.pull`: pity Quý ở lượt 10, Bí mật ở lượt 60, ưu tiên món chưa có trong cùng bậc, hoàn xu khi trùng, gói 10 đảm bảo Hiếm ở lượt cuối, bậc theo giá với món không có `rarity` riêng.
- **Các số đã đối chiếu với code**: việc 10 XP + 8 xu, tối đa 10 việc có thưởng/ngày. Tập trung 2 XP + 2 xu mỗi 5 phút, từ 10 phút, tối đa 120 phút/phiên, **không giới hạn số phiên/ngày**. Nhật ký 5/5, thở 3/3, phiêu lưu 5 XP/10 xu. 100 XP/cấp. Minigame tối đa 8 xu/lượt và 40 xu/ngày, không có XP. Chăm sóc chỉ có thưởng khi chỉ số dưới 35: cho ăn 2 XP/1 xu, dọn 3/2, nựng 2/1, mỗi loại 2 lần, trần 12 XP/6 xu/ngày. Đồ ăn 3–25 xu, bữa cơ bản miễn phí. Gói chào mừng chỉ có đồ ăn (3 táo + 1 cơm nắm), **không có xu**. Gacha 60/540 xu, trọng số 60/28/10/2, hoàn 15/25/50/120. `GiftCodes`: mã `t3ster` = 1000 xu, **nhập lại bao nhiêu lần cũng được**.
- **Mô phỏng theo ngày** (`sim.py`):
  - Mỗi người chơi có 60 quỹ đạo thu nhập, mỗi quỹ đạo dài 10 năm.
  - Chăm sóc được mô phỏng theo giờ, với giờ mở app riêng của từng người.
  - Gacha chạy Monte Carlo 2000 lần cho mỗi kịch bản. Mỗi lần ghép với một quỹ đạo thu nhập ngẫu nhiên để ra số ngày.
  - Kết quả là trung vị và P90.
- **Kịch bản đề xuất** (`proposal.py`) chạy lại đúng 10 người chơi đó, cùng seed, chỉ đổi các con số.

### Giả định chung

1. Bắt đầu với 0 xu và 0 XP (cấp 1). "Ngày N" là ngày thứ N kể từ khi cài.
2. Ngày nghỉ được mô phỏng bằng xác suất mở app. Số việc mỗi ngày phân bố đều trong một khoảng. Mặc định 92% phiên tập trung chạy hết giờ (người P8 là 50%, P9 là 100%).
3. Phiêu lưu có thưởng khi trong ngày có ít nhất 4 dòng sổ cái thuộc loại việc, tập trung, nhật ký hoặc thở, đúng như `Adventure.energy`.
4. Mỗi lượt minigame được ~N(μ; 1,6) xu, kẹp trong khoảng 1–8, tổng ngày không quá 40.
5. Chăm sóc: chỉ dọn hoặc nựng khi chỉ số dưới 35 (lúc đó mới có thưởng). Khi đói thì dùng bữa miễn phí. Riêng P6 và P10 mua táo 3 xu để cho ăn tới khi no ≥70; đây là khoản chi "khuyến khích" duy nhất, vì app không có khoản chi bắt buộc nào.
6. **Mua hết cửa hàng** nghĩa là tổng xu ròng tích lũy ≥ 29.245 và đã đạt cấp 8. Thứ tự mua không ảnh hưởng thời điểm xong.
7. **Đủ đồ gacha**:
   - (a) Tài khoản trắng dồn hết xu vào gacha cho tới khi có đủ 14 món chỉ-gacha.
   - (a2) Như (a) nhưng tới khi đủ cả 124 món trong máy.
   - Mỗi kịch bản chạy hai cách quay: quay lẻ 60 xu và gói 10 giá 540 xu.
   - Thời điểm xong được tính theo "đỉnh xu cần có", tức là khoản cần trả trước khi nhận xu hoàn của lượt đó.
8. **Phá đảo** = mọi món cửa hàng + 14 món chỉ-gacha (497 món không mặc định). Có hai chiến lược:
   - S1: mua hết cửa hàng rồi mới quay.
   - S2: quay trước cho tới khi đủ 14 món, rồi mua phần cửa hàng còn thiếu. Các món cửa hàng đã quay ra thì không phải mua.
9. **2 tuần đầu**: không tính 16 món giá 0 xu. Có hai kiểu mua:
   - "Rẻ trước": luôn mua món rẻ nhất đã mở khóa. Đây là giới hạn trên của số món.
   - "Ngẫu nhiên": chọn một món đã mở khóa rồi để dành xu cho tới khi mua được. Kiểu này gần với hành vi thật hơn.
10. Không tính lỗ hổng như mã quà, đổi giờ hay sửa file sao lưu. Các lỗ hổng này được tính riêng ở mục 4.

### 10 người chơi giả lập

| # | Tên | Hành vi (khi mở app) | Mở app | Chăm sóc |
|---|---|---|---|---|
| P1 | Rất lười | 1–3 việc | 3/7 ngày | 1 lần/ngày mở |
| P2 | Lười | 2–4 việc, nhật ký 10% | 85% | 1 lần |
| P3 | Nhẹ nhàng | 4–6 việc + nhật ký 90% | 90% | 2 lần |
| P4 | Cân bằng | 4–6 việc + 1×25' + nhật ký 85% + thở 70% | 90% | 2 lần |
| P5 | Học sinh | 5–7 việc + 2×25' + 1–2 lượt minigame (~5 xu) + nhật ký 30% | 90% | 3 lần |
| P6 | Chăm chỉ | 7–9 việc + 3×25' + nhật ký + thở + 7–9 lượt minigame (đạt trần), mua táo | 95% | 4 lần |
| P7 | Đi làm bận | Ngày thường 2–4 việc (mở 80%); T7–CN 6–8 việc + 2×50' + nhật ký + thở + 3–4 lượt minigame | 80% / 95% | 1 / 3 lần |
| P8 | Hay bỏ dở | 3–6 việc + 3×25' (50% kết thúc sớm, không thưởng) + nhật ký/thở 50% | 85% | 2 lần |
| P9 | Cày tối đa hợp lệ | 10 việc + 2×120' + nhật ký + thở + phiêu lưu + minigame 40 + chăm đúng lúc | 100% | 7 lần |
| P10 | Chỉ minigame + chăm | Không việc, không tập trung; 5–7 lượt minigame (~6 xu); mua táo | 90% | 4 lần |

## 1. Thống kê danh mục

### Bảng 1a. Đồ phòng (bán trong cửa hàng)

| Phòng (mở ở cấp) | Số món (không tính mặc định) | Miễn phí | Biến thể màu | Tổng giá đồ | Sàn riêng: số món / tổng giá | Tổng cả phòng | Cấp cao nhất cần |
|---|---:|---:|---:|---:|---:|---:|---:|
| Phòng học (cấp 1) | 59 | 3 | 19 | 3,455 | 12 / 615 | 4,070 | 6 |
| Phòng ngủ (cấp 1) | 69 | 3 | 22 | 4,470 | 12 / 685 | 5,155 | 7 |
| Bếp & bàn ăn (cấp 2) | 60 | 2 | 12 | 4,000 | 11 / 620 | 4,620 | 8 |
| Phòng tắm (cấp 3) | 59 | 3 | 22 | 3,420 | 11 / 595 | 4,015 | 8 |
| Khu vườn (cấp 4) | 60 | 4 | 17 | 4,040 | 10 / 590 | 4,630 | 8 |
| **Cộng đồ phòng** | | | | | | **363 món / 22,490 xu** | |

### Bảng 1b. Thú cưng

| Lớp | Cửa hàng: số món / tổng giá / cấp cao nhất | Chỉ có trong gacha (Quý / Bí mật) | Có trong máy gacha? |
|---|---:|---:|---|
| Loài (hình dạng) | 15 / 1,380 / 6 | 1 / 1 | có |
| Màu lông | 10 / 390 / 5 | 0 / 0 | không |
| Mũ | 28 / 1,400 / 8 | 2 / 2 | có |
| Kính | 15 / 675 / 6 | 1 / 0 | có |
| Cổ | 16 / 605 / 6 | 0 / 2 | có |
| Áo | 20 / 1,405 / 8 | 1 / 0 | có |
| Lưng / phụ kiện | 16 / 900 / 7 | 2 / 2 | có |
| **Cộng thú cưng** | **120 món / 6,755 xu** | **7 / 7** | |

**Tổng cửa hàng:** 483 món (467 có giá, 16 miễn phí), **29,245 xu**; 105 món là biến thể màu (6,840 xu = 23% tổng giá). Cộng 14 món chỉ-gacha → bộ sưu tập đầy đủ 497 món (+7 món mặc định = 504).

**Phân bố cấp mở khóa (đồ cửa hàng):** cấp 1: 105, cấp 2: 72, cấp 3: 101, cấp 4: 85, cấp 5: 62, cấp 6: 37, cấp 7: 15, cấp 8: 6. Cấp cao nhất cần để mua hết: **8** (700 XP). Phòng: học/ngủ cấp 1, bếp 2, tắm 3, vườn 4.

**Phân bố giá:** 0 xu: 16, 1–29 xu: 30, 30–49 xu: 139, 50–89 xu: 205, 90–129 xu: 80, 130–160 xu: 13. Trung bình món có giá: 62.6 xu; đắt nhất 160 xu (Tủ lạnh mèo).

### Bảng 1c. Máy gacha (pool = mọi món thú cưng không mặc định trừ màu lông)

| Bậc (trọng số) | Số món | Trong đó bán ở cửa hàng (tổng giá) | Chỉ-gacha | Hoàn xu khi trùng |
|---|---:|---:|---:|---:|
| Thường (60%) | 45 | 45 (1,450 xu) | 0 | 15 |
| Hiếm (28%) | 48 | 48 (3,135 xu) | 0 | 25 |
| Quý (10%) | 24 | 17 (1,780 xu) | 7 | 50 |
| Bí mật (2%) | 7 | 0 (0 xu) | 7 | 120 |

Bậc của món cửa hàng tính theo giá (<50 Thường, 50–89 Hiếm, ≥90 Quý), trừ Ma bông có `rarity: .rare` (120 xu → Hiếm).

**Giá trị nhận được trên mỗi lượt 60 xu** (giá cửa hàng của món mới + xu hoàn; món chỉ-gacha tính 0), mô phỏng 2000 lần, quay lẻ từ tài khoản trắng:

| Lượt thứ | 1–25 | 26–50 | 51–75 | 76–100 | 101–125 | 126–150 | 151–175 | 176–200 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Giá trị TB (xu) | 47 | 47 | 45 | 38 | 36 | 36 | 33 | 27 |
| Xu nhận/xu chi | 0.78 | 0.78 | 0.75 | 0.63 | 0.60 | 0.60 | 0.55 | 0.46 |

## 2. Kết quả mô phỏng hiện tại

### Bảng 2. Mười người chơi giả lập

Xu/ngày là **ròng** (đã trừ đồ ăn tự mua), trung bình 365 ngày đầu, gồm cả ngày nghỉ. Ngày = ngày thứ mấy kể từ khi cài (trung vị 60 quỹ đạo). Gacha: trung vị / P90 của 2000 lần Monte Carlo. Số > 3650 là ngoại suy tuyến tính.

| # | Người chơi | Xu/ngày (gộp) | XP/ngày | Cấp 5 / 8 / 10 / 20 (ngày) | Mua hết cửa hàng | Đủ 14 món chỉ-gacha (lẻ) | (gói 10) | Đủ cả 124 món máy chỉ bằng gacha (gói 10) | Phá đảo: shop trước (gói 10) | Phá đảo: gacha trước (gói 10) |
|---|---|---:|---:|---|---:|---:|---:|---:|---:|---:|
| P1 | Rất lười | 7.7 (7.7) | 10.0 | 40 / 69 / 90 / 193 | 3,785 | 1,600 / 1,948 | 1,450 / 1,758 | 1,462 / 1,772 | 4,883 / 5,225 | 4,386 / 4,717 |
| P2 | Lười | 25.6 (25.6) | 30.4 | 14 / 24 / 30 / 62 | 1,144 | 483 / 587 | 437 / 531 | 441 / 534 | 1,474 / 1,562 | 1,324 / 1,420 |
| P3 | Nhẹ nhàng | 51.9 (51.9) | 58.5 | 7 / 12 / 16 / 33 | 563 | 238 / 290 | 216 / 261 | 217 / 262 | 729 / 773 | 653 / 700 |
| P4 | Cân bằng | 61.7 (61.7) | 68.2 | 6 / 11 / 13 / 28 | 476 | 201 / 244 | 181 / 221 | 183 / 222 | 613 / 650 | 550 / 590 |
| P5 | Học sinh | 79.6 (79.6) | 81.4 | 5 / 9 / 11 / 23 | 366 | 155 / 189 | 140 / 170 | 141 / 171 | 475 / 504 | 425 / 457 |
| P6 | Chăm chỉ | 133.7 (145.1) | 121.5 | 4 / 6 / 8 / 16 | 219 | 93 / 113 | 84 / 102 | 85 / 103 | 283 / 300 | 253 / 272 |
| P7 | Đi làm bận | 54.1 (54.1) | 55.4 | 8 / 14 / 18 / 35 | 544 | 230 / 279 | 209 / 252 | 210 / 252 | 700 / 742 | 629 / 674 |
| P8 | Hay bỏ dở | 57.6 (57.6) | 63.1 | 7 / 12 / 15 / 30 | 506 | 216 / 262 | 194 / 237 | 196 / 237 | 655 / 695 | 588 / 631 |
| P9 | Cày tối đa hợp lệ | 237.1 (237.1) | 214.4 | 2 / 4 / 5 / 9 | 124 | 53 / 64 | 48 / 58 | 48 / 58 | 160 / 169 | 143 / 153 |
| P10 | Chỉ minigame + chăm | 24.2 (35.1) | 7.4 | 55 / 96 / 122 / 258 | 1,207 | 510 / 618 | 462 / 558 | 464 / 560 | 1,557 / 1,648 | 1,396 / 1,496 |

### Bảng 3. Cảm giác tiến bộ 2 tuần đầu và cơ cấu thu nhập

| # | Món có giá đầu tiên (ngày) — mua rẻ trước / chọn ngẫu nhiên | Số món mua được trong 14 ngày — rẻ trước / ngẫu nhiên | Cơ cấu xu/ngày (việc · tập trung · nhật ký · thở · phiêu lưu · minigame · chăm) | Đồ ăn tự mua (xu/ngày) |
|---|---|---|---|---:|
| P1 Rất lười | 2 / 6 | 5 / 2 | 6.9 · 0 · 0 · 0 · 0 · 0.0 · 0.9 | 0.0 |
| P2 Lười | 1 / 2 | 17 / 8 | 20.4 · 0 · 0.4 · 0 · 3.1 · 0.0 · 1.7 | 0.0 |
| P3 Nhẹ nhàng | 1 / 1 | 32 / 13 | 36.0 · 0 · 4.1 · 0 · 9.0 · 0.0 · 2.7 | 0.0 |
| P4 Cân bằng | 1 / 1 | 37 / 16 | 36.0 · 8.3 · 3.8 · 1.9 · 9.0 · 0.0 · 2.7 | 0.0 |
| P5 Học sinh | 1 / 1 | 45 / 20 | 43.2 · 16.6 · 1.3 · 0 · 9.0 · 6.7 · 2.8 | 0.0 |
| P6 Chăm chỉ | 1 / 1 | 70 / 32 | 60.8 · 26.2 · 4.5 · 2.6 · 9.5 · 37.7 · 4.2 | 11.49 |
| P7 Đi làm bận | 1 / 2 | 33 / 14 | 28.9 · 10.0 · 2.4 · 0.7 · 5.4 · 4.7 · 2.0 | 0.0 |
| P8 Hay bỏ dở | 1 / 1 | 35 / 15 | 30.6 · 12.8 · 2.1 · 1.3 · 8.4 · 0.0 · 2.6 | 0.0 |
| P9 Cày tối đa hợp lệ | 1 / 1 | 106 / 54 | 80.0 · 96.0 · 5.0 · 3.0 · 10.0 · 40.0 · 3.1 | 0.0 |
| P10 Chỉ minigame + chăm | 1 / 2 | 16 / 9 | 0.0 · 0 · 0 · 0 · 0 · 31.2 · 4.0 | 10.92 |

### Chi phí gacha (không phụ thuộc người chơi)

| Kịch bản | Số lượt trung vị / P90 | Xu ròng trung vị / P90 | Giá trị đồ cửa hàng nhận kèm |
|---|---:|---:|---:|
| Tài khoản trắng, quay lẻ tới đủ 14 món độc quyền | 247 / 317 | 12,355 / 15,001 | 6,365 |
| Tài khoản trắng, quay lẻ, đủ cả 124 món trong máy | 247 / 324 | 12,430 / 15,250 | 6,365 |
| Tài khoản trắng, gói 10, tới đủ 14 món độc quyền | 250 / 320 | 10,975 / 13,322 | 6,365 |
| Tài khoản trắng, gói 10, đủ cả 124 món | 250 / 330 | 11,040 / 13,396 | 6,365 |
| Đã mua hết cửa hàng, quay lẻ lấy 14 món độc quyền | 246 / 320 | 9,682 / 12,370 | 0 |
| Đã mua hết cửa hàng, gói 10 lấy 14 món độc quyền | 250 / 320 | 8,280 / 10,465 | 0 |

## 3. Nhận xét

### 3.1 Nhịp kinh tế có hợp với người chơi không?

- **Giai đoạn đầu vui.**
  - Từ P2 trở lên, món có giá đầu tiên thường mua được ngay ngày 1. Món rẻ nhất ở cấp 1 là 20 xu, mà một ngày P4 đã có ~60 xu.
  - Trong 2 tuần đầu, theo kiểu mua "ngẫu nhiên", P3–P5 mua được 13–20 món và P6 được 32 món. Như vậy là đủ cảm giác tiến bộ.
  - Chỉ có P1 (mở app 3 ngày/tuần, 2 việc) là chậm: ~2 món trong 2 tuần, món đầu tiên vào ngày ~6.
  - Không có xu khởi đầu: gói chào mừng chỉ có đồ ăn, nên ngày đầu người chơi phải làm việc rồi mới mua được gì.
- **Giai đoạn giữa và cuối quá dài so với một app thói quen.**
  - Cửa hàng có 483 món, tổng 29.245 xu. Người cân bằng (P4, ~62 xu/ngày) cần **~16 tháng** để mua hết cửa hàng và **~18 tháng** để phá đảo.
  - Người chăm chỉ (P6) cần ~8 tháng. Người lười (P2) cần 3–4 năm.
  - Nếu mục tiêu là "người chăm vừa phá đảo trong 3–6 tháng" thì hiện tại chậm hơn mục tiêu khoảng 2,5–4 lần.
  - Ngược lại, mỗi món trung bình 62,6 xu, tức chừng 1 ngày làm việc, nên cảm giác "đắt" chỉ đến khi người chơi nhìn vào cả bộ sưu tập.
- **Cấp độ hết ý nghĩa rất sớm.**
  - Món cần cấp cao nhất là cấp 8 (700 XP). P4 đạt cấp 8 vào ngày ~11, P6 vào ngày ~6.
  - Sau đó XP không còn mở khóa gì, trong khi cấp 20 chỉ cần ~4 tuần với P4.
  - Ngược lại, P10 (chỉ minigame + chăm) có ~7 XP/ngày, tới ngày ~96 mới lên cấp 8. Người này bị khóa khỏi 378/483 món (cần cấp ≥2) trong nhiều tuần, vì minigame không cho XP.
- **Khoảng cách giữa người cày và người cân bằng là ~3,8 lần** (237 so với 62 xu/ngày).
  - Riêng tập trung chiếm 96 xu/ngày của P9 (4 giờ).
  - Nếu treo máy thì không có trần (xem mục 4).
  - Với app thói quen nên giữ khoảng cách ≤ 3 lần.
- **Tập trung bị định giá thấp so với tick việc.**
  - 25 phút tập trung = 10 xu, trong khi một việc (bấm mất 2 giây) = 8 xu.
  - Ở P4, việc chiếm 58% thu nhập, tập trung chỉ 13%.
  - Riêng 10 "việc rác" mỗi ngày đã cho 80 xu chỉ trong một phút.
- **Đồ ăn và chăm sóc là vòng phụ an toàn.**
  - Không có vòng lặp sinh xu: táo 3 xu, cho ăn được thưởng 1 xu. Thưởng chăm sóc tối đa 6 xu/ngày, thực tế 2–4 xu.
  - Khoản chi duy nhất có thể lặp lại là đồ ăn, mà bữa cơ bản thì miễn phí. Người thích chăm (P6, P10) chi khoảng 11 xu/ngày cho táo, những người khác chi 0.
  - Khi đã mua hết đồ, **không còn chỗ tiêu xu**: P9 hết đồ vào ngày ~124, sau đó xu chỉ nằm im hoặc đổ vào gacha để nhận hoàn xu trùng.
- **Tài liệu ghi sai số.** `docs/DATA_AND_RULES_VI.md` ghi "một ngày bình thường (5 việc + 50 phút + nhật ký + thở + chuyến đi) ≈ 30–45 xu". Theo code thật là **78 xu + 83 XP**. Câu "40 xu/ngày ≈ 8 việc" cũng sai: 40 xu chỉ bằng 5 việc. Comment trong `MinigameConfig` lặp lại con số cũ.

### 3.2 Gacha hấp dẫn hay kém mua thẳng?

- **Tính trên mỗi xu bỏ ra, gacha luôn thua mua thẳng** nếu chỉ tính đồ có bán ở cửa hàng.
  - Lượt đầu ở tài khoản trắng mang về món trị giá trung bình 47 xu cho 60 xu, tức 0,78. Mua gói 10 thì được 0,88.
  - Từ lượt ~76, giá trị giảm còn 0,63, và còn 0,46 ở lượt 176–200 (chủ yếu là xu hoàn trùng 15/25).
  - Mua thẳng luôn được 1,00.
- **Giá thật của 14 món chỉ-gacha rất cao.**
  - Có 7 món Bí mật, mỗi món cần trung bình ≈ 35 lượt: (1 − 0,98⁶⁰)/0,02 = 35,1. Bảy món là ~250 lượt.
  - Khi đã có đủ đồ cửa hàng, 14 món này tốn 8.280 xu (gói 10, trung vị) tới 9.682 xu (quay lẻ), P90 là 10.465–12.370 xu.
  - Tức là **~600–700 xu mỗi món, ~1.200–1.400 xu mỗi món Bí mật**, gấp 8–9 lần món đắt nhất cửa hàng (160 xu).
  - Theo nhịp chơi: P4 cần ~6 tháng chỉ để gom đủ đồ gacha, P2 cần ~15 tháng.
- **Nghịch lý cho người muốn sưu tầm hết.**
  - Máy gacha chứa cả 110 món trang phục có bán ở cửa hàng, và cần ~250 lượt vì 7 món Bí mật.
  - Vì vậy **quay trước rồi mua sau (S2) rẻ hơn mua cửa hàng trước (S1) ~3.700 xu** (≈ 33,9k so với 37,5k xu, tương đương ~2 tháng với P4).
  - Người đã mua trang phục ở cửa hàng rồi mới quay sẽ thấy máy toàn ra món trùng, dù vẫn được hoàn 15–25 xu. Cảm giác này dễ khiến người chơi thấy "bị phạt" vì đã mua thẳng.
- Gói 10 rẻ hơn 10% và đảm bảo Hiếm. Tuy vậy, đảm bảo Hiếm hầu như vô nghĩa: xác suất 10 lượt không có Hiếm trở lên chỉ là 0,6¹⁰ ≈ 0,6%.
- Gacha bỏ qua `requiredLevel`: người chơi cấp 1 vẫn quay được Vương miện (cấp 8). Lỗi này nhỏ nhưng nên biết.
- Bậc của món cửa hàng được suy ra từ giá. Nếu sau này đổi giá trang phục, món có thể đổi bậc, làm thay đổi pool và cả cách đọc bộ đếm pity từ sổ cái. Khi đổi giá nên gán `rarity` cố định cho món.

### 3.3 So với các app tương tự (cảm nhận chung)

- **Finch**: tiền kiếm đều đặn theo mục tiêu nhỏ, cửa hàng xoay vòng theo ngày hoặc mùa nên không có áp lực "mua hết". Người chơi luôn có món mới để chờ. CozyDay có danh mục cố định 483 món nên dễ tạo cảm giác "bài tập về nhà" ở giai đoạn cuối, và cũng không có chỗ tiêu xu khi đã mua xong.
- **Forest**: tiền gắn với thời gian tập trung thật, và rời app thì cây chết (ở chế độ nghiêm). CozyDay thưởng tập trung thấp hơn tick việc, và ở chế độ thường thì rời app vẫn có thưởng đủ. Đây là hướng ngược với Forest.
- **Habitica**: thưởng việc có lợi suất giảm dần, có giới hạn rơi đồ mỗi ngày, và có nhiều chỗ tiêu vàng tiêu hao. CozyDay đã có trần việc và trần minigame (tốt), nhưng chưa có lợi suất giảm dần, nhiệm vụ ngày/tuần hay chỗ tiêu dài hạn.
- **Tổng thể**: tốc độ kiếm đầu game của CozyDay ngang hoặc hào phóng hơn các app trên. Phần đuôi (bộ sưu tập và gacha Bí mật) thì nặng hơn nhiều.

## 4. Lỗ hổng cày xu (xếp theo mức độ)

| # | Lỗ hổng | Ở đâu | Mức thu | Mức độ |
|---|---|---|---|---|
| 1 | **Mã quà `t3ster` = 1000 xu, nhập lại không giới hạn.** Ô nhập hiện khi chạm 7 lần vào dòng Phiên bản. Mã nằm dạng chữ thường trong code và docs | `Core/Rewards/GiftCodes.swift`, `AppStore+Gacha.swift: redeemGiftCode` | ~34–38 lần nhập là phá đảo | **Nghiêm trọng nếu phát hành** |
| 2 | **Phiên tập trung không có trần/ngày và tính bằng giờ tường** (`Date`). Ở chế độ thường, rời app vẫn thưởng đủ. Bật "tự chạy phiên kế tiếp" (chỉ cần app mở, màn hình sáng) thì 120' + 5' nghỉ lặp lại cả ngày | `RewardConfig.focusReward`, `FocusTimer.reconcile`, `Pomodoro.shouldAutoStart` | 11 phiên × 48 = **~528 xu + 528 XP/ngày** khi treo máy; một phiên 120' trước khi ngủ là +48 | Cao |
| 3 | **Đổi giờ máy.** (a) Vặn đồng hồ tới 2 giờ thì phiên 120' xong ngay: +48 xu mỗi ~1 phút. (b) Mọi trần đều theo ngày lịch (`DayKey`, `isDate(inSameDayAs:)`). Đổi sang một ngày chưa dùng, tới hoặc lùi đều được, sẽ có lại trọn bộ trần. Không có mốc "thời gian lớn nhất đã thấy" | `SystemClock`, `RewardPolicy.taskRewardsToday`, khóa `journal:/breathing:/adventure:<ngày>` | ~144 xu cho mỗi "ngày giả" (80 việc + 5 + 3 + 10 + 40 minigame + 6 chăm), cộng tập trung không giới hạn | Cao (chơi đơn, nhưng phá hết tiến trình) |
| 4 | **Sửa file sao lưu.** JSON không ký. Khi kiểm tra chỉ chặn tổng xu âm, dòng mua dương và minigame > 8. Dòng `gift`/`taskCompleted`/`focusCompleted` chỉ cần ≥ 0, nên ghi 99.999 xu vẫn hợp lệ | `Core/Backup/BackupDocument.swift` (dòng ~228–243) | Vô hạn | Trung bình |
| 5 | **Lưu rồi quay lại gacha (save-scum).** Xuất sao lưu, quay (RNG là `SystemRandomNumberGenerator`), không ưng thì khôi phục rồi quay lại. Xu và bộ đếm pity cũng quay về | `AppStore+Gacha.swift`, `AppStore+Backup.restore` | Chọn được món, giảm chi phí đồ Bí mật đi vài lần | Thấp–trung bình |
| 6 | **Việc rác.** Tạo rồi tick 10 việc vô nghĩa, có trần nhưng không cần thời gian | `RewardPolicy.forTaskCompletion` | 80 xu/ngày trong 1 phút (34% thu nhập tối đa hợp lệ) | Thấp (khó tránh trong app to-do) |
| 7 | **Minigame kết thúc sớm.** Xếp Khối/Gộp Bánh: đạt điểm tối thiểu rồi "Kết thúc lượt". Lật Thẻ Dễ cho 5 xu trong ≤40 giây | `MinigameConfig` | 40 xu trong ~6 phút, có trần | Thấp |
| 8 | Phiêu lưu đếm cả dòng "Hết hạn mức" 0 xu của việc thứ 11 trở đi | `Adventure.energy` | Không đáng kể | Rất thấp |

**Không phải lỗ hổng** (đã kiểm tra):

- Mua đồ ăn rồi cho ăn bị lỗ 2 xu mỗi lần.
- Bỏ đánh dấu rồi đánh dấu lại việc, hoặc xóa rồi tạo lại việc: đều bị khóa theo `task:<id>` và trần 10 việc/ngày.
- Khôi phục sao lưu là thay thế toàn bộ dữ liệu, nên không nhân đôi được đồ.
- Chỉ số chăm sóc không tăng khi lùi giờ.

## 5. Đề xuất (có số liệu)

### 5.1 Đóng lỗ hổng (làm trước)

1. **Mã quà**: chỉ biên dịch `GiftCodes` trong `#if DEBUG`, hoặc mỗi mã chỉ dùng được 1 lần (khóa `gift:<mã>` thay vì `gift:<uuid>`). Xóa mã khỏi docs công khai.
2. **Trần tập trung theo ngày: 240 phút có thưởng/ngày.** Mức này vừa đủ cho P9, nên người chơi thật không mất gì. Thêm điều kiện: phiên được nối bằng "tự chạy" mà app không được chạm trong cả phiên thì không có thưởng, hoặc chỉ thưởng khi bật chế độ nghiêm.
3. **Chống đổi giờ**:
   - Lưu `maxSeenNow`. Khi `now < maxSeenNow − 10 phút` thì tạm khóa mọi thưởng cho tới khi giờ quay về.
   - Khi phiên tập trung kết thúc, so mức tăng `Date` với mức tăng `ProcessInfo.systemUptime` từ lúc bắt đầu. Nếu giờ tường nhảy hơn 10 phút so với uptime (và máy không khởi động lại) thì không thưởng.
   - Chặn thưởng cho các ngày trước ngày cài app.
4. **Sao lưu**: kiểm tra trần theo loại (việc ≤ 8 xu/10 XP, tập trung ≤ 48, nhật ký 5, thở 3, phiêu lưu 10, chăm ≤ 2, `gift` chỉ nhận mệnh giá có trong danh sách) và tổng theo ngày (việc ≤ 80, minigame ≤ 40, chăm ≤ 6). Có thể thêm HMAC nhẹ để chặn người sửa tay nghiệp dư.
5. **Gacha save-scum**: lưu hạt giống của lượt kế tiếp (`gacha.nextSeed`) vào sổ cái hoặc vào sao lưu, để khôi phục lại vẫn ra đúng kết quả cũ.

### 5.2 Cân bằng lại (đã mô phỏng)

`proposal.py` áp đồng thời các thay đổi A–E dưới đây:

- **A. Nhiệm vụ ngày**: 3 hoạt động có thưởng bất kỳ (việc, tập trung, nhật ký, thở) cho **+15 xu, +10 XP**. **Nhiệm vụ tuần**: ngày thứ 5 trong tuần hoàn thành nhiệm vụ ngày cho **+60 xu**. Không có chuỗi gãy, không phạt khi bỏ lỡ. Đây là cách thưởng đều đặn mà không khuyến khích cày: người chơi vừa phải nhận +20 xu/ngày, P9 cũng chỉ nhận chừng đó.
- **B. Tập trung**: 60 phút có thưởng đầu tiên mỗi ngày được **3 xu/5 phút** (25' = 15 xu, hơn 2 việc). Sau đó 2 xu/5 phút. Tối đa **240 phút có thưởng/ngày**. XP giữ nguyên.
- **C. Minigame**: trần ngày = **25 + 5 × số việc xong hôm nay** (tối đa 40). Người chỉ chơi game vẫn có 25 xu; ai làm 3 việc thì vẫn đạt trần 40.
- **D. Biến thể màu ×0,7**: 105 món, tổng 6.840 → ~4.810 xu. Tổng cửa hàng còn 27.215 xu.
- **E. Gacha**: Bí mật 2% → **3%** (Thường 59%), pity Bí mật 60 → **40** lượt, hoàn xu trùng **20/30/60/150**. Kỳ vọng ~23,5 lượt mỗi món Bí mật.

**Kết quả mô phỏng: hiện tại → đề xuất** (trung vị; "phá đảo" tính theo chiến lược tốt nhất là quay gói 10 trước):

| # | Xu/ngày hiện tại → đề xuất | Mua hết cửa hàng (ngày) | Đủ 14 món chỉ-gacha, gói 10 (trung vị) | Phá đảo, gacha trước, gói 10 (trung vị / P90) | Món mua trong 14 ngày (chọn ngẫu nhiên) |
|---|---|---|---|---|---|
| P1 Rất lười | 7.7 → **9.8** | 3,785 → **2,766** | 1,450 → **884** | 4,386 / 4,717 → **3,004 / 3,124** | 2 → **3** |
| P2 Lười | 25.6 → **38.0** | 1,144 → **714** | 437 → **229** | 1,324 / 1,420 → **779 / 818** | 8 → **11** |
| P3 Nhẹ nhàng | 51.9 → **73.8** | 563 → **369** | 216 → **118** | 653 / 700 → **402 / 416** | 13 → **20** |
| P4 Cân bằng | 61.7 → **87.6** | 476 → **311** | 181 → **100** | 550 / 590 → **338 / 350** | 16 → **24** |
| P5 Học sinh | 79.6 → **109.8** | 366 → **248** | 140 → **79** | 425 / 457 → **270 / 280** | 20 → **29** |
| P6 Chăm chỉ | 133.7 → **167.3** | 219 → **163** | 84 → **53** | 253 / 272 → **177 / 183** | 32 → **43** |
| P7 Đi làm bận | 54.1 → **74.3** | 544 → **368** | 209 → **119** | 629 / 674 → **399 / 414** | 14 → **20** |
| P8 Hay bỏ dở | 57.6 → **84.2** | 506 → **322** | 194 → **104** | 588 / 631 → **352 / 368** | 15 → **23** |
| P9 Cày tối đa hợp lệ | 237.1 → **272.6** | 124 → **100** | 48 → **32** | 143 / 153 → **109 / 112** | 54 → **67** |
| P10 Chỉ minigame + chăm | 24.2 → **15.5** | 1,207 → **1,756** | 462 → **561** | 1,396 / 1,496 → **1,908 / 1,968** | 9 → **6** |

Gacha shop_first|True|excl: lượt 250 → 170; xu ròng 8,280 → 4,920 (P90 10,465 → 6,151)

Gacha gacha_first|True|excl: lượt 250 → 180; xu ròng 10,975 → 8,485 (P90 13,322 → 9,560)

**Đọc kết quả**:

- Người chơi vừa phải (P3, P4, P7, P8) có thêm **+37–46% xu/ngày**. Thời gian phá đảo giảm từ ~18–21 tháng xuống **~11–13 tháng**. Đủ đồ gacha giảm từ ~6–7 tháng xuống **~3,5–4 tháng**.
- P5 phá đảo sau ~9 tháng, P6 sau ~6 tháng. Số món mua được trong 2 tuần đầu tăng từ 13–20 lên 20–29.
- Người cày (P9) chỉ thêm +15%. Khoảng cách P9/P4 giảm từ 3,8 lần xuống **3,1 lần**.
- Chi phí đủ 14 món chỉ-gacha (khi đã mua hết cửa hàng) giảm từ 8.280 xu xuống **4.920 xu** (P90 từ 10.465 xuống 6.151), tức ~350 xu mỗi món, ~2–3 lần món đắt nhất cửa hàng. Như vậy đồ độc quyền vẫn có giá, nhưng không còn như một bức tường.
- Đánh đổi:
  - P10 (chỉ minigame) giảm từ 24 xuống 15,5 xu/ngày ròng. Đây là điều mong muốn với một app năng suất, nhưng nếu muốn giữ P10 thì đặt trần C là 30 + 5 × số việc.
  - P2 vẫn cần ~2 năm để phá đảo. Điều này chấp nhận được vì P2 hiếm khi nhắm tới việc sưu tầm hết.

**Mục tiêu thời gian nên chốt**:

- Món đầu tiên mua trong ngày 1. Từ 1 tới 2 món/ngày trong tuần đầu với P4.
- "Phòng yêu thích hoàn chỉnh" (~4.000–5.000 xu): 6–8 tuần với P4.
- Đủ đồ gacha: 3–4 tháng với P4.
- **Phá đảo: 10–12 tháng với P4, 5–6 tháng với P6, không dưới 3 tháng với P9.**
- Nếu muốn "người chăm vừa (P4) phá đảo trong 3–6 tháng" thì ngoài A–E còn phải **giảm toàn bộ giá ~60%** (27.215 → ~11.000 xu). Khi đó P9 xong trong ~2 tháng và mỗi món chỉ còn ~1/3 ngày làm việc. Không khuyến nghị cách này, vì danh mục 483 món là nội dung dài hạn. Nên giữ độ dài, nhưng thêm chỗ tiêu và đồ theo mùa (mục 5.3).

### 5.3 Đề xuất khác (chưa mô phỏng, có số đề xuất)

1. **Tách gacha khỏi đồ cửa hàng.**
   - Nên bỏ 110 món có bán ở cửa hàng ra khỏi pool. Thay vào đó, thêm 30–40 biến thể màu trang phục chỉ có trong gacha (Thường/Hiếm), giữ 7 Quý và 7 Bí mật.
   - Lợi ích: gacha có bộ sưu tập riêng, mua thẳng không còn bị "phạt" (xem 3.2), và EV mỗi lượt minh bạch.
   - Nếu giữ pool như hiện tại thì ít nhất nên hoàn xu trùng theo giá cửa hàng: ~60% giá món, tối thiểu 15.
2. **Thêm cấp mở khóa tới cấp 25–30.** Hiện tại cấp 8 là hết.
   - Rải 10% món đắt nhất (~48 món ≥ 100 xu) lên các cấp 10–25.
   - Mỗi 5 cấp (từ cấp 10) tặng 1 vé gacha miễn phí, khoảng +8 xu/ngày quy đổi với P4.
   - XP khi đó có ý nghĩa thêm ~6 tuần (P4 đạt cấp 25 vào ngày ~36), còn P6 cũng không vượt quá nhanh.
3. **Lợi suất giảm dần cho việc**: 3 việc đầu 8 xu, việc 4–10 được 5 xu.
   - P4 (5 việc): 40 → 34 xu. P9: 80 → 59 xu.
   - Kết hợp với A (nhiệm vụ ngày), người chơi vừa phải vẫn có lợi hơn hiện tại, còn "việc rác" bớt hấp dẫn.
4. **Chỗ tiêu xu dài hạn** cho người đã mua gần hết:
   - Cửa hàng mùa: 8–12 món mỗi quý, 80–200 xu/món, ~1.200 xu/quý.
   - Đồ ăn đặc biệt hoặc "bữa tiệc" 40–80 xu, cho thú cưng một hiệu ứng vui.
   - Khung ảnh và hiệu ứng Studio.
   - "Quyên góp" mở huy hiệu (500/1.000/2.000 xu).
   - Với P9 (~240 xu/ngày), cửa hàng mùa chỉ chiếm ~5 ngày mỗi quý. Vì vậy cần thêm ít nhất một chỗ tiêu không giới hạn mang tính trang trí, ví dụ thay màu đồ đã có với giá 20 xu/lần.
5. **Gói chào mừng thêm 50 xu và 1 vé gacha miễn phí** (vé đảm bảo Hiếm, có màn hướng dẫn). Người chơi lười (P1) sẽ có món đầu tiên ngay ngày 1 thay vì ngày ~6.
6. **Thưởng mốc ngày hoạt động** (không phải chuỗi liên tục, nên không phạt): tổng 7/30/100 ngày có mở app được 50/150/400 xu, hoặc một món độc quyền ở mốc 100 ngày. Tính ra ~6 xu/ngày trong 100 ngày đầu với người chơi đều, đủ làm "điểm hẹn" mà không gây áp lực.
7. **Sửa tài liệu**: thay "30–45 xu" bằng "~78 xu" cho một ngày bình thường, và "40 xu ≈ 8 việc" bằng "≈ 5 việc".

## 6. Script và file đã dùng

Tất cả nằm trong `docs/review/economy-tools/`:

- `run_dump.sh` + `swift/main.swift` + `swift/Package.swift`: biên dịch Core trong chroot Swift và xuất `catalog.json`.
- `catalog_stats.py`: thống kê nhanh danh mục (`python3 -I catalog_stats.py <thư mục>`).
- `sim.py`: mô phỏng 10 người chơi và Monte Carlo gacha (`python3 -I sim.py <thư mục> 2000`). Kết quả ghi ra `sim_results.json` và `run_output.txt`.
- `proposal.py`: chạy lại với luật đề xuất A–E. Kết quả ghi ra `proposal_results.json` và `proposal_output.txt`.
- `tables.py`: sinh các bảng của báo cáo (`tables.md`). `compare.md` là bảng so sánh.
