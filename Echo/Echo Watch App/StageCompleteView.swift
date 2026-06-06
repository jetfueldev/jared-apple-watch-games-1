import SwiftUI

struct StageCompleteView: View {
    let stageNumber: Int
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.green.opacity(0.7))

                Text("\(stageNumber)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))

                Image(systemName: "arrow.right")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .scaleEffect(appeared ? 1.0 : 0.7)
            .opacity(appeared ? 1.0 : 0)
            .animation(.easeOut(duration: 0.4), value: appeared)
        }
        .onAppear {
            appeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onDismiss()
            }
        }
    }
}
