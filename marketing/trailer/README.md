# Trailer quảng cáo CozyDay (30 giây)

- Video: `out/CozyDay-trailer-30s.mp4` (1080×1920, 30 khung/giây, H.264 + AAC, dọc cho điện thoại)
- Ảnh bìa: `out/CozyDay-trailer-cover.jpg` (khung cuối của end card)
- Kịch bản có mốc thời gian: [STORYBOARD.md](STORYBOARD.md)

## Hình ảnh lấy từ đâu

| Loại | Cảnh | Cách làm |
|---|---|---|
| Giao diện thật | Tick việc trên Hôm nay, popup thưởng, Tủ đồ, cho ăn, nựng, dọn nhà | Quay màn hình iOS Simulator (iPhone 17 Pro) chạy bản Debug của app bằng workflow `Trailer footage`. Thao tác do bản Debug tự bấm theo kịch bản, gọi đúng hàm mà nút/cử chỉ gọi (`Cozyday/App/PreviewMode.swift`, các màn `trailer…`). Mức thưởng trên màn hình do app tự tính. |
| Gameplay thật | Nhảy Mây, Giỏ Quà, Lật Thẻ | Cùng cách quay; game chạy bằng engine thật, bot của bản Debug điều khiển (như video gameplay trong CI). |
| Cutscene | Mở đầu (thẻ việc rối → xếp gọn), montage trang phục, phòng ngủ ăn mừng, end card | Vẽ từng khung bằng chính code vẽ của app: `PetPainter`, `AvatarPainter` (nền/phong cảnh/hiệu ứng của Ảnh đại diện), `ItemPainter` (đồ trong phòng). Mọi trang phục và đồ đạc đều có trong `Catalog`. |
| Icon | End card | Đúng file `Cozyday/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`. |
| Âm thanh | Nhạc nền + hiệu ứng | Tự tổng hợp bằng numpy (`tools/audio.py`), không dùng mẫu âm thanh bên ngoài. |

Phông chữ tiêu đề: Baloo 2 và Nunito (Google Fonts, giấy phép SIL Open Font License), tải tự động khi dựng.
Không có huy hiệu App Store hay đường tải.

## Dựng lại

1. **Quay footage** (chỉ khi giao diện đổi): commit có `[trailer]` trong message lên nhánh `claude/**`, hoặc
   Actions → "Trailer footage" → Run workflow. Mất khoảng 10–16 phút macOS. Clip nén (1080 px) được commit vào
   `footage/`. Thêm `[clips: today-tick clean]` để chỉ quay lại vài clip. Workflow tự chọn múi giờ đang là buổi sáng
   để màn Hôm nay có việc trễ giờ và thú cưng không ngủ.
2. **Dựng video** trên Linux có Swift 6, Node + Playwright (Chromium), Python 3 + Pillow + numpy, ffmpeg:

   ```bash
   marketing/trailer/tools/build_trailer.sh
   ```

   Các bước bên trong:
   - `frames.py` liệt kê khung cần vẽ → `render_frames.sh` biên dịch `harness_trailer.swift` cùng code vẽ thật của app với
     bản SwiftUI giả xuất SVG (`svg_shim/`) → `svg2png_batch.js` chuyển sang PNG trong suốt.
   - `audio.py` tạo `audio.wav`.
   - `compose.py` ghép cutscene, footage, title, chuyển cảnh, âm thanh → MP4; khung cuối → ảnh bìa.
   - Mốc thời gian dùng chung ở `timeline.py`; vùng cắt và giây bắt đầu của từng clip ở bảng `SHOT` trong `compose.py`.

   Xem nhanh vài khung mà không xuất video: `compose.py … --stills 3.5,9.2,27.8` (ghi JPG vào thư mục ra).

## Giới hạn đã biết

- Thao tác trong footage do bản Debug tự bấm, không có ngón tay thật; ở cảnh dọn nhà có hình dụng cụ đi theo điểm lau
  (giống khi kéo bằng tay), các cảnh khác không có con trỏ.
- Simulator trên máy CI ghi theo khung hình thay đổi (thống kê ở `footage/frames.txt`), video được đưa về 30 khung/giây
  khi dựng. Độ mượt trên iPhone thật có thể khác.
- Claude kiểm tra video bằng cách xem các khung hình trích ra và đo âm lượng/dạng sóng; không nghe được âm thanh.
