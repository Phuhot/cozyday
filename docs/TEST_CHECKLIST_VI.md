# Kiểm thử Cozyday

## 1. Test tự động

| Bộ test | Chạy ở đâu | Nội dung |
|---|---|---|
| `Tests/CoreTests` (38 test) | `swift test` trên Linux (workflow **Core logic tests**) và trong Xcode test target | Khóa ngày theo lịch địa phương, đổi giờ mùa hè, lịch lặp, không sinh trùng occurrence, sửa "lần này trở đi" không đổi quá khứ, xóa giữ lịch sử, timeline không đè chữ, replan (không đụng việc cố định/xong, không chồng lịch, báo việc không đủ chỗ), thưởng một lần, mua đồ (thiếu xu, mua 2 lần), timer (tạm dừng, mở lại sau nhiều giờ, kết thúc sớm), nhắc việc (cửa sổ 7 ngày, giới hạn 60), sao lưu (round-trip, bản mới hơn, file rác, file cụt, thiếu trường, ID trùng, tham chiếu sai, xu âm, qua nửa đêm), thống kê. |
| `Tests/AppTests` | iOS Simulator (job **Unit test trên iOS Simulator**) | SwiftData thật (trong bộ nhớ): hồ sơ tạo một lần + không reset khi mở lại, hoàn thành 2 lần/mở lại không thưởng trùng, xóa việc giữ sổ cái, mua đồ không trừ 2 lần + bền sau mở lại, occurrence không trùng qua mở lại + đổi ngày, sửa tương lai không đổi quá khứ, thưởng focus một lần sau mở lại, sao lưu → khôi phục thay thế toàn bộ, sao lưu hỏng không đụng dữ liệu, từ chối việc qua nửa đêm. |
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
