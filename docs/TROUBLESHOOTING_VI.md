# Xử lý sự cố Cozyday

Nguyên tắc chung:

- **Đọc lỗi đầu tiên có ý nghĩa**, không phải dòng cuối. Trong log GitHub Actions, script in sẵn khối
  `---- 40 dòng lỗi đầu tiên ----` khi build/test thất bại.
- **Không xóa app hay dữ liệu** để "thử lại từ đầu" khi chưa xuất sao lưu và chưa hiểu nguyên nhân.
- Khi nhờ Claude sửa: gửi **tên bước bị đỏ** + **khoảng 30 dòng quanh dòng `error:` đầu tiên** + nội dung `build-info.txt`
  (nếu có). Không gửi mật khẩu, mã 2FA, chứng chỉ, pairing file, file sao lưu hay nội dung nhật ký.

Mỗi mục: **Triệu chứng → Xem gì → Nguyên nhân thường gặp → Cách xử lý ít rủi ro nhất**.

---

## 1. GitHub Actions

### 1.1 Không thấy workflow / không có nút "Run workflow"

- **Xem gì:** repo có file `.github/workflows/ios-unsigned.yml` trên nhánh `main` không (chọn nhánh `main` → mở thư mục `.github`).
  Tab **Settings → Actions → General**: mục *Actions permissions* có đang cho phép chạy không.
- **Nguyên nhân:** (a) code mới chỉ nằm ở nhánh `claude/…`, chưa merge vào `main` — nút *Run workflow* chỉ hiện cho workflow trên nhánh mặc định;
  (b) tải source ZIP rồi tự upload qua web nhưng thiếu thư mục ẩn `.github`; (c) Actions bị tắt.
- **Xử lý:** merge Pull Request vào `main` (hướng dẫn cài, mục A3); hoặc upload lại đúng đường dẫn `.github/workflows/ios-unsigned.yml`;
  bật Actions trong Settings. Trong khi chờ, các lần push lên nhánh `claude/**` vẫn tự chạy build.

### 1.2 Workflow báo hết phút / "spending limit" / job không khởi động

- **Xem gì:** GitHub → ảnh đại diện → **Settings → Billing and licensing** → mục Usage của Actions.
- **Nguyên nhân:** repo private dùng hạn mức phút miễn phí theo tháng; phút macOS được tính theo hệ số cao (thường ×10).
- **Xử lý:** chờ sang tháng (hạn mức reset), chỉ chạy workflow khi thật sự cần, **bỏ chọn** "Chạy thêm unit test" khi chỉ cần IPA.
  Cân nhắc chuyển repo sang public nếu chấp nhận lộ source (không có dữ liệu cá nhân trong repo). Không bắt buộc gắn thẻ thanh toán.

### 1.3 Bước "Chọn Xcode" lỗi: `Không thấy /Applications/Xcode_26.6.app`

- **Nguyên nhân:** GitHub cập nhật image `macos-26` và gỡ bản Xcode đã pin.
- **Xem gì:** log của bước đó in danh sách Xcode đang có.
- **Xử lý:** sửa `XCODE_VERSION` trong `.github/workflows/ios-unsigned.yml` sang một bản trong danh sách (ưu tiên bản ổn định mới nhất, không lấy beta),
  đối chiếu https://github.com/actions/runner-images (file `images/macos/macos-26-arm64-Readme.md`). Nếu `macos-26` bị khai tử, đổi `runs-on`.

### 1.4 Bước "Cài XcodeGen" lỗi SHA-256 không khớp

- **Nguyên nhân:** file tải về khác file đã kiểm (bị thay đổi hoặc tải lỗi).
- **Xử lý:** chạy lại một lần. Nếu vẫn sai: **đừng** tắt kiểm tra; báo cho Claude để xác minh lại bản phát hành chính thức của XcodeGen
  và cập nhật `XCODEGEN_SHA256`.

---

## 2. Lỗi biên dịch Swift / cấu hình project

### 2.1 `error:` trong file `.swift`

- **Xem gì:** khối "40 dòng lỗi đầu tiên" trong bước **Build Release cho thiết bị**; artifact `build-logs-device-runN` chứa
  `xcodebuild-archive.log` đầy đủ.
- **Xử lý:** gửi dòng `…/Tên.swift:dòng:cột: error: …` đầu tiên cho Claude. Một lỗi có thể kéo theo nhiều lỗi sau — sửa lỗi đầu trước.

### 2.2 Lỗi deployment target / API "only available in iOS 18"

- **Nguyên nhân:** dùng API mới hơn iOS 17 mà thiếu kiểm tra `if #available`.
- **Xử lý:** báo Claude; không hạ/tăng `IPHONEOS_DEPLOYMENT_TARGET` tùy tiện vì iPhone của bạn cần chạy được bản build.

### 2.3 Thiếu scheme/target, thiếu icon (`AppIcon`), `Assets.car`

- **Xem gì:** bước "Tạo Xcode project" (in `xcodebuild -list`) và bước "Kiểm tra cấu trúc IPA".
- **Nguyên nhân:** `project.yml` bị sửa sai thụt lề YAML; thư mục `Cozyday/Resources/Assets.xcassets` bị thiếu/đổi tên.
- **Xử lý:** khôi phục `project.yml`/asset từ commit trước (GitHub → file → *History*), hoặc gửi lỗi cho Claude.

---

## 3. IPA sai loại / sai cấu trúc / chữ ký

### 3.1 Bước kiểm tra báo `DTPlatformName='iphonesimulator'` hoặc `platform IOSSIMULATOR`

- **Nguyên nhân:** build nhầm cho simulator. Bản simulator **không bao giờ** chạy được trên iPhone thật.
- **Xử lý:** không dùng IPA đó. Script build luôn dùng `-sdk iphoneos -destination generic/platform=iOS`; nếu ai sửa script, khôi phục lại.

### 3.2 Sideloadly báo IPA hỏng / "Invalid IPA" / không tìm thấy Payload

- **Xem gì:** bạn có đang kéo **artifact ZIP** thay vì **IPA bên trong** không? Đã đổi đuôi file chưa?
- **Xử lý:** giải nén artifact ZIP, dùng đúng file `Cozyday-unsigned.ipa`. So SHA-256 (hướng dẫn cài, A5). Tải lại nếu khác.

### 3.3 Lỗi entitlement / "app requires capabilities"

- **Nguyên nhân:** app khai báo quyền mà tài khoản miễn phí không ký được (iCloud, push, App Groups…). Cozyday 1.0 **không** dùng các quyền này,
  và bước kiểm tra IPA sẽ FAIL nếu có extension hay provisioning profile lạ.
- **Xử lý:** gửi đoạn log Sideloadly cho Claude.

---

## 4. Sideloadly không nhận iPhone

- **Xem gì:** iTunes có thấy iPhone không? iPhone đã mở khóa và chọn **Tin cậy** chưa? Cáp có truyền dữ liệu (không chỉ sạc)?
- **Nguyên nhân thường gặp:** chưa Trust; driver Apple chưa có (cài iTunes bản từ Apple, không phải Microsoft Store — theo yêu cầu hiện hành
  của Sideloadly); cổng USB hub chập chờn.
- **Xử lý (ít rủi ro trước):** rút ra cắm lại, mở khóa iPhone → đổi cổng USB/cáp → khởi động lại PC → cài lại iTunes đúng bản theo trang Sideloadly.
  Không gỡ hàng loạt phần mềm Apple theo hướng dẫn trôi nổi.
- **Developer Mode:** nếu app cài xong nhưng không mở, kiểm tra *Cài đặt → Quyền riêng tư & Bảo mật → Chế độ nhà phát triển*.

---

## 5. Apple Account / giới hạn tài khoản miễn phí

| Triệu chứng | Nguyên nhân có thể | Xử lý |
|---|---|---|
| Đăng nhập lỗi, yêu cầu mã | 2FA, mật khẩu sai, Apple chặn tạm thời | Nhập mã 2FA **trên máy bạn** trong Sideloadly; chờ một lúc rồi thử lại. Không gửi mã cho ai. |
| "Maximum number of apps" / quá 3 app | Tài khoản miễn phí giới hạn số app sideload đang hoạt động | Gỡ một app sideload khác **không cần dữ liệu** (đừng gỡ Cozyday nếu chưa sao lưu). |
| Quá giới hạn App ID mới | Đã tạo nhiều bundle ID khác nhau trong 7 ngày | Dùng lại đúng bundle ID cũ (`com.phuhot.cozyday` hoặc ID Sideloadly đã dùng), chờ hết 7 ngày. |
| App không mở được sau ~7 ngày | Chữ ký hết hạn | Ký/cài đè lại cùng IPA, cùng Apple Account, cùng bundle ID (hướng dẫn cài, C1). **Không xóa app.** |

---

## 6. App không mở / văng / dữ liệu "biến mất"

### 6.1 Bấm icon, app hiện rồi tắt ngay

- **Kiểm tra theo thứ tự:** chữ ký hết hạn? (mục 5) → Developer Mode đã bật? → đã Tin cậy nhà phát triển?
- Nếu vẫn văng: *Cài đặt → Quyền riêng tư & Bảo mật → Phân tích & Cải tiến → Dữ liệu phân tích* → tìm mục bắt đầu bằng `Cozyday` →
  gửi cho Claude phần đầu (tên exception, vài dòng "Thread 0"). Không cần gửi nội dung nhật ký.

### 6.2 App mở màn hình "Không mở được dữ liệu"

- App **cố ý không xóa** database khi không đọc được. Màn hình hiện chi tiết lỗi kỹ thuật (không chứa nội dung nhật ký).
- Xử lý: tắt hẳn app, mở lại; giải phóng dung lượng iPhone; nếu vẫn lỗi, chụp màn hình gửi Claude. **Không gỡ app** — gỡ sẽ mất dữ liệu.

### 6.3 Cập nhật xong thấy app trống trơn

- **Nguyên nhân hay gặp nhất:** bundle ID khác lần trước (Sideloadly đổi ID, hoặc ký bằng Apple Account khác) → iPhone coi là **app khác**,
  app cũ (có dữ liệu) có thể vẫn nằm đâu đó hoặc đã bị thay.
- **Xem gì:** trong app: *Cài đặt → Thông tin → Bundle ID*. So với ID ghi lại lần trước. Trên màn hình chính có hai icon Cozyday không?
- **Xử lý:** **đừng tạo dữ liệu mới** trong bản trống. Cài lại với đúng bundle ID/Apple Account cũ; nếu không được, dùng
  *Cài đặt → Khôi phục từ sao lưu…* với file JSON đã xuất gần nhất.

### 6.4 Khôi phục sao lưu bị từ chối

- App kiểm tra file trước khi ghi; nếu báo lỗi thì **dữ liệu hiện tại không bị đổi**.
- "Phiên bản dữ liệu X, app chỉ đọc tới Y": file được xuất từ bản app mới hơn → cập nhật app rồi khôi phục.
- "Không phải file sao lưu của Cozyday" / "bị hỏng": file bị cắt cụt hoặc bị sửa tay. Dùng bản sao lưu khác.

---

## 7. Thông báo và hẹn giờ khi chạy nền

| Triệu chứng | Nguyên nhân có thể | Xử lý |
|---|---|---|
| Không bao giờ có thông báo | Đã từ chối quyền | Cozyday → Cài đặt → Thông báo → *Mở Cài đặt iPhone* → bật Thông báo. |
| Thông báo đến muộn / không kêu | Chế độ Tập trung (Focus), Tóm tắt theo lịch, chế độ im lặng | Thêm Cozyday vào danh sách cho phép của Focus; kiểm tra âm lượng. |
| Việc ở xa (sau 7 ngày) không được nhắc | App chỉ lên lịch nhắc cho 7 ngày tới (giới hạn 64 thông báo chờ của iOS) | Mở app ít nhất vài ngày một lần để lịch nhắc được làm mới. |
| Hẹn giờ tập trung "dừng" khi khóa máy | Không — đồng hồ được tính từ mốc thời gian đã lưu | Mở lại app: thời gian còn lại được tính đúng; nếu đã hết giờ, phiên được chốt **một lần** kèm thưởng. |
| Không nghe báo hết giờ tập trung | Chưa cho phép thông báo, hoặc đang Focus | Như hai dòng đầu. Cozyday không phát nhạc nền giả để giữ app chạy. |

Cozyday không phải ứng dụng báo thức: iOS có quyền trì hoãn hoặc gom thông báo. Đừng dùng cho việc cần đúng từng giây.
