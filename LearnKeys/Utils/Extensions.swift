import SwiftUI
import Foundation
import CoreGraphics

// MARK: - Color Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let alphaValue, redValue, greenValue, blueValue: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (alphaValue, redValue, greenValue, blueValue) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (alphaValue, redValue, greenValue, blueValue) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (alphaValue, redValue, greenValue, blueValue) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (alphaValue, redValue, greenValue, blueValue) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(redValue) / 255,
            green: Double(greenValue) / 255,
            blue: Double(blueValue) / 255,
            opacity: Double(alphaValue) / 255
        )
    }
}

// MARK: - String Extensions

extension String {
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        } else {
            return self
        }
    }
} 