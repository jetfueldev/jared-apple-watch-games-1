import SwiftUI

struct PadView: View {
    let padColor: PadColor
    let isLit: Bool
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isLit ? padColor.litColor : padColor.color)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.white.opacity(isLit ? 0.3 : 0.06), lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.15), value: isLit)
            .onTapGesture {
                guard isEnabled else { return }
                onTap()
            }
    }
}
