# CozyDay: đánh giá UX/UI (iOS, phong cách cozy/cute)

Người đánh giá: UX/UI tester (vai trò). Chỉ đánh giá, không sửa repo.
Nguồn: 88 ảnh trong `docs/screenshots/` (iPhone 17 Pro simulator, commit `ce1f209`, chụp lúc 19:01 giờ VN), `docs/UI_PREVIEW_VI.md` và code trong `Cozyday/Features/*`, `Cozyday/DesignSystem/*`.

Ghi chú về bộ ảnh:
- `12-wardrobe.jpg` giống hệt `07-corner.jpg`. Sheet Tủ đồ chưa kịp mở khi CI chụp. Tủ đồ chế độ sáng chỉ còn `49-wardrobe-secret.jpg`.
- `15-pet-gallery.jpg` / `dark-15-pet-gallery.jpg` là màn chỉ có trong bản Debug (`App/CozydayApp.swift`), người dùng không thấy.
- `53-focus-mini.jpg`: đồng hồ nhỏ đang che nút "+". Lỗi này đã được sửa ở commit `8480cd1`, sau lúc chụp (chuyển sang góc trái, `Features/Root/RootView.swift`). Cần chụp lại để xác nhận.
- Ảnh tĩnh không cho thấy animation. Theo code thì thú cưng có thở, chớp mắt, đi lại, tim bay khi chạm (`Corner/PetArt.swift`, `Corner/RoomArt.swift`).

---

## 0. Tóm tắt

Điểm mạnh:
- Bộ nhân vật rất đẹp và đồng nhất: 11 loài, hình tròn chibi, má hồng, nét mảnh, phụ kiện dễ thương (`15-pet-gallery.jpg`, `23-collection.jpg`). Đây là tài sản lớn nhất của app.
- Năm căn phòng vẽ kỹ, màu pastel hài hòa. Khu vườn đẹp nhất (`22-garden.jpg`).
- Bộ minigame thống nhất phong cách: thẻ lật, bánh kẹo của Gộp Bánh, khối thạch của Xếp Khối (`35`, `43`, `44`).
- Tab Tập trung đã thành màn riêng, vòng đếm lớn, nút rõ (`06`, `50`). Phàn nàn "pomodoro mờ nhạt" về cơ bản đã giải quyết.
- App có hỗ trợ Dynamic Type thật sự. Phần lớn màn vẫn dùng được khi chữ rất lớn, và Hôm nay tự chuyển sang dạng Danh sách.

Vấn đề lớn nhất:
1. **Tương phản thấp có tính hệ thống.** Nút "mềm" (chữ cùng màu với nền nhạt 14%) chỉ đạt 2.0:1 (Cho ăn, Nựng, Sắp xếp lại), 2.75:1 (Dọn nhà) và 3.1:1 (Hộp chờ). Giá "xu" màu mật ong đạt 2.2:1. Chữ trắng trên nút cam đào đạt 2.27:1 (Quay 1 lượt). Ở chế độ tối, số ngày trên lịch tâm trạng chỉ còn khoảng 1.5–1.7:1 (`dark-09-journal.jpg`).
2. **Góc nhỏ vẫn dài và giống bảng điều khiển.** Từ trên xuống có: tên, cấp, giai đoạn, chọn phòng, phòng, dòng hướng dẫn, thẻ chăm sóc (3 thanh, 3 nút to, 1 dòng ghi chú), 6 ô tính năng, thẻ chuyến đi, thẻ tuần. Tủ đồ, Gacha và Sân chơi nằm dưới mép màn hình đầu tiên (`07`, `25`).
3. **Màn đầu của Hôm nay bị header chiếm chỗ.** Ngày được hiện 3 lần, thêm bong bóng thú cưng, 2 băng rôn và mục "Chưa xếp giờ". Timeline, thứ quan trọng nhất, bắt đầu ở khoảng 80% chiều cao màn hình. Nút "+" lại che dấu tick của việc đầu tiên (`02-today.jpg`).
4. **Onboarding dài nhưng thiếu khoảnh khắc cảm xúc.** Người dùng đi qua 9 màn (video, 5 trang tour, 3 bước thiết lập) nhưng không được chọn thú cưng. Tour cũng không nhắc tới tab Tập trung và Nhật ký (`01`, `45`, `Onboarding/*.swift`).
5. **Gacha chưa "đã".** Máy đứng yên, kết quả tự lật mỗi 0,18 giây, thẻ kết quả nhỏ, độ hiếm chỉ thể hiện bằng nền gần như xám nên nhìn không ra (`46`, `47`).
6. **Một số chỗ vỡ khi chữ lớn.** "Ngẫu nhiên" bị bẻ thành từng chữ cái (`large-41-avatar.jpg`). "Đã sạch 1/8" bị cắt thành "Đã sạc…", đọc ra nghĩa khác (`large-28-clean.jpg`). "Cấp / 6" xuống dòng (`large-07-corner.jpg`).
7. **Giao diện chưa nhất quán.** Ba sheet dùng Form nền xám hệ thống (`03`, `11`, `18`) trong khi các sheet còn lại dùng nền kem. Tiêu đề lớn dùng font SF đen tuyền (`09`, `10`), không phải font rounded màu tím than. Đóng sheet lúc là "Đóng", lúc là "Xong", lúc bên trái, lúc bên phải. Viền "đang chọn" có ba màu khác nhau.

---

## 1. Đánh giá từng màn

### 1.1 Onboarding & tour

| Ảnh | Nhận xét |
|---|---|
| `01-onboarding.jpg` | Khung hình đầu là video quay màn hình app, bị mờ và phóng to: timeline, việc gạch ngang, hai việc chồng nhau bị cắt "Học Swif…", "Gọi điện…". Ấn tượng đầu tiên là "app lịch", trong khi thú cưng mới là thứ tạo khác biệt. Chú thích "Việc nhỏ." nằm trong một pill mờ đè lên nội dung. Pill "+10 XP · +5 xu" ở đáy bị video cắt mất một nửa. Thưởng trong video là +5 xu, trang tour 1 lại ghi +8 xu, hai con số không khớp. |
| `45-tour.jpg` | Sạch, thoáng, thứ bậc rõ: minh họa, tiêu đề lớn, mô tả. Có cả "1/5" lẫn chấm trang, hai thứ cùng một việc. Tour có 5 trang (Ngày gọn gàng, Bạn nhỏ, Trang trí, Sân chơi & gacha, Mẹo) nhưng **không có trang nào cho Tập trung (Pomodoro) và Nhật ký**, dù đây là 2 trong 5 tab. Trang 4 (`TourPlayArt`) dùng icon SF trong ô tím, kém dễ thương hơn hẳn các trang khác. |
| (code) `OnboardingView.swift` | Ba bước: tên + tên thú, mục tiêu, thói quen. Người dùng **không được chọn loài thú**: mặc định là mèo đội mầm lá, muốn loài khác phải mua (Thỏ 60–85 xu). Ô nhập dùng `.roundedBorder` mặc định của hệ thống nên lạc tông. |

### 1.2 Hôm nay

| Ảnh | Nhận xét |
|---|---|
| `02-today.jpg` | Ngày hiện 3 lần: "Hôm nay" (tiêu đề), "Thứ ba, 20 tháng 10", "Tháng 10, 2026" và dải tuần. Bong bóng thoại cạnh thú cưng đẹp, nhưng câu "Tối rồi, hôm nay An vất vả rồi." lặp chữ "rồi". Hai băng rôn (Hộp chờ, việc trễ) xếp chồng, đều là nút "mềm" tương phản thấp (3.1:1 và 2.0:1). Biểu tượng hộp chờ ở góc trái **trùng chức năng** với băng rôn Hộp chờ. Biểu tượng đồng hồ ở góc phải **trùng chức năng** với tab Tập trung. Timeline bắt đầu ở y≈1030/1300. Nút "+" đè lên dấu tick của "Đi bộ 30 phút", dễ bấm nhầm. Nhãn "Timeline" là tiếng Anh, đứng cạnh "Danh sách" là tiếng Việt. |
| `03-task-editor.jpg` | Form nền xám hệ thống (#F2F2F7), lệch tông kem của app. Muốn thêm nhanh một việc phải đi qua nhiều mục (Việc con, Nhóm & ưu tiên, Thời gian…). Ngày hiển thị theo định dạng hệ thống "ngày 20 thg 10, 2026", khác cách viết "Thứ ba, 20 tháng 10" ở màn Hôm nay. Nút "Lưu" bị vô hiệu khi trống, nhìn gần giống nút "Hủy". |
| `04-replan.jpg` | Sheet rõ ràng, phần "18:00 → 20:00" dễ hiểu. Đoạn giải thích 3 dòng dày đặc, có dấu chấm phẩy (xem mục câu chữ). |
| `05-inbox.jpg` | Nút "+" là hình tròn tím đặc, khác hẳn các nút header dạng pill kem ở màn khác. "Đóng" nằm bên trái, trong khi đa số sheet đặt "Xong" bên phải. Không có thao tác vuốt để xếp lịch nhanh. Khoảng trống lớn bên dưới chưa được dùng: có thể thêm gợi ý hoặc minh họa. |
| `17-task-detail.jpg` | Nút chính "Hoàn thành" bị mép sheet cắt ở mức chiều cao trung bình. Người dùng phải kéo sheet lên mới thấy "Tập trung", "Đổi ngày/giờ", "Sửa". |
| `53-focus-mini.jpg` | Đồng hồ nhỏ che nút "+" (đã sửa sau lúc chụp). Biểu tượng "brain.head.profile" trong pill khác biểu tượng đồng hồ của tab Tập trung. |
| `01` (khung timeline) | Hai việc trùng giờ bị chia đôi cột, tiêu đề và giờ đều bị cắt ("11:3…"). `DayTimeline.swift` dòng 181 đặt `lineLimit` 1–2 theo số cột. |

### 1.3 Tập trung (Pomodoro)

| Ảnh | Nhận xét |
|---|---|
| `50-focus-idle.jpg` | Thứ bậc tốt: vòng tròn lớn, 25:00 to, nút "Bắt đầu 25 phút" nổi bật. Có điều cần sửa: (a) "2/6 phiên" và 4 chấm (2/4, tính theo chu kỳ tới giờ nghỉ dài) đặt cạnh nhau nên đọc như hai con số mâu thuẫn. (b) "Không gắn việc ⌃" trông như chữ thường, khó nhận ra là menu. (c) Hai nút góc là thanh trượt (cài đặt hẹn giờ) và bánh răng (cài đặt app), dễ nhầm với nhau. (d) Chip âm nền bị mép phải cắt cụt "Tiếng ồn nâu", không có hiệu ứng mờ dần báo rằng còn cuộn được. Thú cưng trong vòng khá nhỏ, chỉ khoảng 1/4 đường kính. |
| `06-focus.jpg` | Lúc đang chạy có tên việc phía trên, "phiên 3/4" dưới số giờ. Màn lúc này hiện **ba con số đếm phiên** (2/6, 2 trên 4 chấm, 3/4), quá nhiều. "Tạm dừng" màu xám tím đậm, "Kết thúc" hồng nhạt. Thứ tự ưu tiên vậy là đúng. |
| `51-focus-settings.jpg` | Nền kem, thẻ trắng: đây là mẫu Form đúng phong cách mà các Form khác nên theo. Preset 25/5, 50/10, 90/15 hữu ích, nhưng không cho biết preset nào đang chọn. |
| `52-focus-full.jpg` | Tối giản, đẹp. Nút thu nhỏ ở góc nhỏ và xám, khó thấy. Màn toàn màn hình không có nút tạm dừng, cũng không có gợi ý "chạm để hiện điều khiển". |
| `large-06-focus.jpg` | "2/6 phiên · / 50 phút" xuống dòng xấu. Nút Tạm dừng/Kết thúc bị đẩy xuống dưới thanh tab, phải cuộn mới thấy nút điều khiển chính. |

### 1.4 Góc nhỏ (thú cưng)

| Ảnh | Nhận xét |
|---|---|
| `07-corner.jpg`, `19`–`22` | Phòng đẹp, là "hero" đúng nghĩa. Phía trên phòng có 4 tầng thông tin: tên + bút, cấp + thanh XP, dòng "Đang lớn · lớn thành 'Trưởng thành' ở cấp 10" (chữ xanh lá, 3.0:1), chip chọn phòng. Chip phòng bị cắt "Bếp & b". Ở `21-bath.jpg`, chip "Phòng tắm" đang chọn **nằm ngoài màn hình** nên không biết mình đang ở phòng nào. Dòng hướng dẫn "Chạm để vuốt ve, vuốt qua lại để nựng…" hiện mãi, nên chỉ hiện vài lần đầu. |
| `25-care.jpg` | Thẻ chăm sóc có 3 thanh tiến độ và 3 nút to cao khoảng 70pt, cùng kích thước nên không nút nào nổi bật hơn. "Cho ăn" có chữ cam đào trên nền cam đào nhạt (2.0:1). Khi đói, nút cần bấm nhất lại không nổi bật. Ghi chú "Thưởng chăm sóc hôm nay: 0/12 XP · 0/6 xu…" dài. Lưới 6 ô (Sân chơi, Gacha, Tủ đồ, Trang trí, Bộ sưu tập, Ảnh đại diện) dùng icon SF trong vòng tròn màu, chung chung so với chất lượng tranh vẽ. Khi cuộn lên, tiêu đề "Góc nhỏ" và nút bánh răng đè lên tranh phòng, không có nền mờ. |
| `13-adventure.jpg` | Câu chuyện hay, giọng văn ấm. Chỉ minh họa bằng thú cưng trong vòng tròn tím, không có cảnh "quán trà ven đường" và không có món kỷ vật. |
| `14-memories.jpg` | Một bức tường chữ: ngày, tiêu đề, đoạn văn, lặp lại. Không có hình kỷ vật (viên đá có sọc, lông chim sẻ…), không có tem hay ảnh. Đây là chỗ "nhạt" nhất trong khi nội dung rất có tiềm năng. |
| `26-food.jpg` | Thẻ món ăn: nút "Mua · 3 xu" rộng làm phần chữ bên trái bị ép, nên "+15 no bụng · +3 / vui vẻ" bị ngắt dòng. "Đang có 3" và mô tả vị nằm chung một dòng. Đoạn mở đầu "Đồ ăn là vật phẩm dùng một lần…; món đắt chỉ để đổi vị" có dấu chấm phẩy, giọng văn kỹ thuật. |
| `27-feed.jpg`, `29-care-capped.jpg` | Phản hồi tốt: thú cưng, "Bông ăn ngon lành!", "+2 XP · +1 xu", "No bụng: 24 → 42". Câu "Hôm nay đã nhận đủ thưởng cho việc này" khá mơ hồ. Dòng cuối "Đồ ăn trong game là đồ ăn tưởng tượng… không phải hướng dẫn dinh dưỡng cho thú thật" làm mất không khí. Cho ăn nên có tương tác trực tiếp, ví dụ kéo món vào miệng thú. Hiện chỉ có nút. |
| `28-clean.jpg` | Ý tưởng chổi lông gà và khăn lau rất dễ thương. Nửa dưới màn hình trống, trong khi tranh phòng có thể to hơn. Hai ô dụng cụ cao khoảng 140pt nhưng icon bên trong nhỏ. Bụi xám phủ lên thú cưng trông hơi bẩn thật. Có thể cho thú nhảy ra chỗ khác trong lúc dọn. |
| `49-wardrobe-secret.jpg`, `dark-12-wardrobe.jpg` | Bóng đen của món bí mật gợi tò mò tốt. Nút "Món bí mật: thử vận may ở máy gacha" dẫn sang gacha, hợp lý. Thẻ đồ vẽ **cả con thú nhỏ** nên phụ kiện chỉ chiếm vài pixel ("Kẹo mút", "Bóng bay" khó thấy). Chấm màu xanh/tím ở góc thẻ là ký hiệu độ hiếm nhưng không có chú giải. |
| `08-shop.jpg`, `48-shop-floor.jpg` | Lưới 3 cột đẹp. Tên dài xuống 2 dòng ("Giường / mèo hồng") làm thẻ cao thấp lệch nhau. Có hai mục "Tường & sàn" và "Sàn" khiến người dùng không rõ khác nhau ở đâu. Món khóa "Mở ở cấp 7" chỉ bị làm mờ, không có biểu tượng ổ khóa. |
| `23-collection.jpg`, `24-look.jpg` | Ba con số đầu trang (2/47 bộ phối, 8/81, 36/118) tạo động lực sưu tầm tốt. **Giá không khớp**: Thỏ ở đây là 85 xu (giá cả bộ), trong Tủ đồ là 60 xu (chỉ hình dạng). Capybara 125 xu ở lưới nhưng là "Hình dạng · 90 xu" trong chi tiết. Cần ghi rõ "cả bộ". |
| `41-avatar.jpg`, `42-avatar-outfit.jpg` | Khung ảnh đại diện cầu vồng rất đẹp, đáng để khoe. Nút bật/tắt "Hiện tên & cấp" dạng `.toggleStyle(.button)`: khi bật trông như nút bị vô hiệu, không phân biệt được bật hay tắt. "Ngẫu nhiên" chữ cam đào trên nền nhạt (2.0:1). Tên nền trộn tiếng Anh ("Lavender"). Chip phụ "Cổ" bị cắt. "Hình dạng" là thuật ngữ khó hiểu, nên dùng "Loài". |

### 1.5 Sân chơi & minigame

| Ảnh | Nhận xét |
|---|---|
| `30-playground.jpg` | Mỗi game là một thẻ to (ảnh, tên, kỷ lục, mô tả, nút Chơi). Với 5 game, người dùng phải cuộn khoảng 3 màn. Dòng "Hình dạng: mèo (đang dùng)" dùng thuật ngữ khó hiểu. "Sân chơi là giờ nghỉ ngắn. Việc chính… vẫn cho nhiều xu hơn" mang giọng dạy dỗ. |
| `31-pick-pet.jpg` | Loài chưa có hiện xám kèm ổ khóa, rõ ràng. Đoạn giải thích 3 dòng ở đầu dài. |
| `32-tutorial.jpg` | Thẻ hướng dẫn 3 bước đánh số, gọn và dễ hiểu. Mây giông của game nền lọt lên vùng thanh trạng thái (góc trái trên, có tia sét cạnh giờ). |
| `33`, `39-*` (Nhảy Mây) | Nền tím hồng đẹp, HUD gọn. Mây đứt nét, mây giông có mặt cau có, dễ đọc. Điểm "+3" màu vàng nâu dễ thấy. |
| `34`, `40-*` (Giỏ Quà) | Vật phẩm rơi từ **trên thanh trạng thái và Dynamic Island**, đi qua nút tạm dừng và HUD (`40-basket-frames-1/3/4`). Nút tạm dừng đặt trên một đám mây trang trí nên trông như bị dính vào mây. Chữ "+1" và "+2" màu xanh xám nhạt, gần như không thấy (`34`, `40-3`). |
| `35-memory.jpg`, `dark-35` | Đẹp. Lưng thẻ tím có dấu chân, thẻ đã ghép có viền xanh và dấu tick. Có một khoảng trống khoảng 120pt giữa bong bóng thoại và lưới thẻ. |
| `43-blocks.jpg` | Khối thạch bóng bẩy. Ô trống xen hai tông nên lưới hơi rối mắt. Ba khối chờ ở khay nhỏ khoảng 1/3 kích thước thật, ô khay thì to và trống. "+10" mờ trên lưới. |
| `44-merge.jpg` | Bánh kẹo dễ thương, có số cấp. Có 4 nút mũi tên, tốt cho trợ năng. Một bóng chữ mờ còn sót cạnh bong bóng "Ngon quá!" (hiệu ứng chuyển tiếp chồng nhau). |
| `36-pause.jpg` | Rõ ràng. Câu chữ hơi dài, xem mục câu chữ. |
| `37`, `38` (kết quả) | Rõ ràng: kỷ lục, bảng số, "+5 xu", hạn mức. Thú cưng giữ nguyên dáng như mọi màn khác, chưa có biểu cảm ăn mừng riêng. Cũng không thấy pháo giấy (cần kiểm tra trên máy). |

### 1.6 Gacha

| Ảnh | Nhận xét |
|---|---|
| `46-gacha.jpg` | Máy hồng và viên nang màu đẹp nhưng nhỏ, khoảng 210pt, và đứng yên. Theo `GachaView.swift`, máy chỉ chuyển động 1,35 giây khi quay. Đoạn mô tả 3 dòng cạnh số xu bị ép hẹp. "Quay 10 lượt · 540 xu" là rẻ 10% nhưng không ghi ra. Thẻ "Còn 10 lượt chắc chắn có món Quý" là thiết kế minh bạch, tốt. Kệ trưng bày "???" có bóng đen tạo tò mò tốt. Không thấy bảng tỉ lệ trên màn đầu, dù tài liệu nói có. |
| `47-gacha-result.jpg` | Tiêu đề "Có món quý nè!" tím. Mười thẻ nền xanh xám, xám hoặc tím nhạt, **độ hiếm gần như không nhìn ra**: không có nhãn "Quý/Hiếm", không có ánh sáng, không có viền màu. Mỗi thẻ là cả con mèo mặc thêm một món nhỏ, ví dụ "Dây cỏ bốn lá" gần như không thấy. Theo code, thẻ tự lật mỗi 0,18 giây (`GachaResultView`), người dùng không được tự bấm mở viên nang nên mất phần hồi hộp. |
| `large-46-gacha.jpg` | Bố cục chữ lớn hợp lý (tiêu đề sang trái, số xu một dòng riêng). |

### 1.7 Nhật ký, Thở, Tiến bộ, Cài đặt

| Ảnh | Nhận xét |
|---|---|
| `09-journal.jpg` | Tiêu đề lớn "Nhật ký" màu đen tuyền, font SF thường, khác phong cách rounded tím than ở các tab khác. Lịch tâm trạng chỉ có ô màu. Chú giải nằm dưới thanh tab nên bị che khi chưa cuộn. Có thể vẽ mặt cảm xúc nhỏ vào ô cho dễ thương. |
| `18-journal-editor.jpg` | Form xám hệ thống. Thứ tự là Gợi ý, Tâm trạng, Ghi chú, nhưng chọn tâm trạng mới là việc nhanh và chính nên đặt lên đầu. Mặt cảm xúc nhạt màu, nhỏ, không có trạng thái chọn rõ. Nhãn ô viết là "Ghi chú", nghe như ghi chú công việc. Câu "lưu dạng chữ thường trên máy" dễ hiểu nhầm là chữ không viết hoa. |
| `16-breathing.jpg` | Gọn, rõ. Nút "Bắt đầu" xanh lá trong khi nút chính ở các màn khác là tím, chấp nhận được vì màu theo chủ đề. |
| `10-progress.jpg` | Tốt: thẻ "An & Bông", 4 ô thống kê, biểu đồ. Nhãn "7 ngày / 30 ngày" và số xu nằm cùng hàng, hơi lạ chỗ. |
| `11-settings.jpg` | Form xám hệ thống. Đoạn giải thích thông báo 4 dòng dài. Còn lại là cài đặt chuẩn, ổn. |

---

## 2. Chế độ tối

Nhìn chung làm tốt: nền tím than #24222E, thẻ #2F2C3B, nút chính tím sáng với chữ tối (7.6:1). Tranh phòng giữ màu và chỉ hơi tối đi.

| Ảnh | Vấn đề |
|---|---|
| `dark-09-journal.jpg` | **Lỗi tương phản nặng nhất app.** Số ngày dùng `Palette.ink`, ở chế độ tối là gần trắng (#F3EEF8), đặt trên ô tâm trạng pastel (vàng, be, xanh lá) chỉ được khoảng 1.5–1.7:1. Các ô "8", "12", "18" gần như không đọc được. Code ở `Journal/JournalView.swift` dòng 189–192. |
| `dark-25-care.jpg` | Ba nút chăm sóc thành nâu đục, xám xanh và nâu hồng. Chữ đọc được (5.6:1) nhưng trông bẩn, mất vẻ pastel. |
| `dark-07`, `dark-19` | Phòng vẫn là ban ngày (trời xanh, mặt trời) dù đang 19:00 và đang bật giao diện tối. Đây là cơ hội làm "đèn ngủ, trời sao" rất cozy. |
| `dark-46-gacha.jpg` | Ổn. Bóng món bí mật màu xám sáng, không lộ chi tiết. |
| `dark-41-avatar.jpg`, `dark-37`, `dark-35`, `dark-10` | Ổn. |
| `dark-52-focus-full.jpg` | Giống hệt bản sáng vì màn toàn màn hình luôn tối. Hợp lý. |

---

## 3. Chữ cỡ Trợ năng (rất lớn)

Đáng khen: hầu hết màn co giãn được. Hôm nay chuyển sang Danh sách, Gacha chuyển tiêu đề sang trái.

| Ảnh | Vấn đề | Gợi ý sửa |
|---|---|---|
| `large-41-avatar.jpg` | "Ngẫu nhiên" bị bẻ thành "Ngẫ / u / nhiê / n". Tên nền bị cắt "Trời hồ…", "Laven…". | `Avatar/AvatarViews.swift` khoảng dòng 208: bọc `HStack` trong `ViewThatFits { HStack… ; VStack… }`. Lưới nền nên giảm còn 2 cột khi `dynamicTypeSize.isAccessibilitySize`. |
| `large-28-clean.jpg` | "Đã sạch 1/8" bị cắt thành "**Đã sạc…**", đọc ra nghĩa khác hẳn. "Chổi lôn…" bị cắt. Đoạn hướng dẫn chạm vào ô dụng cụ. | `Care/CareViews.swift` khoảng dòng 241–262: ở cỡ trợ năng, đưa thanh tiến độ xuống dưới tiêu đề (VStack) và cho dòng "Đã sạch" `.fixedSize()`. Dụng cụ xếp dọc. |
| `large-07-corner.jpg` | "Cấp" và "6" bị tách thành 2 dòng. | `Corner/CornerView.swift` dòng 260: thêm `.fixedSize()` cho `Text("Cấp …")`. |
| `large-25-care.jpg` | "No / bụng", "Nhà / sạch", "24 · Cần / chăm" xuống dòng từng chữ. | `NeedRow` dùng `ViewThatFits`: nhãn một dòng, giá trị xuống dòng dưới. |
| `large-06-focus.jpg` | "2/6 phiên · / 50 phút". Nút Tạm dừng nằm dưới thanh tab. | Tách "50 phút" thành dòng riêng. Ở cỡ trợ năng, thu nhỏ vòng tròn và ẩn thú cưng trong vòng. |
| `large-02-today.jpg` | Băng rôn Hộp chờ dài 3 dòng, nút "+" đè lên chữ. Ngày tháng chiếm 2 hàng. | Bỏ băng rôn Hộp chờ, dùng huy hiệu số trên icon hộp chờ. Hoặc chuyển "+" lên thanh điều hướng. |
| `large-03-task-editor.jpg`, `large-26-food.jpg` | Segmented control của hệ thống (Thấp/Vừa/Cao, Khay/Mua) không phóng to theo, lệch hẳn so với chữ xung quanh. | Thay bằng chip tự vẽ có hỗ trợ Dynamic Type, hoặc Picker `.menu`. |
| `large-37-result.jpg` | Nút "Chơi lại" bị đẩy xuống mép, phải cuộn. | Ghim nút ở đáy thẻ, nội dung phía trên cuộn được. |
| `large-30-playground.jpg` | Nút "Chơi" ở dưới màn thứ 2. | Ở cỡ trợ năng, rút gọn thẻ đầu (bỏ đoạn giải thích). |

---

## 4. Nhất quán hệ thống

| Hạng mục | Hiện trạng | Đề xuất |
|---|---|---|
| Nền sheet | Form xám hệ thống ở `03`, `11`, `18`. Nền kem ở `51`, `26`, `46`… | `.scrollContentBackground(.hidden).cozyBackground()` cho `TaskEditorView.swift:38`, `SettingsView.swift:35`, `JournalView.swift:279`, giống `FocusSettingsView.swift:93`. |
| Font tiêu đề | Tiêu đề điều hướng (lớn và nhỏ) dùng SF mặc định đen tuyền. Nội dung dùng `.rounded` màu `ink`. Không có cấu hình `UINavigationBar.appearance()` nào. | Đặt `largeTitleTextAttributes`/`titleTextAttributes` dùng font rounded và màu `Palette.ink`. Hoặc tự vẽ header cho mọi tab. |
| Kiểu header tab | Hôm nay, Tập trung, Góc nhỏ dùng tiêu đề nhỏ. Nhật ký, Tiến bộ dùng tiêu đề lớn. | Chọn một kiểu. Đề xuất tiêu đề nhỏ cho cả 5 tab. |
| Nút đóng sheet | "Đóng" trái (`05`), "Đóng" phải (`16`, `17`), "Xong" phải (`08`, `11`, `14`, `26`, `46`), "Hủy/Lưu" (`03`, `18`, `41`). | Sheet chỉ để xem dùng "Xong" bên phải. Sheet chỉnh sửa dùng "Hủy" trái, "Lưu" phải. |
| Viền "đang chọn / đang dùng" | Xanh lá (`08`, `16`, `49`), tím (`31` "Đang dùng", `dark-12` xem thử), cam đào (`42` "Mũ len"). | Quy ước xanh lá = đang dùng, tím = đang xem thử. Bỏ cam đào. |
| Chip chọn | Cấp 1 tím (phòng, tab ảnh đại diện), cấp 2 cam đào chữ trắng (2.27:1). Segmented hệ thống ở chỗ khác. | Chip cấp 2 dùng nền `lavenderSoft` + chữ `ink` + viền. Giảm bớt segmented hệ thống. |
| Icon | Icon tab trộn nét mảnh (mặt trời, đồng hồ) với khối đặc (chân, sách, cột). Icon mini bar "brain.head.profile" khác icon tab "timer". Icon trong ô Góc nhỏ là SF chung chung. | Dùng một biểu tượng duy nhất cho Tập trung ở tab, header, mini bar. Ô Góc nhỏ nên dùng mini-illustration (máy gacha mini, tủ áo mini) vẽ bằng `ItemPainter`. |
| Góc bo | Token `Radius` 10/16/22/28 được dùng đều. Ổn. | — |
| Đồng xu | Xu chân mèo nhất quán ở mọi nơi. Tốt. | — |
| Tên gọi thú cưng | "thú cưng" (Cài đặt, tour), "bạn nhỏ" (onboarding, Sân chơi), "bạn chơi", tên riêng "Bông". | Văn bản hệ thống dùng tên riêng, chỉ dùng "thú cưng" khi bắt buộc. Bỏ "bạn nhỏ" vì dễ lẫn với "bạn" là người dùng. |

---

## 5. Luồng & khả năng tìm tính năng

### 5.1 Lần đầu mở app
Luồng hiện tại: Video (1 màn), Tour (5 màn), Thiết lập (3 bước), rồi Hôm nay trống với empty state "Bấm nút + để thêm việc".
- Tối thiểu khoảng 9 lần chạm trước khi dùng được app. Mức này chấp nhận được với app có trò chơi hóa, nhưng **thiếu khoảnh khắc gắn bó**: không chọn hay ấp thú, không có cảnh thú cưng chào mình lần đầu.
- Tour bỏ sót Tập trung và Nhật ký.
- Sau onboarding không có hướng dẫn tại chỗ (coach mark). Người mới không biết Tủ đồ, Gacha, Sân chơi nằm cuối tab Góc nhỏ.
- "Bỏ qua" ở video nhảy thẳng tới Thiết lập. Hợp lý.

### 5.2 Số lần chạm cho thao tác thường dùng

| Thao tác | Đường đi hiện tại | Lần chạm | Nhận xét |
|---|---|---|---|
| Đánh dấu xong việc | Chạm vòng tròn | 1 | Tốt. |
| Thêm việc có giờ | + → gõ tên → bật giờ → chọn giờ → Lưu | 4–5 + gõ | Nên có thêm nhanh: gõ "Học Swift 19h" rồi Enter. |
| Bắt đầu Pomodoro | Tab Tập trung → Bắt đầu | 2 | Tốt. |
| Pomodoro cho một việc | Giữ lâu việc → "Tập trung cho việc này" → Bắt đầu | 3 | Context menu khó phát hiện. Nên có nút ▶ trên dòng việc đang tới giờ. |
| Cho ăn | Tab Góc nhỏ → cuộn → Cho ăn → Cho ăn (món) → Xong | 4 + cuộn | Nên có nút ăn ngay trên tranh phòng, hoặc kéo đồ ăn vào thú. |
| Dọn nhà | Tab → cuộn → Dọn nhà → chà → (tự đóng) | 2 + cuộn + chà | Ổn. |
| Mở Tủ đồ | Tab → cuộn → Tủ đồ | 2 + cuộn | Nên có nút trên tranh phòng hoặc chạm giữ thú → "Thay đồ". |
| Quay gacha | Tab → cuộn → Máy gacha → Quay | 3 + cuộn | Ô bị khuất dưới mép màn đầu. |
| Chơi minigame | Tab → cuộn → Sân chơi → cuộn → Chơi → Bắt đầu | 4–5 + 2 lần cuộn | Dài nhất. |
| Viết nhật ký | Tab → Viết nhật ký → chọn mặt → gõ → Lưu | 4 + gõ | Ổn. Có thể cho chọn mặt ngay trên thẻ "Hôm nay thế nào?". |

---

## 6. Cảm giác cozy/cute

| Mảng | Đánh giá | Chỗ nhạt / chỗ quá tải |
|---|---|---|
| Thú cưng | 9/10 về tạo hình. Có thở, chớp mắt, đi lại, tim bay. | Một hình thú cưng giống hệt được dùng như sticker lặp lại ở rất nhiều nơi (Hôm nay, thẻ chăm sóc, Sân chơi, kết quả, gacha, Thở…). Thiếu biểu cảm theo ngữ cảnh: ăn mừng ở màn kết quả, đeo kính đọc sách khi Tập trung, ngái ngủ lúc 22h. |
| Phòng | 8.5/10. | Không đổi theo giờ (đèn, trời sao buổi tối). Chưa thấy đồ nội thất có tương tác (bật đèn, mở tủ lạnh). |
| Đồ & cửa hàng | 7/10. | Thẻ đồ thú cưng vẽ cả con thú nên phụ kiện quá nhỏ. Thẻ nội thất ổn. |
| Minigame | 8/10. | Giỏ Quà: vật phẩm lọt lên vùng trạng thái. Điểm "+1" gần như vô hình. |
| Gacha | 5/10. | Máy đứng yên, không có cần quay. Kết quả lật tự động quá nhanh. Độ hiếm không có ánh sáng, không có âm thanh. Đây là chỗ "đã mắt" quan trọng nhất mà chưa đạt. |
| Tập trung | 7/10. | Rõ ràng nhưng giống app hẹn giờ thường. Thú cưng nhỏ và thụ động. Có thể đặt thú vào góc học tập (tranh phòng học thu nhỏ, đèn bàn sáng dần theo tiến độ), kiểu Finch/Forest. |
| Chuyến đi / Sổ ký ức | 5/10. | Văn hay nhưng trình bày như văn bản pháp lý. Thiếu tranh cảnh, tem, kỷ vật. |
| Quá tải | | Góc nhỏ (11 khối nội dung). Header Hôm nay. Mỗi màn đều có một đoạn chữ xám cảnh báo hoặc giải thích (dinh dưỡng, y tế, thông báo, xu sân chơi, khóa máy, quyền riêng tư). Gom lại hoặc chuyển vào nút "i". |

---

## 7. Câu chữ tiếng Việt

Nhìn chung câu chữ tự nhiên, không sai chính tả, giọng "mình–bạn" thân thiện, lời thoại theo loài rất dễ thương. Vấn đề chính: lặp từ, dùng dấu chấm phẩy và giọng kỹ thuật trong UI, trộn tiếng Anh, gọi tên thú cưng không thống nhất, lạm dụng "nè".

| Ảnh | Hiện tại | Đề xuất |
|---|---|---|
| `02` | Tối rồi, hôm nay An vất vả rồi. | Tối rồi. Hôm nay An vất vả quá ha. |
| `02` | Timeline / Danh sách | Theo giờ / Danh sách |
| `07` | Đang lớn · lớn thành "Trưởng thành" ở cấp 10 | Đang lớn · Cấp 10 sẽ trưởng thành |
| `07` | Chạm để vuốt ve, vuốt qua lại để nựng, giữ rồi kéo để đưa Bông sang chỗ khác. | Chạm để vuốt ve · Vuốt để nựng · Giữ để bế Bông đi (và chỉ hiện vài lần đầu) |
| `18` | lưu dạng chữ thường trên máy, có trong file sao lưu. | Chỉ lưu trên iPhone này (chưa mã hóa) và có trong bản sao lưu. |
| `18` | Ghi chú | Viết vài dòng |
| `18` | Không bắt buộc. Viết gì cũng được, một chữ cũng được. | Viết một chữ thôi cũng được. |
| `26` | Đồ ăn là vật phẩm dùng một lần, mua lại được. Món rẻ đủ dùng hằng ngày; món đắt chỉ để đổi vị. | Món rẻ đủ no mỗi ngày. Món đắt để Bông đổi vị. |
| `27`, `29` | Đồ ăn trong game là đồ ăn tưởng tượng… không phải hướng dẫn dinh dưỡng cho thú thật. | Bỏ, hoặc chuyển vào Cài đặt > Giới thiệu. |
| `29` | Hôm nay đã nhận đủ thưởng cho việc này. | Hôm nay Bông nhận đủ thưởng cho ăn rồi, mai lại có nha. |
| `04` | …Việc cố định, việc đã xong và việc sắp tới giữ nguyên; thời lượng không đổi. | CozyDay dời các việc trễ vào chỗ trống từ giờ tới 22:00. Việc ghim giờ, việc đã xong và việc sắp tới giữ nguyên. |
| `30` | Hình dạng: mèo (đang dùng) | Đang chơi cùng: Mèo |
| `30` | Sân chơi là giờ nghỉ ngắn. Việc chính, tập trung và chăm sóc bản thân vẫn cho nhiều xu hơn. | Chơi một chút cho vui. Làm việc và tập trung vẫn được nhiều xu hơn. |
| `31` | Bạn nhỏ mặc nguyên bộ đồ đang dùng. Đổi ở đây chỉ áp dụng cho Sân chơi… Hình dạng không làm game dễ hay khó hơn. | Chỉ đổi bạn chơi trong Sân chơi. Loài nào cũng chơi như nhau. |
| `32` | Bạn nhỏ tự nảy khi chạm mây. | Bông tự nảy khi chạm mây. (dùng tên riêng) |
| `36` | Thời gian đang đứng yên. Bấm Tiếp tục để đếm ngược 3 giây rồi chơi tiếp. | Đang tạm dừng. Bấm Tiếp tục, đếm 3 giây là chơi tiếp. |
| `46` | Còn 10 lượt chắc chắn có món Quý | Tối đa 10 lượt nữa là có món Quý |
| `46` | Quay 10 lượt · 540 xu | Quay 10 lượt · 540 xu (rẻ 10%) |
| `41` | Lavender | Oải hương |
| `42`, `49`, `30` | Hình dạng | Loài |
| `08` | Tường & sàn / Sàn | Kiểu phòng / Sàn |
| `50` | Tiếng ồn nâu | Ồn nâu (êm) hoặc Tiếng rì rầm |
| `11` | Nhắc việc được lên lịch cho 7 ngày tới… nên đừng dùng nó thay chuông báo thức. | Nhắc việc có thể đến trễ khi bật chế độ Tập trung của iOS. Đừng dùng thay báo thức. |
| `23` | Thỏ · 85 xu (lưới) và Thỏ · 60 xu (Tủ đồ) | Cả bộ · 85 xu |
| Lời thoại | "nè" xuất hiện dày đặc (`PetDialogue.swift`) | Giữ "nè" cho khoảng 1/4 số câu, xen "nha", "đó", "hen", "ghê". |

Xưng hô: thú cưng xưng "mình", gọi người dùng là "bạn", đôi khi gọi tên ("An"). Như vậy chấp nhận được, nhưng nên quy ước: câu cảm thán dùng tên, câu rủ rê dùng "bạn". Văn bản hệ thống gọi "bạn" và "CozyDay" (ngôi thứ ba), nhất quán.

---

## 8. Bảng tương phản đo được (WCAG, tính từ token trong `DesignSystem/Theme.swift`)

| Cặp màu | Tỉ lệ | Chỗ dùng | Đạt? |
|---|---|---|---|
| peach #E59A7A trên peach 14% | 2.01:1 | Cho ăn, Nựng, Sắp xếp lại, Ngẫu nhiên | Không |
| sage #6F9A72 trên sage 14% | 2.75:1 | Dọn nhà | Không |
| lavender #8D78CF trên lavender 14% | 3.10:1 | Hộp chờ, Ghi nhanh, Toàn màn hình, Về Sân chơi | Chỉ đạt với chữ lớn |
| trắng trên peach | 2.27:1 | Quay 1 lượt, chip cấp 2 | Không |
| honey #D9A441 trên surface | 2.21:1 | Mọi giá "xx xu", "Mở ở cấp 7" | Không |
| sage trên background | 3.00:1 | "Đang lớn…", "Đã sạch 1/8" | Chỉ đạt với chữ lớn |
| trắng trên lavender | 3.67:1 | Nút chính | Đạt với chữ đậm ≥14pt |
| ink tối (#F3EEF8) trên ô tâm trạng | ~1.5–1.7:1 | `dark-09` lịch | Không |

Cách sửa chung: thêm token "ink" đậm cho từng màu nhấn, ví dụ `peachInk` #A8533A, `sageInk` #4A7350, `honeyInk` #946A12, `lavenderInk` #6A55B0. Dùng chúng làm `foregroundStyle` trong `SoftButtonStyle` (`DesignSystem/Components.swift:46`) và cho giá xu. Giữ màu nhạt cho nền.

---

## 9. Đề xuất theo mức ưu tiên

### Ưu tiên CAO

1. **Sửa tương phản của nút mềm, giá xu và chip.**
   Ảnh: `02`, `25`, `26`, `41`, `46`, `08`, `dark-25`.
   Vấn đề: tỉ lệ 2.0–2.75:1, khó đọc ngoài trời và với người thị lực kém.
   Sửa: thêm token `*Ink` đậm trong `Theme.swift`. `SoftButtonStyle` dùng `tintInk` cho chữ. Giá xu dùng `honeyInk`. Nút "Quay 1 lượt" dùng chữ `ink` tối trên peach (khoảng 5:1).

2. **Sửa số ngày trên lịch tâm trạng ở chế độ tối.**
   Ảnh: `dark-09-journal.jpg`.
   Sửa: `JournalView.swift:192`: ô có màu tâm trạng dùng `Palette.catInk` (cố định, tối). Ô không có tâm trạng giữ `Palette.ink`.

3. **Sửa các chỗ vỡ chữ khi chữ lớn.**
   Ảnh: `large-41-avatar` (Ngẫu nhiên), `large-28-clean` ("Đã sạc…"), `large-07-corner` ("Cấp / 6"), `large-25-care`.
   Sửa: `ViewThatFits` ở `AvatarViews.swift` khoảng dòng 208 và `CareViews.swift` khoảng dòng 241. `.fixedSize()` cho `Text("Cấp…")` ở `CornerView.swift:260`. `NeedRow` xếp dọc khi `isAccessibilitySize`.

4. **Sắp lại Góc nhỏ: phòng là trung tâm, tính năng nằm ngay trên màn đầu.**
   Ảnh: `07`, `25`, `dark-25`.
   Vấn đề: 11 khối nội dung. Tủ đồ, Gacha, Sân chơi nằm dưới mép màn. Thẻ chăm sóc trông như bảng điều khiển.
   Sửa (`CornerView.swift`, `CareViews.swift`):
   - Gộp tên, cấp, xu vào một hàng gọn. Dòng giai đoạn lớn chuyển thành popover khi chạm vào cấp.
   - Đặt 3 chỉ số thành 3 vòng tròn nhỏ có icon, nằm đè lên góc dưới tranh phòng, giống Finch. Chạm vào vòng là làm hành động tương ứng. Chỉ số đang "Cần chăm" thì nảy nhẹ.
   - Ngay dưới phòng là một hàng dock 4–6 nút tròn (Tủ đồ, Trang trí, Sân chơi, Gacha, Bộ sưu tập, Ảnh) vẽ mini-illustration, cuộn ngang.
   - Bỏ dòng hướng dẫn cố định, thay bằng tooltip 3 lần đầu.
   - Thẻ chuyến đi và thẻ tuần giữ ở dưới.

5. **Làm gọn màn đầu Hôm nay.**
   Ảnh: `02`, `large-02`, `53`.
   Sửa (`TodayView.swift`):
   - Bỏ dòng "Thứ ba, 20 tháng 10" vì dải tuần đã chọn ngày. Gộp lời chào vào bong bóng thú cưng.
   - Bỏ băng rôn Hộp chờ, chuyển thành huy hiệu số trên icon hộp chờ ở góc trái.
   - Bỏ icon đồng hồ ở góc phải vì đã có tab Tập trung.
   - Băng rôn "việc trễ" thu thành một dòng chip nhỏ.
   - Thêm khoảng đệm bên phải cho timeline (khoảng 72pt ở vùng nút +), hoặc dời "+" vào thanh điều hướng hay `tabViewBottomAccessory` (iOS 26), để nút không che dấu tick.

6. **Onboarding: cho chọn thú cưng và giới thiệu Tập trung.**
   Ảnh: `01`, `45`.
   Sửa (`OnboardingView.swift`, `IntroViews.swift`):
   - Thêm bước "Chọn bạn đồng hành": 3–4 loài khởi đầu miễn phí, có animation chào khi chọn.
   - Rút tour còn 3 trang: Ngày gọn gàng, Tập trung cùng Bông, Chăm & trang trí. Gộp Mẹo nhanh vào coach mark trong app.
   - Video mở đầu nên bắt đầu bằng thú cưng, không phải ảnh quay màn hình bị mờ. Thống nhất số xu (+5/+8).
   - Sau onboarding, thêm checklist "Ngày đầu tiên" (thêm 1 việc, thử 1 phiên 25 phút, cho Bông ăn), mỗi mục có thưởng.

7. **Gacha phải "đã mắt" hơn.**
   Ảnh: `46`, `47`, `dark-46`.
   Sửa (`GachaView.swift`, `GachaArt.swift`):
   - Máy to hơn (khoảng 280pt), viên nang lắc lư nhẹ khi rảnh, có cần gạt kéo được.
   - Kết quả: viên nang màu theo độ hiếm, **người dùng chạm để mở** (có nút "Mở hết"). Món Quý/Bí mật có ánh sáng tỏa, pháo giấy và rung.
   - Thẻ kết quả có nhãn độ hiếm và viền màu, hiện **cận cảnh món đồ** chứ không phải cả con thú. Món tốt nhất hiện to ở đầu.
   - Ghi "rẻ 10%" cho gói 10 lượt. Thêm nút "Tỉ lệ" ở góc.

8. **Thống nhất nền sheet và font tiêu đề.**
   Ảnh: `03`, `11`, `18` (nền), `09`, `10` (tiêu đề).
   Sửa: `.scrollContentBackground(.hidden).cozyBackground()` cho 3 Form. Cấu hình `UINavigationBar.appearance()` dùng font rounded và màu `ink`, hoặc chuyển Nhật ký và Tiến bộ sang tiêu đề nhỏ như 3 tab còn lại.

### Ưu tiên TRUNG BÌNH

9. **Tập trung: bớt số đếm, tăng chất "cozy".** Ảnh `06`, `50`, `52`, `large-06`.
   Chỉ giữ "Phiên 3/4" kèm 4 chấm, chuyển "2/6 phiên hôm nay" thành dòng nhỏ. "Không gắn việc" thành chip có viền và icon. Thêm hiệu ứng mờ dần ở mép phải hàng chip âm nền. Đặt thú cưng to hơn hoặc trong cảnh bàn học. Màn toàn màn hình: chạm để hiện Tạm dừng, nút thu nhỏ to và rõ hơn. Đồng hồ nhỏ nên dùng `tabViewBottomAccessory` của iOS 26 thay cho overlay tự đặt (`RootView.swift`).
10. **Thẻ đồ trong Tủ đồ/Gacha/Ảnh đại diện: phóng to vào món đồ.** Ảnh `49`, `47`, `42`. Vẽ thú cưng cắt ở vùng đầu khi chọn mũ/kính, toàn thân khi chọn áo. Hoặc vẽ riêng món đồ bằng `ItemPainter`. Thêm chú giải cho chấm độ hiếm.
11. **Cho ăn và Dọn nhà mang tính chơi hơn.** Ảnh `27`, `28`. Kéo món ăn vào miệng thú. Màn dọn nhà: tranh phòng to tới khoảng 60% chiều cao, dụng cụ thành nút tròn nổi dưới tranh, bỏ khoảng trống phía dưới.
12. **Sổ ký ức và chuyến đi có hình.** Ảnh `13`, `14`. Mỗi chuyến có một tranh nhỏ (dùng lại nền của ảnh đại diện hoặc khu vườn) và kỷ vật vẽ bằng `ItemPainter`. Sổ ký ức trình bày dạng nhật ký dán ảnh, có tem ngày.
13. **Sân chơi dạng lưới 2 cột.** Ảnh `30`, `large-30`. Thẻ game gồm ảnh, tên, kỷ lục. Chạm vào là mở luôn hướng dẫn hoặc chơi. Mô tả chuyển vào thẻ hướng dẫn.
14. **Giỏ Quà: vùng sinh vật phẩm.** Ảnh `34`, `40-basket-frames-1…4`. Sinh dưới HUD (safe area cộng khoảng 60pt), hoặc thêm dải gradient che phía trên. Đổi màu "+1/+2" sang `honeyInk` có viền trắng. Bỏ đám mây trang trí sau nút tạm dừng.
15. **Thống nhất nút đóng sheet và màu viền chọn.** Ảnh `05`, `16`, `17`, `31`, `42`. Xem mục 4.
16. **Chi tiết việc: nút chính không bị cắt.** Ảnh `17`. Ghim "Hoàn thành / Tập trung" ở đáy sheet bằng `.safeAreaInset(edge: .bottom)`, hoặc mặc định mở `.large`.
17. **Giá trong Bộ sưu tập rõ ràng.** Ảnh `23`, `24`, `dark-12`. Ghi "Cả bộ · 85 xu" để không mâu thuẫn với giá 60 xu ở Tủ đồ.
18. **Phòng đổi theo giờ / chế độ tối.** Ảnh `dark-07`, `dark-19`. Sau 18h thì cửa sổ thành trời tím có sao, đèn bàn và đèn dây sáng lên. Đây là điểm cộng lớn cho cảm giác cozy với người dùng hay mở app buổi tối.
19. **Rút gọn các đoạn chú thích và cảnh báo.** Ảnh `26`, `27`, `11`, `30`, `31`, `06`, `18`. Xem bảng câu chữ. Chuyển các câu pháp lý vào một nút "i".
20. **Chip chọn phòng tự cuộn tới phòng đang chọn.** Ảnh `21-bath`. Dùng `ScrollViewReader.scrollTo(selection)` trong `RoomPicker` (`CornerView.swift:360`).

### Ưu tiên THẤP

21. Hai việc trùng giờ trên timeline: khi có từ 2 cột trở lên, cho thẻ xếp lệch nhau và giữ tiêu đề 2 dòng thay vì cắt "Học Swif…". Ảnh `01`. File `DayTimeline.swift:181`.
22. Shop: "Tường & sàn" đổi thành "Kiểu phòng". Món khóa thêm icon ổ khóa. Tên món giới hạn 1 dòng có co chữ để thẻ đều chiều cao. Ảnh `08`, `48`.
23. Lịch tâm trạng: vẽ mặt cảm xúc nhỏ trong ô. Đưa chú giải lên trên lịch. Ảnh `09`.
24. Trình viết nhật ký: chuyển phần Tâm trạng lên đầu. Mặt cảm xúc to hơn, có trạng thái chọn rõ (viền và phóng to). Ảnh `18`.
25. Thú cưng có biểu cảm theo ngữ cảnh: ăn mừng ở `37`/`38`, kính đọc sách ở `06`, ngái ngủ sau 22h. Hiện `PetArt` đã có `mood`, chỉ cần thêm pose.
26. Icon tab: dùng cùng độ đậm, và màu chưa chọn là `ink` thay vì đen tuyền. Dùng cùng biểu tượng Tập trung ở tab, header và mini bar.
27. "Hiện tên & cấp" (`41`) đổi sang `Toggle` dạng công tắc hoặc chip có dấu tick.
28. Merge (`44`): kiểm tra bóng chữ thoại bị chồng khi đổi câu. Blocks (`43`): khối trong khay to hơn (khoảng 0.6 kích thước thật).
29. Bóng chữ "Việc nhỏ." và pill thưởng bị cắt trong video intro (`01`): dựng lại video để chú thích nằm trong vùng an toàn.
30. Chụp lại `12-wardrobe.jpg` (đang trùng `07`) và `53-focus-mini.jpg` (sau commit `8480cd1`).
