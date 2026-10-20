import SwiftUI

/// Bảng công cụ của chế độ "Dữ liệu thử nghiệm" (mã phuhotdz). Chỉ hiện khi chế độ đang bật.
/// Không ghi gì vào việc, nhật ký, huy hiệu, chuỗi ngày hay kết quả chơi.
struct TesterToolsView: View {
    @Environment(AppStore.self) private var store
    @Environment(UIState.self) private var ui

    var body: some View {
        Form {
            Section {
                Label("Dữ liệu thử nghiệm", systemImage: "flask.fill")
                    .font(Typography.headline)
                    .foregroundStyle(Palette.peach)
                Text("Đang có \(store.wallet.coins) xu, \(store.wallet.tickets) vé. Cấp hiển thị \(store.wallet.level) (cấp thật \(store.wallet.realLevel)).")
                    .font(Typography.callout)
                    .foregroundStyle(Palette.inkMuted)
            }

            Section {
                Button("Thêm 1.000 xu thử nghiệm") { grant(coins: 1000, tickets: 0) }
                Button("Thêm 10 vé thử nghiệm") { grant(coins: 0, tickets: 10) }
            } header: {
                Text("Xu và vé")
            } footer: {
                Text("Dùng để thử mua, quay máy gacha nhiều lần. Các dòng này được ghi là “Dữ liệu thử nghiệm” trong sổ cái, không phải phần thưởng thật.")
            }

            TesterPreviewSections()
        }
        .scrollContentBackground(.hidden)
        .cozyBackground()
        .navigationTitle("Công cụ thử nghiệm")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) { ErrorOverlay() }
    }

    private func grant(coins: Int, tickets: Int) {
        if ui.run({ try store.grantTesterCurrency(coins: coins, tickets: tickets) }) {
            ui.showReward(coins > 0 ? "+\(coins) xu thử nghiệm" : "+\(tickets) vé thử nghiệm")
        }
    }
}

/// Các mục xem trước (hoạt ảnh từng bậc gacha, sự kiện…). Nối thêm khi các tính năng đó có màn xem trước.
struct TesterPreviewSections: View {
    var body: some View {
        EmptyView()
    }
}
