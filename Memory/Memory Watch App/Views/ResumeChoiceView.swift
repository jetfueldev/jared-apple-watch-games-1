import SwiftUI

struct ResumeChoiceView: View {
    let theme: Theme
    let snapshot: GameSnapshot

    var body: some View {
        HStack(spacing: 20) {
            NavigationLink(value: ResumeDestination(theme: theme, gridSize: GridSizes.all.first(where: { $0.pairs == snapshot.pairs }) ?? GridSizes.startingSize, snapshot: snapshot)) {
                VStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white.opacity(0.5))
                    Text(formatDate(snapshot.savedAt))
                        .font(.system(size: 11, weight: .light).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.white.opacity(0.08))
                )
            }
            .buttonStyle(.plain)

            NavigationLink(value: ResumeDestination(theme: theme, gridSize: GridSizes.startingSize, snapshot: nil)) {
                VStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 20))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.white.opacity(0.08))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(maxHeight: 100)
        .backNavigation()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("M/d")
        return formatter.string(from: date)
    }
}
