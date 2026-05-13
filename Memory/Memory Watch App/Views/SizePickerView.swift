import SwiftUI

struct SizePickerView: View {
    let theme: Theme

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(GridSizes.all) { size in
                    NavigationLink(value: size) {
                        Text("\(size.pairs)")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .navigationDestination(for: GridSize.self) { size in
            GameView(theme: theme, gridSize: size)
        }
    }
}
