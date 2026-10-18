# PROJECT_STATUS — Cozyday

Cập nhật: 2026-10-18 (phiên 3) · Nhánh: `claude/ios-project-section-12-4bpxn7` · Repo: `Phuhot/cozyday` (private)

## Mốc hiện tại

| Mốc | Trạng thái |
|---|---|
| **A — kiểm chứng đường cài** | CI: **đã xác minh** (build Release iphoneos arm64 không ký, đóng gói, kiểm tra IPA, upload artifact — run #1). iPhone: **chưa xác minh** (chờ bạn cài thử). |
| **B — lõi dùng được** | Code xong: onboarding, task/timeline, Hộp chờ, mèo gốc, thưởng một lần, lưu SwiftData, sao lưu/khôi phục. Build IPA + 49 unit test: **đạt** (run #5). Trên máy thật: **chưa xác minh**. |
| **C — hoàn thiện 1.0** | Code xong: việc lặp, nhắc việc, focus timer, phòng/cửa hàng, nhật ký, thống kê, accessibility cơ bản. Build: **đạt**. Trên máy thật: **chưa xác minh**. |
| **E — chiều sâu (sau phản hồi cài thử)** | Thú cưng: 5 hình dạng, 8 màu lông, 34 món trang phục, 3 giai đoạn lớn, animation, vuốt ve + lời thoại, tủ đồ mặc thử, chuyến đi mỗi ngày + Sổ ký ức. Lập kế hoạch: việc con, kéo đổi giờ, sự kiện app Lịch (chỉ đọc), gợi ý nhật ký, bài thở, thống kê tâm trạng. Build + test simulator: **đạt** (run #12). Trên máy thật: **chưa xác minh**. |
| **D — bàn giao** | Tài liệu cài đặt, xử lý sự cố, dữ liệu/quy tắc, checklist đã có. **Ảnh giao diện** chụp tự động trên iOS Simulator: [`docs/UI_PREVIEW_VI.md`](docs/UI_PREVIEW_VI.md). Còn chờ: kết quả cài thử trên iPhone. |

## Quyết định kỹ thuật

- **Native Swift + SwiftUI**, iOS **17.0** (giả định — cần đối chiếu iPhone của bạn), chỉ iPhone, dọc.
- **SwiftData** với `VersionedSchema` V1 → **V2** (thêm việc con, migration nhẹ) + `SchemaMigrationPlan`; `cloudKitDatabase: .none`; store riêng `Cozyday.store`.
  Không dùng relationship (tham chiếu bằng ID) để quy tắc xóa rõ ràng và sổ cái không bị cascade.
- **Một lớp ghi duy nhất** `AppStore` (@MainActor): mọi thao tác = kiểm tra bằng Core → sửa model → `save()` một lần; lỗi → `rollback()`.
- **Core thuần Foundation** (`Cozyday/Core`) biên dịch cả trong app và trong `Package.swift` để test trên Linux.
- **Số dư xu/XP = tổng sổ cái** (không lưu số dư riêng). Khóa sổ cái: `task:<id>`, `focus:<id>`, `journal:<ngày>`, `purchase:<item>`.
- **Giờ của việc = giờ đồng hồ địa phương** + khóa ngày `yyyy-MM-dd`; mốc tuyệt đối dùng `Date`. Phép tính ngày qua `Calendar`.
- **Focus timer**: nguồn sự thật là mốc thời gian đã lưu; UI chỉ vẽ; thông báo cục bộ khi hết giờ; không background audio.
- **Thông báo**: ID ổn định (`task.<uuid>`, `focus.end`, `journal.daily`), cửa sổ 7 ngày, tối đa 60 nhắc việc (giới hạn iOS 64).
- **Thú cưng** vẽ theo lớp bằng Canvas (đuôi → tai → thân → áo → mặt → kính → cổ → mũ), animation tính từ thời gian
  (`TimelineView`), tắt khi bật Giảm chuyển động. Ngoại hình suy ra từ kho đồ + vị trí trang bị — **không đổi lược đồ**.
- **Mèo, đồ nội thất, mood** vẽ bằng SwiftUI Canvas; icon vẽ bằng `scripts/tools/make_icon.py`. Không tải ảnh ngoài.
- **CI**: XcodeGen tạo project; `xcodebuild archive` Release `-sdk iphoneos -destination generic/platform=iOS ARCHS=arm64`
  với `CODE_SIGNING_ALLOWED=NO`; đóng gói `Payload/Cozyday.app` bằng `ditto` + `zip -y`; script kiểm tra IPA fail nếu thiếu/sai.
- Swift language mode 5 (trình biên dịch Swift 6.3 của Xcode 26.6) để tránh lỗi strict concurrency không cần thiết.

## Phiên bản đã pin (đã đối chiếu 18/10/2026)

| Thành phần | Phiên bản | Nguồn xác minh |
|---|---|---|
| Runner | `macos-26` (arm64), image 20261013 | actions/runner-images README + log run |
| Xcode | 26.6 (17F113), Swift 6.3.3, iOS SDK 26.5 (23F81a) | log "In phiên bản công cụ" |
| XcodeGen | 2.46.0, SHA-256 `4d9e34b6…6806` | GitHub Releases yonaskolb/XcodeGen |
| actions/checkout | v7 (v7.0.1) | tags của repo action |
| actions/upload-artifact | v7 (v7.0.2), node24 | action.yml |
| Swift Linux (test Core) | 6.2 (`swift:6.2-noble`) | Docker Hub |
| Bundle ID | `com.phuhot.cozyday` | `project.yml`, kiểm trong `verify_ipa.sh` |
| Deployment target | iOS 17.0 | `project.yml` |

## Kết quả kiểm tra thực tế

| Kiểm tra | Kết quả |
|---|---|
| `swift test` Core (38 test) trên Linux, Swift 6.2.4 (máy của Claude) | **Đạt** |
| Workflow *Core logic tests (Linux)* trên GitHub (run #1) | **Đạt** |
| Workflow *iOS unsigned IPA* run #1 (Mốc A): build + verify + artifact + test simulator | **Đạt** — IPA 164 KB, `iphoneos/iPhoneOS/arm64`, MinimumOS 17.0 |
| Run #2 (Mốc B/C lần đầu) | **Lỗi biên dịch** (`private(set)` + extension khác file) → đã sửa |
| Run #3: build Release + kiểm tra cấu trúc IPA + upload | **Đạt** (job test bị Claude huỷ sớm vì tưởng treo — thực ra simulator khởi động chậm) |
| **Run #5** (commit `a621802`): build Release + kiểm tra IPA + upload | **Đạt** — `Cozyday-unsigned-ipa-run5`, 840 KB, SHA-256 `19f669c86cd8518391b008c0b991664b6dbba46b85d4d42677a8b7efca5ff6d0`, `iphoneos/iPhoneOS/arm64`, MinimumOS 17.0, version 0.1.0 (5), 0 cảnh báo biên dịch trong source |
| **Run #5**: unit test trên iOS Simulator (iOS 26.5) | **Đạt 49/49** (11 test SwiftData `AppTests` + 38 test logic) |
| **Run #6–#9** (ảnh mới nhất: run #9, commit `8363e7f`): chụp 18 ảnh giao diện trên iOS Simulator (iPhone 17 Pro, iOS 26.5; sáng, tối, cỡ chữ Trợ năng lớn nhất) | **Đạt**, không màn nào crash. Ảnh ở `docs/screenshots/`. Claude đã xem từng ảnh và sửa 6 lỗi (bên dưới) |
| Bản Release không chứa chế độ dữ liệu mẫu (`CozyPreview`) | **Đạt** — `verify_ipa.sh` kiểm tra mỗi lần build |
| Thời lượng thực tế mỗi run | Build IPA ≈ 1,5 phút macOS; test simulator ≈ 5–11 phút (phần lớn là khởi động simulator); chụp ảnh ≈ 4–6 phút |
| **Run #10–#12**: thú cưng mới + việc con/lịch/bài thở — build Release, kiểm tra IPA, unit test, chụp 27 ảnh | **Đạt** ở run #12 (commit `882099a`): **68/68 test** trên iOS Simulator, gồm test migration V1→V2 trên kho thật và test tủ đồ/chuyến đi. Run #10 lỗi biên dịch (`switch` thiếu case) → sửa ở run #11 |
| `swift test` Core trên Linux (54 test) | **Đạt** |
| Cài IPA bằng Sideloadly lên iPhone thật (bản đầu) | Bạn báo **đã cài thử được** (phiên 3) — chưa có checklist chi tiết |
| Mở độc lập khi tắt PC, offline, dữ liệu sau khi tắt/mở app | **Chưa xác minh** |
| Giao diện (bố cục, dark mode, Dynamic Type) | **Đã xem qua ảnh simulator** iPhone 17 Pro / iOS 26.5. **Chưa xem** trên máy thật, trên iOS 17–18, màn nhỏ (SE/mini) |
| VoiceOver, thao tác chạm/kéo thật | **Chưa xác minh** |
| Thông báo thật trên thiết bị | **Chưa xác minh** |

## Lỗi giao diện phát hiện qua ảnh simulator (đã sửa)

1. Số xu ở thanh công cụ chỉ hiện biểu tượng (iOS 26 thu gọn item tùy biến) → số xu đưa vào nội dung (Góc nhỏ, Cửa hàng, Tiến bộ).
2. Nút "Hộp chờ (N)" ở thanh công cụ mất chữ → thêm dòng "Hộp chờ: N việc chưa xếp lịch" trong màn Hôm nay.
3. Timeline luôn bắt đầu 07:00, mở app buổi chiều phải cuộn mới thấy việc → bắt đầu từ việc đầu tiên / 1 giờ trước hiện tại.
4. Cài đặt: hai ô tên không có nhãn → "Tên của bạn", "Tên mèo".
5. Cỡ chữ Trợ năng: số ngày trên thanh tuần bị bẻ "1/8" → thu nhỏ chữ trong ô, không xuống dòng.
6. Dark mode: chữ trắng trên nút lavender/sage sáng chỉ ~2:1 → chữ tối (~7–8:1).

## Chưa làm (có lý do)

- **Widget màn hình chính, Live Activity cho hẹn giờ, Apple Watch**: cần thêm *app extension*. Với Apple Account miễn phí,
  mỗi extension tốn thêm một App ID (giới hạn khoảng 10 App ID / 7 ngày), và widget cần App Group để đọc dữ liệu của app —
  chưa chắc Sideloadly ký được App Group bằng tài khoản miễn phí. Đề xuất: làm thành một bản IPA *thử nghiệm riêng* để bạn
  cài thử, không gộp vào bản chính cho tới khi chắc chắn cài được.
- **AI tự xếp lịch**: đặc tả không dùng AI trả phí; "Sắp xếp lại" dùng thuật toán xác định.
- **Đồng bộ nhiều thiết bị, bạn bè/tặng quà**: cần máy chủ hoặc iCloud — ngoài phạm vi (offline, không tài khoản).

## Vấn đề còn mở / rủi ro

1. Chưa biết **mẫu iPhone và phiên bản iOS** của bạn → deployment target 17.0 là giả định. Nếu máy < iOS 17 cần đổi hướng lưu trữ (SwiftData yêu cầu iOS 17).
2. Chưa biết bạn chọn **private hay public** cho repo; hiện private → phút macOS có hạn mức.
3. Workflow nằm trên nhánh `claude/…`; cần **merge vào `main`** để có nút Run workflow (hoặc nhờ Claude mở Pull Request).
4. Trang sideloadly.io không truy cập được từ môi trường của Claude → yêu cầu Windows/iTunes/auto-refresh trong tài liệu cần bạn đối chiếu trang chính thức.
5. Chưa có kéo-thả để đổi giờ (đã có form "Đổi ngày/giờ" thay thế, dùng được với VoiceOver).
6. Ảnh giao diện chỉ chụp trên iOS 26 (runner không có sẵn simulator iOS 17/18). Giao diện iOS 17–18 (không có Liquid Glass) chưa được xem.

## Bước tiếp theo

1. Bạn: trả lời 3 câu hỏi (iPhone + iOS; Windows 10/11; GitHub/Sideloadly + private/public).
2. Bạn: tải artifact IPA mới nhất → cài bằng Sideloadly → chạy checklist `docs/TEST_CHECKLIST_VI.md` → gửi kết quả/ảnh lỗi.
3. Claude: sửa lỗi theo phản hồi thiết bị; tinh chỉnh giao diện theo ảnh chụp từ iPhone thật của bạn.

## Backlog sau 1.0 (không làm trong bản này)

Kéo-thả đổi giờ trên timeline · widget · Live Activities · đồng bộ iCloud · SideStore · thêm đồ/pet · xuất lịch (.ics) · mã hóa file sao lưu.
