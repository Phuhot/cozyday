# Bàn giao CozyDay V9

Nhánh làm việc: `codex/cozyday-v9-completion`, tiếp nối iOS WIP `63c7345` trên `claude/ios-project-section-12-4bpxn7`. `main` có phần web riêng; không lấy đó làm nền iOS. Quy tắc và số liệu mô phỏng: [ECONOMY_V9_VI.md](ECONOMY_V9_VI.md).

## Thay đổi chính

- Mã `t3ster`: 10.000 xu một lần trên bộ dữ liệu. Nhận dạng dấu cũ bằng loại `gift`, khóa `gift:…`, ghi chú `Mã quà`, đúng 1.000 xu (bản cũ chỉ có mã này). Một lần cũ bù 9.000; nhiều lần cũ bù phần thiếu tới 10.000, không thu hồi tiền thừa. Không suy đoán từ số dư. Nếu dấu đã bị xóa/sửa thì không thể xác định lịch sử mã; không tự phát bù theo số dư.
- `phuhotdz`: xác nhận và khuyến khích sao lưu trước khi bật; cấp hiển thị 30, mọi món trong danh mục được thử, kể cả món thêm sau này. Kho thật, XP, việc, nhật ký và kết quả game không tự thay đổi. Công cụ riêng thêm xu/vé thử, xem bốn tier cutscene và ba lễ Việt. Đây là mã nằm trong app, không phải xác thực quản trị.
- Nhãn thử nghiệm vẫn còn sau khi tắt, vì tiền/đồ đã thử có thể còn trong bộ dữ liệu. Huy hiệu và thưởng lễ không nhận trên bộ dữ liệu này. Tắt chỉ tháo món chưa sở hữu thật; muốn trở lại nguyên trạng phải khôi phục bản sao lưu trước khi bật.
- Ba nhiệm vụ/ngày, tổng 15 xu; bốn ngày nhận trong tuần mở rương 40 xu + một vé; quà mốc cấp và đồ cấp 15/21/30. Tuần và ranh giới ngày được mô tả trong tài liệu kinh tế.
- Gacha chỉ có 48 món riêng, thứ tự **Thường < Hiếm < Quý < Bí mật**. Không trùng ID với đồ mua trực tiếp. Tỉ lệ cơ bản 57/30/10/3%; tối đa 40 lượt liên tiếp tới Bí mật, reset khi nhận, tính tuần tự trong gói mười. Tỉ lệ tổng có bảo đảm khác 3% cơ bản. Trong một tier ưu tiên món chưa có; khi đã đủ tier, đồ trùng hoàn 20/30/60/150 xu.
- Bổ sung hình vẽ còn thiếu của pool WIP: mũ tách trà/vịt, kính chanh/bong bóng, vòng vỏ sò/anh đào, váy trà/dâu, áo khoác thuyền trưởng, túi ốc/đèn sao, đèn sứa, hộp nhạc, giường trăng. So sánh đại diện Hiếm/Quý/Bí mật dùng cùng capybara và màu lông để thấy rõ khác biệt thiết kế.
- Thanh toán, kết quả, inventory và dấu kết quả chưa xem cùng một lần lưu SwiftData. Pity được suy từ lịch sử đã lưu. Bấm quay lại khi còn kết quả chưa xem bị chặn. Kết quả đã xem cũng có dấu trong sổ cái, đi theo sao lưu; thoát cảnh không quay lại hoặc cộng quà nữa.
- Màn khoe đồ tạo bản sao pet giữ loài/màu/giai đoạn, bỏ trang phục cũ và chỉ mặc món vừa nhận. Loài/màu/nội thất có kiểu xem tương ứng. Chỉ nút Mặc ngay mới đổi trang bị thật. Mua & mặc cũng cùng một transaction.
- Cảnh capsule dài 9 giây, dùng pet thật: máy → rơi/nảy/lăn → pet cúi/nghiêng/gẩy → mở viên → vui và kết quả. Dựng 2.5D bằng Canvas, phối cảnh, lớp xa/gần và bóng; không có model 3D. Một cảnh cho gói mười; Bỏ qua có ngay đầu. Hoạt ảnh ngắn/Reduce Motion 1,8 giây; vào background về kết quả đã lưu. Âm dùng bộ tổng hợp `GameSound`/`GameSynth` sẵn có, do dự án tạo, không tải âm bên ngoài; reveal đổi theo tier, dùng cài đặt âm thanh chung và audio session ambient/mix. Khi âm tập trung đang phát, cảnh không đổi session và không phát cue riêng.
- Hôm nay có header gọn, lối vào Tập trung/Ba điều nhỏ; Focus đưa bộ đếm lên trước phần thống kê; vẫn dùng FocusCoordinator và timer timestamp cũ. Góc nhỏ đưa chăm sóc chi tiết vào sheet, giữ phòng/pet và các thao tác thường dùng gần đầu, gộp phần chuyến đi/tuần.
- Kỷ vật chuyến đi lưu tên/loài/ngày/câu chuyện lúc nhận, đặt một món mỗi phòng, đổi vật trưng bày không xóa món trước. Dữ liệu chuyến đi cũ chỉ lưu tiêu đề nên hiển thị giới hạn đó; không dựng lại truyện cũ theo pet hiện tại.
- Bảy huy hiệu, số ngày gắn bó cộng dồn và các mốc 7/30 ngày, không phạt khi nghỉ. Dấu ngày có ý nghĩa và số lượt chăm/game lưu trong sổ cái, không mất khi dọn lịch sử chi tiết. Ngày cũ được chốt một lần khi nâng cấp từ lịch sử và sổ thưởng còn lưu; đổi múi giờ không tính lại chúng thành ngày mới. Hoạt động cũ không thưởng mà lịch sử chi tiết đã bị dọn từ trước thì không thể phục dựng. Bật chế độ thử không tự tạo thành tích.
- Lễ Việt theo dữ liệu **2025–2027**: Tết/Trung thu có ngày dương lịch riêng từng năm, 20/10; cửa sổ ±3 ngày theo giờ Việt Nam. Mỗi lễ cần chăm hai lần, tập trung mười phút và viết nhật ký trong cửa sổ, thưởng 15 xu + đồ trưng bày (bao lì xì/đèn lồng/lọ hoa). Ngoài lịch không giả sự kiện, chủ đề có thể quay lại năm sau. Cần bổ sung dữ liệu lịch trước năm 2028.
- Onboarding chọn mèo, thỏ, hamster hoặc cún: bốn dáng cơ bản dễ nhận biết, không có loài gacha hiếm. Chỉ loài chọn được cấp, có xem trước và đặt tên. Gọi onboarding lần nữa trên hồ sơ đã xong không đổi pet hoặc cấp thêm loài.

## Dữ liệu

Giữ bundle ID `com.phuhot.cozyday`, đường kho `Cozyday.store`. Lược đồ SwiftData V4 nối V3, thêm tickets/kỷ vật; backup JSON bản 3 đọc được bản 1/2. Cờ mã, cấp sàn, thưởng nhiệm vụ/rương/mốc/huy hiệu/lễ, pity, kỷ vật và kết quả chưa xem đều theo backup. Khôi phục kiểm tra tham chiếu trang bị và kỷ vật. Test mode có thể lưu trang bị ảo mà không đưa chúng vào kho thật.

## Kiểm tra và bằng chứng

Bản code cuối `60f6091` được xác minh ở [run #39](https://github.com/Phuhot/cozyday/actions/runs/39639161111): **toàn run thành công**, gồm **220 test iOS Simulator, 0 lỗi**, build Release arm64, kiểm tra/đóng gói IPA, quay video, chụp và lưu ảnh lên nhánh. **168 test Core** cũng đã qua trên Linux; đây là phần lõi của bộ test, không cộng thành 388 test riêng biệt. Các commit sau lượt này chỉ cập nhật tài liệu và bằng chứng hình ảnh.

- [Tải IPA #39, checksum và build-info](https://github.com/Phuhot/cozyday/actions/runs/39639161111/artifacts/12363747910). Artifact giữ 14 ngày theo workflow.
- [Bộ ảnh V9](screenshots-v9/) · [Hôm nay trên 12 Pro Max](screenshots-v9/v9-iPhone-12-Pro-Max-today.jpg) · [Góc nhỏ tối](screenshots-v9/dark-07-corner.jpg) · [Tập trung](screenshots-v9/06-focus.jpg) · [So sánh ba tier](screenshots-v9/v9-tiers.jpg).
- [Video capsule và màn nhận món](media/v9-gacha-cutscene-run39.mp4), bản nén 720 px từ video thật. [Artifact video gốc](https://github.com/Phuhot/cozyday/actions/runs/39639161111/artifacts/12364448539).
- [Log test #39](https://github.com/Phuhot/cozyday/actions/runs/39639161111/artifacts/12364869365), giữ 7 ngày.
- [Pull request #2](https://github.com/Phuhot/cozyday/pull/2), base là nhánh iOS Claude, chưa merge.

Đã tải IPA #39 về cloud và đối chiếu SHA-256 khớp: `5860a4dfeadb54350df8544027771bb1d37972919ccb951c43f559aee74a7cc9`. Bundle ID `com.phuhot.cozyday`, phiên bản `0.1.0 (39)`, tối thiểu iOS 17.0; chưa ký. Lần tải đầu bị chặn mạng, lần tải sau khi run hoàn tất đã thành công.

Lượt trước, [run #38](https://github.com/Phuhot/cozyday/actions/runs/39595150344) trên `27e719b` có **218 test iOS Simulator, 0 lỗi**, cùng ảnh/video thật đã tải và xem. Toàn run bị đánh dấu cancelled ở mốc 45 phút; không coi đây là lượt CI xanh. Checksum IPA #38 đã đối chiếu trùng build-info.

Đã xem ảnh thật của Today trên iPhone 12 Pro Max/SE (cỡ mặc định và lớn), Corner sáng/tối, Focus và so sánh ba tier. 12 Pro Max mặc định thấy việc chưa xếp giờ và các hàng timeline ngay màn đầu; SE thấy việc chưa xếp giờ. Cỡ chữ trợ năng phải cuộn thêm, chữ xuống dòng; tiêu đề thanh điều hướng Hôm nay trên SE có dấu ba chấm, bảng nhiệm vụ ở mức chữ lớn nhất có hàng rất cao. Góc nhỏ mặc định thấy các nút chăm sóc và gacha gần phòng; Focus thấy timer/nút điều khiển trước thống kê. Đây là kiểm tra ảnh tĩnh, chưa thay cho thử cuộn/VoiceOver bằng tay trên máy thật.

Đã trích và xem các mốc thời gian từ video capsule #39: máy, viên nang bên chân pet, mở viên và chuyển sang màn nhận **Mũ tách trà (Hiếm)**. Cảnh dùng pet đang mặc nhiều phụ kiện; màn nhận món vẫn đúng loài/màu nhưng chỉ còn chiếc mũ mới, có Mặc ngay/Để sau. Preview gọi giao dịch thật trong kho mẫu trước khi chạy cảnh. File gốc dài 12,7 giây, gồm khởi động và hoạt ảnh; bản nén giữ toàn bộ nội dung, chỉ đổi độ phân giải/bitrate/fps. File do `simctl recordVideo` tạo **chỉ có video, không có audio track**; âm thanh mới kiểm tra bằng code, còn cần nghe trên iPhone. Video #38 trước đó kết thúc ở bảng so sánh tier, đã được thay bằng bằng chứng giao dịch này.

Lượt cuối dùng `visual_suite=focused` để chụp lại các màn V9/sáng/tối/chữ lớn/hai kích thước iPhone, vẫn chạy toàn bộ test. Bộ ảnh đầy đủ run #38 đã lưu trong artifact; lần chụp tập trung được xuất riêng ở `docs/screenshots-v9`. Các minigame không đổi không quay lại năm video lớn trong lượt này.

Các test trọng yếu bao gồm: migration kho V3 có dữ liệu thật sang V4, bù mã một lần, cấp cũ không tụt, claim nhiệm vụ/rương/mốc không lặp, pity 39→40/reset/gói mười, pool không trùng shop, rollback giao dịch gacha và mua/mặc, khôi phục kết quả với UserDefaults mới và qua backup, onboarding gọi lại, kỷ vật giữ nguyên sau đổi tên, ngày gắn bó giữ nguyên khi đổi múi giờ và qua backup, nhận lễ/huy hiệu lặp, save lỗi và bộ dữ liệu thử nghiệm.

Đường chụp CI dùng dữ liệu mẫu trong bộ nhớ, không mở save cá nhân. Chụp sáng/tối/chữ lớn, iPhone 12 Pro Max và SE (nếu runtime có hỗ trợ), Today có việc/không việc, nhiệm vụ, hub kỷ vật và so sánh tier. Video `v9-gacha-cutscene.mp4` quay màn Canvas đang chạy trên simulator.

## Thử trên iPhone trước khi dùng hằng ngày

1. Xuất backup trước, cài đè với cùng bundle ID/chữ ký phù hợp. Kiểm lại số dư, pet, phòng, đồ và lịch sử; không gỡ app để né migration.
2. Nhập `t3ster` nhiều lần; nếu có save cũ từng nhận 1.000 thì kiểm chỉ bù 9.000. Khôi phục lại backup có cờ không phát thêm.
3. Bật thử nghiệm trên bộ dữ liệu đã sao lưu. Mặc món chưa sở hữu, xuất/khôi phục; tắt và kiểm món ảo được tháo, tiền/đồ đã mua còn và nhãn thử vẫn hiện.
4. Quay một/gói mười/vé; skip ở từng đoạn, đưa app ra nền hoặc buộc đóng giữa cảnh rồi mở gacha. Kết quả phải giữ nguyên, không trừ thêm; preview không tháo outfit thật. Dùng tùy chọn ngắn và Reduce Motion.
5. Thử âm khi bật/tắt âm trong app, bật im lặng, đang nghe nhạc ngoài và đang phát âm tập trung. Simulator không chứng minh công tắc im lặng/loa/hiệu năng máy thật.
6. Today trên 12 Pro Max: việc đầu nhìn thấy sớm; thử việc trùng giờ, không việc, chữ trợ năng. Focus bắt đầu/tạm dừng/ra nền/mở lại; kết thúc không thưởng hai lần. Kiểm VoiceOver và vùng chạm bằng thao tác thật.
7. Nhận nhiệm vụ sát đổi ngày/tuần, thử lịch/múi giờ khác. Mỗi khóa ngày/tuần chỉ nhận một lần; nhận bù hôm qua không tính hai ngày cho cùng khóa.
8. Nhận kỷ vật, đổi tên/loài, đặt/chuyển/cất rồi backup/khôi phục. Ký ức cũ giữ nguyên. Preview lễ không nhận quà; muốn thử claim phải dùng đồng hồ kiểm thử của test, không sửa dữ liệu thật để tạo kết quả giả.

IPA từ workflow là **chưa ký**, cần ký/cài bằng công cụ của bạn. Build simulator không thay việc cài và dùng bản Release trên iPhone thật.
