# Cozyday

App iPhone dùng cá nhân: sắp xếp một ngày thành **timeline** trực quan, hoàn thành việc để chăm **thú cưng tròn xinh**
(11 loài, 80+ món trang phục) và trang trí 5 không gian nhỏ. Native Swift + SwiftUI + SwiftData, chạy **offline**, không tài khoản, không máy chủ,
không quảng cáo, không mua hàng trong app.

> Lấy cảm hứng về *cách giải quyết nhu cầu* từ các app lập lịch và app thú cưng tự chăm sóc, nhưng tên, bố cục, mèo,
> đồ nội thất, icon và câu chữ đều là tài sản gốc của dự án (vẽ bằng code / script trong repo).

## App làm gì

| Tab | Nội dung |
|---|---|
| **Hôm nay** | Đầu trang gọn (ngày, lời chào, thú cưng nói chuyện trong bong bóng + tiến độ) · thanh chọn ngày theo tuần + nút về hôm nay · nhóm việc chưa xếp giờ · timeline dọc với đường "bây giờ", việc trùng giờ chia cột không đè chữ · chế độ Danh sách (tự bật khi cỡ chữ rất lớn) · Hộp chờ · **Sắp xếp lại** việc trễ (xem trước, có Hủy) · nút + thêm việc · mở **Tập trung** |
| **Góc nhỏ** | Thú cưng **11 loài** (mèo, thỏ, hamster, gấu nhỏ, cáo, cún, vịt, ếch, capybara, gấu trúc, chim cánh cụt), **11 màu lông**, **trang phục & phụ kiện** (mũ, kính, đồ ở cổ, áo, cánh/ba lô/bóng bay… — 80+ món, một số mở khóa theo cấp) · **lớn dần** theo cấp · **animation**: thở, chớp mắt, vẫy đuôi, giật tai, nhảy, đi lại trong phòng; chạm để vuốt ve, **vuốt qua lại để nựng** (mắt híp, tim bay), **giữ rồi kéo để mang sang chỗ khác** · **Tủ đồ** mặc thử miễn phí · **Bộ sưu tập**: lưới các loài và 40 bộ phối sẵn, mua & mặc cả bộ bằng một chạm · **5 không gian**: phòng học, phòng ngủ, bếp & bàn ăn, phòng tắm, khu vườn (mở theo cấp), mỗi nơi có tường & sàn/bầu trời đổi được và 5–6 vị trí đồ (120+ món trang trí) · **Chuyến đi mỗi ngày** với nhiều câu chuyện theo loài và mùa, lưu trong **Sổ ký ức** · "Tuần này của thú cưng" · **Chăm sóc**: No bụng / Nhà sạch / Vui vẻ giảm rất chậm (sàn 20, không bao giờ ốm hay bỏ đi), khay & cửa hàng **đồ ăn** (6 món, bữa cơ bản miễn phí khi đói), **dọn nhà** bằng cách chạm/vuốt bụi, nựng để vui — thưởng nhỏ có hạn mức · **Sân chơi**: 3 minigame ngắn chơi bằng chính thú cưng của bạn — **Nhảy Mây** (nảy lên mây), **Giỏ Quà** (hứng quà 60 giây), **Lật Thẻ Bạn Nhỏ** (trí nhớ) — kỷ lục, xu thưởng phụ tối đa 20 xu/ngày, không quảng cáo, không mất xu khi thua |
| **Nhật ký** | Mood 1–5 có nhãn chữ + ghi chú · **câu gợi ý viết** · lịch tháng tô màu theo mood · **bài thở có hướng dẫn** (3 nhịp, 1–5 phút) |
| **Tiến bộ** | Việc đã xong, phút tập trung, số ngày có hoạt động, chuỗi ngày · biểu đồ 7/30 ngày · **phân bố tâm trạng** · lịch sử xu & vật phẩm. Chỉ dữ liệu thật. |
| **Cài đặt** (nút bánh răng) | Tên, khung giờ trong ngày, rung, thông báo, **hiện sự kiện từ app Lịch** (chỉ đọc), **Xuất / Khôi phục sao lưu**, quy tắc phần thưởng, quyền riêng tư |

Việc: tạo / sửa / xóa / hoàn thành / bỏ hoàn thành / bỏ qua / chuyển ngày · nhóm, ưu tiên, ghi chú, **việc con (checklist)**,
giờ hoặc chỉ thời lượng, nhắc trước · **kéo tay nắm trên timeline để đổi giờ** · lặp hằng ngày hoặc theo thứ, có ngày kết thúc ·
sửa/xóa việc lặp "chỉ lần này" hoặc "lần này và các lần sau" · sự kiện từ app Lịch hiện cạnh việc và được "Sắp xếp lại" tránh.
Tập trung: 25/5, 50/10 hoặc tùy chỉnh 5–120 phút, gắn việc, tạm dừng/tiếp tục/kết thúc sớm, đúng cả khi app bị đóng.

Quy tắc dữ liệu, sao lưu, lịch lặp và phần thưởng: [`docs/DATA_AND_RULES_VI.md`](docs/DATA_AND_RULES_VI.md).

## Cài lên iPhone (Windows, không cần Mac)

Đường đi: **source trên GitHub → GitHub Actions (macOS, Xcode) build IPA chưa ký → tải về Windows → Sideloadly ký bằng
Apple Account miễn phí của bạn → iPhone**. App đã cài chạy độc lập, không cần máy tính bật.

- Hướng dẫn từng bước: [`docs/INSTALL_WINDOWS_IPHONE_VI.md`](docs/INSTALL_WINDOWS_IPHONE_VI.md)
- Gặp lỗi: [`docs/TROUBLESHOOTING_VI.md`](docs/TROUBLESHOOTING_VI.md)
- Checklist kiểm tra trên máy thật: [`docs/TEST_CHECKLIST_VI.md`](docs/TEST_CHECKLIST_VI.md)
- **Xem giao diện trước khi cài** (ảnh chụp trên iOS Simulator): [`docs/UI_PREVIEW_VI.md`](docs/UI_PREVIEW_VI.md)

IPA chưa ký **không** tự cài được bằng Safari; phải qua công cụ ký như Sideloadly. Build thành công ≠ cài thành công —
việc cài được xác nhận bằng checklist trên iPhone thật.

## Yêu cầu

- iPhone chạy **iOS 17.0 trở lên** (deployment target 17.0; cần đối chiếu với máy của bạn).
- Tài khoản GitHub (repo `Phuhot/cozyday` đang **private**), Apple Account (miễn phí được), máy Windows có Sideloadly + iTunes/iCloud
  bản tải từ Apple (theo yêu cầu hiện hành của Sideloadly).

## Giới hạn cần biết

- Ký bằng Apple Account miễn phí: app hết hạn sau khoảng **7 ngày** và cần ký lại (dữ liệu giữ nguyên nếu cùng bundle ID + cùng tài khoản);
  thường tối đa khoảng 3 app sideload cùng lúc. Tự refresh qua Wi-Fi cần PC đang bật.
- Thông báo là thông báo cục bộ; iOS có thể trì hoãn/ẩn theo Focus và cài đặt. Nhắc việc được lên lịch cho 7 ngày tới, làm mới khi mở app.
- Không có iCloud/đồng bộ. Gỡ app = mất dữ liệu trên máy. Hãy **Xuất sao lưu** định kỳ (file JSON không mã hóa).
- Chưa có widget, Live Activities, Apple Watch, chặn app, AI, đồng bộ nhiều máy (xem `PROJECT_STATUS.md` — lý do và kế hoạch).

## Cấu trúc source

```
Cozyday/
  App/            Điểm vào app, AppDelegate (thông báo)
  Core/           Logic thuần Foundation — test được trên Linux (ngày/lặp, timeline, replan,
                  sổ cái thưởng, cửa hàng, focus timer, nhắc việc, sao lưu, thống kê,
                  Care/ nhu cầu & đồ ăn, Play/ luật 3 minigame + quy đổi xu)
  Persistence/    Lược đồ SwiftData V1→V2→V3 + migration plan, AppStore (ghi theo giao dịch)
  Services/       Thông báo, điều hướng, trạng thái UI, file sao lưu
  DesignSystem/   Design tokens (màu, khoảng cách, bo góc, chữ, chuyển động) + component
  Features/       Today, Focus, Corner (mèo/phòng/cửa hàng), Care (chăm sóc, đồ ăn, dọn nhà),
                  Play (Sân chơi: vòng lặp khung hình, hình vẽ game, âm thanh tự tổng hợp), Journal, Progress,
                  Settings, Onboarding, Root
  Resources/      Info.plist, Assets.xcassets (icon gốc)
Tests/
  CoreTests/      Test logic (chạy cả `swift test` và trong Xcode)
  AppTests/       Test SwiftData thật trên iOS Simulator
project.yml       Đặc tả XcodeGen (project .xcodeproj được tạo trong CI, không commit)
Package.swift     Chỉ để chạy test logic bằng `swift test`
scripts/ci/       Script build/kiểm tra IPA mà workflow gọi
scripts/tools/    Script vẽ icon
.github/workflows/
  ios-unsigned.yml  Build IPA chưa ký (+ test simulator tùy chọn)
  core-tests.yml    Test logic trên Linux
```

## Build & test (dành cho người phát triển)

- **IPA:** GitHub → Actions → *iOS unsigned IPA* → Run workflow. Pin: runner `macos-26`, Xcode 26.6 (iOS SDK 26.5), XcodeGen 2.46.0 (kiểm SHA-256).
- **Test logic:** `swift test` (macOS/Linux có Swift 6.2+), hoặc workflow *Core logic tests (Linux)*.
- **Test app:** chọn "Chạy thêm unit test" khi Run workflow.
- Trên Mac (nếu sau này có): `xcodegen generate` rồi mở `Cozyday.xcodeproj`.

## Trạng thái

Xem [`PROJECT_STATUS.md`](PROJECT_STATUS.md): quyết định kỹ thuật, phiên bản đã pin, kết quả kiểm tra thực tế, việc còn mở.
