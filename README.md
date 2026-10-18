# Cozyday

App iPhone dùng cá nhân: sắp xếp một ngày thành **timeline** trực quan, hoàn thành việc để chăm **chú mèo tròn màu kem**
và trang trí góc phòng nhỏ. Native Swift + SwiftUI + SwiftData, chạy **offline**, không tài khoản, không máy chủ,
không quảng cáo, không mua hàng trong app.

> Lấy cảm hứng về *cách giải quyết nhu cầu* từ các app lập lịch và app thú cưng tự chăm sóc, nhưng tên, bố cục, mèo,
> đồ nội thất, icon và câu chữ đều là tài sản gốc của dự án (vẽ bằng code / script trong repo).

## App làm gì

| Tab | Nội dung |
|---|---|
| **Hôm nay** | Đầu trang gọn (ngày, lời chào, mèo nhỏ, tiến độ) · thanh chọn ngày theo tuần + nút về hôm nay · nhóm việc chưa xếp giờ · timeline dọc với đường "bây giờ", việc trùng giờ chia cột không đè chữ · chế độ Danh sách (tự bật khi cỡ chữ rất lớn) · Hộp chờ · **Sắp xếp lại** việc trễ (xem trước, có Hủy) · nút + thêm việc · mở **Tập trung** |
| **Góc nhỏ** | Mèo có 4 trạng thái (thư giãn, vui, tập trung, nghỉ) · phòng 5 vị trí cố định (tường, đèn, bàn, cây, ghế/thảm) · cấp độ XP · **cửa hàng 15 món** (3 miễn phí): xem trước, mua, đặt vào phòng, thay, bỏ |
| **Nhật ký** | Mood 1–5 có nhãn chữ + một đoạn ghi chú · lịch tháng tô màu theo mood · xem/sửa ngày cũ |
| **Tiến bộ** | Việc đã xong, phút tập trung, số ngày có hoạt động, chuỗi ngày · biểu đồ 7/30 ngày · lịch sử xu & vật phẩm. Chỉ dữ liệu thật. |
| **Cài đặt** (nút bánh răng) | Tên, khung giờ trong ngày, rung, thông báo, **Xuất / Khôi phục sao lưu**, quy tắc phần thưởng, quyền riêng tư |

Việc: tạo / sửa / xóa / hoàn thành / bỏ hoàn thành / bỏ qua / chuyển ngày · nhóm, ưu tiên, ghi chú, giờ hoặc chỉ thời lượng,
nhắc trước · lặp hằng ngày hoặc theo thứ, có ngày kết thúc · sửa/xóa việc lặp "chỉ lần này" hoặc "lần này và các lần sau".
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
- Bản 1.0 không có widget, Live Activities, Apple Watch, chặn app, AI.

## Cấu trúc source

```
Cozyday/
  App/            Điểm vào app, AppDelegate (thông báo)
  Core/           Logic thuần Foundation — test được trên Linux (ngày/lặp, timeline, replan,
                  sổ cái thưởng, cửa hàng, focus timer, nhắc việc, sao lưu, thống kê)
  Persistence/    Lược đồ SwiftData V1 + migration plan, AppStore (ghi theo giao dịch)
  Services/       Thông báo, điều hướng, trạng thái UI, file sao lưu
  DesignSystem/   Design tokens (màu, khoảng cách, bo góc, chữ, chuyển động) + component
  Features/       Today, Focus, Corner (mèo/phòng/cửa hàng), Journal, Progress, Settings, Onboarding, Root
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
