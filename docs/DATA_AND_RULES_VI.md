# Dữ liệu, sao lưu và quy tắc của Cozyday

## 1. Lưu trữ

- **SwiftData**, file `Application Support/Cozyday.store` trong sandbox của app. CloudKit **tắt tường minh**
  (`cloudKitDatabase: .none`). Không có máy chủ, tài khoản, analytics.
- Không lưu lịch sử bằng `UserDefaults`. Không ghi tên việc/nhật ký vào log.
- Bản kiểm chứng Mốc A dùng file riêng `PathCheck.store`; bản đầy đủ không đọc/ghi file này.
- Mở store thất bại (ví dụ migration lỗi) → app hiện màn hình lỗi, **không xóa database** để "khởi tạo lại".

### Các bảng (lược đồ phiên bản 1 — `CozySchemaV1`)

| Bảng | Khóa / tham chiếu | Ghi chú |
|---|---|---|
| `ProfileModel` | một dòng duy nhất | Tên người dùng, tên mèo, mục tiêu, khung giờ hoạt động, rung, nhắc nhật ký, `dataVersion`. Tạo **đúng một lần** khi chưa có. |
| `TaskTemplateModel` | `id` (UUID) | Mẫu việc lặp: nội dung + lịch lặp (`daily`/`weekly`, các thứ, ngày bắt đầu/kết thúc). |
| `TaskOccurrenceModel` | `id` (UUID), `occurrenceKey` (duy nhất về logic), `templateID?` | Từng lần việc. `dayRaw = ""` = Hộp chờ. |
| `LedgerEntryModel` | `id`, `key` (duy nhất về logic) | Sổ cái thưởng/chi. **Số dư xu và XP = tổng sổ cái**, không lưu số dư riêng. |
| `OwnedItemModel` | `itemID` | Đồ đã sở hữu, kèm `transactionID` của dòng sổ cái mua. |
| `EquippedSlotModel` | `slotRaw` | Món đang đặt ở mỗi vị trí phòng. |
| `FocusSessionModel` | `id` | Phiên tập trung/nghỉ, lưu mốc thời gian (không lưu "giây còn lại"). |
| `JournalEntryModel` | `id`, `dayRaw` (một mục/ngày) | Mood 1–5 + ghi chú. |

Danh mục đồ (`Catalog`) nằm trong code với **ID cố định** (`desk.pine`, `lamp.candle`…) nên luôn idempotent: cập nhật app
không reset xu hay đồ đạc. Đổi tên hiển thị được, nhưng **không bao giờ đổi ID**.

### Quan hệ và quy tắc xóa

Không dùng relationship của SwiftData; tham chiếu bằng ID để quy tắc xóa rõ ràng:

- Xóa việc một lần → xóa occurrence. **Sổ cái giữ nguyên** (không cascade) nên không thể xóa rồi tạo lại để nhận thưởng lần nữa cho cùng occurrence.
- Xóa "chỉ lần này" của việc lặp → occurrence thành **bia mộ** (`isRemoved = true`) để không bị sinh lại.
- Xóa "lần này và các lần sau" → mẫu kết thúc vào hôm trước (hoặc bị xóa nếu từ lần đầu); lần chưa làm từ ngày đó bị xóa; lần đã xong/bỏ qua được giữ làm lịch sử.
- Xóa nhật ký → không thu hồi thưởng nhật ký.
- Mọi thao tác ghi đi qua `AppStore.commit`: sửa model + `save()` một lần; lỗi → `rollback()` + nạp lại, báo lỗi cho người dùng.

### Migration

- Mỗi lần đổi lược đồ: thêm `CozySchemaV2` (không sửa V1 đã phát hành), thêm vào `CozyMigrationPlan.schemas` và một `MigrationStage`
  (lightweight nếu chỉ thêm trường có giá trị mặc định; custom nếu cần chuyển dữ liệu). Tăng `BackupDocument.currentSchemaVersion`
  nếu định dạng sao lưu đổi, và giữ khả năng đọc bản cũ.
- Test bắt buộc trước khi phát hành: mở store V1 có dữ liệu bằng bản mới, xác nhận hồ sơ/xu/đồ không bị reset.

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
| Hoàn thành một lần việc **lần đầu** | +10 XP, +5 xu | `task:<occurrenceID>` |
| Phiên tập trung ≥ 10 phút **chạy hết giờ** | +2 XP và +1 xu mỗi 5 phút (tối đa 120 phút) | `focus:<sessionID>` |
| Viết nhật ký (một lần mỗi ngày) | +5 XP, +2 xu | `journal:<yyyy-MM-dd>` |
| Mua đồ | −giá (đồ miễn phí ghi 0 xu) | `purchase:<itemID>` |

- Bỏ hoàn thành hoặc xóa việc **không thu hồi** thưởng đã nhận; hoàn thành lại cùng lần việc **không** nhận thêm.
- Thống kê "việc đã xong" phản ánh **trạng thái hiện tại** (bỏ hoàn thành thì số giảm), độc lập với sổ cái.
- Tạm dừng không tính vào phút tập trung. Kết thúc sớm: không thưởng, nhưng số phút đã chạy được ghi lại.
- Mở lại app sau khi phiên đã hết giờ: phiên được chốt **một lần** với thời điểm kết thúc thật; không tự tạo thêm phiên nghỉ.
- Mua đồ: kiểm tra đủ xu + chưa sở hữu → ghi dòng sổ cái và đồ sở hữu **trong cùng một lần save**. Bấm nhanh hai lần: lần thứ hai bị từ chối.
- XP chỉ để vui (cấp = XP/100 + 1). Mèo không ốm, không bỏ đi, không mất đồ khi bạn nghỉ. Chuỗi ngày không có hình phạt.

## 4. Sao lưu và khôi phục

### Xuất

*Cài đặt → Xuất sao lưu…* → lưu vào app Tệp. File `Cozyday-backup-YYYY-MM-DD.json`:

```json
{
  "format": "cozyday.backup",
  "schemaVersion": 1,
  "exportedAt": "2026-10-18T15:00:00.000Z",
  "appVersion": "0.1.0 (12)",
  "profile": { … },
  "templates": [ … ],
  "occurrences": [ … ],
  "ledger": [ … ],
  "ownedItems": [ … ],
  "equipped": [ … ],
  "focusSessions": [ … ],
  "journal": [ … ]
}
```

Đầy đủ mọi thứ cần để khôi phục, **kể cả sổ cái và đồ đạc**. File là chữ đọc được, **không mã hóa**.

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
