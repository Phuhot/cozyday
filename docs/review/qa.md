# Báo cáo QA: CozyDay

- Nhánh `claude/ios-project-section-12-4bpxn7`, commit `87371c9` (Minigame: hiệu ứng và âm thanh cho Xếp Khối, Gộp Bánh).
- Cách làm: đọc code + tài liệu, lần theo từng luồng như người dùng thật, đối chiếu ảnh CI trong `docs/screenshots` (ảnh chụp ở commit `ce1f209`, tức **trước** 2 commit cuối: đồng hồ nhỏ chuyển sang trái và hiệu ứng minigame mới chưa có ảnh).
- Không chạy được trên máy thật hay simulator. Mục nào phụ thuộc hành vi iOS mà code không tự chứng minh được thì ghi "chưa chắc" hoặc "cần xác minh trên máy".
- Không sửa file nào trong repo.

Mức độ: **Nghiêm trọng** (mất dữ liệu, crash, hoặc phá hẳn một tính năng chính/kinh tế xu) · **Cao** · **Trung bình** · **Thấp**.

---

## Tóm tắt nhanh

| # | Mức | Vấn đề | Chỗ chính |
|---|---|---|---|
| N1 | Nghiêm trọng | Viết nhật ký cho **ngày bất kỳ trong quá khứ** vẫn được +5 XP +5 xu, không giới hạn. Không cần chỉnh giờ máy | `AppStore+Corner.swift:140`, `JournalView.swift:185,197,253` |
| C1 | Cao | Khóa máy **không được nhận ra**: app chỉ xin 4 giây chạy nền nhưng iOS báo khóa máy sau khoảng 10 giây. Hậu quả: chế độ nghiêm dừng phiên khi người dùng chỉ khóa máy; thông báo nhắc vẫn hiện trên màn hình khóa | `FocusCoordinator.swift:204-245` |
| C2 | Cao | Thưởng tập trung **không có hạn mức ngày**. Có thể bật tự chạy tiếp rồi để máy đó, hoặc chỉnh giờ máy là xong một phiên 120 phút (+48 xu) trong vài giây | `Ledger.swift:124`, `AppStore+Focus.swift:61-73`, `FocusTimer.swift:49,82` |
| C3 | Cao | Mã quà `t3ster` (+1000 xu) có trong bản Release và nhập lại được vô hạn | `GiftCodes.swift:5`, `SettingsView.swift:76,158` |
| C4 | Cao | Lách chế độ nghiêm theo 2 cách: bật âm nền (app chạy nền và tự chốt phiên), hoặc tắt hẳn app khi đang rời đi (bộ theo dõi chỉ nằm trong RAM) | `FocusCoordinator.swift:35,173-202,253-262`, `Info.plist` (`UIBackgroundModes: audio`) |
| T1 | Trung bình | Bộ sưu tập vẽ rõ **Kỳ lân (Bí mật)** và Rồng con kèm giá xu và nút Mua. Bấm Mua thì báo lỗi "chỉ có trong máy gacha" | `CollectionView.swift:28-33,43-45,173-181`, `PetLooks.swift:82-83` |
| T2 | Trung bình | Sửa file sao lưu JSON để có xu tùy ý; khôi phục bản cũ để quay gacha lại không mất xu | `BackupDocument.swift:230-243` |
| T3 | Trung bình | Phiên âm thanh dùng chung bị giành nhau: hẹn giờ dùng `.playback`, game và video dùng `.ambient`. Chơi game xong thì âm nền tắt khi khóa máy hoặc khi gạt công tắc im lặng. Chuông kêu cả khi máy đang im lặng | `FocusAudio.swift:56-59`, `GameRuntime.swift:154-158,203-205`, `IntroViews.swift:23` |
| T4 | Trung bình | Đang tạm dừng mà bật chế độ nghiêm thì không còn nút Tiếp tục | `FocusView.swift:311`, `FocusCoordinator.swift:97` |
| T5 | Trung bình | Với cài đặt mặc định (tự bắt đầu giờ nghỉ), màn "Xong một phiên", số lần rời app và nút "Đánh dấu việc đã xong" gần như không bao giờ hiện | `FocusCoordinator.swift:156-161` |
| T6 | Trung bình | Gacha: đóng màn trong 1,35 giây máy đang quay thì xu đã trừ nhưng không hiện kết quả | `GachaView.swift:236-249` |

Danh sách đầy đủ, kèm các mục Thấp và test còn thiếu, nằm ở bên dưới.

---

## NGHIÊM TRỌNG

### N1. Nhật ký ghi lùi ngày: xu/XP vô hạn, không cần chỉnh giờ máy
- **File:** `Cozyday/Persistence/AppStore+Corner.swift:140`: `if day <= self.today, let entry = RewardPolicy.forJournal(day: day, …)`. Khóa `journal:<ngày>` là khóa **theo ngày được chọn**, không theo ngày viết.
  `Cozyday/Features/Journal/JournalView.swift:185` (chạm ô ngày nào cũng mở trình sửa), `:197` (chỉ khóa ngày **tương lai**), `:253-258` (`shift(-1)` lùi tháng không giới hạn).
- **Tái hiện:**
  1. Tab Nhật ký, bấm mũi tên "Tháng trước" vài lần.
  2. Chạm ngày 1, chọn một mood, Lưu. Popup báo "+5 XP, +5 xu".
  3. Lặp lại cho ngày 2, 3… rồi lùi tiếp sang các tháng, các năm trước.
- **Hậu quả:** khoảng 150 xu/tháng lịch, lùi bao xa cũng được, nên số xu là vô hạn và máy gacha 60 xu/lượt mất ý nghĩa. Ngoài ra các dòng thưởng này có `createdAt = now`, nên `Adventure.energy` (`Adventure.swift:25-28`) đếm chúng vào năng lượng **hôm nay**: viết 4 ngày cũ là đủ 100%, nhận thêm +10 xu chuyến đi.
- **Sửa:** chỉ thưởng khi `day == today` (hoặc cho phép hôm qua). Ngày cũ vẫn ghi được nhưng không có thưởng; giao diện ghi rõ "Ngày cũ không có thưởng". Thêm test `testBackdatedJournalHasNoReward`.

---

## CAO

### C1. Khóa máy không được nhận ra: chế độ nghiêm dừng phiên oan, thông báo nhắc hiện khi máy đang khóa (cần xác minh trên máy, khả năng xảy ra rất cao)
- **File:** `Cozyday/Services/FocusCoordinator.swift`
  - `:204-218` `sceneEnteredBackground`: ghi `leftAt`, rồi **luôn** hẹn thông báo nhắc sau 15 giây. Lúc này `lockedWhileAway` gần như luôn là false vì tín hiệu khóa máy chưa tới.
  - `:222-232` `holdBackgroundBriefly`: chỉ giữ app chạy nền **4 giây**.
  - `:240-245` `deviceLocked` là nơi duy nhất hủy lời nhắc và đánh dấu khóa máy. Nó dựa vào `protectedDataWillBecomeUnavailableNotification`.
- **Vì sao:** iOS gửi `protectedDataWillBecomeUnavailable` khi khóa bảo vệ dữ liệu bị bỏ, khoảng **10 giây sau khi khóa máy** (máy có mật mã, Face ID là "Yêu cầu ngay"). Không phải ngay lúc app vào nền như chú thích ở `:211` giả định. Sau 4 giây app đã bị tạm dừng, nên không nhận được tín hiệu. Nếu bật âm nền thì app vẫn chạy và không gặp lỗi này, nhưng lại sinh ra lỗi C4.
- **Tái hiện (máy có mật mã, âm nền Tắt, đã cho phép thông báo):**
  1. Bật chế độ nghiêm, bắt đầu phiên 25 phút.
  2. Bấm nút nguồn khóa máy ngay trong app.
  3. Khoảng 15 giây sau, màn hình khóa hiện "Bông vẫn đang tập trung cùng bạn… rời app quá 1 phút thì phiên sẽ dừng".
  4. Chờ 2 phút rồi mở khóa. App báo "Chế độ nghiêm: bạn rời app 2 phút nên phiên dừng ở phút 1. Không có thưởng."
  Không bật chế độ nghiêm thì: lần khóa máy nào cũng bị tính "Rời app 1 lần" và có thông báo nhắc. Đây chính là mục `TEST_CHECKLIST_VI.md:173` ("không bị tính rời app, không có thông báo nhắc"), nhiều khả năng sẽ **trượt**.
- **Hậu quả:** chế độ nghiêm phạt đúng hành vi mà app khuyên ("Bạn có thể khóa máy"). Người dùng mất thưởng và có thông báo phiền.
- **Sửa:**
  - Giữ chạy nền khoảng 12-15 giây (thời gian `beginBackgroundTask` cho phép đủ dài). Tới mốc đó kiểm tra `UIApplication.shared.isProtectedDataAvailable`: nếu false thì coi là đã khóa máy và hủy lời nhắc.
  - Hẹn lời nhắc trễ hơn mốc kiểm tra (ví dụ 20 giây).
  - Khi quay lại app, nếu `lockedAt == nil` mà khoảng vắng mặt rất dài, nên hỏi lại thay vì dừng phiên ngay.

### C2. Thưởng tập trung không có trần: cày xu khi treo máy, hoặc chỉnh giờ máy
- **File:** `Cozyday/Core/Rewards/Ledger.swift:124` (`forFocus`: mỗi phiên một khóa, không đếm theo ngày). `Cozyday/Persistence/AppStore+Focus.swift:61-73`. `Cozyday/Core/Focus/FocusTimer.swift:49-52` (`elapsed` dùng giờ đồng hồ), `:82-91` (`reconcile` tin `now`). `FocusCoordinator.swift:156-159` (tự nối phiên).
- **Tái hiện A (không cần chỉnh giờ):**
  1. Cài đặt hẹn giờ: Tập trung 120 phút, bật "Tự bắt đầu giờ nghỉ" và "Tự bắt đầu phiên tập trung kế tiếp", bật Giữ màn hình sáng.
  2. Bắt đầu phiên, cắm sạc, để máy qua đêm.
  Mỗi vòng 120+5 phút được +48 xu +48 XP, tức khoảng 550 xu/ngày không làm gì.
- **Tái hiện B (chỉnh giờ):**
  1. Bắt đầu phiên 120 phút.
  2. Sang Cài đặt iPhone, Ngày và giờ, đặt giờ tiến thêm 2 tiếng.
  3. Quay lại app: phiên được chốt hoàn thành, +48 xu.
  4. Đặt giờ lại như cũ, lặp lại. Mỗi vòng khoảng 30 giây.
  (Tài liệu đã nói hạn mức theo ngày có thể bị lách bằng chỉnh giờ. Nhưng tập trung **không có hạn mức nào**, nên chỉnh giờ ở đây cho xu vô hạn, không bị chặn ở mức 40 xu/ngày như Sân chơi.)
- **Sửa:**
  - Thêm hạn mức thưởng tập trung theo ngày, ví dụ 240 phút có thưởng/ngày, giống cách làm với việc.
  - Lưu `ProcessInfo.systemUptime` lúc bắt đầu phiên. Khi chốt mà máy chưa khởi động lại và thời gian thực đã trôi (theo uptime) ngắn hơn nhiều so với thời gian theo đồng hồ, thì chốt "đã chỉnh giờ", không thưởng. Lưu ý uptime không chạy khi máy ngủ sâu, nên chỉ dùng làm cận dưới.
  - Có thể không cho tự bắt đầu phiên tập trung khi phiên trước không có tương tác nào.

### C3. Mã quà quản trị có trong bản Release và dùng lại được vô hạn
- **File:** `Cozyday/Core/Rewards/GiftCodes.swift:5` (`["t3ster": 1000]`, không có `#if DEBUG`), `:12-17` (mỗi lần nhập là một `UUID` mới nên không chống trùng). `Cozyday/Features/Settings/SettingsView.swift:76` (chạm 7 lần là hiện ô nhập), `:158-166`.
- **Tái hiện:** Cài đặt, chạm dòng "Phiên bản" 7 lần, nhập `t3ster`, Nhận quà. Bấm tiếp: lần nào cũng +1000 xu.
- **Hậu quả:** ai từng thấy repo, hoặc chạy `strings` trên IPA, đều có xu vô hạn. Mã nằm thẳng trong file nhị phân.
- **Sửa:** chỉ biên dịch khi `#if DEBUG`, hoặc mỗi mã chỉ dùng một lần (khóa `gift:<mã>`). Mã nên băm SHA-256 thay vì để chữ thường trong code.

### C4. Lách chế độ nghiêm: bật âm nền, hoặc tắt hẳn app
- **File:** `FocusCoordinator.swift:35` (`tracker` chỉ nằm trong bộ nhớ), `:173-202` (`sceneBecameActive` chỉ phạt nếu khi quay lại **vẫn còn** phiên tập trung đang chạy), `:253-262` (`scheduleEndWatch` dùng `Task.sleep`), `Cozyday/Resources/Info.plist` (`UIBackgroundModes: audio`), `FocusAudio.swift:59` (`.playback`).
- **Tái hiện A (âm nền):**
  1. Bật chế độ nghiêm và âm nền "Mưa nhẹ", bắt đầu phiên 25 phút.
  2. Chuyển sang app khác (không khóa máy) và dùng hết 25 phút.
  3. App đang phát âm thanh nên không bị tạm dừng. `endWatch` chạy trong nền, `reconcile()` chốt **hoàn thành và có thưởng**, có thể tự bắt đầu giờ nghỉ.
  4. Quay lại: `focusRunning == false`, nên `.ignored`. Không phạt, cũng không đếm lần rời app.
- **Tái hiện B (tắt app):**
  1. Chế độ nghiêm, bắt đầu phiên.
  2. Chuyển sang app khác, vuốt tắt CozyDay trong trình đa nhiệm (hoặc iOS tự đóng app vì thiếu RAM khi dùng game/camera).
  3. Mở lại sau 30 phút: `tracker.leftAt == nil`, nên phiên được chốt hoàn thành và có thưởng.
- **Chưa chắc:** kể cả khi không có âm nền, Task `endWatch` đã hết hạn có thể chạy trước `scenePhase == .active` khi app được đánh thức. Khi đó phiên cũng được chốt trước lúc kiểm tra rời app.
- **Sửa:**
  - Lưu `leftAt` vào UserDefaults lúc vào nền và xóa khi quay lại. Khi chốt phiên (`reconcile`), nếu `strict && leftAt != nil` thì gọi `breakFocus(at: leftAt + 60)` **trước**.
  - Trong `reconcile()` của coordinator, bỏ qua khi `appActive == false && strictMode`.
  - Âm nền không nên giữ app chạy để chốt phiên. Hoặc chỉ cho phép chốt trong nền khi đã nhận ra khóa máy.

---

## TRUNG BÌNH

### T1. Bộ sưu tập làm lộ món Bí mật và có nút Mua không dùng được
- **File:** `Cozyday/Features/Corner/CollectionView.swift:28-33` (lặp `PetSpecies.allCases`, gồm cả `.dragon` và `.unicorn`, vẽ đầy đủ bằng `PetArt` với tên thật). `:43-45` (`PetLooks.all` gồm `look.dragonking` và `look.unicornfairy`, `PetLooks.swift:82-83`). `:97-99` (hiện giá "400 xu"). `:173-181` (nút "Mua N món còn thiếu"). `AppStore+Corner.swift:62-66` (`wearLook` gọi `PurchasePolicy.decide`, nhận `.gachaOnly` và ném lỗi).
- **Tái hiện:**
  1. Góc nhỏ, Bộ sưu tập, kéo xuống cuối mục "Các loài": thấy **Kỳ lân** vẽ rõ, ghi "400 xu"; Rồng con ghi "260 xu".
  2. Khi đủ xu, chạm vào rồi chọn "Mua 1 món còn thiếu · 400 xu". Banner lỗi: "Món này chỉ có trong máy gacha."
- **Hậu quả:** mâu thuẫn với quy tắc "món Bí mật chỉ hiện bóng" (Tủ đồ và máy gacha đã làm đúng). Nút trông như mua được nhưng bấm vào là lỗi. Giá 400/260 xu là giá giả, vì gacha không bán.
- **Sửa:** trong Bộ sưu tập, áp dụng `.silhouette(isHidden)` và tên "???" cho món bí mật chưa có. Bộ có món `gachaOnly` chưa sở hữu thì đổi nút thành "Thử vận may ở máy gacha" và loại giá của món đó khỏi `cost`.

### T2. Sửa file sao lưu để có xu; khôi phục bản cũ để quay gacha lại
- **File:** `Cozyday/Core/Backup/BackupDocument.swift:241-242`: mọi loại dòng sổ cái khác gacha/mua/minigame (task, focus, journal, adventure, breathing, care, **gift**) chỉ bị kiểm `coins >= 0, xp >= 0`, không có trần. `AppStore+Backup.swift:37-74` thay toàn bộ dữ liệu.
- **Tái hiện A:** Xuất sao lưu, mở JSON, đổi `"coins": 8` của một dòng `taskCompleted` thành `999999` (hoặc thêm dòng `gift`), Khôi phục. Xu là 999.999, XP tăng tùy ý nên mở hết khóa theo cấp.
- **Tái hiện B (quay lại gacha):** có 600 xu thì Xuất sao lưu, quay 10 lượt. Không ra món Bí mật thì Khôi phục file vừa xuất, xu và pity về như cũ, quay lại. Lặp tới khi có đủ 7 món Bí mật mà không tốn xu.
- **Hậu quả:** kinh tế xu bị phá nếu người dùng biết cách. App offline nên không chống tuyệt đối được, nhưng hiện chặn quá ít.
- **Sửa (nhẹ):**
  - Kiểm trần theo loại: task ≤ 8 xu/10 XP, focus ≤ 48, journal ≤ 5, gift ≤ giá trị mã…
  - Thêm checksum HMAC với khóa trong app (chặn sửa tay đơn giản).
  - Cảnh báo "khôi phục bản cũ hơn dữ liệu hiện tại sẽ mất các lượt gacha sau ngày …".

### T3. Phiên âm thanh dùng chung bị giành giữa hẹn giờ, game và video giới thiệu
- **File:** `Cozyday/Features/Focus/FocusAudio.swift:56-59` (`setCategory(.playback, .mixWithOthers)` chỉ khi engine **chưa** chạy). `Cozyday/Features/Play/GameRuntime.swift:154-158` (`setCategory(.ambient)`), `:203-205` (`setActive(false)` khi rời game). `Cozyday/Features/Onboarding/IntroViews.swift:23`.
- **Tái hiện:**
  1. Bắt đầu phiên tập trung với âm nền "Sóng biển".
  2. Chuyển sang Góc nhỏ, Sân chơi, chơi một lượt Gộp Bánh rồi thoát. Danh mục âm thanh lúc này là `.ambient`; `FocusAudio` không đặt lại vì engine của nó vẫn đang chạy.
  3. Gạt công tắc im lặng: âm nền tắt. Khóa máy: `.ambient` không được chạy nền, app bị tạm dừng, âm nền tắt (và vô tình làm C4 không còn xảy ra).
  Ngoài ra `GameSound.stop()` gọi `setActive(false)` khi FocusAudio vẫn đang phát. Lời gọi lỗi "busy" bị `try?` nuốt mất; trên một số bản iOS có thể ngắt cả âm nền (chưa chắc).
- **Thêm:** `.playback` bỏ qua công tắc im lặng, nên **chuông hết giờ vẫn kêu khi máy đang im lặng** (thư viện, lớp học), ngược với kỳ vọng.
- **Sửa:** có một "AudioSessionCoordinator" duy nhất. Đặt category theo nhu cầu cao nhất (đang có âm nền thì `.playback`, còn lại `.ambient`) mỗi lần một bộ phát bắt đầu hoặc dừng. Chỉ `setActive(false)` khi không còn ai phát. Chuông dùng `.ambient`, hoặc hỏi người dùng có muốn chuông kêu cả khi im lặng không.

### T4. Đang tạm dừng mà bật chế độ nghiêm thì không thể tiếp tục
- **File:** `Cozyday/Features/Focus/FocusView.swift:311` (`else if !strict { … Tiếp tục/Tạm dừng … }`). `FocusSettingsView.swift:56` (đổi được chế độ nghiêm giữa phiên).
- **Tái hiện:** chế độ thường, bắt đầu phiên, bấm Tạm dừng. Mở Cài đặt hẹn giờ, bật Chế độ nghiêm, Xong. Màn hẹn giờ chỉ còn nút "Giữ 3 giây để dừng"; không có "Tiếp tục".
- **Hậu quả:** người dùng buộc phải dừng sớm (mất thưởng) hoặc tắt chế độ nghiêm.
- **Sửa:** khi `session.isPaused` thì luôn hiện nút Tiếp tục. Hoặc khóa toggle Chế độ nghiêm khi đang có phiên ("áp dụng từ phiên sau").
- **Liên quan (thiết kế):** đang trong phiên vẫn tắt được chế độ nghiêm để có lại nút Tạm dừng, nên "nghiêm" mất tác dụng. Nên khóa toggle khi có phiên.

### T5. Mặc định tự bắt đầu giờ nghỉ nên tổng kết phiên và nút "đã xong việc" không bao giờ hiện
- **File:** `FocusCoordinator.swift:156-161` (`shouldAutoStart` thì `lastFinished = nil`). `Pomodoro.swift:38` (`autoStartBreak = true`). `FocusView.swift:337-379` (`finishedView` chứa "Rời app N lần" và "Đánh dấu … đã xong").
- **Tái hiện:** dùng cài đặt mặc định, chọn "Gắn với việc: Trả lời email", chạy hết 25 phút khi đang mở app. App nhảy thẳng vào giờ nghỉ; không thấy "Xong một phiên!", không thấy số lần rời app, không có nút đánh dấu việc đã xong.
  `selectedTaskID` (`FocusCoordinator.swift:28,89`) vẫn giữ việc cũ, nên phiên tập trung sau tiếp tục gắn vào việc đã xong.
- **Sửa:** hiện tổng kết thu gọn ngay trong màn giờ nghỉ (banner "Xong phiên · rời app N lần · [Đánh dấu xong]"). Xóa `selectedTaskID` khi việc đó được đánh dấu xong.

### T6. Gacha: đóng màn khi máy đang quay thì xu đã trừ nhưng không thấy kết quả
- **File:** `Cozyday/Features/Gacha/GachaView.swift:236-249`. `pullGacha` ghi sổ trước, sau đó `Task` chờ 1,35 giây mới gán `results`. Nút "Xong" và vuốt đóng không bị khóa trong lúc quay.
- **Tái hiện:** bấm "Quay 10 lượt" rồi bấm ngay "Xong". Mất 540 xu, không có màn kết quả. Món vẫn vào Tủ đồ nhưng người dùng không biết đã nhận gì.
- **Sửa:** `.interactiveDismissDisabled(spinningSince != nil)` và tắt nút Xong khi đang quay. Hoặc đưa kết quả lên `UIState` để màn cha hiện.

### T7. Âm nền không tự bật lại sau khi bị ngắt (chưa chắc, cần thử trên máy)
- **File:** `FocusAudio.swift`: không đăng ký `AVAudioSession.interruptionNotification` hay `AVAudioEngineConfigurationChange`.
- **Tái hiện:** khóa máy với âm nền đang phát, có cuộc gọi đến (hoặc gọi Siri, hoặc rút tai nghe). Gọi xong, âm nền im cho tới khi mở app. Khi engine dừng, app có thể bị tạm dừng luôn.
- **Sửa:** nghe thông báo ngắt và đổi cấu hình, khởi động lại engine khi `.ended` kèm `.shouldResume`.

### T8. Onboarding: bấm đúp "Bắt đầu" tạo trùng các thói quen lặp (chưa chắc)
- **File:** `AppStore+Corner.swift:161-189`: `completeOnboarding` không kiểm `profile.onboardingCompleted`. `OnboardingView.swift:60` không khóa nút.
- **Tái hiện:** ở bước 3, chọn 2 thói quen rồi chạm đúp nhanh "Bắt đầu". Nếu SwiftUI kịp nhận 2 lần chạm trước khi đổi màn, mỗi thói quen thành 2 mẫu lặp, và hôm nay hiện "Uống nước" 2 lần.
- **Sửa:** `guard !profile.onboardingCompleted else { return }` ở đầu hàm. Thêm test gọi 2 lần.

---

## THẤP

1. **Gợi ý nghỉ dài sai sau phiên dừng sớm.** `FocusView.swift:338` luôn gọi `suggestedNext(after: .focus)` với số phiên *đã hoàn thành*. Đã xong 4 phiên (đã nghỉ dài), phiên thứ 5 dừng sớm thì nút vẫn ghi "Nghỉ dài 15 phút".
2. **Thống kê và tab Tập trung tính phiên qua nửa đêm khác ngày nhau.** `Stats.swift:37` dùng `startedAt`, còn `Pomodoro.swift:118` dùng `endedAt`. Phiên 23:40-00:05 nằm ở hôm qua trong Tiến bộ nhưng ở hôm nay trong Tập trung.
3. **Banner lỗi hiện đôi ở tab Tập trung.** `FocusView.swift:68` và `RootView.swift:22` cùng vẽ `ErrorOverlay`.
4. **Kéo thanh âm lượng làm tắt tiếng nghe thử.** `FocusCoordinator.swift:15-21`: `didSet` gọi `applyEffects()`, đặt âm nền về `.off` khi không có phiên, ngay khi đang kéo `Slider` (`FocusSettingsView.swift:81`). Không chỉnh được âm lượng theo tai.
5. **Mô tả món bí mật chưa có vẫn hiện.** `WardrobeView.swift:230` `Text(item.blurb)` ghi "Bộ Thiên hà. Hai hành tinh nhỏ bay vòng quanh." dù tên và hình đã ẩn.
6. **Gacha không xét cấp.** `Gacha.swift:84-87`: pool gồm món cửa hàng có `requiredLevel` (ví dụ Ma bông cấp 3, `back.leafcape` cấp 7). Cấp 1 vẫn quay ra và "Mặc ngay" được (`equip` không kiểm cấp). Cần quyết định đây là tính năng hay lỗi.
7. **Xóa toàn bộ dữ liệu còn sót.** `AppStore+Backup.swift:103-105` không xóa `CalendarService.enabledKey` và không đặt lại `AppRouter.selectedTab`. Sau onboarding lại, app có thể mở ở tab Tiến bộ/Tập trung thay vì Hôm nay. Nếu `ensureProfile()` lỗi sau `commit` (`:97`), bộ đệm trong RAM vẫn giữ dữ liệu cũ vì `reloadAll()` không chạy.
8. **Hết giờ khi đang mở app: hai tiếng cùng lúc.** Thông báo `focus.end` không bị hủy (`NotificationService.swift:86-99`) và `AppDelegate.willPresent` hiện banner kèm âm thanh hệ thống, cộng với chuông và rung của coordinator.
9. **Thông báo bị từ chối nhưng không có gợi ý.** `FocusSettingsView.swift:57` "Nhắc khi rời app" vẫn bật được mà không có gì xảy ra, cũng không có dòng "Thông báo đang tắt, mở Cài đặt iPhone".
10. **Chốt phiên lỗi thì không thử lại.** `FocusCoordinator.swift:139-146`: `reconcile()` lỗi lưu thì không gọi `storeChanged()`, `endWatch` không hẹn lại. Đồng hồ đứng ở 00:00 với nút "Tạm dừng" cho tới lần mở app sau.
11. **Chế độ nghiêm và cuộc gọi (thiết kế).** Nghe điện thoại hơn 1 phút (app vào nền) thì phiên bị dừng, không có thưởng. Nên miễn trừ khi có cuộc gọi, hoặc cho phép "Tiếp tục phiên" một lần.
12. **Dải tuần trong Tập trung không tự sang ngày mới.** `FocusView.dayCard` đọc `store.today` nhưng không quan sát `DayClock`. Mở app qua nửa đêm thì "2/6 phiên" giữ số của hôm qua tới khi có thay đổi khác.
13. **Ảnh CI cũ.** `docs/screenshots/info.txt` ghi commit `ce1f209`. Ảnh `53-focus-mini.jpg` vẫn cho thấy đồng hồ nhỏ đè nút "+" (đã sửa ở `8480cd1`, chưa có ảnh mới). Vị trí mới (trái, `RootView.swift:93-96`, cách đáy 92) có thể đè nhãn giờ của timeline, cần chụp lại. Hiệu ứng mới của Xếp Khối/Gộp Bánh (`87371c9`) chưa có ảnh hay video nào.
14. **Tài liệu lệch code.** `TEST_CHECKLIST_VI.md:53` ghi chuyến đi "+3 xu", còn `RewardConfig.adventureCoins = 10`. Hiệu ứng mới dài hơn mức "≤ 0,4 giây (nhãn điểm ≈ 1 giây)" trong `DATA_AND_RULES_VI.md:218`: `BigCallout` khoảng 1,25 giây, `NewSweetPop` khoảng 1,6 giây, hạt tới 1,1 giây.
15. **Chữ lớn.** `large-06-focus.jpg`: nút Tạm dừng/Kết thúc bị thanh tab che, phải cuộn (chấp nhận được). `PuzzlePetBubble` cao cố định 80 điểm với `lineLimit(3)` nên ở cỡ chữ Trợ năng lời thoại bị co hoặc cắt (`PuzzleViews.swift:291-310`).
16. **VoiceOver.** Thẻ kết quả gacha 1 lượt gộp con bằng `.accessibilityElement(children: .combine)` (`GachaView.swift:350`), nên nút "Mặc ngay" có thể không kích hoạt riêng được (chưa chắc). `HoldToEndButton` cho VoiceOver dừng ngay không cần giữ (hợp lý, nhưng gợi ý lại ghi "giữ 3 giây").

---

## Đã soi và không thấy lỗi
- Gacha: trừ xu, thêm đồ, hoàn xu khi trùng nằm trong **một** lần `commit`, lỗi thì rollback. Bộ đếm pity đọc từ sổ cái. 10 lượt chắc chắn có Hiếm. Kiểm tra sao lưu cho dòng gacha (−60…+120) khớp cả trường hợp Bí mật trùng ở lượt 10 (+66).
- Hạn mức 10 việc có thưởng/ngày: dòng 0 xu vẫn giữ khóa nên xóa rồi tạo lại không cày được. Riêng chỉnh giờ máy thì đã được ghi trong tài liệu.
- Sân chơi: các kiểm tra hợp lý của Xếp Khối/Gộp Bánh khớp với luật engine (số đường ≤ 1,25 × số khối, điểm ≤ 5 × khối + 110 × đường; `top ≤ 4(m+2)`). `sessionID` bảo đảm idempotent. Hạn mức 40 xu đọc từ sổ cái.
- Gộp Bánh: id của món bị gộp (ghost) không trùng id món còn trên bàn, nên `ForEach` an toàn.
- Phiên tập trung: chốt đúng một lần (khóa `focus:<id>`), tạm dừng không tính, giờ quay ngược thì `elapsed` không âm.
- Xóa dữ liệu: xóa đủ 12 bảng và các khóa UserDefaults đã liệt kê, tạo lại hồ sơ và gói đồ ăn chào mừng, coordinator được đặt lại.

---

## Thiếu test quan trọng
1. **Nhật ký ngày cũ không có thưởng** (sau khi sửa N1), và nhật ký ngày cũ không nạp năng lượng chuyến đi hôm nay.
2. **FocusCoordinator** (hiện chưa có test nào): bơm `AppClock` giả, kiểm tra
   - (a) chế độ nghiêm khi đang rời app thì phiên chạy hết giờ **không** được thưởng (C4);
   - (b) khóa máy rồi quay lại sau 2 phút không bị tính rời app;
   - (c) tự chạy tiếp chỉ trong cửa sổ 60 giây;
   - (d) bật chế độ nghiêm khi đang tạm dừng vẫn tiếp tục được.
   Tách phần quyết định khỏi UIKit thành struct thuần để test trên Linux.
3. **Trần thưởng tập trung theo ngày** (sau khi thêm) và phát hiện đồng hồ nhảy.
4. **Sao lưu:** từ chối dòng thưởng vượt trần theo loại, dòng `gift` lạ; chạy thử round-trip có dòng `gacha` 10 lượt và đồ `gachaOnly`.
5. **Bộ sưu tập / `wearLook` với bộ có món `gachaOnly`:** phải báo rõ, không hiện giá mua.
6. **Mã quà:** không có trong Release (`#if DEBUG`), hoặc chỉ dùng được một lần.
7. **`completeOnboarding` gọi 2 lần** thì không tạo trùng mẫu lặp.
8. **Pity khi sổ cái bị sắp lại theo `createdAt`:** các lượt quay xen với dòng minigame có `createdAt` trong quá khứ, sau `reloadAll()` bộ đếm vẫn đúng.
9. **Xóa toàn bộ dữ liệu khi đang có phiên tập trung:** không còn phiên, không còn thông báo `focus.end`/`focus.nudge`.
10. **UI test (XCUITest) tối thiểu** cho: bắt đầu, tạm dừng, tiếp tục ở tab và ở sheet cùng lúc; gacha đóng giữa chừng; nhật ký ngày cũ.
