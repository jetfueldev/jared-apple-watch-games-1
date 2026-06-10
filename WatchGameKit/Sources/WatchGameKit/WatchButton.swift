import SwiftUI

public struct WatchButtonStyle: ViewModifier {
    let background: Color

    public init(background: Color = .white.opacity(0.10)) {
        self.background = background
    }

    public func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(background)
            )
    }
}

public extension View {
    func watchButton(_ background: Color = .white.opacity(0.10)) -> some View {
        self.buttonStyle(.plain)
            .modifier(WatchButtonStyle(background: background))
    }
}
