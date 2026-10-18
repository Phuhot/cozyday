# Xem giao diện trước khi cài

App SwiftUI chỉ chạy trên iOS, nên **không mở được bằng trình duyệt hay "localhost" trên Windows**. Cách thay thế:
GitHub Actions mở app trên **iPhone ảo (iOS Simulator)** của máy macOS, chụp từng màn hình với **dữ liệu mẫu** rồi lưu
ảnh vào thư mục [`docs/screenshots/`](screenshots/). Bạn xem các ảnh này ngay trên trang GitHub, kể cả bằng iPhone.

- Dữ liệu mẫu (tên giả "An", 2 tuần việc/nhật ký/tập trung/chuyến đi) chỉ nằm trong bộ nhớ của bản **Debug** cho simulator
  (`Cozyday/App/PreviewMode.swift`). Bản IPA **Release** cài lên iPhone không có chế độ này; bước kiểm tra IPA
  trong CI sẽ báo lỗi nếu nó lọt vào.
- Ảnh là ảnh tĩnh của app thật, chạy trên simulator. Ảnh **không** chứng minh app cài được hay chạy đúng trên iPhone của bạn.
- Giờ trong ảnh là giờ Việt Nam lúc CI chạy, nên vị trí các việc trên timeline đổi theo từng lần chụp.
  Xem `screenshots/info.txt` để biết thiết bị, giờ chụp và commit.

## Ảnh giao diện sáng

| | | |
|---|---|---|
| ![Onboarding](screenshots/01-onboarding.jpg) Onboarding | ![Hôm nay](screenshots/02-today.jpg) Hôm nay (timeline) | ![Thêm việc](screenshots/03-task-editor.jpg) Thêm việc |
| ![Sắp xếp lại](screenshots/04-replan.jpg) Sắp xếp lại việc trễ | ![Hộp chờ](screenshots/05-inbox.jpg) Hộp chờ | ![Tập trung](screenshots/06-focus.jpg) Tập trung |
| ![Góc nhỏ](screenshots/07-corner.jpg) Góc nhỏ | ![Cửa hàng](screenshots/08-shop.jpg) Cửa hàng | ![Nhật ký](screenshots/09-journal.jpg) Nhật ký |
| ![Tiến bộ](screenshots/10-progress.jpg) Tiến bộ | ![Cài đặt](screenshots/11-settings.jpg) Cài đặt | |

## Thú cưng, tủ đồ, chuyến đi

| | | |
|---|---|---|
| ![Các kiểu thú cưng](screenshots/15-pet-gallery.jpg) Các bộ phối: 11 loài × màu lông × trang phục × giai đoạn lớn | ![Tủ đồ](screenshots/12-wardrobe.jpg) Tủ đồ — mặc thử trước khi mua | ![Chuyến đi](screenshots/13-adventure.jpg) Nghe kể chuyến đi |
| ![Sổ ký ức](screenshots/14-memories.jpg) Sổ ký ức | ![Bài thở](screenshots/16-breathing.jpg) Bài thở | ![Chi tiết việc](screenshots/17-task-detail.jpg) Việc con trong chi tiết việc |
| ![Viết nhật ký](screenshots/18-journal-editor.jpg) Gợi ý viết nhật ký | ![Bộ sưu tập](screenshots/23-collection.jpg) Bộ sưu tập: các loài & bộ phối sẵn | ![Xem thử một bộ](screenshots/24-look.jpg) Xem thử & mua cả bộ |

## Các không gian

| | | |
|---|---|---|
| ![Phòng ngủ](screenshots/19-bedroom.jpg) Phòng ngủ | ![Bếp](screenshots/20-kitchen.jpg) Bếp & bàn ăn | ![Phòng tắm](screenshots/21-bath.jpg) Phòng tắm |
| ![Khu vườn](screenshots/22-garden.jpg) Khu vườn | | |

Ảnh tĩnh không thể hiện animation (thở, chớp mắt, vẫy đuôi, đi lại, tim bay khi chạm, nựng, nhấc lên và thả). Phần đó chỉ thấy khi chạy trên máy.

## Giao diện tối

| | | |
|---|---|---|
| ![Hôm nay — tối](screenshots/dark-02-today.jpg) | ![Tập trung — tối](screenshots/dark-06-focus.jpg) | ![Góc nhỏ — tối](screenshots/dark-07-corner.jpg) |
| ![Nhật ký — tối](screenshots/dark-09-journal.jpg) | ![Tiến bộ — tối](screenshots/dark-10-progress.jpg) | ![Tủ đồ — tối](screenshots/dark-12-wardrobe.jpg) |
| ![Thú cưng — tối](screenshots/dark-15-pet-gallery.jpg) | ![Phòng ngủ — tối](screenshots/dark-19-bedroom.jpg) | |

## Cỡ chữ rất lớn (Trợ năng)

| | |
|---|---|
| ![Hôm nay — chữ lớn](screenshots/large-02-today.jpg) Ở cỡ chữ này, Hôm nay tự chuyển sang dạng Danh sách | ![Thêm việc — chữ lớn](screenshots/large-03-task-editor.jpg) |

## Chụp lại ảnh mới

- Mỗi lần CI chạy job *Unit test + ảnh giao diện*, ảnh được upload thành artifact `Cozyday-ui-screenshots-run<số>`
  (giữ 14 ngày; tải ở cuối trang của lần chạy).
- Ảnh trong `docs/screenshots/` chỉ được cập nhật khi commit message có `[ui-preview]`, hoặc khi bấm **Run workflow**
  và tick **Chụp ảnh giao diện…** (nút này chỉ có sau khi workflow đã ở nhánh `main`). Khi đó job
  *Lưu ảnh giao diện vào docs/screenshots* commit ảnh lên đúng nhánh vừa build. Đây là job duy nhất được quyền ghi
  vào repo; job này chạy trên Ubuntu nên rẻ hơn job macOS.
- Mỗi lần chụp tốn thêm khoảng 2 phút macOS, cộng vào job test.

## Muốn bấm thử trên trình duyệt?

Mỗi lần chạy cũng upload artifact `Cozyday-simulator-app-run<số>`: bản `.app` cho simulator, đã nén zip. Một số dịch vụ
bên thứ ba (ví dụ Appetize.io) cho phép tải bản simulator lên và bấm thử app trong trình duyệt. Thường có gói miễn phí,
nhưng giới hạn số phút mỗi tháng. Lưu ý:

- Claude **chưa kiểm chứng** dịch vụ đó nhận file này. Định dạng, giới hạn miễn phí và điều khoản cần bạn xem trên
  trang chính thức của dịch vụ.
- Làm vậy là tải bản build của bạn lên máy chủ của bên thứ ba. App không chứa dữ liệu cá nhân, nhưng chỉ nên làm
  nếu bạn chấp nhận điều đó.
- Mở theo cách này, app hiện **dữ liệu trống** (bắt đầu từ onboarding). Dữ liệu mẫu chỉ bật khi CI mở app kèm tham số
  `-CozyPreview`.
