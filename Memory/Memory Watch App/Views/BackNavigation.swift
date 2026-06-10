import SwiftUI
import WatchGameKit

struct BackNavigationModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .watchBackButton()
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        if value.translation.width > 50 && abs(value.translation.height) < 50 {
                            dismiss()
                        }
                    }
            )
    }
}

extension View {
    func backNavigation() -> some View {
        modifier(BackNavigationModifier())
    }
}
