import SwiftUI
import UIKit

// Design tokens của Cozyday — phong cách "cozy study": kem ấm, lavender chính, sage phụ.

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

extension Color {
    /// Màu tự đổi theo light/dark mode.
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

enum Palette {
    static let background = Color.dynamic(light: 0xFEF6EC, dark: 0x24222E)
    static let surface = Color.dynamic(light: 0xFFFDF8, dark: 0x2F2C3B)
    static let surfaceMuted = Color.dynamic(light: 0xF6EDE0, dark: 0x383447)
    static let line = Color.dynamic(light: 0xE8DCCB, dark: 0x4A4559)

    static let ink = Color.dynamic(light: 0x3E3550, dark: 0xF3EEF8)
    static let inkMuted = Color.dynamic(light: 0x786E87, dark: 0xB9B0C6)

    static let lavender = Color.dynamic(light: 0x8D78CF, dark: 0xB7A6F0)
    static let lavenderSoft = Color.dynamic(light: 0xECE6FA, dark: 0x403856)
    static let sage = Color.dynamic(light: 0x6F9A72, dark: 0x9CC39E)
    static let sageSoft = Color.dynamic(light: 0xE4EFE2, dark: 0x33443A)
    static let peach = Color.dynamic(light: 0xE59A7A, dark: 0xF0B49A)
    static let honey = Color.dynamic(light: 0xD9A441, dark: 0xF0C26A)
    static let danger = Color.dynamic(light: 0xC2565A, dark: 0xF08C8F)
    static let nowLine = Color.dynamic(light: 0xD9667A, dark: 0xF290A2)

    /// Màu chữ đặt trên nền lavender đậm.
    static let onAccent = Color.white

    // Màu dùng cho hình vẽ mèo/phòng (ít đổi theo dark mode để giữ nhận diện)
    static let catCream = Color.dynamic(light: 0xFCF1DE, dark: 0xF4E6CF)
    static let catShade = Color.dynamic(light: 0xEEDCC2, dark: 0xE2CDAE)
    static let catInk = Color(UIColor(hex: 0x4A3C5C))
    static let blush = Color(UIColor(hex: 0xF4B0B0))
    static let wood = Color.dynamic(light: 0xC89B6D, dark: 0xB88B5E)
    static let woodDark = Color.dynamic(light: 0xA07448, dark: 0x8E653E)
    static let roomWall = Color.dynamic(light: 0xF3E9F7, dark: 0x332E42)
    static let roomFloor = Color.dynamic(light: 0xEAD9C3, dark: 0x3C3546)
}

enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum Radius {
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 18
}

/// Vùng chạm tối thiểu theo Human Interface Guidelines.
enum HitTarget {
    static let min: CGFloat = 44
}

enum Typography {
    static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let title = Font.system(.title2, design: .rounded).weight(.semibold)
    static let headline = Font.system(.headline, design: .rounded)
    static let body = Font.system(.body)
    static let callout = Font.system(.callout)
    static let caption = Font.system(.caption)
    static let numeric = Font.system(.title, design: .rounded).weight(.bold).monospacedDigit()
}

enum Motion {
    static let gentle = Animation.spring(response: 0.35, dampingFraction: 0.85)
    static let quick = Animation.easeOut(duration: 0.2)

    /// Trả về nil khi người dùng bật Giảm chuyển động.
    static func gentle(_ reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : gentle
    }
}

extension TaskCategory {
    var color: Color {
        switch self {
        case .study: return Palette.lavender
        case .work: return Color.dynamic(light: 0x6E8FC8, dark: 0x9DB6E6)
        case .health: return Palette.sage
        case .personal: return Palette.peach
        case .home: return Palette.honey
        }
    }

    var softColor: Color {
        switch self {
        case .study: return Palette.lavenderSoft
        case .work: return Color.dynamic(light: 0xE3EAF7, dark: 0x2F3A52)
        case .health: return Palette.sageSoft
        case .personal: return Color.dynamic(light: 0xFBE7DE, dark: 0x4A3530)
        case .home: return Color.dynamic(light: 0xF8EDD3, dark: 0x463C28)
        }
    }

    var symbol: String {
        switch self {
        case .study: return "book.closed"
        case .work: return "briefcase"
        case .health: return "leaf"
        case .personal: return "heart"
        case .home: return "house"
        }
    }
}
