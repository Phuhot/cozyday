# Storyboard trailer CozyDay (30 giây, dọc 1080×1920)

Phong cách: cozy nhưng có năng lượng. Nhân vật chính xuyên suốt là vịt con lông mật ong đội "Đám mây nhỏ", đúng con vịt trong icon app. Nhạc 120 BPM, các nhát cắt chính rơi vào phách (0,5 giây).

Ba loại hình ảnh, ghi rõ ở cột "Nguồn":

- **Cutscene**: diễn hoạt quảng cáo, vẽ bằng chính code vẽ của app (PetPainter, AvatarPainter, ItemPainter) qua harness `tools/harness_trailer.swift`. Không giả làm tính năng.
- **UI thật**: quay màn hình iOS Simulator chạy bản Debug của app. Thao tác do bản Debug tự bấm theo kịch bản, gọi đúng hàm mà nút/cử chỉ gọi (xem `Cozyday/App/PreviewMode.swift`, các màn `trailer…`).
- **Gameplay thật**: quay simulator khi minigame chạy bằng engine thật, bot của bản Debug điều khiển (giống video gameplay trong CI).

Kiểu chuyển cảnh dùng lại nhất quán: (1) zoom có định hướng, (2) object wipe bằng đồng xu, (3) match cut giữ vị trí thú cưng, (4) chuyển theo hành động (cú nhảy).

| Thời gian | Nguồn | Hình | Title | Chuyển cảnh / âm thanh |
|---|---|---|---|---|
| 0,0–0,4 | Cutscene | Vịt bật lên giữa khung, to, nhìn thẳng người xem | | Pop |
| 0,2–1,4 | Cutscene | 5 thẻ việc (đúng tên việc trong dữ liệu mẫu của app) bay vào lộn xộn, nghiêng, rung nhẹ | "Ngày hơi rối?" (0,45) | Vút ×5 |
| 1,45 | Cutscene | Vịt nhảy một cái, vòng sóng tỏa ra; thẻ việc thẳng hàng thành một dòng thời gian 7:00 → 18:30, vịt thu nhỏ xuống dưới | | Boing + tick tick |
| 2,0–2,85 | Cutscene | Vịt vui, tim bay | "Có mình đây!" | Pop + lấp lánh |
| 2,55–3,0 | Cutscene | Zoom có định hướng vào thẻ "Trả lời email của nhóm" | | Vút |
| 3,0–4,1 | UI thật | Cận cảnh đúng việc đó trên màn Hôm nay; nút tròn được bấm, việc chuyển xong | | Tick + chuông |
| 4,1–6,45 | UI thật | Lùi máy: popup thưởng của app (mức thưởng do app tự tính) và thú cưng nảy lên | "Việc nhỏ. Niềm vui lớn." (hai cụm) | Pop |
| 6,45–7,0 | Chuyển | Đồng xu lăn ngang qua khung, phía sau là cảnh mới | | Tiếng xu |
| 7,0–7,9 | UI thật | Tủ đồ của app đang mặc thử đồ; zoom vào thú cưng | | Vút |
| 7,9–12,0 | Cutscene (ảnh đại diện thật) | Thẻ ảnh đại diện, vịt giữ nguyên vị trí, đổi 6 bộ phối theo phách: Đầu bếp (8,0), Thủy thủ (8,5), Mũ cói + vòng hoa (9,0), Phù thủy (9,5), Vương miện + cánh (10,0), Đám mây nhỏ (10,5). Nền và phong cảnh là lựa chọn có thật của Ảnh đại diện | "Một bạn nhỏ. Nhiều cá tính." | Pop mỗi lần đổi (match cut) |
| 12,0–13,5 | UI thật | Cho ăn: khay đồ ăn, thú cưng ăn ba miếng, kết quả bữa ăn | "Chăm chút mỗi ngày." | Vút |
| 13,5–15,3 | UI thật | Nựng: thú cưng híp mắt, tim bay, popup chăm sóc. Đoạn này chậm lại (0,8×) | | Lấp lánh |
| 15,3–17,0 | UI thật | Dọn nhà: chổi lông gà quét mạng nhện, khăn lau vết bẩn, "Sạch bong" (tua nhanh 1,6×) | | Tiếng lau + chuông |
| 17,0–19,0 | Gameplay thật | Nhảy Mây: nảy lên các đám mây | "Chơi một chút!" | Chuyển theo hành động, boing |
| 19,0–21,0 | Gameplay thật | Giỏ Quà: hứng liên tiếp đồ tốt | | Vút |
| 21,0–23,0 | Gameplay thật | Lật Thẻ: ghép cặp cuối, bảng kết quả | | Vút |
| 23,0–25,35 | Cutscene | Phòng ngủ đẹp nhất (giường rèm, đèn mặt trăng, thảm cầu vồng, gấu bông; đều là đồ trong Catalog), vịt nhảy ăn mừng 3 lần, sao và tim bung ra, máy đẩy vào | | Boing ×3, lấp lánh |
| 25,35–26,0 | Chuyển | Vòng tròn khép dần về phía vịt (thu mọi thứ về giữa) | | Vút lên |
| 26,0–26,5 | End card | Icon thật trong asset catalog bật lên có độ nảy, bóng mềm | | Pop + hợp âm kết |
| 26,35 | End card | Chữ "CozyDay" | | |
| 26,45–26,9 | End card | Vịt nhảy ra, ngồi tựa góc icon | | |
| 26,75–27,3 | End card | Vệt sáng lướt qua icon | | Lấp lánh |
| 26,8–27,4 | End card | "Một ngày gọn hơn." / "Một góc nhỏ vui hơn." | | |
| 27,35 | End card | Dòng nhỏ "Bản dùng thử" | | |
| 27,4–30,0 | End card | Giữ yên bố cục (vịt chớp mắt, lấp lánh nhẹ). Khung cuối dùng làm ảnh bìa | | Nhạc ngân, tắt dần |

Ghi chú:

- Tên trên màn kết là "CozyDay", đúng tên hiển thị hiện tại của app (đã đổi từ "Cozyday" theo yêu cầu trước).
- Không có huy hiệu App Store hay đường tải.
- Không dùng thiết kế đồ chưa có trong app; danh sách món ở `tools/frames.py`.
