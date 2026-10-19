# Kiểm thử Cozyday

## 1. Test tự động

| Bộ test | Chạy ở đâu | Nội dung |
|---|---|---|
| `Tests/CoreTests` (54 test) | `swift test` trên Linux (workflow **Core logic tests**) và trong Xcode test target | Khóa ngày theo lịch địa phương, đổi giờ mùa hè, lịch lặp, không sinh trùng occurrence, sửa "lần này trở đi" không đổi quá khứ, xóa giữ lịch sử, timeline không đè chữ, replan (không đụng việc cố định/xong, không chồng lịch, báo việc không đủ chỗ), thưởng một lần, mua đồ (thiếu xu, mua 2 lần), timer (tạm dừng, mở lại sau nhiều giờ, kết thúc sớm), nhắc việc (cửa sổ 7 ngày, giới hạn 60), sao lưu (round-trip, bản mới hơn, file rác, file cụt, thiếu trường, ID trùng, tham chiếu sai, xu âm, qua nửa đêm), thống kê. |
| `Tests/AppTests` | iOS Simulator (job **Unit test trên iOS Simulator**) | SwiftData thật (trong bộ nhớ): hồ sơ tạo một lần + không reset khi mở lại, hoàn thành 2 lần/mở lại không thưởng trùng, xóa việc giữ sổ cái, mua đồ không trừ 2 lần + bền sau mở lại, occurrence không trùng qua mở lại + đổi ngày, sửa tương lai không đổi quá khứ, thưởng focus một lần sau mở lại, sao lưu → khôi phục thay thế toàn bộ, sao lưu hỏng không đụng dữ liệu, từ chối việc qua nửa đêm. Thêm (phiên 3): mở kho dữ liệu V1 thật bằng bản V2 (migration), tủ đồ (mặc định, khóa theo cấp, trang bị sau khi mở lại), chuyến đi + bài thở thưởng một lần. Tổng 68 test cùng CoreTests. |
| Chăm thú cưng & Sân chơi (phiên 5) | Core: Linux + Simulator · App: Simulator | Core (`PlayAndCareTests`): suy giảm chậm/sàn/24 giờ, đọc nhiều lần không giảm thêm, đồng hồ quay ngược, thưởng chỉ khi cần + hạn mức theo loại/tổng/qua nửa đêm, bữa miễn phí không farm, mua đồ ăn idempotent theo mã giao dịch, tiến độ nựng cần vuốt thật, máy trạng thái lượt chơi, đồng hồ lượt không tính lúc tạm dừng, quy đổi xu + hạn mức + phần còn lại, kết quả vô lý không có xu; Nhảy Mây chỉ đáp khi rơi qua mặt bệ, nảy tại chỗ không tăng điểm, bệ sinh ra luôn với tới được (31 seed + "người chơi máy" leo > 200 m), sao tính một lần; Giỏ Quà mỗi món tính một lần, bùn không làm điểm âm, kết thúc đúng 60 giây và không cộng sau đó; Lật Thẻ đủ cặp, có seed, không mở quá 2 thẻ, khóa khi cặp sai, lệnh úp trễ không phá lượt mới. App (`CareAndPlayStoreTests`, `MigrationTests`): gói chào mừng một lần, cho ăn/thử lại/lỗi lưu không nhân đôi, mua đồ ăn lỗi lưu rồi thử lại, lượt chơi lưu một lần qua mở lại app, hạn mức một phần/hết/qua nửa đêm, thoát sớm không xu, sao lưu round-trip và sao lưu bản 1, migration V2 → V3 trên kho thật. |
| Ảnh giao diện | iOS Simulator (cùng job, bước **Chụp ảnh giao diện**) | App bản Debug mở 11 màn với dữ liệu mẫu (sáng), 5 màn tối, 2 màn cỡ chữ Trợ năng; fail nếu màn nào crash. Ảnh: [`UI_PREVIEW_VI.md`](UI_PREVIEW_VI.md). |

**Lưu ý:** test simulator **không** chứng minh IPA cài được trên iPhone thật. Việc đó chỉ được xác nhận bằng checklist phần 2 trên máy của bạn.

## 2. Checklist trên iPhone thật

Đánh dấu `[x]` khi đã thử và đạt; ghi "chưa xác minh" nếu chưa thử. Ghi model iPhone + phiên bản iOS ở đầu.

iPhone: ________ · iOS: ________ · Bản build (Cài đặt → Thông tin → Phiên bản): ________

### Cài đặt & mở độc lập
- [ ] Cài bằng Sideloadly thành công, icon mèo hiện trên màn hình chính
- [ ] Mở được khi đã rút USB và **tắt máy tính**
- [ ] Mở được ở **chế độ máy bay**
- [ ] Tắt hẳn app (vuốt khỏi App Switcher) rồi mở lại: dữ liệu còn

### Luồng chính
- [ ] Onboarding: đặt tên, chọn mục tiêu, chọn 1–2 thói quen → thói quen xuất hiện hôm nay và các ngày sau
- [ ] Onboarding: bấm "Bỏ qua" ở bước 1 → vào app với tên mèo mặc định, không có việc mẫu
- [ ] Tạo việc có giờ, việc không giờ, việc trong Hộp chờ
- [ ] Việc trùng giờ hiện cạnh nhau, có biểu tượng cảnh báo, chữ không đè nhau
- [ ] Việc 5 phút vẫn đọc được tiêu đề
- [ ] Đường "bây giờ" đúng giờ hiện tại
- [ ] Hoàn thành → +10 XP +5 xu; bỏ hoàn thành rồi hoàn thành lại → không cộng thêm
- [ ] Sửa việc lặp "chỉ lần này" và "lần này và các lần sau"; xóa tương tự
- [ ] Chuyển việc sang ngày mai; đưa về Hộp chờ; xếp lịch từ Hộp chờ
- [ ] Đặt việc 23:30 dài 1 giờ → bị từ chối với thông báo dễ hiểu
- [ ] Sắp xếp lại: xem trước, Hủy không đổi gì; Áp dụng dời đúng
- [ ] Tập trung 25 phút: tạm dừng/tiếp tục; khóa máy 2 phút rồi mở lại → thời gian đúng
- [ ] Tập trung: đóng app, đợi hết giờ, mở lại → "Xong rồi" (một lần), thưởng một lần
- [ ] Kết thúc sớm → không thưởng, phút đã tập trung có trong Tiến bộ
- [ ] Cửa hàng: nhận 3 món miễn phí; mua món có giá; thiếu xu không mua được; đặt/thay/bỏ đồ trong phòng
- [ ] Nhật ký: chọn mood + viết; lịch tháng hiện màu; sửa ngày cũ
- [ ] Tiến bộ: 7/30 ngày; biểu đồ; lịch sử xu khớp thao tác đã làm
- [ ] Xuất sao lưu → Tệp; Khôi phục từ file đó → dữ liệu như cũ
- [ ] Khôi phục một file không phải sao lưu (ví dụ file JSON khác) → bị từ chối, dữ liệu không đổi

### Thú cưng & phiên bản mới
- [ ] Cài đè bản mới lên bản cũ (cùng bundle ID, cùng Apple Account): việc, nhật ký, xu, đồ trong phòng còn nguyên
- [ ] Góc nhỏ: thú cưng thở, chớp mắt, vẫy đuôi; thỉnh thoảng đi qua đi lại trong phòng
- [ ] Chạm vào thú cưng: tim bay, rung nhẹ, hiện một câu nói
- [ ] Tủ đồ: mặc thử (không mất xu), mua, dùng, tháo; món khóa theo cấp hiện "Cấp N"; chọn lại Mèo/Kem sữa được
- [ ] Ngoại hình mới hiện đúng ở Hôm nay, Tập trung, Góc nhỏ
- [ ] Chuyến đi: năng lượng tăng 25% mỗi việc xong/tập trung/nhật ký/bài thở; đủ 100% → nghe kể chuyện, nhận +3 xu một lần; Sổ ký ức có câu chuyện
- [ ] Bài thở: vòng tròn phồng/xẹp theo nhịp, chữ đổi đúng; chạy hết giờ → +1 xu (một lần mỗi ngày); bấm Dừng → không thưởng
- [ ] Giảm chuyển động: thú cưng đứng yên, bài thở không phồng/xẹp

### Phòng, bộ sưu tập, nựng thú cưng (bản phòng & bộ sưu tập)
- [ ] Góc nhỏ: hàng chọn phòng có Phòng học, Phòng ngủ, Bếp & bàn ăn, Phòng tắm, Khu vườn; phòng chưa đủ cấp hiện ổ khóa và "Cấp N"
- [ ] Đồ cũ của phòng học vẫn ở đúng chỗ sau khi cài đè
- [ ] Chạm một ô trống trong phòng → mở Trang trí đúng vị trí; mua đồ → đồ hiện ngay trong phòng
- [ ] Đổi "Tường & sàn" (vườn: "Bầu trời") của từng phòng; chọn lại món mặc định được
- [ ] Vuốt qua lại trên thú cưng → mắt híp, má đỏ, tim bay, rung nhẹ, có câu nói
- [ ] Giữ thú cưng ~nửa giây → nhấc lên (mắt tròn, chân lủng lẳng); kéo sang trái/phải rồi thả → thú cưng ở chỗ mới, nhảy nhẹ khi chạm sàn
- [ ] Chạm nhanh thú cưng vẫn là vuốt ve (không bị nhấc lên); cuộn trang Góc nhỏ vẫn mượt
- [ ] Bộ sưu tập: lưới 11 loài + 40 bộ phối sẵn; chạm một bộ → xem thử chuyển động; "Mua N món còn thiếu" trừ đúng tổng xu; thiếu xu/cấp → không trừ gì
- [ ] Tủ đồ có thêm mục "Phụ kiện" (cánh, ba lô, bóng bay…)
- [ ] Hoàn thành việc → thú cưng bật lên cùng bong bóng "+10 XP · +5 xu" rồi tự ẩn
- [ ] Hôm nay: thú cưng nói một câu trong bong bóng nâu; chạm bong bóng → câu khác; chạm thú cưng → sang Góc nhỏ
- [ ] Chuyến đi: câu chuyện thay đổi theo loài thú cưng đang dùng

### Chăm thú cưng (bản Sân chơi & chăm sóc)
- [ ] Cài đè xong: việc, xu, XP, đồ, trang bị, nhật ký còn nguyên; Góc nhỏ có thẻ chăm sóc với No bụng / Nhà sạch / Vui vẻ ở mức dễ chịu
- [ ] Khay đồ ăn có sẵn 3 Táo giòn + 1 Cơm nắm; tắt hẳn app mở lại → không được tặng thêm
- [ ] Cho ăn: số món giảm đúng 1, thú cưng ăn 3 miếng rồi hiện câu nói; no từ 95 → nút Cho ăn bị khóa, không mất món
- [ ] Mua đồ ăn: trừ đúng giá, tăng đúng 1; thiếu xu → nút mờ, không trừ
- [ ] Hôm sau (≈ 1 ngày không cho ăn) No bụng dưới 35: bong bóng chỉ nói một nhu cầu, nét mặt "mong được chăm" (không khóc/giận)
- [ ] Bữa cơ bản miễn phí chỉ hiện khi đói; bấm xong No bụng lên 55, nút biến mất
- [ ] Dọn nhà: bụi/lá/giấy vụn hiện ở sàn khi Nhà sạch thấp; chế độ dọn: chạm/vuốt sạch từng đốm; "Dọn nhanh" cho cùng kết quả; "Thôi" → không lưu gì; trang không bị cuộn khi đang vuốt bụi
- [ ] Nựng: vuốt qua lại trên thú cưng ~3–4 giây → thanh "Đang nựng…" đầy → popup; giữ rồi kéo thú cưng KHÔNG tính là nựng
- [ ] Chăm khi đang ổn: không có XP/xu, có câu giải thích; quá 2 lần/loại trong ngày: báo đã đủ thưởng

### Sân chơi
- [ ] Góc nhỏ có thẻ "Sân chơi"; mở ra thấy bạn nhỏ, số xu, "Xu sân chơi hôm nay x/20", 3 thẻ game có kỷ lục
- [ ] "Đổi bạn chơi": loài đã có chọn được, loài chưa có bị khóa; đổi xong quay lại Góc nhỏ → thú cưng vẫn là loài cũ
- [ ] Lần đầu mỗi game có hướng dẫn ngắn; lần sau vào thẳng đếm ngược 3-2-1
- [ ] Nhảy Mây: kéo ngang một tay điều khiển được; tự nảy; lên cao bệ hẹp dần, có mây xanh di chuyển; rơi → màn kết quả; điểm không tăng khi nảy tại chỗ
- [ ] Giỏ Quà: kéo giỏ mượt; bùn/mây mưa có dấu ✕ dễ nhận; hết 60 giây đúng lúc; không bị cộng điểm sau khi hết giờ
- [ ] Lật Thẻ: Dễ 3×4, Vừa 4×4 vừa màn hình; chạm nhanh nhiều thẻ không mở quá 2; cặp sai tự úp; thú cưng phản ứng vui khi đúng, động viên khi sai
- [ ] Nút tạm dừng dễ bấm; vuốt về màn hình chính / khóa máy giữa lượt → quay lại thấy "Tạm dừng", bấm Tiếp tục có đếm ngược
- [ ] Thoát giữa lượt hỏi xác nhận; thoát xong không có xu, số xu cũ không đổi
- [ ] Kết quả: hiện điểm, kỷ lục mới, xu thực nhận; chơi lại nhiều lượt liên tiếp không nhanh dần sai, không chồng tiếng
- [ ] Chơi tới khi đủ 20 xu/ngày: lượt sau ghi "Hôm nay đã nhận đủ xu sân chơi", kỷ lục vẫn lưu
- [ ] Âm thanh nhỏ, không ngắt nhạc đang nghe; tắt "Âm thanh trò chơi"/"Rung khi chơi" có tác dụng; bật Giảm chuyển động → ít hiệu ứng
- [ ] Xuất sao lưu rồi khôi phục: khay đồ ăn, chỉ số, kỷ lục Sân chơi còn nguyên; chơi lại không nhận trùng

### Lập kế hoạch (mới)
- [ ] Việc con: thêm/xóa/sắp xếp trong form; đánh dấu trong chi tiết; timeline hiện "1/3"
- [ ] Việc lặp có việc con: mỗi ngày bắt đầu chưa làm; sửa "lần này trở đi" giữ các mục đã đánh dấu
- [ ] Kéo tay nắm bên trái khối việc lên/xuống → đổi giờ, làm tròn 5 phút; việc lặp chỉ đổi lần đó
- [ ] Cài đặt → Hiện sự kiện từ app Lịch → iOS hỏi quyền; sự kiện hiện trên timeline (viền nét đứt); "Sắp xếp lại" không xếp việc chồng lên sự kiện
- [ ] Từ chối quyền Lịch → app vẫn dùng bình thường, Cài đặt hiện hướng dẫn bật lại
- [ ] Nhật ký: câu gợi ý, "Câu khác", "Dùng câu này"
- [ ] Tiến bộ: phân bố tâm trạng khớp số ngày đã viết

### Thông báo
- [ ] Bật nhắc cho một việc lần đầu → iOS hỏi quyền
- [ ] Từ chối quyền → app vẫn dùng đủ chức năng; Cài đặt hiện "Thông báo đang tắt" + nút mở Cài đặt iPhone
- [ ] Cho phép → nhận nhắc việc đúng giờ (± độ trễ của iOS); bấm thông báo mở đúng việc
- [ ] Xóa việc có nhắc → không còn nhận nhắc của việc đó
- [ ] Hết giờ tập trung khi app ở nền → có thông báo; bấm mở màn tập trung

### Hiển thị & trợ năng
- [ ] Màn hình nhỏ (iPhone SE/mini) và lớn (Pro Max)
- [ ] Tên việc tiếng Việt dài (≥ 80 ký tự) không vỡ bố cục
- [ ] Bàn phím không che ô đang nhập
- [ ] Dark mode
- [ ] Cỡ chữ lớn nhất (Cài đặt → Trợ năng → Màn hình & cỡ chữ → Chữ lớn hơn) — Hôm nay tự chuyển sang dạng Danh sách
- [ ] VoiceOver: đọc được việc, giờ, trạng thái; thao tác "Hoàn thành", "Sửa", "Đổi ngày hoặc giờ" trong menu rotor
- [ ] Giảm chuyển động: mèo không "thở"/nảy

### Ngày & cập nhật
- [ ] Để app mở qua nửa đêm → "Hôm nay" chuyển sang ngày mới
- [ ] Không mở app vài ngày rồi mở lại → việc lặp các ngày tới có đủ, không trùng
- [ ] Cài đè bản mới (cùng bundle ID) → dữ liệu còn nguyên

## 3. Trạng thái xác minh hiện tại

Xem `PROJECT_STATUS.md` — mục "Kết quả kiểm tra thực tế". Mục nào chưa được thử trên máy thật được ghi rõ **chưa xác minh**.
