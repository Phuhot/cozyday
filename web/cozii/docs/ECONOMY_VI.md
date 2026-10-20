# Kinh tế & phần thưởng của Cozii!

Mọi con số nằm trong `src/content/economy.ts`, `src/content/farm.ts`, `src/content/capsule.ts`, `src/content/town.ts` và
`src/core/games.ts`. Máy chủ (`server/`, đóng gói thành `api/cozii.js`) import đúng các file này, nên chế độ chơi trên máy
và chế độ online luôn cùng luật. Đổi số ở đó rồi chạy lại `npm run sim:economy` để xem tác động.

## 1. Ba loại tiền, không có tiền thật

| Loại | Kiếm ở đâu | Dùng vào đâu |
|---|---|---|
| **Xu** | bán nông sản, giao đơn, minigame, chăm pet đúng lúc, nhiệm vụ ngày, hộ chiếu, ghé thăm & tưới giúp bạn bè | hạt giống, đồ ăn, nội thất, quần áo, mở ô đất, đổi vé capsule |
| **Vé capsule** | 1 vé lúc bắt đầu, nhiệm vụ ngày (đủ 3 việc: +1), hộ chiếu (2–3 vé/chương), đổi 120 xu (tối đa 2 vé/ngày) | quay máy capsule |
| **Mảnh** | đồ capsule bị trùng | đổi lấy món còn thiếu trong bộ |

Không có nạp tiền, không có trao đổi giữa người chơi, không có giao dịch xu giữa tài khoản.

## 2. Nguồn xu và giới hạn

| Nguồn | Luật | Giới hạn |
|---|---|---|
| Vườn | 6 loại cây, 90 giây → 4 giờ. Lãi mỗi vụ một ô: củ cải 1, cà rốt 4, dâu 6, bí ngô 8, ngô 12, hướng dương 15 xu. Cây không bao giờ héo/thối. | Quầy trả đủ giá tới khi **tiền lãi** bán ở quầy trong ngày đạt 250 xu; sau đó mua đúng **giá vốn** hạt (hòa vốn, không lỗ). Chặn vòng lặp cày củ cải vô hạn. |
| Đơn hàng (Bé Bơ) | 3 đơn trên bảng, chỉ dùng cây đã mở. Thưởng = giá bán × 1,4 (làm tròn 5). | 4 đơn/ngày, 3 lần đổi đơn miễn phí/ngày. |
| Minigame | Mỗi trò có ngưỡng tối thiểu và công thức điểm → xu (bảng mục 4). Thua không mất gì. | 12 xu/lượt, 80 xu/ngày cho tất cả minigame. Lượt chơi phải do máy chủ cấp (mã lượt, hết hạn sau 30 phút, nộp một lần). |
| Chăm pet | Cho ăn/dọn/nựng **khi chỉ số dưới 35**: 2/3/2 xu. | 2 lần thưởng mỗi loại/ngày, tổng 12 xu/ngày. Nhu cầu giảm chậm, có sàn 20, tính tối đa 24 giờ vắng nhà. |
| Nhiệm vụ ngày | 3 việc nhẹ chọn theo ngày (cố định cho mỗi người), 20 xu/việc, đủ 3 việc +1 vé. | Bỏ lỡ không bị phạt, không có chuỗi ngày. |
| Hộ chiếu | 5 chương, mỗi chương 100–300 xu + 2–3 vé; chương 5 tặng danh hiệu. | Nhận một lần. |
| Bạn bè (online) | Lần đầu ghé một nhà trong ngày: 3 xu; tưới giúp: 3 xu cho người tưới, cây chủ nhà nhanh hơn 10%. | 4 lần ghé có thưởng/ngày; 3 lần tưới giúp/ngày; mỗi cây tối đa 2 lượt tưới giúp. |

Xu không bao giờ âm (ràng buộc CHECK trong cơ sở dữ liệu, kiểm tra trong luật chơi).

## 3. Chi tiêu

* Cửa hàng: giá = giá gốc bản iOS × 3 (loài × 4), làm tròn 5 xu. Hiện có 147 món, tổng 25.120 xu.
* Ô đất: bắt đầu 4 ô, mở tới 12 ô: ô 5–6 giá 100 (hạng 1), 7–8 giá 250 (hạng 2), 9–10 giá 500 (hạng 3), 11–12 giá 900 (hạng 4).
* Đồ ăn: mua ở Tiệm Bánh hoặc nấu từ nông sản (rẻ hơn). Đồ ăn là vật phẩm tiêu hao, mỗi lần mua có mã yêu cầu riêng.
* Vé capsule: 120 xu, tối đa 2 vé/ngày.

## 4. Minigame → xu

| Trò | Điểm | Ngưỡng có xu | Xu |
|---|---|---|---|
| Nhảy Mây | mét + 3 × sao | 15 m | điểm ÷ 10 (máy chủ chạy lại seed + nhật ký điều khiển khi xếp hạng) |
| Giỏ Quà | điểm hứng quà (60 giây) | 20 điểm | điểm ÷ 15 |
| Lật Thẻ | dễ 6 cặp / vừa 8 cặp | hoàn thành | 3 hoặc 5 xu + thưởng ít lượt / nhanh (tối đa +3) |
| Vườn Nốt Nhạc | độ chính xác × 10 | 40% | độ chính xác ÷ 10 (không có bảng xếp hạng cạnh tranh vì độ trễ âm thanh mỗi máy khác nhau) |
| Đường Về Nhà | mét + 2 × dâu | 50 m | điểm ÷ 25 |
| Xếp Giỏ Picnic | 300 − giây − 40 × gợi ý − nước thừa | hoàn thành | 4 xu, +2 nếu không dùng gợi ý |

Kết quả phi lý (vượt tốc độ tối đa theo thời gian thật của lượt, xong sớm hơn thời lượng bài nhạc…) bị từ chối và không
tính kỷ lục. Mọi loài pet có cùng kích thước va chạm.

## 5. Capsule

* 4 bộ, mỗi bộ 8 món ngoại hình: 5 thường, 2 hiếm, 1 đặc biệt. Tỷ lệ công khai trong game: **thường 70%, hiếm 25%, đặc
  biệt 5%** (chia đều cho các món cùng độ hiếm trong bộ).
* Bảo hiểm: tối đa 8 lượt sẽ có ít nhất một món hiếm trở lên; tối đa 30 lượt sẽ có món đặc biệt.
* Trùng → mảnh (thường 4, hiếm 10, đặc biệt 25). Đổi mảnh lấy món còn thiếu trong bộ: 25 / 60 / 150 mảnh.
* Đủ 8 món → nhận món trang trí riêng của bộ, danh hiệu và tư thế chụp ảnh.
* Kết quả do máy chủ quyết định và lưu cùng giao dịch trừ vé. Gửi lại cùng mã yêu cầu (mạng chập chờn, mở lại trang)
  luôn trả đúng kết quả cũ, không quay lại, không trừ thêm vé.

## 6. Mô phỏng 30 ngày (`npm run sim:economy`)

Mô phỏng chạy **chính luật chơi trong `src/core/engine.ts`** với bốn kiểu người chơi tự động: chăm pet khi cần, gieo cây
vừa kịp lần ghé sau (ưu tiên cây đơn hàng đang cần), giao đơn, bán phần dư, nhận nhiệm vụ & hộ chiếu, để dành tiền mở ô
đất rồi mới mua nội thất rẻ nhất chưa có. "Chơi game giỏi" chơi 12 lượt/ngày điểm cao; "Mê làm vườn" ghé 6 lần ngắn mỗi
ngày và chỉ chơi 1 lượt.

| Kiểu người chơi | Phút/ngày | Xu/ngày (ròng sau tiền hạt) | Xu/phút | Vườn (bán − hạt) | Đơn hàng | Minigame | Chăm pet | Nhiệm vụ ngày | Hộ chiếu |
|---|---|---|---|---|---|---|---|---|---|
| 10 phút/ngày | 10 | 159 | 15.9 | -4 | 85 | 7 | 5 | 51 | 450 (cả 30 ngày) |
| 30 phút/ngày | 30 | 411 | 13.7 | 153 | 133 | 30 | 5 | 57 | 1000 (cả 30 ngày) |
| Chơi game giỏi (45 phút) | 45 | 416 | 9.2 | 121 | 122 | 80 | 3 | 55 | 1000 (cả 30 ngày) |
| Mê làm vườn (6 lần ghé ngắn) | 24 | 390 | 16.2 | 162 | 124 | 7 | 6 | 57 | 1000 (cả 30 ngày) |

| Kiểu người chơi | Lên hạng 2 / 3 / 4 / 5 / 6 (ngày) | Ô đất ngày 7 / 30 | Món sở hữu ngày 1 / 7 / 14 / 30 | Chi: nội thất & đồ / ô đất / đồ ăn / vé | Lượt capsule | Ngày chạm trần xu minigame | Bậc thân thiết |
|---|---|---|---|---|---|---|---|
| 10 phút/ngày | 2 / 4 / 4 / – / – | 8 / 12 | 27 / 34 / 34 / 53 | 1290 / 3500 / 12 / 0 | 28 | 0/30 | 5 |
| 30 phút/ngày | 1 / 2 / 3 / 23 / 23 | 10 / 12 | 30 / 33 / 50 / 91 | 5385 / 3500 / 0 / 3480 | 68 | 0/30 | 6 |
| Chơi game giỏi (45 phút) | 1 / 3 / 4 / 25 / 25 | 10 / 12 | 29 / 32 / 48 / 90 | 5250 / 3500 / 0 / 3720 | 67 | 30/30 | 7 |
| Mê làm vườn (6 lần ghé ngắn) | 1 / 1 / 3 / 19 / 19 | 11 / 12 | 31 / 33 / 58 / 111 | 8190 / 3500 / 0 / 0 | 39 | 0/30 | 6 |

Cửa hàng có 147 món, tổng 25120 xu. Đồ chỉ có trong capsule: 32 món.

Đọc bảng:

* **Chơi nhiều hơn được nhiều hơn nhưng giảm dần**: 30 phút/ngày kiếm khoảng 2,6 lần người chơi 10 phút. Người ghé vườn
  thường xuyên hiệu quả nhất theo phút nhưng bị chặn bởi mức lãi 250 xu/ngày ở quầy và 4 đơn/ngày.
* **Người chơi game giỏi** chạm trần 80 xu/ngày từ minigame mỗi ngày; phần còn lại vẫn đến từ vườn và đơn, nên chơi giỏi
  không vượt hẳn người khác. Bảng xếp hạng chỉ tặng huy hiệu/cúp/khung, không tặng xu.
* **Mua hết cửa hàng** mất khoảng 2 tháng với 30 phút/ngày, khoảng 5 tháng với 10 phút/ngày. Đồ capsule chỉ là ngoại
  hình, có bảo hiểm và đổi mảnh nên không cần may mắn mới hoàn thành bộ.
* Không có vòng lặp lợi nhuận vô hạn: nấu ăn chỉ ra đồ ăn (không bán được), đơn hàng có trần ngày, bán ở quầy vượt mức chỉ
  hòa vốn, minigame có trần ngày, capsule không đổi ra xu.

Mô phỏng là xấp xỉ: người thật chọn cây và món đồ khác, nghỉ vài ngày, v.v. Số liệu dùng để so sánh các lựa chọn cân bằng,
không phải lời hứa về tốc độ tiến triển.

## 7. Chống gian lận & chống trùng (chế độ online)

* Client không bao giờ ghi số xu, phần thưởng hay điểm. Mọi thao tác gửi lên `/api/cozii` kèm **mã yêu cầu**; máy chủ chạy
  luật chơi trong một giao dịch Postgres có khóa dòng tài khoản (`SELECT … FOR UPDATE`) và ghi mã vào `tx_log`. Gửi lại
  cùng mã → trả đúng kết quả cũ (hai tab, mạng rớt rồi thử lại, bấm đúp).
* Thời gian cây lớn và hạn mức ngày dùng **đồng hồ máy chủ**; đồng hồ máy chỉ để hiển thị đếm ngược. Đổi giờ máy không làm
  cây chín sớm.
* Ghé thăm, khen, tưới giúp: hạn mức theo ngày và theo nhà, bảng `help_waters` có khóa duy nhất cho mỗi người tưới mỗi vụ;
  không ai ghi trực tiếp vào dữ liệu người khác.
* Bảng xếp hạng Nhảy Mây: máy chủ cấp mã lượt + seed, nhận nhật ký điều khiển, chạy lại toàn bộ lượt bằng số nguyên và chỉ
  ghi điểm khi khớp, đúng thời gian thật, một kết quả mỗi lượt. Việc này làm gian lận khó hơn nhiều nhưng **không chặn được
  bot chơi hộ hoàn toàn**.
* Chế độ chơi trên máy (không tài khoản) dùng cùng luật nhưng dữ liệu nằm trong trình duyệt: người rành kỹ thuật sửa được,
  nên không có bảng xếp hạng, bạn bè hay phần thưởng được máy chủ xác minh.
