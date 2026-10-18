# PROJECT_STATUS — Cozyday

Cập nhật: 2026-10-18 · Nhánh: `claude/ios-project-section-12-4bpxn7` · Repo: `Phuhot/cozyday` (private)

## Mốc hiện tại

| Mốc | Trạng thái |
|---|---|
| **A — kiểm chứng đường cài** | CI: **đã xác minh** (build Release iphoneos arm64 không ký, đóng gói, kiểm tra IPA, upload artifact — run #1). iPhone: **chưa xác minh** (chờ bạn cài thử). |
| **B — lõi dùng được** | Code xong: onboarding, task/timeline, Hộp chờ, mèo gốc, thưởng một lần, lưu SwiftData, sao lưu/khôi phục. Build IPA + 49 unit test: **đạt** (run #5). Trên máy thật: **chưa xác minh**. |
| **C — hoàn thiện 1.0** | Code xong: việc lặp, nhắc việc, focus timer, phòng/cửa hàng, nhật ký, thống kê, accessibility cơ bản. Build: **đạt**. Trên máy thật: **chưa xác minh**. |
| **D — bàn giao** | Tài liệu cài đặt, xử lý sự cố, dữ liệu/quy tắc, checklist đã có. Còn chờ: kết quả cài thử trên iPhone, kiểm tra UI bằng mắt. |

## Quyết định kỹ thuật

- **Native Swift + SwiftUI**, iOS **17.0** (giả định — cần đối chiếu iPhone của bạn), chỉ iPhone, dọc.
- **SwiftData** với `VersionedSchema` V1 + `SchemaMigrationPlan`; `cloudKitDatabase: .none`; store riêng `Cozyday.store`.
  Không dùng relationship (tham chiếu bằng ID) để quy tắc xóa rõ ràng và sổ cái không bị cascade.
- **Một lớp ghi duy nhất** `AppStore` (@MainActor): mọi thao tác = kiểm tra bằng Core → sửa model → `save()` một lần; lỗi → `rollback()`.
- **Core thuần Foundation** (`Cozyday/Core`) biên dịch cả trong app và trong `Package.swift` để test trên Linux.
- **Số dư xu/XP = tổng sổ cái** (không lưu số dư riêng). Khóa sổ cái: `task:<id>`, `focus:<id>`, `journal:<ngày>`, `purchase:<item>`.
- **Giờ của việc = giờ đồng hồ địa phương** + khóa ngày `yyyy-MM-dd`; mốc tuyệt đối dùng `Date`. Phép tính ngày qua `Calendar`.
- **Focus timer**: nguồn sự thật là mốc thời gian đã lưu; UI chỉ vẽ; thông báo cục bộ khi hết giờ; không background audio.
- **Thông báo**: ID ổn định (`task.<uuid>`, `focus.end`, `journal.daily`), cửa sổ 7 ngày, tối đa 60 nhắc việc (giới hạn iOS 64).
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
| Thời lượng thực tế mỗi run | Build IPA ≈ 1,5 phút macOS; test simulator ≈ 9,5 phút (≈ 8 phút là khởi động simulator) |
| Cài IPA bằng Sideloadly lên iPhone thật | **Chưa xác minh** |
| Mở độc lập khi tắt PC, offline, dữ liệu sau khi tắt/mở app | **Chưa xác minh** |
| Giao diện (bố cục, dark mode, Dynamic Type, VoiceOver) | **Chưa xác minh bằng mắt** — chưa chạy trên simulator có giao diện hay máy thật |
| Thông báo thật trên thiết bị | **Chưa xác minh** |

## Vấn đề còn mở / rủi ro

1. Chưa biết **mẫu iPhone và phiên bản iOS** của bạn → deployment target 17.0 là giả định. Nếu máy < iOS 17 cần đổi hướng lưu trữ (SwiftData yêu cầu iOS 17).
2. Chưa biết bạn chọn **private hay public** cho repo; hiện private → phút macOS có hạn mức.
3. Workflow nằm trên nhánh `claude/…`; cần **merge vào `main`** để có nút Run workflow (hoặc nhờ Claude mở Pull Request).
4. Trang sideloadly.io không truy cập được từ môi trường của Claude → yêu cầu Windows/iTunes/auto-refresh trong tài liệu cần bạn đối chiếu trang chính thức.
5. Chưa có kéo-thả để đổi giờ (đã có form "Đổi ngày/giờ" thay thế, dùng được với VoiceOver).

## Bước tiếp theo

1. Bạn: trả lời 3 câu hỏi (iPhone + iOS; Windows 10/11; GitHub/Sideloadly + private/public).
2. Bạn: tải artifact IPA mới nhất → cài bằng Sideloadly → chạy checklist `docs/TEST_CHECKLIST_VI.md` → gửi kết quả/ảnh lỗi.
3. Claude: sửa lỗi theo phản hồi thiết bị; tinh chỉnh giao diện sau khi có ảnh chụp màn hình.

## Backlog sau 1.0 (không làm trong bản này)

Kéo-thả đổi giờ trên timeline · widget · Live Activities · đồng bộ iCloud · SideStore · thêm đồ/pet · xuất lịch (.ics) · mã hóa file sao lưu.
