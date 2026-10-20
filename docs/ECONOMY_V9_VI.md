# Kinh tế CozyDay sau phiên 9 (bảng trước/sau)

Số liệu do `docs/review/economy-tools/sim_v9.py` tạo ra. Danh mục được xuất thẳng từ code Swift bằng `dump_catalog.sh`. Mỗi người chơi có 300 quỹ đạo 10 năm, gacha chạy 2000 lần thử. Mã t3ster và chế độ Dữ liệu thử nghiệm không được tính vào thu nhập.

Lưu ý: máy gacha ở bảng này mới có 14 món riêng (Quý/Bí mật). Phần nội dung gacha (mốc 2) sẽ thêm món Thường/Hiếm, nên cột "Sau" của gacha và phá đảo cần chạy lại sau khi gộp mốc 2: `./dump_catalog.sh && python3 sim_v9.py catalog.json catalog_v9.json`.

Những thay đổi được tính trong cột "Sau": nhiệm vụ ngày 15 xu cho cả bộ ba mục tiêu, rương tuần 40 xu + 1 vé (4 ngày trong tuần), quà mốc cấp 12–30, đường cấp tới 30 (5.400 XP), đồ đổi màu giảm 30%, gacha chỉ có đồ riêng, tỉ lệ 57/30/10/3, bảo đảm Bí mật ở lượt 40.

## Danh mục và gacha

| | Trước phiên 9 | Sau phiên 9 |
|---|---:|---:|
| Món bán trong cửa hàng | 483 | 483 |
| Tổng giá cửa hàng (xu) | 29,245 | 27,225 |
| Cấp cao nhất cần để mua | 8 | 8 |
| Món trong máy gacha | 124 | 14 |
| Món trong máy theo nhóm (Thường/Hiếm/Quý/Bí mật) | 45 / 48 / 24 / 7 | 0 / 0 / 7 / 7 |
| Tỉ lệ (Thường/Hiếm/Quý/Bí mật) | 60/28/10/2 | 57/30/10/3 |
| Bảo đảm Quý / Bí mật | lượt 10 / 60 | lượt 10 / 40 |

### Gom đủ máy gacha (tài khoản trắng, chỉ dùng xu, 2000 lần thử)

| Cách quay | Trước: lượt (trung vị / P90) | Trước: xu cần | Sau: lượt | Sau: xu cần |
|---|---:|---:|---:|---:|
| Quay lẻ (60 xu) | 248 / 323 | 12,435 / 15,220 | 165 / 214 | 840 / 840 |
| Gói 10 (540 xu) | 250 / 320 | 11,195 / 13,515 | 170 / 220 | 900 / 960 |

Ghi chú: trước phiên 9 máy gacha còn chứa đồ bán trong cửa hàng, nên "gom đủ máy" gồm cả những món mua được bằng xu.

## Ba kiểu người chơi

### Nhẹ nhàng (~10 phút/ngày)

| Chỉ số | Trước phiên 9 | Sau phiên 9 |
|---|---:|---:|
| Xu trung bình/ngày, 30 ngày đầu | 22.2 | 23.8 |
| Xu trung bình/ngày, 90 ngày đầu | 22.4 | 25.2 |
| Vé quay nhận được trong 90 ngày | 0 | 2.3 |
| Ngày đạt cấp 10 (trung vị) | 38 | 38 |
| Ngày đạt cấp 20 | 80 | 111 |
| Ngày đạt cấp 30 | 122 | 226 |
| Ngày mua hết cửa hàng | 1,306 | 1,108 |
| Ngày phá đảo (cửa hàng + đủ máy gacha), trung vị / P90 | 1,873 / 1,987 | 1,112 / 1,139 |

### Đều đặn (~30 phút/ngày)

| Chỉ số | Trước phiên 9 | Sau phiên 9 |
|---|---:|---:|
| Xu trung bình/ngày, 30 ngày đầu | 66.8 | 84.8 |
| Xu trung bình/ngày, 90 ngày đầu | 66.6 | 87.6 |
| Vé quay nhận được trong 90 ngày | 0 | 22.9 |
| Ngày đạt cấp 10 (trung vị) | 14 | 14 |
| Ngày đạt cấp 20 | 29 | 40 |
| Ngày đạt cấp 30 | 44 | 82 |
| Ngày mua hết cửa hàng | 439 | 327 |
| Ngày phá đảo (cửa hàng + đủ máy gacha), trung vị / P90 | 627 / 673 | 302 / 311 |

### Mê Sân chơi (~40 phút/ngày, ít việc)

| Chỉ số | Trước phiên 9 | Sau phiên 9 |
|---|---:|---:|
| Xu trung bình/ngày, 30 ngày đầu | 49.2 | 51.1 |
| Xu trung bình/ngày, 90 ngày đầu | 49.4 | 51.9 |
| Vé quay nhận được trong 90 ngày | 0 | 2.0 |
| Ngày đạt cấp 10 (trung vị) | 45 | 45 |
| Ngày đạt cấp 20 | 94 | 130 |
| Ngày đạt cấp 30 | 143 | 265 |
| Ngày mua hết cửa hàng | 591 | 523 |
| Ngày phá đảo (cửa hàng + đủ máy gacha), trung vị / P90 | 845 / 902 | 525 / 535 |

