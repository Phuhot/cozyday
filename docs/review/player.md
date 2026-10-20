# CozyDay: đánh giá từ góc nhìn người chơi thử và game designer

Phạm vi: chỉ đánh giá, không sửa repo. Nguồn đã đọc: `README.md`, `PROJECT_STATUS.md`, `docs/DATA_AND_RULES_VI.md`,
`docs/UI_PREVIEW_VI.md`, khoảng 20 ảnh trong `docs/screenshots/` (onboarding, Hôm nay, Góc nhỏ, chuyến đi, Sổ ký ức,
Tiến bộ, Sân chơi, gacha, tủ đồ bí mật, chăm sóc, Tập trung, Nhật ký, Gộp Bánh, Nhảy Mây, vườn), cùng code
`Core/Rewards`, `Core/Pet` (Adventure, PetDialogue, PetLooks, PetAppearance), `Core/Shop` (Catalog*, Gacha),
`Core/Play`, `Core/Stats`, `Features/Gacha`, `Features/Onboarding`, `Features/Corner`.

Giới hạn: app chưa được chơi trên máy thật, nên phần cảm giác tay, độ mượt và âm thanh là suy đoán từ ảnh và code.
Ràng buộc cứng được giữ: không đề xuất gì cần máy chủ, đăng nhập, mạng xã hội, quảng cáo hay trả phí.

---

## 0. Các con số làm nền cho mô phỏng

Tính từ `RewardConfig`, `MinigameConfig`, `CareConfig`, `GachaConfig` và danh mục đồ:

| Nguồn | Mỗi ngày (thực tế) | Trần |
|---|---|---|
| Việc xong | 5 việc ≈ 50 XP, 40 xu | 10 việc có thưởng (100 XP, 80 xu) |
| Tập trung | 2 phiên 25 phút ≈ 20 XP, 20 xu | không có trần ngày, tối đa 120 phút mỗi phiên |
| Nhật ký + bài thở | 8 XP, 8 xu | 1 lần mỗi thứ |
| Chuyến đi (đủ 4 hoạt động) | 5 XP, 10 xu | 1 lần |
| Chăm sóc | 0–6 xu | 12 XP, 6 xu |
| Sân chơi | 40 xu, 0 XP | 40 xu |
| **Tổng** | **khoảng 80 XP, 80–120 xu** | |

Hệ quả cho nhịp chơi:

- **Cấp = XP/100 + 1.** Người dùng đều tay lên cấp 2 vào ngày 2, mở vườn (cấp 4) khoảng ngày 4–5. Món cuối cùng
  cần cấp 8 mở vào khoảng ngày 10. Thú cưng "Trưởng thành" ở cấp 10 vào khoảng **ngày 12–14**. Sau mốc này XP
  không còn mở thêm gì. Đây là **vách đá tiến trình lớn nhất** của app.
- **Danh mục khoảng 448 món, mua hết tốn khoảng 29.000 xu**, tức gần một năm thu nhập tối đa. Đuôi sưu tầm rất dài,
  nhưng chỉ có một kiểu mục tiêu: tích xu để mua.
- **Gacha:** 7 món Bí mật, tỉ lệ 2%, bảo hiểm ở lượt 60. Kỳ vọng khoảng 35 lượt cho mỗi món, tức khoảng 245 lượt
  (≈ 13.000 xu, ≈ 4–5 tháng dồn toàn bộ xu) để đủ bộ Bí mật.
- **Sân chơi:** cách lấy đủ 40 xu nhanh nhất là chơi Lật Thẻ mức Dễ (2 xu cơ bản + 3 xu thưởng ≈ 5 xu trong
  khoảng 30–40 giây, 8 ván ≈ 5 phút). Hệ số quy đổi đang đẩy người chơi về **trò nông nhất**.

---

## 1. Mô phỏng 5 kiểu người chơi

### 1.1. Sinh viên lười (Minh, 19 tuổi, cài vì thấy con vịt dễ thương)

| Mốc | Trải nghiệm |
|---|---|
| **Ngày 1** | Trailer và 5 trang giới thiệu dễ thương nhưng hơi dài, Minh bấm "Bỏ qua". Onboarding 3 bước nhanh; Minh tick 2 thói quen gợi ý ("Uống nước", "Đi bộ"). Bất ngờ đầu tiên: icon là vịt vàng nhưng thú cưng lại là **mèo kem**, và muốn đổi sang vịt phải đạt cấp 2 và có 60 xu. Màn Hôm nay có nhiều thứ: thanh tuần, Hộp chờ, "Sắp xếp lại", nhóm chưa xếp giờ, timeline. Minh tick 2 thói quen, nhận popup có thú cưng, rồi sang Sân chơi chơi tới hết 40 xu. **Wow:** thú cưng gọi đúng tên mình; chơi Nhảy Mây bằng chính con mèo của mình. |
| **Tuần 1** | Lý do quay lại: thanh nhu cầu xuống "Cần chăm" mỗi ngày (khoảng 15 giờ mới xuống dưới 35) và chuyến đi kể chuyện. Năng lượng chuyến đi chỉ cần 4 hoạt động nên tick 2 thói quen + bài thở + nhật ký là đủ, khá dễ. Ngày 3–4 Minh bỏ một ngày. App không phạt, nhưng khi quay lại cũng **không có gì đón** (không có quà "mừng bạn quay lại", không có thư của thú cưng). |
| **Tháng 1** | Khả năng cao đã rời app vào khoảng ngày 7–10. Lý do: không có mục tiêu nhỏ trong ngày ("hôm nay làm gì?"), Sân chơi bị trần 40 xu nên chơi 10 phút là hết lý do mở, truyện chuyến đi lặp khuôn (19 khuôn) và bắt đầu đoán trước được. |
| **Tháng 3** | Đã gỡ app. Nếu app ký bằng Apple Account miễn phí thì sau 7 ngày không ký lại, app không mở được nữa: với người lười đây là điểm rơi gần như chắc chắn. |

- **Giữ chân:** thú cưng dễ thương, chăm sóc nhẹ không có hình phạt, chuyến đi.
- **Chán vì:** không có nhiệm vụ ngày dẫn đường, không có quà mốc chuỗi ngày, Hôm nay quá nhiều chức năng với người
  chỉ có 2 việc.
- **Khó chịu:** không được chọn loài lúc đầu; banner "Có 1 việc trễ giờ" xuất hiện mỗi tối dù chữ nhẹ nhàng.

### 1.2. Sinh viên chăm (Linh, 21 tuổi, ôn IELTS, ở ký túc xá)

| Mốc | Trải nghiệm |
|---|---|
| **Ngày 1** | Tạo lịch tuần: việc lặp theo thứ, việc con ("Listening 3 bài"), nhắc trước. Tab Tập trung: **wow** với chế độ nghiêm (giữ 3 giây mới dừng), âm mưa nhẹ, "Ghi nhanh" ý nghĩ chen ngang vào Hộp chờ, chấm vòng 2/6 phiên. "Sắp xếp lại" việc trễ có xem trước và nút Hủy: thông minh mà không gây sợ. Kết thúc ngày đầu ở cấp 2, mở bếp. |
| **Tuần 1** | Giai đoạn đẹp nhất: mỗi ngày lên khoảng 1 cấp, mỗi 1–2 ngày mở một phòng mới, mua bàn có máy tính, đèn nấm. Chuyến đi luôn đầy năng lượng. Nhật ký và lịch tâm trạng tô màu tạo thói quen buổi tối. |
| **Tháng 1** | Ngày 12–14 thú cưng "Trưởng thành" và thanh XP **không còn ý nghĩa**. Tiến bộ chỉ có 7 hoặc 30 ngày, không có tổng giờ tập trung, kỷ lục cá nhân, mốc "100 giờ", hay thống kê theo môn hoặc nhóm. Xu dồn lại 2.000–3.000 nhưng Linh không phải người sưu tầm. Cô vẫn ở lại **vì phần lập kế hoạch tốt**, còn phần game mờ dần thành phông nền. |
| **Tháng 3** | Vẫn dùng nếu không có gì làm phiền. Rủi ro: muốn widget đếm giờ và đếm ngược ngày thi. Nếu thấy thiếu tổng kết tháng, cô sẽ chuyển sang một app Pomodoro có thống kê sâu hơn. |

- **Giữ chân:** chất lượng planner và Pomodoro, tiến trình 2 tuần đầu dày đặc.
- **Chán vì:** hết mục tiêu dài hạn sau cấp 10; thống kê nông; không có "Tổng kết tháng" để tự hào.
- **Wow:** chế độ nghiêm, "Ghi nhanh", thú cưng ngồi đọc sách cùng khi đang tập trung ("Suỵt… mình đang tập trung cùng Linh đó").

### 1.3. Người đi làm bận (Tuấn, 27 tuổi, nhân viên văn phòng)

| Mốc | Trải nghiệm |
|---|---|
| **Ngày 1** | **Wow:** bật "hiện sự kiện từ app Lịch", cuộc họp hiện ngay cạnh việc và "Sắp xếp lại" tự tránh giờ họp. Kéo tay nắm để đổi giờ việc rất tiện. Khó chịu: thêm việc cần mở form đầy đủ; không có ô nhập nhanh kiểu "gọi khách 15h 30p"; không có widget. |
| **Tuần 1** | Mở app sáng và tối. Góc nhỏ, chăm sóc, Sân chơi gần như bị bỏ qua; thanh "Cần chăm" nhắc nhẹ nhưng anh không có thời gian dọn nhà bằng cách chà chổi. |
| **Tháng 1** | Dùng như planner thuần. Phần thú cưng chỉ là hình ở đầu trang Hôm nay. Không có lý do vào Góc nhỏ vì không có "việc 30 giây" (nhận quà ngày, nhiệm vụ nhanh). |
| **Tháng 3** | Bỏ nếu chi phí nhập việc lớn hơn giá trị, hoặc nếu một lần quên ký lại làm app không mở được. Lúc đó anh quay về Lịch hoặc Reminders của iPhone. |

- **Giữ chân:** đọc lịch iPhone, replan, timeline đẹp.
- **Chán vì:** ma sát nhập liệu, phần game không vừa với 30 giây rảnh của anh.
- **Cần:** nhập nhanh, mẫu ngày, tổng kết tuần ngắn, và một nghi thức "kế hoạch buổi sáng" trong 20 giây có thú cưng.

### 1.4. Người thích sưu tầm (Vy, 23 tuổi, từng chơi Neko Atsume và Pokémon Sleep)

| Mốc | Trải nghiệm |
|---|---|
| **Ngày 1** | **Wow lớn:** Tủ đồ mặc thử miễn phí, Bộ sưu tập 40 bộ phối, máy gacha với tỉ lệ công khai và 7 bóng đen "???". Mỗi món đều vẽ tay bằng code, có câu giới thiệu dễ thương ("Hung dữ… một chút xíu"). Khó chịu: ngày đầu chỉ có khoảng 100 xu, loài và màu lông khóa theo cấp. |
| **Tuần 1** | Vy cày tới trần 10 việc và trần 40 xu Sân chơi (nhanh nhất bằng Lật Thẻ Dễ). Mua màu lông, sàn, đồ phòng ngủ. Khoảng ngày 6 đủ 540 xu quay 10 lượt: được Rồng con, rất vui. Rồi Vy nhận ra 6/10 viên là món Thường giá 20–45 xu mà cô vốn mua thẳng được, rẻ hơn 60 xu một lượt, nên **thấy bị thiệt**. |
| **Tháng 1** | Đã có khoảng 3.000 xu tổng thu. Dồn vào gacha thì khoảng ngày 35–40 chạm bảo hiểm và có món Bí mật đầu tiên. Thiếu: % hoàn thành tổng, thưởng khi đủ bộ (Bộ Thiên hà, Bộ Rồng mây), cách trưng đồ. Mỗi phòng chỉ có 5–6 vị trí cố định, mỗi vị trí 1 món, nên có 10 cái giường mà chỉ đặt được 1. Không lưu được bộ phối tự tạo. |
| **Tháng 3** | Rủi ro cao: "đã có hết những gì mình thích" vào khoảng tháng 2–3. Danh mục không bao giờ đổi, không có đồ theo mùa, không có đợt đồ mới. Với người sưu tầm, **nội dung đóng băng là lý do rời app số 1**. |

- **Giữ chân:** số lượng và chất lượng đồ, mặc thử, gacha minh bạch, bóng đen Bí mật.
- **Chán vì:** không có đợt đồ mới, không có thưởng hoàn thành, vị trí trưng bày bị giới hạn.
- **Khó chịu:** món Thường trong gacha rẻ hơn giá một lượt; hoàn xu cho món trùng thấp (Thường 15 xu so với 60 xu một lượt).

### 1.5. Chỉ thích thú cưng và minigame (Bảo, 18 tuổi)

| Mốc | Trải nghiệm |
|---|---|
| **Ngày 1** | Muốn chọn con vịt như trên icon: không được. Chơi cả 5 game. **Wow:** chơi bằng chính bạn nhỏ đang mặc đồ, bạn nhỏ reo khi xóa đường ("Liền tay 3 lần rồi!") hoặc lo khi bàn kín; Gộp Bánh có bậc bánh dễ thương; Nhảy Mây có mây giông cau có và chim. Hết 40 xu sau khoảng 10–15 phút. |
| **Tuần 1** | Đuổi kỷ lục được 3–4 ngày. Game không cho XP nên Bảo **không lên cấp nếu không làm việc**: loài, phòng và đồ đều khóa theo cấp. Đây là ý đồ thiết kế (game là giờ nghỉ), nhưng người kiểu này sẽ thấy bị ép. Tương tác thú cưng gồm vuốt, nựng, nhấc thả, cho ăn bằng nút: dễ thương nhưng xem 2 ngày là hết điều mới. |
| **Tháng 1** | Mỗi game là một bản 2048 hoặc Block Blast tốt nhưng không có màn, nhiệm vụ, mở khóa hay mục tiêu trong game. Lật Thẻ chỉ có 2 mức, tối đa 8 cặp. Rời app vào khoảng tuần 2–3. |
| **Tháng 3** | Đã rời. |

- **Giữ chân:** chơi bằng thú cưng của mình, phản ứng của bạn nhỏ trong game, không quảng cáo.
- **Chán vì:** game không có tiến trình, trần xu thấp, thú cưng ít hành vi mới.
- **Khó chịu:** không chọn được loài lúc đầu; game không cho XP nên mọi thứ khóa theo cấp đều xa.

### 1.6. Tổng hợp đường giữ chân

| Người chơi | Ngày 7 | Ngày 30 | Ngày 90 | Điểm rơi chính |
|---|---|---|---|---|
| Sinh viên lười | Có thể | Thấp | Rất thấp | Không có nhiệm vụ ngày và quà quay lại |
| Sinh viên chăm | Cao | Khá | Khá | Hết mục tiêu sau cấp 10 (ngày 13) |
| Người đi làm | Khá | Khá | Trung bình | Ma sát nhập việc, thiếu widget |
| Người sưu tầm | Rất cao | Cao | Trung bình | Danh mục đóng băng, không có sự kiện |
| Thú cưng/minigame | Trung bình | Thấp | Rất thấp | Game không có tiến trình |

Chẩn đoán chung: **2 tuần đầu rất tốt, sau đó app không còn "chuyện mới".** Cái thiếu là nhịp nội dung theo
thời gian (ngày, tuần, mùa) và mục tiêu dài hạn ngoài việc tích xu.

---

## 2. Điểm mạnh hiện tại

1. **Planner thật sự dùng được:** timeline, việc lặp có "chỉ lần này / các lần sau", việc con, Hộp chờ, replan
   tất định có xem trước, đọc lịch iPhone. Mạnh hơn hẳn Finch hay Habitica ở phần lập kế hoạch.
2. **Pomodoro chín chắn:** chế độ nghiêm, đếm rời app, Ghi nhanh, âm nền tự tổng hợp, đồng hồ nhỏ khi ở tab khác.
3. **Triết lý không gây tội lỗi** (không ốm, không bỏ đi, sàn chỉ số 20, câu thoại không trách móc). Đây là điểm
   Finch được yêu thích, và CozyDay làm đúng.
4. **Kinh tế chống cày** có suy nghĩ: trần 10 việc, sổ cái idempotent, Sân chơi không cho XP.
5. **Lượng nội dung vẽ tay lớn:** 18 loài, 11 màu lông, khoảng 448 món, 5 phòng + sàn, 40 bộ phối, avatar.
6. **Văn hóa Việt tự nhiên** trong truyện: cốm, hoa sữa, mưa ngâu, đèn ông sao, xôi gấc, ô ăn quan, múa rối nước.
   Truyện có 19 khuôn ghép theo loài và mùa, và Sổ ký ức giữ lại.
7. **Gacha minh bạch:** tỉ lệ công khai, bảo hiểm hiện số lượt còn lại, ưu tiên món chưa có. Đây là gacha "tử tế".
8. **Hoàn thiện kỹ thuật:** dark mode, Dynamic Type, VoiceOver cho cả minigame.

---

## 3. Những gì còn thiếu so với app cùng loại (xếp theo tác động đến giữ chân)

Mỗi mục có đánh giá có nên làm không. Không liệt kê cho đủ.

| # | Thiếu | So với | Tác động | Đáng làm? |
|---|---|---|---|---|
| 1 | **Nhiệm vụ ngày/tuần** (3 việc nhỏ mỗi ngày, 1 rương tuần) | Habitica dailies, Pokémon Sleep, Finch "micro-goals" | Rất cao: cho người lười và người chơi game một lý do cụ thể để mở app, đồng thời dạy dần các tính năng | **Có, ưu tiên số 1.** Rẻ vì dựng trên sổ cái sẵn có |
| 2 | **Sự kiện theo mùa và lễ Việt** (Tết, Rằm tháng Giêng, Trung thu, 20/10, 20/11, Noel, mùa thi) | Neko Atsume, Finch seasonal, Animal Crossing | Rất cao với người sưu tầm và người quay lại: "có gì mới tháng này" | **Có.** Âm lịch tính offline được bằng `Calendar(identifier: .chinese)`. Đồ theo sự kiện quay lại mỗi năm để tránh FOMO độc hại |
| 3 | **Mục tiêu dài hạn sau cấp 10** (album, huy hiệu, mốc tích lũy) | Pokémon Sleep (Sleep Style Dex), Forest (cây trong rừng) | Cao: lấp vách đá ngày 13 | **Có.** Xem đề xuất 3 và 5 |
| 4 | **Chuỗi ngày có quà mốc** (hiện chỉ là ô "14 ngày liên tiếp" và 2 câu thoại) | Finch, Duolingo (bản mềm) | Cao với người lười, trung bình với người khác | **Có, bản nhẹ:** quà ở mốc, tự có "ngày nghỉ phép", không mất gì khi đứt chuỗi |
| 5 | **Kỷ vật chuyến đi thành đồ thật** (hiện chỉ là chữ) | Neko Atsume (mementos), Finch (souvenirs) | Cao, rẻ, gắn cảm xúc | **Có.** Đây là cơ hội lớn nhất đang bị bỏ phí |
| 6 | **Thú cưng nhớ và phản ứng với bạn** (mood nhật ký, việc vừa làm, ngày quay lại) | Finch (hỏi han, phản ứng mood) | Cao với người thích thú cưng | **Có**, làm bằng luật và khuôn câu, không cần AI |
| 7 | **Tổng kết tuần/tháng + ảnh chia sẻ** (PNG tạo trên máy) | Finch "weekly recap", Forest | Trung bình đến cao, và là kênh "truyền miệng" duy nhất khi không có mạng xã hội | **Có.** Đã có hạ tầng xuất PNG của avatar |
| 8 | **Minigame có tiến trình** | Pokémon Café, các game merge | Trung bình | **Có, mức vừa phải.** Game là phụ, đừng biến app thành game |
| 9 | **Thông báo dễ thương** (hiện có nhắc việc, nhật ký, hết giờ, nhắc quay lại phiên) | Finch | Trung bình | **Có, có giới hạn:** tối đa 1–2 mỗi ngày, chỉ nội dung tích cực (truyện đã sẵn sàng, chào buổi sáng) |
| 10 | **Widget màn hình chính** | Mọi app cùng loại | Cao về lý thuyết | **Có điều kiện.** `PROJECT_STATUS` ghi rõ: extension và App Group có thể không ký được bằng Apple Account miễn phí. Làm IPA thử nghiệm riêng, đừng gộp vào bản chính |
| 11 | Trưng bày tự do (đặt nhiều món, kéo thả trong phòng) | Neko Atsume, Animal Crossing | Trung bình, chi phí cao | Chưa, chỉ làm "kệ trưng bày" (xem đề xuất 3) |
| 12 | Nhiều thú cưng cùng lúc hoặc nuôi bạn bè | Neko Atsume | Trung bình, phá thiết kế hiện tại | **Không nên** lúc này: một bạn đồng hành gắn bó hơn và khớp triết lý Finch |

Không đề xuất: bảng xếp hạng chung, tặng quà bạn bè, đồng bộ (cần máy chủ), và streak có hình phạt.

---

## 4. Minigame

| Game | Nhận xét | Hay hay nhạt |
|---|---|---|
| **Nhảy Mây** | Độ khó mới tốt (mây giông, chim, mây mỏng, tối đa ở 160 m). Lượt ngắn, chơi lại nhanh. Nhưng 1 xu cho 15 điểm, kỷ lục mẫu 48 m chỉ được khoảng 3 xu, nên mất công hơn Lật Thẻ | **Hay** (game hành động tốt nhất) |
| **Giỏ Quà** | 60 giây cố định, 4 loại quà và 2 vật xấu, không có biến thể. Chơi 3 lần là thấy hết | **Nhạt nhất** |
| **Lật Thẻ Bạn Nhỏ** | Dễ và Vừa (6 hoặc 8 cặp), hình là các loài. Ván 30 giây cho tới 5 xu nên thành lối cày tối ưu | **Nhạt**, và đang làm méo kinh tế |
| **Xếp Khối** | Bản Block Blast làm kỹ: bóng mờ, đường sắp xóa sáng lên, combo "Liền tay", bạn nhỏ lo khi bàn kín | **Hay**, dễ nghiện |
| **Gộp Bánh** | 2048 với 12 bậc bánh, chữ "Ngon quá!". Một ván dài (vài phút) mà chỉ khoảng 7 xu | **Hay**, nhưng thiếu "mục tiêu bậc bánh" |

**Cần thêm, theo thứ tự đáng làm:**

1. **Cân lại quy đổi xu** để trò khó và dài không thua trò ngắn: thưởng theo phút chơi hợp lệ, hoặc giảm Lật Thẻ Dễ
   xuống tối đa 3 xu. Việc này cỡ S.
2. **Thử thách ngày** cho mỗi game: dùng seed theo ngày, cả ngày là cùng một ván, so với kỷ lục của chính mình
   (bảng xếp hạng cá nhân top 5 lượt, theo tuần). Engine đã có seed nên chi phí thấp. Gắn vào nhiệm vụ ngày.
3. **Nhiệm vụ trong game và mốc kỷ lục** mở khóa đồ trang trí game (nền trời Nhảy Mây theo giờ hoặc mùa, giỏ, bộ
   thẻ, khay bánh) và huy hiệu: "Leo 100 m", "Gộp ra bánh 3 tầng", "Xóa 4 đường một lúc".
4. **Sổ bánh của Gộp Bánh:** lần đầu gộp ra bậc mới thì thêm vào album. Bậc 512 trở lên tặng một món "Món ăn" (`treat`)
   cho bếp. Đây là cách nối minigame với phòng.
5. **Lật Thẻ mức Khó** (10–12 cặp, thẻ đồ trang phục, có thể dùng mặt thẻ là đồ đã sở hữu). Nó vừa là game vừa là
   cách khoe bộ sưu tập.
6. **Giỏ Quà:** thêm biến thể theo mùa (Trung thu rơi bánh nướng và đèn lồng, Tết rơi lì xì) và 1–2 vật phẩm hỗ trợ
   (giỏ to 5 giây, nam châm). Rẻ mà làm game đỡ phẳng.
7. **Không làm** bảng xếp hạng online hay game mới thứ 6 trước khi 5 game có tiến trình.

---

## 5. Gacha và sưu tầm

**Động lực hay ức chế?** Hiện tại là **động lực ở tuần đầu, ức chế nhẹ từ tuần 2.**

Phần tốt:
- Minh bạch (tỉ lệ, bảo hiểm, đếm ngược "Còn 60 lượt chắc chắn có món Bí mật") và không có tiền thật, nên không độc hại.
- Ưu tiên món chưa có, nên không có cảm giác "ra trùng mãi".
- 14 món chỉ có trong gacha (2 bộ Quý, 2 bộ Bí mật, Rồng con, Kỳ lân) là lý do chính đáng để quay.

Phần gây ức chế:
1. **Giá trị kỳ vọng âm so với cửa hàng:** 60% ra món Thường (giá shop dưới 50 xu) mà một lượt tốn 60 xu. Người sưu
   tầm tính được ngay và thấy mình bị "đánh thuế". Hoàn xu món trùng (15/25/50/120) cũng thấp.
2. **Không có hồi hộp lúc mở:** 10 viên lật đều nhau mỗi 0,18 giây, không có viên nang đổi màu báo trước độ hiếm,
   và món Bí mật không có màn mở riêng. Khoảnh khắc đáng giá nhất của gacha đang bị bỏ qua.
3. **Chiến lược ẩn:** mua trước đồ shop giá từ 90 xu sẽ "dọn" nhóm Quý và tăng cơ hội ra món chỉ có trong gacha.
   Người thường không biết điều này.
4. **Cạnh tranh xu với trang trí phòng:** cùng một ví, nên quay gacha làm chậm phòng và ngược lại.
5. Đủ bộ Bí mật cần khoảng 4–5 tháng, mà **đủ bộ không có thưởng gì**.

**Bóng đen có đủ tò mò không?** Có một nửa. Màn tủ đồ hiện bóng toàn thân thú cưng đang mặc món đó, kèm câu "Bộ Thiên
hà. Cổ áo dựng cao, vạt áo đầy sao.": gợi ý tên bộ là cách tốt. Nhưng ở lưới gacha, 7 bóng đều là cùng một dáng
mèo cộng một chi tiết nhỏ, nhìn gần giống nhau. Cách sửa:
- Vẽ bóng **của riêng món** (không kèm thân thú cưng), hoặc phóng to phần món.
- Hiện tên bộ và số món của bộ ("Bộ Rồng mây 0/3").
- Thêm một **gợi ý mở dần** khi đã quay N lượt (ví dụ sau 20 lượt hiện màu viền) để tò mò tăng theo thời gian.

**Đề xuất cho gacha** (không có tiền thật nên có thể hào phóng):
- **Bụi sao:** món Thường và món trùng cho bụi sao. Đủ 300 bụi đổi một món Quý tự chọn, đủ 1.000 đổi một món Bí mật
  tự chọn. Cách này loại bỏ cảm giác "thuế".
- **Vé Mây Mây miễn phí:** 1 vé mỗi tuần từ rương nhiệm vụ tuần, cộng vé ở các mốc chuỗi ngày.
- **Kệ máy theo mùa:** mỗi mùa hoặc lễ có 3–4 món riêng xoay vòng và quay lại mỗi năm.
- **Thưởng đủ bộ:** đủ Bộ Thiên hà mở hiệu ứng avatar hoặc nền phòng ngủ "Thiên hà đêm".
- **Màn mở Bí mật riêng:** màn tối, viên nang rung, bóng đen rồi mới lộ hình, có rung phản hồi.

**Sưu tầm nói chung:** cần **% hoàn thành tổng** (tủ đồ, phòng, loài), **thưởng đủ bộ** cho 40 bộ phối sẵn, **lưu
bộ phối tự tạo** (đã có trong backlog) và một **kệ trưng bày** cho kỷ vật và huy hiệu.

---

## 6. Top 10 đề xuất

Độ khó: S khoảng 1–2 ngày, M khoảng 3–6 ngày, L từ 1–2 tuần trở lên. Ưu tiên: P0 làm ngay, P1 làm sau P0, P2 làm khi rảnh.

| # | Đề xuất | Mô tả ngắn | Lý do | Độ khó | Ưu tiên |
|---|---|---|---|---|---|
| 1 | **Nhiệm vụ ngày + rương tuần** | Mỗi ngày 3 nhiệm vụ nhỏ xoay vòng theo seed ngày, ví dụ "Xong 1 việc trước 12h", "1 phiên tập trung", "Nựng bạn nhỏ", "Chơi 1 ván Xếp Khối", "Viết 1 dòng nhật ký". Có một nhiệm vụ dễ đến mức chỉ cần mở app là xong. Đủ 3 nhiệm vụ được một con dấu; 5 con dấu mỗi tuần mở rương (xu, vé gacha, đôi khi một món chỉ có trong rương). Không cộng dồn và không phạt khi bỏ | Cho người lười và người chơi game một lý do cụ thể để mở app; dạy dần các tính năng; nối Góc nhỏ với Hôm nay. Dữ liệu suy ra từ sổ cái nên khớp kiến trúc | M | **P0** |
| 2 | **Lịch sự kiện mùa và lễ Việt** | Tính offline (âm lịch qua `Calendar .chinese`): Tết (phòng có bánh chưng, câu đối, lì xì trong Giỏ Quà), Rằm tháng Giêng, Trung thu (đèn ông sao, truyện riêng), 20/10, 20/11 (sinh viên tặng thầy cô), Noel, mùa thi tháng 6 (thú cưng cổ vũ, bộ đồ sĩ tử). Mỗi sự kiện có lớp trang trí tạm, 3–5 món theo mùa trong shop hoặc gacha, câu thoại riêng, 2–3 khuôn truyện riêng. Món quay lại mỗi năm | "Có gì mới" là điều giữ người sưu tầm và người đã rời quay lại; văn hóa Việt là điểm khác biệt so với Finch. Nội dung viết một lần, dùng lại hằng năm | M (khung) + L (nội dung vẽ) | **P0** |
| 3 | **Kỷ vật chuyến đi thành đồ sưu tầm + kệ kỷ vật** | Mỗi chuyến đi tặng kỷ vật thật (tận dụng khoảng 50 kỷ vật sẵn có trong `Adventure.swift`, vẽ icon nhỏ). Có "Hộp kỷ vật" dạng lưới với ô "???", và một vị trí "Kệ kỷ vật" trong phòng học hoặc phòng ngủ để trưng 3–6 món. Sổ ký ức có hình kỷ vật cạnh mỗi truyện | Biến phần thưởng cảm xúc tốt nhất của app thành mục tiêu sưu tầm dài hạn không tốn xu; lấp vách đá sau cấp 10; tạo album kỷ niệm | M | **P0** |
| 4 | **Chuỗi ngày mềm + quà mốc** | Mốc 3, 7, 14, 30, 60, 100 ngày nhận quà (xu, vé, món riêng "Khăn chuỗi 30 ngày"). Mỗi tuần tự có 1 "ngày nghỉ phép", và khi chuỗi đứt app không thông báo gì tiêu cực. Mốc đã đạt giữ vĩnh viễn ("Kỷ lục chuỗi: 42"). Thêm "Quà chào mừng quay lại" sau 3 ngày vắng | Chuỗi ngày hiện chỉ là một con số. Quà mốc tăng giữ chân ngày 7 và 30 mà vẫn giữ triết lý không tội lỗi | S | **P0** |
| 5 | **Huy hiệu thành tựu (30–40 cái) + mốc tích lũy** | Ví dụ: "100 việc", "50 giờ tập trung", "30 trang nhật ký", "Mở đủ 5 phòng", "Leo 150 m", "Bánh kem 3 tầng", "Đủ bộ Rồng mây", "Đọc 50 chuyến đi". Có huy hiệu ẩn (dậy sớm 7 ngày, tập trung lúc nửa đêm). Huy hiệu hiện ở Tiến bộ và có thể đặt lên avatar | Mục tiêu dài hạn sau cấp 10, phục vụ cả 5 kiểu người; tính được hoàn toàn từ dữ liệu sẵn có | M | **P1** |
| 6 | **Thú cưng phản ứng và nhớ** | Luật và khuôn câu, không dùng AI: mood nhật ký thấp thì thú cưng an ủi và gợi ý bài thở; nhắc lại việc vừa làm ("Hôm qua bạn tập trung 90 phút đó!"); chào khi quay lại sau nhiều ngày; nói theo dịp (sinh nhật người dùng, nhập ở onboarding). Thêm hành vi theo giờ: ngủ trên giường sau 23h, phòng đổi ánh sáng ngày và đêm, kéo đồ ăn thả vào thú cưng (đã có trong backlog). Onboarding cho **chọn loài khởi đầu miễn phí** (mèo, vịt, thỏ, cún) | Đây là phần Finch làm tốt nhất: cảm giác được hiểu. Câu thoại hiện tại xoay vòng theo giờ và chưa "nhớ" gì. Chọn loài ngay từ đầu sửa sai lệch giữa icon vịt và mèo mặc định | M | **P1** |
| 7 | **Minigame có tiến trình + cân lại xu** | Thử thách ngày theo seed; nhiệm vụ trong game; mốc kỷ lục mở nền hoặc skin game; Sổ bánh của Gộp Bánh; Lật Thẻ mức Khó; Giỏ Quà theo mùa; quy đổi xu không ưu ái Lật Thẻ Dễ | Giữ kiểu người chơi số 5 thêm vài tuần; sửa lối cày méo | M | **P1** |
| 8 | **Gacha công bằng hơn và hồi hộp hơn** | Bụi sao đổi món tự chọn; vé miễn phí hằng tuần; viên nang đổi màu báo độ hiếm trước khi mở; màn mở Bí mật riêng; bóng đen của riêng món kèm tên bộ; thưởng đủ bộ; kệ máy theo mùa | Biến cảm giác "thuế 60 xu" thành mục tiêu dài hạn; tăng tò mò với món Bí mật | S–M | **P1** |
| 9 | **Thư tổng kết tuần/tháng + thẻ ảnh chia sẻ** | Tối Chủ nhật bạn nhỏ gửi "thư tuần": số việc, phút tập trung, ngày vui nhất (mood), chuyến đi thích nhất, kỷ vật mới. Cuối tháng có bản to hơn. Xuất PNG trên máy (dùng lại hạ tầng của avatar) để tự chia sẻ qua bảng chia sẻ của iOS | Nghi thức nhìn lại hằng tuần là lý do mở app của người chăm và người bận; ảnh là kênh truyền miệng duy nhất khi không có mạng xã hội | S–M | **P1** |
| 10 | **Thông báo dễ thương có giới hạn** | Tùy chọn, tối đa 2 mỗi ngày, chỉ nội dung tích cực: sáng "Hôm nay mình làm gì trước nhỉ?" (mở thẳng màn lên kế hoạch nhanh 3 việc); tối "Bông đi chơi về rồi, có chuyện kể!" khi năng lượng đã 100% mà chưa nghe; ngày lễ. Không bao giờ nhắc "đói" hay "bẩn" | Kéo người lười quay lại mà không phá triết lý không tội lỗi; chỉ dùng thông báo cục bộ sẵn có | S | **P2** |

**Quick win ngoài top 10** (mỗi việc cỡ S):
- Màn **lên cấp** có ăn mừng (hiện chưa có) và màn **lớn lên** riêng ở cấp 4 và cấp 10.
- Trailer mở đầu ghi "+10 XP · +5 xu" trong khi luật thật là +8 xu: sửa cho khớp.
- Thêm **% hoàn thành** ở Tủ đồ, Bộ sưu tập, từng phòng.
- **Lưu bộ phối tự tạo** (3–5 ô).
- Phòng đổi ánh sáng theo giờ thật (đèn bàn sáng buổi tối, trăng qua cửa sổ).
- Nhập việc nhanh bằng một dòng chữ ("Gọi mẹ 20h 15p"), dùng bộ phân tích đơn giản có luật.
- **Cảnh báo hết hạn ký:** app đọc ngày hết hạn trong `embedded.mobileprovision` (offline) và nhắc trước 2 ngày
  "Nhớ ký lại và xuất sao lưu". Với cách cài sideload 7 ngày, đây có thể là cứu cánh giữ chân thực tế lớn nhất,
  nhưng cần kiểm chứng file này còn trong bản Sideloadly ký lại.

**Thứ tự làm gợi ý:** 4 (S, nhanh có kết quả) → 1 → 3 → 2 (khung sự kiện trước, nội dung Tết là đợt đầu tiên)
→ 5 → 8 → 6 → 7 → 9 → 10.

---

## 7. Rủi ro khi thêm các tính năng này

- **Quá tải màn Hôm nay:** nhiệm vụ ngày nên ở Góc nhỏ hoặc một dải nhỏ có thể thu gọn, không thêm banner thứ ba
  vào Hôm nay.
- **Lạm phát xu:** mọi nguồn xu mới (rương, chuỗi ngày, huy hiệu) nên trả bằng vé, bụi sao hoặc món riêng nhiều hơn
  bằng xu, để không phá cân bằng 30–45 xu mỗi ngày đã tính.
- **FOMO:** đồ sự kiện phải quay lại mỗi năm, và nói rõ điều đó trong app ("Món này sẽ quay lại vào Trung thu năm sau").
- **Sao lưu:** tiến độ nhiệm vụ, huy hiệu và kỷ vật nên suy ra từ sổ cái và ngày (như năng lượng chuyến đi) để
  không phải tăng phiên bản lược đồ hay định dạng sao lưu khi không cần.
