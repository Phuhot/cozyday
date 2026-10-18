# Cài Cozyday lên iPhone từ máy Windows (không cần Mac)

Tài liệu này đi đúng theo source và workflow trong repo. Mỗi bước ghi **làm gì → ở đâu → kết quả mong đợi**.
Lệnh trong khung `PowerShell` là lệnh chạy trên Windows của bạn. Các lệnh macOS (`xcodebuild`, `brew`…) chỉ chạy
**tự động trên máy chủ GitHub** — bạn không cần và không thể chạy chúng trên Windows.

> Tài liệu viết ngày 18/10/2026. Giao diện GitHub, Sideloadly và iOS có thể đổi tên nút. Nếu khác, đối chiếu
> trang hướng dẫn chính thức được liên kết ở từng phần.

## 0. Bức tranh tổng thể

```
Source trên GitHub ──(GitHub Actions, máy macOS của GitHub)──► Cozyday-unsigned.ipa (chưa ký)
     ▲                                                              │ tải về Windows
     │ sửa code (Claude / GitHub Desktop)                           ▼
  Windows ◄──────────────────────────────────── Sideloadly ký bằng Apple Account của bạn ──USB──► iPhone
```

Thuật ngữ dùng trong tài liệu:

| Thuật ngữ | Nghĩa |
|---|---|
| **Repo** (repository) | Thư mục dự án lưu trên GitHub, có lịch sử thay đổi. Repo của bạn: `Phuhot/cozyday` (đang **private**). |
| **Branch** (nhánh) | Một dòng phát triển. `main` là nhánh mặc định. Claude làm việc trên `claude/ios-project-section-12-4bpxn7`. |
| **Commit / Push** | Commit = lưu một mốc thay đổi; Push = đẩy các commit đó lên GitHub. |
| **GitHub Actions / workflow** | Máy chủ của GitHub tự chạy kịch bản build. Workflow của dự án: **iOS unsigned IPA**. |
| **Runner** | Máy ảo GitHub dùng để chạy workflow. Ở đây là macOS 26 với Xcode 26.6. |
| **Artifact** | File kết quả mà workflow để lại cho bạn tải (dạng `.zip`). |
| **IPA** | Gói cài app iOS. `Cozyday-unsigned.ipa` là bản **chưa ký**. |
| **Ký (sign)** | Gắn chứng nhận để iPhone cho phép chạy app. Sideloadly làm việc này bằng Apple Account của bạn. |
| **Sideload** | Cài app ngoài App Store. |

Ba loại file **khác nhau**, đừng nhầm:

1. **Source ZIP** — nút *Code → Download ZIP* trên GitHub. Chứa mã nguồn. **Không cài được** lên iPhone.
2. **Artifact ZIP** — tải ở trang kết quả workflow, tên dạng `Cozyday-unsigned-ipa-run12.zip`. Đây chỉ là lớp vỏ.
3. **IPA** — nằm **bên trong** artifact ZIP: `Cozyday-unsigned.ipa` (+ file `.sha256` và `build-info.txt`).
   Đây mới là file đưa vào Sideloadly. Đừng đổi đuôi `.ipa` thành `.zip` hay ngược lại.

---

## A. Chuẩn bị source và GitHub

### A1. Kiểm tra repo đã có đủ file

- **Làm gì:** mở `https://github.com/Phuhot/cozyday` (đăng nhập tài khoản GitHub của bạn).
- **Ở đâu:** ô chọn nhánh phía trên danh sách file (mặc định ghi `main`) → chọn `claude/ios-project-section-12-4bpxn7`.
- **Kết quả mong đợi:** thấy các thư mục `Cozyday`, `Tests`, `docs`, `scripts`, file `project.yml`, `README.md`
  và thư mục `.github` (chứa `workflows/ios-unsigned.yml`).

### A2. Private hay public? (bạn quyết định — Claude không tự đổi)

Repo hiện là **private**. Khác biệt chính (kiểm tra lại tại trang billing của GitHub vì chính sách có thể đổi):

| | Private (hiện tại) | Public |
|---|---|---|
| Ai thấy source | Chỉ bạn (và người bạn mời) | Mọi người |
| Phút Actions | Có hạn mức miễn phí mỗi tháng (gói Free: 2.000 phút **quy đổi**); phút **macOS bị nhân hệ số** (thường ×10), nên thực tế chỉ khoảng 200 phút macOS/tháng | Runner chuẩn miễn phí cho repo public |
| Rủi ro | Hết hạn mức thì workflow dừng (nếu chưa gắn thẻ thanh toán thì không bị trừ tiền) | Lộ toàn bộ source; **không bao giờ** được đưa dữ liệu cá nhân, file sao lưu, chứng chỉ vào repo |

Một lần build IPA của Cozyday đo được khoảng **1,5 phút macOS** (chỉ build); nếu chọn chạy test simulator thì thêm khoảng **10 phút** (phần lớn là khởi động simulator) — chỉ chọn khi cần.
Xem mức đã dùng: GitHub → ảnh đại diện → **Settings → Billing and licensing → Usage** (tên mục có thể khác).
Không bật thanh toán chỉ để chạy workflow; chạy thủ công khi cần là đủ.

### A3. Đưa workflow lên nhánh `main` để có nút "Run workflow"

GitHub chỉ hiện nút **Run workflow** cho workflow nằm trên nhánh mặc định (`main`). Code hiện nằm ở nhánh của Claude.

- **Cách đơn giản:** trên trang repo, GitHub thường hiện dải vàng *"claude/… had recent pushes — Compare & pull request"*.
  Bấm vào → **Create pull request** → **Merge pull request** → **Confirm merge**.
  (Hoặc nhờ Claude tạo Pull Request, bạn chỉ việc bấm Merge.)
- **Kết quả mong đợi:** chọn nhánh `main` thấy đủ file như A1.
- **Trong lúc chưa merge:** mỗi lần Claude đẩy code lên nhánh `claude/…`, workflow vẫn tự chạy và tạo artifact — bạn có thể tải IPA từ đó (bước A5).

### A4. Chạy workflow build IPA

- **Làm gì / ở đâu:** repo → tab **Actions** → cột trái chọn **iOS unsigned IPA** → nút **Run workflow** (bên phải) →
  chọn branch `main` → để trống ô "Chạy thêm unit test" (tiết kiệm phút) → bấm nút **Run workflow** màu xanh.
- **Kết quả mong đợi:** sau vài giây xuất hiện một dòng chạy mới (biểu tượng vàng đang chạy). Sau khoảng 2–4 phút chuyển
  thành dấu tích xanh.
- **Xem log:** bấm vào dòng chạy → bấm job **Build IPA (iphoneos arm64, chưa ký)** → mở từng bước. Bước
  *Kiểm tra cấu trúc IPA* in ra bundle ID, phiên bản, `Platform: iphoneos / iPhoneOS / arm64` và dòng `Kiểm tra IPA: ĐẠT`.
- **Nếu không thấy workflow trong tab Actions:** xem `docs/TROUBLESHOOTING_VI.md` mục 1.

### A5. Tải IPA về Windows

- **Ở đâu:** trang của lần chạy thành công → kéo xuống mục **Artifacts** → bấm `Cozyday-unsigned-ipa-runN`.
- **Kết quả:** trình duyệt tải về `Cozyday-unsigned-ipa-runN.zip`. Chuột phải → **Extract All…** (Giải nén tất cả).
  Trong thư mục giải nén có:
  - `Cozyday-unsigned.ipa` — file để cài
  - `Cozyday-unsigned.ipa.sha256` — mã kiểm tra
  - `build-info.txt` — commit, phiên bản Xcode/SDK đã build
- **Hạn tải:** artifact IPA được giữ **14 ngày** (log: 7 ngày). Tải về và cất giữ trước khi hết hạn. Hết hạn thì chạy lại A4.
- **(Tùy chọn) Kiểm tra file không bị hỏng:** mở PowerShell trong thư mục đó và chạy

  ```powershell
  Get-FileHash .\Cozyday-unsigned.ipa -Algorithm SHA256
  Get-Content .\Cozyday-unsigned.ipa.sha256
  ```

  Hai chuỗi mã (không phân biệt hoa/thường) phải giống nhau.

### A6. (Khi muốn tự sửa code) Lấy source về máy

Bạn **không bắt buộc** phải có source trên máy để cài app — chỉ cần IPA. Nếu muốn sửa:

- **Cách dễ — GitHub Desktop:** tải tại `https://desktop.github.com/` → đăng nhập GitHub → **File → Clone repository** →
  chọn `Phuhot/cozyday` → **Clone**. Đổi nhánh ở nút **Current branch**. Sau khi sửa file: nhập mô tả ở ô *Summary* →
  **Commit to <nhánh>** → **Push origin**.
- **Cách tải ZIP:** nút xanh **Code → Download ZIP**. Lưu ý thư mục `.github` là thư mục ẩn: bật
  *File Explorer → View → Show → Hidden items* để thấy. ZIP chỉ để xem/sửa; muốn đưa lên GitHub vẫn cần GitHub Desktop hoặc git.
- **Cách PowerShell (đã cài Git for Windows):**

  ```powershell
  git clone https://github.com/Phuhot/cozyday.git
  cd cozyday
  git switch main
  git status
  ```

---

> **Muốn xem giao diện trước khi cài?** Mở [`UI_PREVIEW_VI.md`](UI_PREVIEW_VI.md) trên GitHub (xem được bằng điện thoại):
> ảnh chụp từng màn của app trên iPhone ảo, với dữ liệu mẫu. Không cần tải gì.

## B. Cài IPA bằng Sideloadly

> Chỉ tải Sideloadly tại trang chính thức **https://sideloadly.io/**. Đọc mục yêu cầu hệ thống và FAQ ở đó trước khi cài —
> môi trường này của Claude không truy cập được trang đó lúc viết tài liệu, nên các chi tiết dưới đây cần bạn đối chiếu.

### B1. Chuẩn bị trên Windows

1. Tải và cài **Sideloadly cho Windows** từ trang chính thức.
2. Cài **iTunes** và **iCloud** bản tải trực tiếp từ Apple (bản "web"/".exe"), **không phải bản Microsoft Store**,
   nếu trang Sideloadly còn yêu cầu như vậy. Không cần gỡ hàng loạt phần mềm Apple khác — chỉ làm đúng những gì trang chính thức hướng dẫn.
3. Khởi động lại máy nếu trình cài yêu cầu.

### B2. Kết nối iPhone lần đầu

1. Cắm iPhone vào PC bằng cáp USB, **mở khóa iPhone**.
2. Trên iPhone hiện "**Tin cậy máy tính này?**" (Trust This Computer?) → chọn **Tin cậy** → nhập mật mã iPhone.
3. Mở iTunes một lần: thấy biểu tượng iPhone ở góc trên là Windows đã nhận máy.

### B3. Cài app

1. Mở **Sideloadly**.
2. Ô thiết bị (iDevice): chọn đúng iPhone của bạn.
3. Ô **Apple Account**: nhập email Apple Account của bạn **ngay trong Sideloadly trên máy bạn**.
   Mật khẩu và mã xác minh 2 bước (2FA) chỉ nhập vào cửa sổ của Sideloadly / iPhone — **không gửi cho Claude, không lưu vào GitHub**.
   Có thể dùng một Apple Account phụ chỉ để ký app nếu bạn muốn tách biệt.
4. Kéo `Cozyday-unsigned.ipa` vào cửa sổ Sideloadly (hoặc bấm biểu tượng IPA để chọn file).
5. **Advanced options:** giữ mặc định. Ghi lại **bundle ID** Sideloadly dùng (mặc định là `com.phuhot.cozyday`).
   Nếu Sideloadly buộc phải đổi bundle ID (ví dụ ID đã bị đăng ký bởi tài khoản khác), ghi lại ID mới và **dùng đúng ID đó cho các lần cài sau**.
6. Bấm **Start**. Chờ log báo *Done*.
- **Kết quả mong đợi:** biểu tượng mèo kem trên nền tím xuất hiện trên màn hình chính iPhone.

### B4. Cho phép chạy app trên iPhone (lần đầu)

Tùy phiên bản iOS và cách ký, iPhone có thể yêu cầu một hoặc cả hai bước sau. Làm **theo đúng màn hình hiện ra**:

- **Developer Mode** (iOS 16 trở lên): *Cài đặt → Quyền riêng tư & Bảo mật → Chế độ nhà phát triển* → bật → iPhone khởi động lại →
  sau khi mở khóa chọn **Bật**. Mục này thường chỉ xuất hiện sau khi đã cài một app được ký kiểu phát triển.
- **Tin cậy nhà phát triển:** khi mở app thấy "Nhà phát triển không được tin cậy" → *Cài đặt → Cài đặt chung →
  Quản lý VPN & Thiết bị* → mục có **email Apple Account của chính bạn** → **Tin cậy**.
  Chỉ tin cậy hồ sơ mang Apple Account của bạn; không tin cậy hồ sơ lạ.

### B5. Giới hạn của Apple Account miễn phí (kiểm tra lại với tài liệu hiện hành)

- App ký bằng tài khoản miễn phí **hết hạn sau khoảng 7 ngày**; hết hạn thì app không mở được cho tới khi ký lại (mục C).
- Thường chỉ **khoảng 3 app sideload** hoạt động cùng lúc trên một thiết bị với tài khoản miễn phí, và có giới hạn số App ID tạo mới mỗi tuần.
- Không dùng được các quyền cần tài khoản trả phí (iCloud, push từ máy chủ…). Cozyday bản 1.0 không cần các quyền này.
- Tham khảo: Apple — *About your developer account* (https://developer.apple.com/help/account/basics/about-your-developer-account).

### B6. Nghiệm thu trên iPhone (làm theo thứ tự, đánh dấu từng mục)

1. [ ] Mở Cozyday → qua 3 bước giới thiệu (hoặc bấm **Bỏ qua**).
2. [ ] Tab **Hôm nay** → nút **+** → tạo việc có giờ → **Lưu** → việc hiện trên timeline.
3. [ ] Chạm vòng tròn bên phải việc → việc gạch ngang, hiện "+10 XP · +5 xu"; xu ở tab **Góc nhỏ** tăng 5.
4. [ ] Bỏ đánh dấu rồi đánh dấu lại → **không** nhận thêm xu.
5. [ ] Tab **Góc nhỏ** → **Cửa hàng & trang trí** → nhận một món miễn phí → món hiện trong phòng.
6. [ ] Vuốt tắt hẳn app (App Switcher) → mở lại: việc, xu, đồ vẫn còn.
7. [ ] **Rút cáp USB, tắt máy tính** → mở app: vẫn chạy bình thường (bản Release không cần máy tính hay Metro/Expo).
8. [ ] Bật **Chế độ máy bay** → mở app, tạo/hoàn thành việc: chạy bình thường (app offline hoàn toàn).
9. [ ] **Cài đặt (bánh răng) → Xuất sao lưu…** → lưu vào *Tệp* (Files) → kiểm tra file `Cozyday-backup-YYYY-MM-DD.json` xuất hiện.

Ghi lại kết quả (và ảnh chụp lỗi nếu có) để gửi lại cho Claude nếu cần sửa.

---

## C. Gia hạn và cập nhật

### C1. Gia hạn (re-sign) — khi code KHÔNG đổi

- Gia hạn **không cần build lại**. Dùng lại đúng file IPA đã cài (giữ file này cẩn thận) — hoặc dùng tính năng refresh của Sideloadly.
- Làm **trước** khi hết 7 ngày: cắm iPhone → Sideloadly → cùng **Apple Account**, cùng IPA, cùng bundle ID → **Start**.
  App được cài đè, **dữ liệu giữ nguyên** (vì cùng bundle ID và cùng tài khoản ký).
- **Tự refresh qua Wi-Fi** (nếu bản Sideloadly của bạn hỗ trợ): bật tùy chọn tự refresh cho app trong Sideloadly. Điều kiện
  thường gặp: PC **đang bật**, dịch vụ nền (daemon) của Sideloadly **đang chạy**, PC và iPhone **cùng mạng Wi-Fi**, iPhone đã
  từng ghép đôi qua USB và cho phép đồng bộ qua Wi-Fi. **Máy tính tắt thì không tự refresh được.** Đối chiếu hướng dẫn chính thức.
- Nếu đã quá hạn và app không mở: **đừng xóa app**. Chỉ cần ký/cài đè lại như trên — dữ liệu vẫn nằm trong app.

### C2. Cập nhật lên phiên bản mới — khi code ĐÃ đổi

1. **Xuất sao lưu** trong app trước (Cài đặt → Xuất sao lưu…).
2. Chạy workflow (A4) trên nhánh có code mới → tải IPA mới (A5).
3. Cài IPA mới bằng Sideloadly với **cùng Apple Account và cùng bundle ID** → app được cài đè, dữ liệu giữ nguyên.
   **Không gỡ app trước** khi cài bản mới.
4. Mở app kiểm tra dữ liệu. Nếu thấy trống: dừng lại, đừng tạo dữ liệu mới, xem `docs/TROUBLESHOOTING_VI.md` mục 6.

### C3. Những điều KHÔNG phải sao lưu

- Gia hạn chữ ký hay cài lại **không** phải là sao lưu. Gỡ app = mất dữ liệu trên máy.
- Chỉ file `Cozyday-backup-….json` bạn đã xuất mới là bản sao lưu. File này chứa nội dung riêng tư ở dạng chữ, **không mã hóa** —
  cất ở nơi an toàn, **không** đưa lên repo GitHub.

### C4. (Tùy chọn, nâng cao) SideStore

SideStore là cách tự refresh ngay trên iPhone, ít phụ thuộc PC hơn, nhưng cần thiết lập pairing file và VPN cục bộ phức tạp hơn.
Chưa được kiểm chứng với Cozyday; chỉ cân nhắc sau khi đường Sideloadly đã ổn định. Không gửi pairing file cho bất kỳ ai.
