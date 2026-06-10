import SwiftUI

public struct BackButtonModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
            }
    }
}

public extension View {
    func watchBackButton() -> some View {
        modifier(BackButtonModifier())
    }
}
