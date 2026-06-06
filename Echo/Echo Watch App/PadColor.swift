import SwiftUI
import WatchKit

enum PadColor: Int, CaseIterable, Identifiable {
    case red, blue, yellow, green, orange, purple, white

    var id: Int { rawValue }

    var color: Color {
        switch self {
        case .red:    return Color(red: 0.85, green: 0.2, blue: 0.2).opacity(0.3)
        case .blue:   return Color(red: 0.2, green: 0.4, blue: 0.9).opacity(0.3)
        case .yellow: return Color(red: 0.9, green: 0.8, blue: 0.2).opacity(0.3)
        case .green:  return Color(red: 0.2, green: 0.75, blue: 0.3).opacity(0.3)
        case .orange: return Color(red: 0.95, green: 0.5, blue: 0.15).opacity(0.3)
        case .purple: return Color(red: 0.6, green: 0.25, blue: 0.85).opacity(0.3)
        case .white:  return Color.white.opacity(0.2)
        }
    }

    var litColor: Color {
        switch self {
        case .red:    return Color(red: 1.0, green: 0.25, blue: 0.25)
        case .blue:   return Color(red: 0.3, green: 0.5, blue: 1.0)
        case .yellow: return Color(red: 1.0, green: 0.9, blue: 0.3)
        case .green:  return Color(red: 0.3, green: 0.9, blue: 0.4)
        case .orange: return Color(red: 1.0, green: 0.6, blue: 0.2)
        case .purple: return Color(red: 0.7, green: 0.35, blue: 1.0)
        case .white:  return Color.white.opacity(0.9)
        }
    }

    var hapticType: WKHapticType {
        switch self {
        case .red:    return .click
        case .blue:   return .directionUp
        case .yellow: return .directionDown
        case .green:  return .start
        case .orange: return .stop
        case .purple: return .retry
        case .white:  return .notification
        }
    }
}
