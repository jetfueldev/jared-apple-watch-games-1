import SwiftUI

public struct ProgressCapsule: View {
    let progress: Double
    var width: CGFloat
    var height: CGFloat

    public init(progress: Double, width: CGFloat = 140, height: CGFloat = 3) {
        self.progress = progress
        self.width = width
        self.height = height
    }

    public var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(.white.opacity(0.08))
            Capsule()
                .fill(.blue.opacity(0.4))
                .frame(width: max(4, progress * width))
        }
        .frame(width: width, height: height)
    }
}
