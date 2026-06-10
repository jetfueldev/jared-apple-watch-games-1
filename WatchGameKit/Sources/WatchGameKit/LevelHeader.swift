import SwiftUI

public struct LevelHeader: View {
    let icon: String
    let level: Int
    let totalLevels: Int

    public init(icon: String, level: Int, totalLevels: Int) {
        self.icon = icon
        self.level = level
        self.totalLevels = totalLevels
    }

    private var progress: Double {
        Double(max(level - 1, 0)) / Double(totalLevels)
    }

    public var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 20))

            Text("\(level)")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))

            ProgressCapsule(progress: progress)
                .padding(.bottom, 4)
        }
    }
}
