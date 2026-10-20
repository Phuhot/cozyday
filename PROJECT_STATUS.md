# PROJECT_STATUS — CozyDay

Cập nhật: 2026-10-19 (phiên 6) · Nhánh: `claude/ios-project-section-12-4bpxn7` · Repo: `Phuhot/cozyday` (private)

## Mốc hiện tại

| Mốc | Trạng thái |
|---|---|
| **A — kiểm chứng đường cài** | CI: **đã xác minh** (build Release iphoneos arm64 không ký, đóng gói, kiểm tra IPA, upload artifact — run #1). iPhone: **chưa xác minh** (chờ bạn cài thử). |
| **B — lõi dùng được** | Code xong: onboarding, task/timeline, Hộp chờ, mèo gốc, thưởng một lần, lưu SwiftData, sao lưu/khôi phục. Build IPA + 49 unit test: **đạt** (run #5). Trên máy thật: **chưa xác minh**. |
| **C — hoàn thiện 1.0** | Code xong: việc lặp, nhắc việc, focus timer, phòng/cửa hàng, nhật ký, thống kê, accessibility cơ bản. Build: **đạt**. Trên máy thật: **chưa xác minh**. |
| **E — chiều sâu (sau phản hồi cài thử)** | Thú cưng: 5 hình dạng, 8 màu lông, 34 món trang phục, 3 giai đoạn lớn, animation, vuốt ve + lời thoại, tủ đồ mặc thử, chuyến đi mỗi ngày + Sổ ký ức. Lập kế hoạch: việc con, kéo đổi giờ, sự kiện app Lịch (chỉ đọc), gợi ý nhật ký, bài thở, thống kê tâm trạng. Build + test simulator: **đạt** (run #12). Trên máy thật: **chưa xác minh**. |
| **F — phòng, bộ sưu tập, giao diện dễ thương (phiên 4)** | 5 không gian (phòng học, phòng ngủ, bếp, phòng tắm, vườn) mở theo cấp, 120+ đồ trang trí, tường & sàn/bầu trời đổi được · 11 loài, 11 màu lông, 80+ trang phục & phụ kiện (vị trí mới `back`) · Bộ sưu tập: 40 bộ phối sẵn, mua & mặc cả bộ · vuốt để nựng, giữ để nhấc & thả · 18 khuôn truyện theo loài/mùa, lời thoại theo loài · giao diện: thú cưng nói chuyện ở Hôm nay, popup thưởng có thú cưng, tuần của thú cưng, nút/thẻ mềm, nền họa tiết. Kiểm tra: run #14 (commit `7625744`) build Release + kiểm tra IPA **đạt**, **77/77 test** trên iOS Simulator **đạt**, 35 ảnh giao diện. Run #13 lỗi biên dịch (trùng tên `FlowChips`) → sửa ở run #14. Trên máy thật: **chưa xác minh**. |
| **G — chăm thú cưng + Sân chơi (phiên 5)** | Nhu cầu No bụng/Nhà sạch/Vui vẻ (suy giảm theo mốc thời gian, sàn 20, tối đa 24 giờ, không hình phạt) · khay & cửa hàng đồ ăn (6 món, `food-purchase:<id>`), bữa cơ bản miễn phí, dọn nhà (chạm/vuốt hoặc Dọn nhanh), nựng (vuốt thật ~3,5 s hoặc nút); thưởng nhỏ `care:<id>` có hạn mức · Sân chơi: Nhảy Mây, Giỏ Quà, Lật Thẻ Bạn Nhỏ — chơi bằng thú cưng đang có (đổi loài đã sở hữu chỉ trong Sân chơi), kỷ lục, xu phụ ≤ 6/lượt, ≤ 20/ngày (`minigame:<sessionID>`), tạm dừng tự động, đếm ngược khi tiếp tục, lưu một lần + thử lại cùng sessionID · lược đồ **V3** (chỉ thêm bảng), sao lưu **bản 2** (đọc được bản 1). Kiểm tra: **run #16** (commit `366305c`) build Release + kiểm tra IPA **đạt**, **122/122 test** trên iOS Simulator **đạt**, 92 test Core trên Linux (CI) **đạt**, chụp 65 ảnh + 3 video **đạt** (không crash). Ảnh trong repo là của run #15; ảnh run #16 (sau khi sửa bố cục chữ lớn) chỉ nằm trong artifact vì job lưu ảnh không chạy được — xem "Vấn đề còn mở". Trên máy thật: **chưa xác minh**. |
| **H — ảnh đại diện, icon, phản hồi cài thử (phiên 6)** | Tên hiển thị **CozyDay** (bundle ID `com.phuhot.cozyday`, kho `Cozyday.store` giữ nguyên → cài đè không mất dữ liệu) · icon mới: vịt con vàng đội mây (`AvatarPainter.appIcon`) · **Ảnh đại diện**: 10 nền, 8 phong cảnh, 9 hiệu ứng, 4 biểu cảm, trang phục riêng từ đồ đã có, mở theo cấp, lưu PNG qua bảng chia sẻ, thẻ ở Góc nhỏ + Tiến bộ, có trong sao lưu (trường tùy chọn) · Phản hồi cài thử: **Dọn nhà** bị kẹt cuộn → thành màn toàn màn hình, chà bằng chổi lông gà/khăn lau (mạng nhện, vết bùn, bụi, lá, giấy) · **Nhảy Mây** dễ quá → độ khó tối đa ở 160 m (trước 400 m), mây giông, chim, mây mỏng; vẫn luôn leo được (test 30 seed). Kiểm tra: 100 test Core trên Linux (máy Claude) **đạt**; **run #18** (commit `888708d`, chạy lại lần 5 sau khi gỡ chặn thanh toán): build Release + kiểm tra IPA **đạt** (`Cozyday-unsigned-ipa-run18`), unit test trên simulator **đạt**, ảnh + video **đạt** và đã lưu vào `docs/screenshots`. Ảnh cho thấy mạng nhện trong màn dọn nhà quá mờ trên tường sáng → đã đậm nét (commit sau run #18, chưa có trong IPA). Câu chữ trong app và truyện đã được viết lại: bỏ gạch ngang dài, câu sáo, emoji. Trên máy thật: **chưa xác minh**. |
| **I — trailer quảng cáo 30 giây (phiên 7)** | `marketing/trailer/out/CozyDay-trailer-30s.mp4` (1080×1920, 30 fps, H.264 + AAC, 7,5 MB) + ảnh bìa. Ghép từ: footage giao diện & gameplay thật quay trên iOS Simulator (workflow mới **Trailer footage**, chỉ chạy khi commit có `[trailer]`; run 1–3), cutscene vẽ bằng code vẽ của app (PetPainter/AvatarPainter/ItemPainter), icon thật trong asset catalog, nhạc + hiệu ứng tự tổng hợp. Bản Debug có thêm các màn `trailer…` tự thao tác (gọi đúng hàm của nút/cử chỉ); bản Release không vào các nhánh này. Kiểm tra: bản Debug build + chạy trên simulator **đạt** (trailer run 1–3, không màn nào crash); **chưa** chạy lại unit test simulator / build IPA Release sau các thay đổi chỉ-Debug này. Storyboard và cách dựng lại: [`marketing/trailer/`](marketing/trailer/README.md). |
| **D — bàn giao** | Tài liệu cài đặt, xử lý sự cố, dữ liệu/quy tắc, checklist đã có. **Ảnh giao diện** chụp tự động trên iOS Simulator: [`docs/UI_PREVIEW_VI.md`](docs/UI_PREVIEW_VI.md). Còn chờ: kết quả cài thử trên iPhone. |

## Quyết định kỹ thuật

- **Native Swift + SwiftUI**, iOS **17.0** (giả định — cần đối chiếu iPhone của bạn), chỉ iPhone, dọc.
- **SwiftData** với `VersionedSchema` V1 → V2 (thêm việc con) → **V3** (thêm bảng chăm sóc + Sân chơi), đều migration nhẹ + `SchemaMigrationPlan`; `cloudKitDatabase: .none`; store riêng `Cozyday.store`.
  Không dùng relationship (tham chiếu bằng ID) để quy tắc xóa rõ ràng và sổ cái không bị cascade.
- **Một lớp ghi duy nhất** `AppStore` (@MainActor): mọi thao tác = kiểm tra bằng Core → sửa model → `save()` một lần; lỗi → `rollback()`.
- **Core thuần Foundation** (`Cozyday/Core`) biên dịch cả trong app và trong `Package.swift` để test trên Linux.
- **Số dư xu/XP = tổng sổ cái** (không lưu số dư riêng). Khóa sổ cái: `task:<id>`, `focus:<id>`, `journal:<ngày>`, `purchase:<item>`,
  `food-purchase:<transactionID>` (đồ ăn mua lặp lại), `care:<careActionID>`, `minigame:<sessionID>`.
- **Minigame vẽ bằng SwiftUI Canvas + CADisplayLink** (không SpriteKit): dùng lại `PetPainter`, vẽ thử được trên Linux;
  bạn nhỏ được dựng sẵn thành ảnh một lần cho mỗi (ngoại hình, tư thế, cỡ) — bộ đệm tối đa 24 ảnh. Luật chơi, va chạm,
  điểm, thưởng nằm trong `Core/Play` (thuần, có seed, test được); thời gian lượt = tổng các bước thời gian thật khi đang chơi
  (khung khựng > 0,1 s chỉ tính 0,1 s), không đếm khung hình. Âm thanh tự tổng hợp (AVAudioEngine, phiên `.ambient`).
- **Nhu cầu thú cưng** tính lười từ mốc `asOf` đã lưu (không timer nền); chỉ ghi khi có hành động chăm sóc.
- **Giờ của việc = giờ đồng hồ địa phương** + khóa ngày `yyyy-MM-dd`; mốc tuyệt đối dùng `Date`. Phép tính ngày qua `Calendar`.
- **Focus timer**: nguồn sự thật là mốc thời gian đã lưu; UI chỉ vẽ; thông báo cục bộ khi hết giờ; không background audio.
- **Thông báo**: ID ổn định (`task.<uuid>`, `focus.end`, `journal.daily`), cửa sổ 7 ngày, tối đa 60 nhắc việc (giới hạn iOS 64).
- **Thú cưng** vẽ theo lớp bằng Canvas (đuôi → tai → thân → áo → mặt → kính → cổ → mũ), animation tính từ thời gian
  (`TimelineView`), tắt khi bật Giảm chuyển động. Ngoại hình suy ra từ kho đồ + vị trí trang bị — **không đổi lược đồ**.
- **Mèo, đồ nội thất, mood** vẽ bằng SwiftUI Canvas; icon = `AvatarPainter.appIcon` (vịt con vàng đội mây) xuất ra PNG 1024 không alpha. Không tải ảnh ngoài.
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
| **Run #13–#14**: phòng, bộ sưu tập, loài mới — build Release, kiểm tra IPA, unit test, chụp 35 ảnh | **Đạt** ở run #14: **77/77 test** trên iOS Simulator (gồm mua cả bộ "tất cả hoặc không", khóa đồ theo cấp mở phòng). Run #13 lỗi biên dịch → đã sửa |
| `swift test` Core trên Linux (61 test) | **Đạt** (phiên 4) |
| **Run #15** (commit `cd5b8a7`, phiên 5 — chăm thú cưng + Sân chơi): build Release + kiểm tra IPA | **Đạt** — `Cozyday-unsigned-ipa-run15`, 1,8 MB, `iphoneos/arm64`, MinimumOS 17.0, bundle `com.phuhot.cozyday`; 1 cảnh báo biên dịch (`Identifiable` của PlayHostModel) → đã sửa |
| Run #15: unit test trên iOS Simulator | **Đạt 122/122** (gồm `CareAndPlayStoreTests`, migration V2 → V3 trên kho thật, sao lưu bản 1/bản 2) |
| Run #15: 65 ảnh + 3 video gameplay trên simulator | **Đạt**, không màn nào crash. Claude đã xem từng ảnh mới: thấy bố cục chữ rất lớn bị chật ở Đồ ăn/Sân chơi → sửa ở run #16. Video nằm trong artifact (Claude không tải được do proxy chặn máy chủ lưu artifact) — thay vào đó đối chiếu ảnh chụp liên tiếp với giờ trong log: đồng hồ Giỏ Quà chạy 25 s trong 25,3 s thực; Nhảy Mây leo 3,6 m/s (≤ giới hạn vật lý ~4 m/s) |
| **Run #16** (commit `366305c`, bản cuối phiên 5): build Release + kiểm tra IPA, 122/122 test simulator, chụp ảnh + video | **Đạt** — artifact `Cozyday-unsigned-ipa-run16`, `Cozyday-ui-screenshots-run16`, `Cozyday-gameplay-videos-run16`. Workflow *Core logic tests (Linux)* run #4 **đạt**. Job Ubuntu *Lưu ảnh giao diện vào docs/screenshots* **không khởi động** — GitHub báo: *"The job was not started because recent account payments have failed or your spending limit needs to be increased"* (bạn chụp màn hình xác nhận). Không phải lỗi code |
| `swift test` Core trên Linux (92 test, phiên 5) | **Đạt** — thêm 31 test: nhu cầu, đồ ăn, thưởng/hạn mức, máy trạng thái lượt chơi, 3 engine game (có "người chơi máy" leo > 200 m với 31 seed) |
| Minigame vẽ thử trên Linux (mây, sao, quà, bùn/mây mưa có dấu ✕, giỏ, đồ ăn, bụi) | **Đạt**, đã xem bằng mắt |
| Hình vẽ phòng/thú cưng kiểm tra kiểu + vẽ thử ra PNG trên Linux (SwiftUI giả xuất SVG, chỉ để xem trước — không thay cho build thật) | **Đạt**: mọi món đồ, 6 loài mới, 40 bộ phối đều đã được vẽ ra và xem bằng mắt |
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
5. Cử chỉ nhấc/nựng thú cưng nằm trong ScrollView của Góc nhỏ: cần thử trên máy thật xem có tranh chấp với cuộn trang không.
   (Dọn nhà đã chuyển sang màn riêng toàn màn hình ở phiên 6 — không còn khóa cuộn trang.)
6. Ảnh giao diện chỉ chụp trên iOS 26 (runner không có sẵn simulator iOS 17/18). Giao diện iOS 17–18 (không có Liquid Glass) chưa được xem.
7. Sân chơi chưa được chơi bằng tay trên máy thật: cảm giác kéo, độ khó, tốc độ khung hình (simulator CI không có GPU thật),
   âm thanh, rung, VoiceOver trong 2 game hành động (vuốt lên/xuống để di chuyển) đều **chưa xác minh**.
8. Hạn mức theo ngày (chăm sóc, Sân chơi) đổi theo ngày giờ của máy — app offline không chống được việc chỉnh giờ (đã ghi trong tài liệu).
9. Run #16: job lưu ảnh (Ubuntu) bị GitHub chặn vì **thanh toán thất bại hoặc chạm giới hạn chi tiêu Actions** (đã xác nhận qua
   thông báo của GitHub). Trước khi xử lý ở *Settings → Billing and plans*, mọi lần build mới (kể cả IPA) đều có thể bị chặn.
   Phần sửa bố cục chữ rất lớn (Đồ ăn, Sân chơi) ở run #16 vì vậy **chưa được Claude xem lại bằng ảnh**.
   Run #17 (commit `b7649d4`) và các lần sau: **mọi job** (cả test Linux) dừng sau 5–9 giây, không có log → GitHub không cấp máy chạy.
   Vì vậy code phiên 6 (ảnh đại diện, dọn nhà, Nhảy Mây, icon, tên CozyDay) **chưa được biên dịch cho iOS**; chỉ phần Core đã
   qua 100 test trên Linux ở máy Claude. Sau khi sửa thanh toán: mở run mới nhất trên nhánh → *Re-run all jobs*.

## Bước tiếp theo

1. Bạn: trả lời 3 câu hỏi (iPhone + iOS; Windows 10/11; GitHub/Sideloadly + private/public).
2. Bạn: tải artifact IPA mới nhất → cài bằng Sideloadly → chạy checklist `docs/TEST_CHECKLIST_VI.md` → gửi kết quả/ảnh lỗi.
3. Bạn: thử các mục "Chăm thú cưng" và "Sân chơi" trong checklist (nhất là kéo một tay, tạm dừng khi vuốt về màn hình chính, hạn mức 40 xu).
4. Claude: sửa lỗi theo phản hồi thiết bị; chỉnh độ khó/độ nhạy kéo của minigame theo cảm nhận của bạn.
5. Bạn: thử Dọn nhà mới (chổi/khăn), Nhảy Mây có chướng ngại, Ảnh đại diện → báo độ khó và cảm giác chà có vừa không.

## Backlog sau 1.0 (không làm trong bản này)

Widget · Live Activities · đồng bộ iCloud · SideStore · lưu nhiều bộ phối của riêng bạn · xuất lịch (.ics) · mã hóa file sao lưu ·
nhạc nền tự sáng tác cho Sân chơi · thêm minigame · kéo món ăn thả vào thú cưng (hiện chỉ có nút Cho ăn).
