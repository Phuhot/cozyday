# Kinh tế CozyDay V9

Danh mục xuất từ Swift Core hiện tại bằng `docs/review/economy-tools/dump_catalog.sh`; bảng bên dưới chạy lại ngày 21/10/2026 bằng `sim_v9.py`. Mốc so sánh trước V9 là bản danh mục tại commit `87371c9`. Không tính `t3ster`, `phuhotdz` hoặc tiền thử nghiệm vào thu nhập thông thường.

## Nguồn thưởng và giới hạn

| Nguồn | Trước V9 | V9 | Giới hạn |
|---|---|---|---|
| Hoàn thành việc | 8 xu + 10 XP | Giữ nguyên | 10 việc có thưởng/ngày; cùng lần việc chỉ thưởng một lần |
| Tập trung | 2 xu + 2 XP/5 phút | Giữ nguyên | Phiên hoàn thành từ 10 phút; tối đa 120 phút/phiên, 240 phút có thưởng/ngày; nghỉ không thưởng |
| Nhật ký | 5 xu + 5 XP | Giữ nguyên | Một lần/ngày, cho hôm nay hoặc hôm qua |
| Thở | 3 xu + 3 XP | Giữ nguyên | Một lần/ngày |
| Chuyến đi | 10 xu + 5 XP | Giữ nguyên, thêm kỷ vật | Một lần/ngày, đủ bốn hoạt động nạp năng lượng |
| Chăm sóc | Tối đa 6 xu + 12 XP/ngày | Giữ nguyên | Áp dụng điều kiện/cooldown từng hành động; không thưởng vô hạn |
| Minigame | Tối đa 8 xu/lượt, 40 xu/ngày | Giữ nguyên | Lượt hợp lệ; không có XP |
| Bộ ba nhiệm vụ ngày | Chưa có | **Tổng 15 xu** | Nhận khi đủ cả ba, một lần/ngày; thưởng hoạt động ở trên tính riêng |
| Rương tuần | Chưa có | 40 xu + 1 vé | Nhận bộ nhiệm vụ ở bốn ngày khác nhau; một rương/tuần |
| Quà cấp 12/15/18/21/24/27/30 | Chưa có | Tổng 540 xu + 12 vé | Nhận bằng tay, mỗi mốc một lần dựa trên cấp thật |
| Bảy huy hiệu | Chưa có | Tổng 100 xu | Mỗi huy hiệu một lần; bộ dữ liệu thử nghiệm không nhận thưởng thật |
| Tết/Trung thu/20-10 | Chưa có | 15 xu + kỷ vật/lễ | Đủ nhiệm vụ trong cửa sổ ±3 ngày; một lần/ID sự kiện/năm |
| Đồ gacha trùng | Hoàn xu theo tier | 20/30/60/150 xu | Thường/Hiếm/Quý/Bí mật; đã tính trong mô phỏng chi phí gacha |

Tuần tính từ thứ Hai đến Chủ nhật theo lịch Gregorian của app. Khóa nhận nhiệm vụ là ngày địa phương `quest:YYYY-MM-DD`, khóa rương là ngày thứ Hai `chest:YYYY-MM-DD`. Có thể nhận nhiệm vụ hôm qua, và rương tuần trước trong tuần kế tiếp. Đổi múi giờ không sửa các khóa đã nhận; các hoạt động có timestamp được quy về lịch hiện tại, nên đi qua múi giờ có thể đổi tiến độ chưa nhận ở ranh giới ngày. Sự kiện lễ luôn dùng **Asia/Ho_Chi_Minh**. Đây là app offline: không hứa chống tuyệt đối sửa đồng hồ hay chỉnh file save.

## Giá và đường cấp

`CatalogItem.variant` xác định đồ đổi màu bằng `variantOf` và ID `base~tag`. Đồ đổi màu bán trực tiếp lấy 70% giá niêm yết cũ, làm tròn về bội số 5 gần nhất (nửa lên), tối thiểu 5 xu khi giá cũ dương. Ví dụ 50→35, 75→55, 100→70. Không giảm đồ gốc, đồ riêng của gacha hoặc tự hoàn tiền giao dịch cũ.

| Nhóm cửa hàng | Trước: số món / tổng xu / khoảng giá | Sau: số món / tổng xu / khoảng giá |
|---|---|---|
| Đồ gốc ngoài đồ mặc định | 378 / 22.405 / 0–160 | Giữ nguyên |
| Đồ đổi màu | 105 / 6.840 / 15–150 | 108 / 5.240 / 10–175 |

Ba món đổi màu mới mở theo tiến trình: Tranh bình minh cấp 15 (105 xu), Đèn giấy ánh trăng cấp 21 (140 xu), Kệ sách mừng trưởng thành cấp 30 (175 xu). Chúng dùng hình vẽ có sẵn, phối màu riêng; mở quyền mua, không tự trao đồ.

Đường XP mới: 100 XP/cấp tới cấp 10, sau đó 150 tới 15, 200 tới 20, 250 tới 25, 300 tới 30. Cấp 30 cần tổng 5.400 XP. Công thức cũ thực tế không có trần: migration giữ nguyên XP và ghi cấp sàn theo công thức cũ. Người cũ từng vượt 30 vẫn giữ cấp đó; tiến trình mới dừng ở 30. Khi cấp sàn cao hơn cấp tính từ XP mới, cần tích đủ XP của đường mới để tiếp tục lên. Quà mốc chỉ phát khi bấm nhận, không phát khi mở app.

## Giả định mô phỏng

300 quỹ đạo/người chơi, tối đa 3.650 ngày; gacha 2.000 lần thử, seed cố định. Ba kiểu chơi có xác suất mở app 85%/92%/92%, làm 1–3/3–6/0–2 việc; người đều đặn có một phiên tập trung 25 phút, người mê sân chơi có 6–9 lượt game. Các khoảng phút là mô tả hành vi, không đo thời gian hoàn thành việc ngoài app.

Thu nhập là **xu gộp trước chi phí đồ ăn/tiêu dùng**, tự nhận mọi thưởng đủ điều kiện. Có tính sáu huy hiệu không phụ thuộc mua đồ (90 xu) và sự kiện trong lịch đã hỗ trợ; huy hiệu sưu tập 10 xu không tính vì mô hình không đặt lịch mua từng món. Mô phỏng bắt đầu 2/11/2026, chỉ có lễ năm 2027 trong các ngày sau đó; không tự lặp lịch âm sang năm chưa hỗ trợ.

Ngày mua hết cửa hàng dùng toàn bộ ngân sách cho cửa hàng và chờ đủ cấp. Dòng cửa hàng + gacha là **ước tính ngân sách**, mua cửa hàng trước, loại các món gacha cũ đã mua khỏi phần còn thiếu, rồi dùng giá trị 60 xu/vé để giảm riêng ngân sách gacha; vé không trả được giá cửa hàng. Số ngày thực tế còn phụ thuộc thời điểm mua/quay, quà đã nhận và tiêu dùng. P90 là mức 90% các lần mô phỏng không vượt quá, không phải bảo đảm thời gian gom đủ bộ.

Ví dụ theo thu nhập gộp trung bình 90 ngày sau V9: mũ len 30 xu cần khoảng 2/1/1 ngày; món 90 xu cần khoảng 4/2/2 ngày ở ba kiểu chơi (chưa tính khóa cấp). Một lượt 60 xu cần khoảng 3/1/2 ngày. Đây là mốc tiết kiệm khi không tiêu xu vào việc khác.

Chạy lại:

```sh
bash docs/review/economy-tools/dump_catalog.sh
python3 docs/review/economy-tools/sim_v9.py \
  docs/review/economy-tools/catalog.json \
  docs/review/economy-tools/catalog_v9.json
```

## Danh mục và gacha

| | Trước phiên 9 | Sau phiên 9 |
|---|---:|---:|
| Món bán trong cửa hàng | 483 | 486 |
| Tổng giá cửa hàng (xu) | 29,245 | 27,645 |
| Cấp cao nhất cần để mua | 8 | 30 |
| Món trong máy gacha | 124 | 48 |
| Món trong máy theo nhóm (Thường/Hiếm/Quý/Bí mật) | 45 / 48 / 24 / 7 | 18 / 13 / 9 / 8 |
| Tỉ lệ (Thường/Hiếm/Quý/Bí mật) | 60/28/10/2 | 57/30/10/3 |
| Bảo đảm Quý / Bí mật | lượt 10 / 60 | lượt 10 / 40 |

### Gom đủ máy gacha (tài khoản trắng, chỉ dùng xu, 2000 lần thử)

| Cách quay | Trước: lượt (trung vị / P90) | Trước: xu cần | Sau: lượt | Sau: xu cần |
|---|---:|---:|---:|---:|
| Quay lẻ (60 xu) | 248 / 323 | 12,435 / 15,220 | 189 / 240 | 7,420 / 8,980 |
| Gói 10 (540 xu) | 250 / 320 | 11,195 / 13,515 | 190 / 240 | 6,660 / 7,940 |

Ghi chú: trước phiên 9 máy gacha còn chứa đồ bán trong cửa hàng, nên "gom đủ máy" gồm cả những món mua được bằng xu.

## Ba kiểu người chơi

### Nhẹ nhàng (~10 phút/ngày)

| Chỉ số | Trước phiên 9 | Sau phiên 9 |
|---|---:|---:|
| Xu trung bình/ngày, 30 ngày đầu | 22.2 | 25.4 |
| Xu trung bình/ngày, 90 ngày đầu | 22.4 | 26.0 |
| Vé quay nhận được trong 90 ngày | 0 | 2.3 |
| Ngày đạt cấp 10 (trung vị) | 38 | 38 |
| Ngày đạt cấp 20 | 80 | 111 |
| Ngày đạt cấp 30 | 122 | 226 |
| Ngày mua hết cửa hàng | 1,306 | 1,123 |
| Ngày tích đủ ngân sách cửa hàng + gacha (ước tính), trung vị / P90 | 1,725 / 1,861 | 1,390 / 1,465 |

### Đều đặn (~30 phút/ngày)

| Chỉ số | Trước phiên 9 | Sau phiên 9 |
|---|---:|---:|
| Xu trung bình/ngày, 30 ngày đầu | 66.8 | 87.0 |
| Xu trung bình/ngày, 90 ngày đầu | 66.6 | 88.6 |
| Vé quay nhận được trong 90 ngày | 0 | 22.9 |
| Ngày đạt cấp 10 (trung vị) | 14 | 14 |
| Ngày đạt cấp 20 | 29 | 40 |
| Ngày đạt cấp 30 | 44 | 82 |
| Ngày mua hết cửa hàng | 439 | 331 |
| Ngày tích đủ ngân sách cửa hàng + gacha (ước tính), trung vị / P90 | 580 / 625 | 377 / 397 |

### Mê Sân chơi (~40 phút/ngày, ít việc)

| Chỉ số | Trước phiên 9 | Sau phiên 9 |
|---|---:|---:|
| Xu trung bình/ngày, 30 ngày đầu | 49.2 | 52.3 |
| Xu trung bình/ngày, 90 ngày đầu | 49.4 | 52.6 |
| Vé quay nhận được trong 90 ngày | 0 | 2.0 |
| Ngày đạt cấp 10 (trung vị) | 45 | 45 |
| Ngày đạt cấp 20 | 94 | 130 |
| Ngày đạt cấp 30 | 143 | 265 |
| Ngày mua hết cửa hàng | 591 | 530 |
| Ngày tích đủ ngân sách cửa hàng + gacha (ước tính), trung vị / P90 | 781 / 841 | 656 / 689 |

