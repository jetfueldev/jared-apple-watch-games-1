import SwiftUI

struct ThemePickerView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Themes.all) { theme in
                    NavigationLink(value: theme) {
                        CardSymbolView(symbol: theme.displayIcon, size: 40)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .navigationDestination(for: Theme.self) { theme in
            SizePickerView(theme: theme)
        }
    }
}
