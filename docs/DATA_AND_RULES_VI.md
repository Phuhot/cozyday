# Dữ liệu, sao lưu và quy tắc của Cozyday

## 1. Lưu trữ

- **SwiftData**, file `Application Support/Cozyday.store` trong sandbox của app. CloudKit **tắt tường minh**
  (`cloudKitDatabase: .none`). Không có máy chủ, tài khoản, analytics.
- Không lưu lịch sử bằng `UserDefaults`. Không ghi tên việc/nhật ký vào log.
- Bản kiểm chứng Mốc A dùng file riêng `PathCheck.store`; bản đầy đủ không đọc/ghi file này.
- Mở store thất bại (ví dụ migration lỗi) → app hiện màn hình lỗi, **không xóa database** để "khởi tạo lại".

### Các bảng (lược đồ hiện tại: phiên bản 3 — `CozySchemaV3`)

| Bảng | Khóa / tham chiếu | Ghi chú |
|---|---|---|
| `ProfileModel` | một dòng duy nhất | Tên người dùng, tên mèo, mục tiêu, khung giờ hoạt động, rung, nhắc nhật ký, `dataVersion`. Tạo **đúng một lần** khi chưa có. |
| `TaskTemplateModel` | `id` (UUID) | Mẫu việc lặp: nội dung + lịch lặp (`daily`/`weekly`, các thứ, ngày bắt đầu/kết thúc) + việc con mẫu (V2). |
| `TaskOccurrenceModel` | `id` (UUID), `occurrenceKey` (duy nhất về logic), `templateID?` | Từng lần việc. `dayRaw = ""` = Hộp chờ. `subtasksJSON` (V2): việc con của lần này. |
| `LedgerEntryModel` | `id`, `key` (duy nhất về logic) | Sổ cái thưởng/chi. **Số dư xu và XP = tổng sổ cái**, không lưu số dư riêng. |
| `OwnedItemModel` | `itemID` | Đồ đã sở hữu (đồ phòng và đồ thú cưng), kèm `transactionID` của dòng sổ cái mua. |
| `EquippedSlotModel` | `slotRaw` | Món đang dùng ở mỗi vị trí: các vị trí của 5 không gian (phòng học, phòng ngủ, bếp, phòng tắm, vườn — mỗi nơi có một vị trí "tường & sàn"/"bầu trời") + 7 lớp thú cưng (`species`, `fur`, `hat`, `glasses`, `neck`, `outfit`, `back`). Thêm vị trí mới không cần đổi lược đồ: `slotRaw` là chuỗi. |
| `FocusSessionModel` | `id` | Phiên tập trung/nghỉ, lưu mốc thời gian (không lưu "giây còn lại"). |
| `JournalEntryModel` | `id`, `dayRaw` (một mục/ngày) | Mood 1–5 + ghi chú. |
| `PetCareStateModel` (V3) | một dòng duy nhất | No bụng, Nhà sạch, Vui vẻ (0–100) + mốc `asOf` đã tính tới. Dùng chung cho thú cưng — đổi loài/ngoại hình không đổi. |
| `FoodStockModel` (V3) | `foodID` | Số lượng mỗi món trong khay đồ ăn (0–99). |
| `CareActionModel` (V3) | `id` = careActionID | Mỗi lần chăm: loại, ngày, chỉ số trước/sau, XP/xu đã nhận, lý do. Giữ 30 ngày gần nhất (đủ tính hạn mức). |
| `MinigameResultModel` (V3) | `id` = sessionID | Kết quả một lượt Sân chơi: game, điểm, độ cao/số món/số lượt lật, thời gian chạy, ngày, xu nhận, lý do. Giữ 200 lượt mới nhất + mọi lượt 3 ngày gần đây + kỷ lục từng game. |

Danh mục đồ (`Catalog`) nằm trong code với **ID cố định** (`desk.pine`, `species.fox`, `hat.crown`…) nên luôn idempotent:
cập nhật app không reset xu hay đồ đạc. Đổi tên hiển thị được, nhưng **không bao giờ đổi ID**.

- Hình dạng **Mèo** và lông **Kem sữa** là lựa chọn mặc định: luôn thuộc về bạn, đang dùng khi vị trí đó trống, không ghi vào kho.
- Ngoại hình thú cưng **suy ra** từ các món đang dùng + cấp (giai đoạn lớn) — không lưu riêng.
- Năng lượng chuyến đi **suy ra** từ sổ cái trong ngày; câu chuyện chọn cố định theo ngày — không lưu riêng.
- Sự kiện từ app Lịch **không** được lưu vào Cozyday và **không** có trong bản sao lưu.

### Quan hệ và quy tắc xóa

Không dùng relationship của SwiftData; tham chiếu bằng ID để quy tắc xóa rõ ràng:

- Xóa việc một lần → xóa occurrence. **Sổ cái giữ nguyên** (không cascade) nên không thể xóa rồi tạo lại để nhận thưởng lần nữa cho cùng occurrence.
- Xóa "chỉ lần này" của việc lặp → occurrence thành **bia mộ** (`isRemoved = true`) để không bị sinh lại.
- Xóa "lần này và các lần sau" → mẫu kết thúc vào hôm trước (hoặc bị xóa nếu từ lần đầu); lần chưa làm từ ngày đó bị xóa; lần đã xong/bỏ qua được giữ làm lịch sử.
- Xóa nhật ký → không thu hồi thưởng nhật ký.
- Mọi thao tác ghi đi qua `AppStore.commit`: sửa model + `save()` một lần; lỗi → `rollback()` + nạp lại, báo lỗi cho người dùng.

### Migration

- **V1 → V2** (bản có việc con): migration nhẹ, chỉ thêm cột `subtasksJSON` (mặc định rỗng). Dữ liệu cũ giữ nguyên;
  test `MigrationTests` tạo kho V1 thật trên đĩa rồi mở bằng bản mới, kiểm tra hồ sơ, việc, xu, đồ còn nguyên.
- Mỗi lần đổi lược đồ: thêm phiên bản mới (không sửa phiên bản đã phát hành), thêm vào `CozyMigrationPlan.schemas` và một `MigrationStage`
  (lightweight nếu chỉ thêm trường có giá trị mặc định; custom nếu cần chuyển dữ liệu). Tăng `BackupDocument.currentSchemaVersion`
  nếu định dạng sao lưu đổi, và giữ khả năng đọc bản cũ.
- **V2 → V3** (chăm thú cưng + Sân chơi): migration nhẹ, **chỉ thêm bảng mới**. Lần đầu mở bản mới, app tạo hồ sơ chăm sóc
  với chỉ số dễ chịu (No bụng 80, Nhà sạch 85, Vui vẻ 80) và gói đồ ăn chào mừng (3 Táo giòn, 1 Cơm nắm) **trong cùng một lần
  lưu** — mở lại app hay chạy lại migration không tặng thêm. Test `testV2StoreOpensWithV3KeepingDataAndGrantsWelcomeOnce`
  tạo kho V2 thật trên đĩa (hồ sơ, việc có việc con, xu, đồ, trang bị, nhật ký) rồi mở bằng bản mới.
- Test bắt buộc trước khi phát hành: mở store bản cũ có dữ liệu bằng bản mới, xác nhận hồ sơ/xu/đồ không bị reset.
- App **không bao giờ** xóa hay tạo lại kho dữ liệu để "sửa" lỗi migration: nếu không mở được, app hiện màn báo lỗi.

## 2. Ngày, giờ và lịch lặp

- **Khóa ngày** (`DayKey`, dạng `yyyy-MM-dd`) tính theo lịch và múi giờ của thiết bị — không bao giờ cắt ngày theo UTC.
- Giờ của việc lưu dạng **giờ đồng hồ địa phương** (phút từ 00:00) + khóa ngày. Đổi múi giờ thì 08:00 vẫn là 08:00.
  Các mốc tuyệt đối (lúc hoàn thành, mốc phiên tập trung, thời điểm ghi sổ cái) lưu bằng `Date`.
- Cộng/trừ ngày luôn qua `Calendar` (không cộng 86.400 giây) — đúng cả ngày đổi giờ mùa hè.
- Việc qua nửa đêm: **bị từ chối** kèm thông báo dễ hiểu (bản 1.0). Thời lượng 5 phút – 12 giờ.
- **Lịch lặp:** hằng ngày, hoặc các thứ đã chọn; tùy chọn ngày kết thúc. Mẫu (template) tách khỏi từng lần (occurrence).
- **Khóa ổn định** của occurrence lặp: `t:<templateID>|<yyyy-MM-dd>` (ngày gốc). Mở app nhiều lần, qua ngày, mở lại sau nhiều ngày
  đều không tạo trùng. Chuyển một lần sang ngày khác vẫn giữ khóa ngày gốc.
- Occurrence được sinh khi xem một ngày và cho cửa sổ hôm nay + 7 ngày (phục vụ nhắc việc).
- **Sửa việc lặp:**
  - *Chỉ lần này*: đổi riêng lần đó, đánh dấu `isDetached` (sửa mẫu sau này không ghi đè).
  - *Lần này và các lần sau*: mẫu cũ kết thúc hôm trước, mẫu mới bắt đầu từ lần này. Lần **trước đó** không bị chạm vào;
    lần đã hoàn thành/bỏ qua về sau giữ nguyên nội dung lịch sử.
- **Sắp xếp lại (replan)** — thuật toán xác định, không AI: chỉ dời việc chưa xong, không cố định, đã trễ giờ; xếp vào khoảng trống từ
  bây giờ (làm tròn 5 phút) tới hết khung giờ hoạt động; ưu tiên cao trước; giữ thời lượng; không chồng lịch; không đủ chỗ thì liệt kê,
  không âm thầm bỏ. Luôn xem trước, có nút Hủy.

## 3. Phần thưởng (bản 1.0)

Các con số nằm trong `Cozyday/Core/Rewards/RewardConfig.swift`.

| Sự kiện | Thưởng | Khóa chống trùng |
|---|---|---|
| Hoàn thành một lần việc **lần đầu** (tối đa 10 việc có thưởng mỗi ngày) | +10 XP, +8 xu | `task:<occurrenceID>` |
| Phiên tập trung ≥ 10 phút **chạy hết giờ** | +2 XP và +2 xu mỗi 5 phút (tối đa 120 phút) | `focus:<sessionID>` |
| Viết nhật ký (một lần mỗi ngày) | +5 XP, +5 xu | `journal:<yyyy-MM-dd>` |
| Bài thở chạy hết giờ (một lần mỗi ngày) | +3 XP, +3 xu | `breathing:<yyyy-MM-dd>` |
| Nghe thú cưng kể chuyến đi (đủ 100% năng lượng, một lần mỗi ngày) | +5 XP, +10 xu | `adventure:<yyyy-MM-dd>` |
| Mua đồ | −giá (đồ miễn phí ghi 0 xu) | `purchase:<itemID>` |
| Mua đồ ăn (mua lặp lại được) | −giá × số lượng | `food-purchase:<transactionID>` (mỗi lần mua một mã) |
| Chăm thú cưng đúng lúc cần | xem mục 3b | `care:<careActionID>` |
| Lượt Sân chơi hợp lệ | xem mục 3c, **không có XP** | `minigame:<sessionID>` |
| Một lượt máy gacha | −60 xu (10 lượt: −540), cộng lại xu nếu ra món trùng | `gacha:<pullID>` |
| Mã quà (ẩn trong Cài đặt, cho người thử nghiệm) | +xu theo mã | `gift:<id>` |

- **Hạn mức thưởng việc**: mỗi ngày (theo ngày bấm hoàn thành) chỉ 10 việc đầu có XP/xu. Việc thứ 11 trở đi vẫn ghi
  một dòng sổ cái 0 XP/0 xu với ghi chú "Hết hạn mức: …" để giữ khóa `task:<id>`, nên tạo hàng loạt việc rồi tick, hay
  xóa đi tạo lại, không còn cày được xu. Giao diện báo một câu nhẹ nhàng thay cho popup thưởng.
- Bỏ hoàn thành hoặc xóa việc **không thu hồi** thưởng đã nhận; hoàn thành lại cùng lần việc **không** nhận thêm.
- Thống kê "việc đã xong" phản ánh **trạng thái hiện tại** (bỏ hoàn thành thì số giảm), độc lập với sổ cái.
- Tạm dừng không tính vào phút tập trung. Kết thúc sớm: không thưởng, nhưng số phút đã chạy được ghi lại.
- Mở lại app sau khi phiên đã hết giờ: phiên được chốt **một lần** với thời điểm kết thúc thật; không tự tạo thêm phiên nghỉ.
- Mua đồ: kiểm tra đủ xu + chưa sở hữu → ghi dòng sổ cái và đồ sở hữu **trong cùng một lần save**. Bấm nhanh hai lần: lần thứ hai bị từ chối.
- Năng lượng chuyến đi: mỗi việc xong lần đầu, phiên tập trung có thưởng, nhật ký, bài thở trong ngày = +25%. Không bao giờ bị trừ.
- Một số hình dạng/trang phục cần đạt cấp nhất định mới mua được. Cấp không bao giờ giảm (mua đồ chỉ trừ xu, không trừ XP).
- Không gian mở theo cấp, không tốn xu: phòng học và phòng ngủ từ cấp 1, bếp cấp 2, phòng tắm cấp 3, vườn cấp 4.
  Đồ của một phòng không mua được trước cấp mở phòng đó. Tường & sàn mặc định của mỗi phòng luôn thuộc về bạn.
- **Mặc cả bộ** (Bộ sưu tập): mua mọi món còn thiếu trong một lần save — đủ cấp và đủ xu cho **cả bộ** mới mua, nếu không
  thì không món nào bị trừ xu. Mỗi món vẫn ghi một dòng `purchase:<itemID>` riêng. Mặc bộ mới thay toàn bộ 7 lớp ngoại hình;
  đồ cũ vẫn còn trong kho.
- Vị trí thú cưng sau khi kéo thả và phòng đang xem chỉ là tiện ích hiển thị trên máy (không nằm trong sao lưu).
- Việc con không có thưởng riêng.
- XP chỉ để vui (cấp = XP/100 + 1). Thú cưng không ốm, không bỏ đi, không mất đồ khi bạn nghỉ. Chuỗi ngày không có hình phạt.

## 3b. Chăm thú cưng

Các con số nằm trong `Cozyday/Core/Care/PetCare.swift` (`CareConfig`).

- **Ba nhu cầu** (0–100, cao là tốt): No bụng, Nhà sạch (một chỉ số chung cho cả nhà), Vui vẻ. Dưới 35 = *Cần chăm*,
  35–69 = *Bình thường*, từ 70 = *Ổn*. Góc nhỏ hiện cả ba bằng biểu tượng + nhãn + thanh + số + chữ (không chỉ dùng màu);
  bong bóng lời thoại chỉ nói **một** nhu cầu thấp nhất.
- **Suy giảm**: No bụng −3/giờ, Nhà sạch −2/giờ, Vui vẻ −2,5/giờ. Tính từ mốc thời gian đã lưu, không có timer chạy nền:
  - vắng mặt lâu chỉ tính tối đa **24 giờ**; không bao giờ thấp hơn **20** (một tuần không mở app vẫn chỉ ~20);
  - mở app/đọc lại nhiều lần không tính lặp (chỉ ghi khi có hành động chăm sóc);
  - đồng hồ quay ngược: chỉ số đứng yên, không tăng; mốc thời gian không bao giờ lùi.
  - Đã xuống dưới 35 thì giữ nguyên tới khi được chăm (chỉ tăng khi bạn chăm), nên luôn có thời gian để chăm.
- **Không có hình phạt**: thú cưng không ốm, không bỏ đi, không mất cấp/đồ; không có thông báo nhắc chăm; lời thoại không trách móc.
  Khi cần chăm, nét mặt thú cưng chỉ hơi "mong được chăm" (mắt tròn, mày hơi cụp).
- **Đồ ăn** (đồ tưởng tượng trong game): Táo giòn 3 xu (+18), Cà rốt 3 xu (+15, +3 vui), Bánh yến mạch 6 xu (+25, +6 vui),
  Cơm nắm 8 xu (+35, +4 vui), Súp rau 12 xu (+45, +8 vui), Hộp picnic 25 xu (+70, +20 vui). Mua một lần trừ xu một lần, tăng
  đúng số lượng; thử lại cùng mã giao dịch không trừ lần hai. Món rẻ nhất (3 xu) đắt hơn thưởng cho ăn (1 xu) → không "mua
  rồi cho ăn" để kiếm xu được.
- **Cho ăn**: trừ đúng một món; chỉ số không vượt 100; đang no từ 95 trở lên thì không cho ăn (không mất món).
- **Bữa cơ bản miễn phí**: chỉ khi No bụng dưới 35, đưa lên 55, không tạo vật phẩm, không có thưởng. Luôn dùng được kể cả khi hết xu.
- **Dọn nhà** (toàn màn hình, không cuộn trang): 6–8 vết bẩn — mạng nhện ở góc trên, vết bùn trên tường/sàn, bụi, lá khô,
  giấy vụn trên sàn. Cầm **chổi lông gà** (mạng nhện, bụi, lá, giấy) hoặc **khăn lau** (vết bùn) và chà qua lại: vết bẩn mờ dần
  theo quãng chà (bụi ~0,55, lá/giấy ~0,45, mạng nhện ~0,8, vết bùn ~1,1 bề ngang phòng). Dùng sai dụng cụ vẫn sạch, chỉ
  chậm hơn (35%) và có gợi ý đổi. Một lần di tay tính tối đa 0,12 bề ngang phòng (kéo nhảy cóc không làm sạch ngay).
  VoiceOver: mỗi vết bẩn là một nút "lau sạch", cả phòng có thao tác "Dọn hết" — cùng kết quả.
  Sạch hết → lưu một lần (`care:<actionID>` cố định cho cả lượt; lỗi lưu → *Thử lưu lại* cùng mã). Thoát giữa chừng không
  lưu gì. Nhà sạch từ 95 thì không cần dọn.
- **Nựng**: vuốt qua lại trên thú cưng tổng cộng ~3,5 giây (chỉ tính lúc ngón tay thật sự vuốt), hoặc nút *Nựng một chút*.
  Giữ rồi kéo vẫn là nhấc thú cưng, không tính là nựng. Chạm thường không có xu.
- **Thưởng** chỉ khi chỉ số **trước** khi chăm dưới 35 (bữa cơ bản không bao giờ có thưởng):

  | Chăm | Thưởng |
  |---|---|
  | Cho ăn | +2 XP, +1 xu |
  | Dọn nhà | +3 XP, +2 xu |
  | Nựng | +2 XP, +1 xu |

  Mỗi loại tối đa **2 lượt có thưởng/ngày**; tổng tối đa **12 XP và 6 xu/ngày** (tách riêng khỏi hạn mức Sân chơi).
  Hết hạn mức vẫn chăm bình thường. Chăm sóc **không** nạp năng lượng chuyến đi. Ngày = ngày địa phương lúc chăm.
- Mỗi hành động có mã `careActionID`; cập nhật chỉ số + trừ đồ ăn + lưu lịch sử + ghi thưởng trong **một lần lưu**. Bấm nhanh
  hai lần / thử lại cùng mã: không làm lại. Lỗi lưu: rollback toàn bộ, không báo đã nhận.

## 3c. Sân chơi (minigame)

Các con số nằm trong `Cozyday/Core/Play/Minigame.swift` (`MinigameConfig`).

**Cân bằng:** một ngày bình thường (5 việc + 50 phút tập trung + nhật ký + bài thở + chuyến đi) cho khoảng 30–45 xu và 70+ XP.
Sân chơi chỉ là giờ nghỉ ngắn nên mỗi lượt 1–6 xu, **không có XP**, tối đa **20 xu/ngày** (≈ 4 việc) — thấp hơn mức 60 xu
tham khảo vì 60 xu sẽ vượt cả thu nhập từ hoạt động chính.

| Game | Lượt hợp lệ (có xu) | Quy đổi |
|---|---|---|
| Nhảy Mây | rơi xuống (kết thúc đúng luật) và leo ≥ 15 m | điểm = mét + 3 × sao; 1 xu mỗi 15 điểm (độ khó mới không đổi cách quy đổi) |
| Giỏ Quà | chơi **hết 60 giây** và ≥ 20 điểm | 1 xu mỗi 20 điểm |
| Lật Thẻ | **ghép hết bàn** | Dễ 2 xu / Vừa 3 xu; +1 nếu lượt lật ≤ 2 × số cặp; +1 nếu ≤ số cặp + 3; +1 nếu nhanh (Dễ ≤ 40 s, Vừa ≤ 65 s) |

- Tối đa 6 xu/lượt. Chỉ còn 4 xu trong hạn mức thì chỉ nhận 4 (*partialCap*). Hết hạn mức: vẫn chơi, vẫn lưu kết quả và
  kỷ lục, màn kết quả ghi "Hôm nay đã nhận đủ xu sân chơi".
- Thoát giữa lượt: không lưu, không xu. Thua không bao giờ mất xu. Không mua lượt, không quảng cáo.
- **Kiểm tra hợp lý** trước khi trao xu (không tin hoàn toàn số liệu từ màn hình): Nhảy Mây ≤ 8 m/giây chơi và điểm phải khớp
  độ cao + sao; Giỏ Quà ≤ 40 điểm/giây và ≤ 61 giây; Lật Thẻ số lượt ≥ số cặp, thời gian ≥ 0,6 giây/cặp. Sai → lưu kết quả,
  0 xu (*implausible*).
- **Ngày tính hạn mức** = ngày địa phương lúc lượt **kết thúc** (bắt đầu 23:59, xong 00:01 → tính ngày mới). Mốc kết thúc
  ở tương lai bị kẹp về hiện tại. Hạn mức tính từ sổ cái nên khởi động lại app không đặt lại hạn mức.
- Mỗi lượt có `sessionID` riêng. Kết quả + dòng `minigame:<sessionID>` lưu trong **một lần lưu**, tự động khi lượt kết thúc
  (không cần bấm "nhận"). Mở lại màn kết quả / bấm nhiều lần / mở lại app: không cộng thêm. Lỗi lưu: màn kết quả báo rõ và có
  nút *Thử lưu lại* — thử với **cùng** sessionID. Kết quả đã lưu vẫn thấy trong *Lượt gần đây* nếu app bị đóng trước màn kết quả.
- Kỷ lục theo từng game, dùng chung cho mọi loài. Loài và trang phục không đổi hitbox hay độ khó.
- **Nhảy Mây — độ khó** (`CloudJumpEngine`): 12 m đầu là vùng khởi động dễ; sau đó độ khó tăng dần tới tối đa ở **160 m**
  (trước đây 400 m): khoảng cách giữa mây lớn dần (tối đa 38), mây hẹp dần (26 → 14), nhiều mây di chuyển hơn (20% → 50%).
  Chướng ngại xuất hiện từ 12 m (18% → 50% khoảng trống giữa hai mây có một chướng ngại):
  - **Mây giông** cau có: đứng yên sát hành lang bay giữa hai mây;
  - **Chim nhỏ**: bay qua lại trong một khoảng trời, có thể cắt ngang đường lên mây kế — canh lúc chim bay đi rồi nhảy;
  - **Mây mỏng** (viền nét đứt): nảy được một lần rồi tan; không có hai mây mỏng liền nhau.
  Chạm chướng ngại: mất đà bay lên và rơi nhẹ xuống (không mất lượt ngay — lái về mây bên dưới là nảy tiếp được).
  **Luôn chơi được**: mọi khoảng cách vẫn trong tầm nhảy; chướng ngại không bao giờ chạm vùng của mây ngay bên dưới và mây
  trước đó, nên đứng nảy tại chỗ để chờ luôn an toàn; chim không bay trên mây mỏng. Có test với 30 seed: người chơi máy biết
  chờ chim leo > 200 m không rơi; tốc độ leo tối đa theo vật lý vẫn < 4 m/giây.
- **Giới hạn chống gian lận**: app hoàn toàn offline nên nếu bạn đổi ngày giờ của máy, hạn mức theo ngày (cả chăm sóc lẫn Sân
  chơi) đổi theo. Cozyday không hứa chống được kiểu gian lận này.

## 3d. Ảnh đại diện

`Cozyday/Core/Pet/Avatar.swift` (`AvatarConfig`, `AvatarCatalog`), vẽ bằng `AvatarPainter`.

- Gồm **nền** (10), **phong cảnh** (8), **hiệu ứng** (9), **biểu cảm** (4) và **trang phục riêng** cho ảnh. Không tốn xu,
  không có thưởng. Vài lựa chọn mở theo cấp như các phòng (Đêm tím 3, Biển xanh 4, Hoàng hôn 5, Thiên hà 8; Trăng khuyết 3,
  Bãi biển 4, Cầu vồng 5, Đồi tuyết 6, Anh đào 7; Bong bóng 4, Tuyết rơi 6, Cánh hoa 7, Đom đóm 8, Pháo giấy 10).
- Trang phục riêng chỉ chọn từ **đồ đã có**; mặc định là "theo đồ đang mặc". Đổi đồ trong ảnh không thay đồ trong phòng.
  Giai đoạn lớn luôn theo cấp thật.
- Lưu bằng `UserDefaults` (khóa `avatar.config`, không đổi lược đồ SwiftData) và có trong bản sao lưu (trường `avatar`,
  tùy chọn). ID lạ hoặc chưa mở khóa → hiển thị lựa chọn mặc định, không lỗi.
- *Lưu ảnh / chia sẻ*: tạo PNG 1024×1024 **trên máy** chỉ khi bạn bấm; không tải lên đâu. Lưu vào app Ảnh cần quyền "chỉ thêm
  ảnh" (`NSPhotoLibraryAddUsageDescription`) — app không đọc ảnh có sẵn.
- Icon của app là ảnh đại diện "Trời hồng + Đệm mây + Lấp lánh" với vịt con vàng đội mây (`AvatarPainter.appIcon`).

## 3e. Máy gacha, đồ hiếm và đồ bí mật

Luật nằm trong `Cozyday/Core/Shop/Gacha.swift` (`GachaConfig`, `GachaPolicy`), hiện công khai trong màn máy gacha.

- Giá: 60 xu/lượt, 540 xu/10 lượt. Lượt 10 chắc chắn có ít nhất một món Hiếm.
- Tỉ lệ: Thường 60%, Hiếm 28%, Quý 10%, Bí mật 2%. Độ hiếm của món cửa hàng tính theo giá (< 50 xu Thường,
  50–89 Hiếm, ≥ 90 Quý); món có `rarity` riêng (đồ chỉ có trong gacha) giữ độ hiếm đó.
- Bảo hiểm: 9 lượt liền không có món Quý trở lên thì lượt thứ 10 chắc chắn Quý; lượt thứ 60 kể từ món Bí mật gần nhất
  chắc chắn Bí mật. Bộ đếm đọc thẳng từ sổ cái (`gacha:` + món đã ra), không lưu riêng.
- Máy chỉ ra trang phục (mũ, kính, cổ, áo, phụ kiện) và hình dạng; không ra màu lông hay đồ trong phòng.
- Ưu tiên món chưa có trong cùng độ hiếm. Khi đã có đủ cả nhóm, món trùng đổi thành xu: Thường 15, Hiếm 25, Quý 50, Bí mật 120.
- Mỗi lượt là một dòng sổ cái `gacha:<pullID>`: xu = −giá lượt + xu hoàn (nếu trùng), `refID` = ID món. Món mới được thêm
  vào kho trong **cùng một lần save** với các dòng sổ cái.
- Món `gachaOnly` không mua được trong cửa hàng/tủ đồ. Món Bí mật chưa có chỉ hiện bóng đen và tên "???".
- Sao lưu: dòng `gacha` phải có 0 XP và xu trong khoảng −60 … +120.

## 3f. Xóa toàn bộ dữ liệu và mã quà

- Cài đặt → *Xóa toàn bộ dữ liệu*: hỏi hai lần (lần đầu gợi ý tạo bản sao lưu). Xóa mọi bảng SwiftData và các tùy chọn
  hiển thị (ảnh đại diện, phòng đang xem, tùy chọn Sân chơi), tạo lại hồ sơ trống rồi app quay về màn giới thiệu. Không hoàn tác.
- Mã quà: chạm 7 lần vào dòng *Phiên bản* trong Cài đặt để hiện ô nhập. Mã đúng ghi một dòng `gift:<id>`; nhập lại được.

## 4. Sao lưu và khôi phục

### Xuất

*Cài đặt → Xuất sao lưu…* → lưu vào app Tệp. File `CozyDay-backup-YYYY-MM-DD.json`:

```json
{
  "format": "cozyday.backup",
  "schemaVersion": 2,
  "exportedAt": "2026-10-18T15:00:00.000Z",
  "appVersion": "0.1.0 (12)",
  "profile": { … },
  "templates": [ … ],
  "occurrences": [ … ],          // có "subtasks" nếu việc có việc con (bản cũ không có khóa này vẫn đọc được)
  "ledger": [ … ],
  "ownedItems": [ … ],
  "equipped": [ … ],
  "focusSessions": [ … ],
  "journal": [ … ],
  "petCare": { … },              // từ bản 2: nhu cầu + mốc thời gian
  "foodStock": [ … ],            // khay đồ ăn
  "careActions": [ … ],          // lịch sử chăm sóc gần đây
  "minigameResults": [ … ],      // kết quả Sân chơi
  "avatar": { … }                // ảnh đại diện (tùy chọn; file cũ không có → ảnh mặc định)
}
```

Đầy đủ mọi thứ cần để khôi phục, **kể cả sổ cái và đồ đạc**. File là chữ đọc được, **không mã hóa**.

File sao lưu **bản 1** (trước khi có chăm thú cưng / Sân chơi) vẫn khôi phục được: chỉ số chăm sóc về mức dễ chịu, khay đồ ăn
trống (không tặng lại gói chào mừng), chưa có kết quả Sân chơi. Bản 2 được kiểm tra thêm: chỉ số 0–100, số lượng đồ ăn 0–99,
ID không trùng, món ăn có trong danh mục, dòng thưởng Sân chơi không có XP và ≤ 6 xu, và thưởng chăm sóc / Sân chơi trong
2 ngày trước lúc xuất phải có lịch sử đi kèm (để sau khi khôi phục vẫn chống thưởng trùng và tính đúng hạn mức).

### Khôi phục (thay thế toàn bộ)

1. Kiểm tra kích thước (≤ 25 MB) → JSON hợp lệ → `format` → `schemaVersion` (từ chối bản mới hơn app) → giải mã đầy đủ kiểu dữ liệu.
2. Kiểm tra: ID trùng (mọi bảng), khóa occurrence/sổ cái trùng, tham chiếu (mẫu lặp, đồ trong danh mục, đồ trang bị phải đã sở hữu và đúng vị trí),
   giá trị (giờ/thời lượng, qua nửa đêm, mood 1–5, số xu không âm, dòng mua không cộng xu…).
3. Hiện **xem trước số bản ghi** của file và của dữ liệu hiện tại → người dùng xác nhận.
4. Xóa + chèn trong **một lần save**; lỗi → rollback, dữ liệu cũ còn nguyên.
5. Sau khôi phục: dựng lại lịch nhắc từ dữ liệu (không nhập ID thông báo cũ); phiên tập trung quá hạn trong file được chốt một lần
   (sổ cái chống thưởng trùng).

### Giới hạn cần biết

- Gỡ app có thể xóa toàn bộ dữ liệu trên máy. Gia hạn chữ ký/cài lại **không phải** sao lưu.
- Đổi bundle ID hoặc Apple Account khi ký có thể khiến iPhone coi là app khác → dữ liệu không đi theo.
- Ghi đĩa thất bại (hết dung lượng…) → app báo lỗi, không báo "đã lưu" giả.
