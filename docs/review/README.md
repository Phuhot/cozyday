# Đánh giá bản phiên 8 bởi 4 tester (đọc code + ảnh CI, chưa chạy trên máy thật)

Báo cáo đầy đủ:

- [qa.md](qa.md): tester chức năng (lỗi, trường hợp biên, lỗ hổng xu).
- [ux.md](ux.md): tester giao diện (88 ảnh sáng/tối/chữ lớn, tương phản, câu chữ).
- [player.md](player.md): người chơi thử + thiết kế game (giữ chân, thiếu gì, top 10 đề xuất).
- [economy.md](economy.md): kinh tế xu, mô phỏng 10 người chơi, thời gian phá đảo. Script ở `economy-tools/`
  (`python3 -I sim.py economy-tools` để chạy lại; `catalog.json` xuất từ code Core lúc đánh giá).

## Đã sửa ngay sau khi có báo cáo

| Vấn đề | Cách sửa |
|---|---|
| Viết nhật ký lùi ngày cũ để lấy xu không giới hạn | Chỉ thưởng nhật ký của hôm nay hoặc hôm qua |
| Tập trung không có trần ngày (treo máy ~530 xu/ngày) | Tối đa 240 phút có thưởng mỗi ngày; vượt thì báo rõ |
| Sửa tay file sao lưu để thêm xu | Mỗi loại thưởng bị kiểm tra theo mức tối đa của luật |
| Khóa máy bị tính là rời app (iOS báo khóa máy ~10 giây sau) | Giữ app chạy nền ~13 giây để chờ tín hiệu; chỉ nhắc khi chắc là sang app khác |
| Chế độ nghiêm bị lách bằng âm nền / tắt hẳn app | Không chốt phiên khi đang ở app khác; lưu lúc rời app xuống máy |
| Đang tạm dừng mà bật chế độ nghiêm thì mất nút Tiếp tục | Phiên đang tạm dừng vẫn có nút Tiếp tục |
| Tổng kết phiên gần như không hiện khi tự bắt đầu giờ nghỉ | Hiện thẻ tổng kết gọn trong lúc nghỉ (rời app, đánh dấu việc xong) |
| Bộ sưu tập lộ Kỳ lân/Rồng con (món Bí mật) kèm nút Mua lỗi | Hiện bóng + "???", báo "chỉ ra từ máy gacha" thay cho nút Mua |
| Đóng máy gacha lúc đang quay thì mất màn kết quả | Không cho đóng trong 1,3 giây quay |
| Âm thanh game tắt âm nền của hẹn giờ; chuông kêu cả khi gạt im lặng | Game không đổi/tắt phiên âm thanh khi âm nền đang chạy; chuông (không có âm nền) theo công tắc im lặng |
| Chữ nút mềm và giá xu tương phản ~2:1 | Chữ đậm hơn ở chế độ sáng; màu chữ giá xu riêng (~4.6:1) |
| Lịch tâm trạng ở chế độ tối gần như không đọc được | Số ngày màu tối cố định trên ô màu |
| Tài liệu ghi sai số xu một ngày | Sửa theo số mô phỏng |

## Cần bạn quyết (chưa làm)

1. Mã `t3ster` (+1000 xu) đang có trong bản cài và nhập lại được nhiều lần: giữ nguyên, chỉ cho nhập 1 lần, hay chỉ có trong bản Debug.
2. Cân lại kinh tế (economy.md mục đề xuất): nhiệm vụ ngày, giá biến thể màu, tỉ lệ gacha / bỏ đồ cửa hàng khỏi máy, mở rộng cấp tới 25–30.
3. Tính năng giữ chân (player.md): nhiệm vụ ngày + rương tuần, sự kiện lễ Việt, kỷ vật chuyến đi thành đồ trưng bày, chuỗi ngày mềm, huy hiệu, chọn loài khởi đầu…
4. Giao diện (ux.md): Góc nhỏ gọn hơn, màn đầu Hôm nay bớt header, gacha "đã mắt" hơn, thống nhất sheet/nút đóng.
