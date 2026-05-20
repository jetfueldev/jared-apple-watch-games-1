import SwiftUI

struct SettingsView: View {
    @AppStorage("ricochet_currentLevel") private var currentLevel = 1
    @AppStorage("ricochet_highestLevel") private var highestLevel = 1
    @State private var showResetConfirm = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.green.opacity(0.6))
                    Text("\(highestLevel)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(.white.opacity(0.06))
                .cornerRadius(10)

                Button {
                    showResetConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14))
                        Text("1")
                            .font(.system(size: 14, design: .rounded))
                        Spacer()
                    }
                    .foregroundStyle(.red.opacity(0.7))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .background(.white.opacity(0.06))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .confirmationDialog("", isPresented: $showResetConfirm) {
                    Button(role: .destructive) {
                        currentLevel = 1
                        highestLevel = 1
                        dismiss()
                    } label: {
                        Label {
                            Text("Reset")
                        } icon: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}
