import SwiftUI

struct PadView: View {
    let padColor: PadColor
    let isLit: Bool
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: 14)
                .fill(isLit ? padColor.litColor : padColor.glassColor)

            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(isLit ? 0.2 : 0.08), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )

            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(isLit ? 0.4 : 0.12), lineWidth: 1)
        }
        .animation(.easeInOut(duration: 0.15), value: isLit)
        .onTapGesture {
            guard isEnabled else { return }
            onTap()
        }
    }
}
