import SwiftUI

struct MenuView: View {
    @AppStorage("ricochet_currentLevel") private var currentLevel = 1
    @AppStorage("ricochet_highestLevel") private var highestLevel = 1

    private var hasProgress: Bool { currentLevel > 1 }
    private var progress: Double {
        Double(max(currentLevel - 1, 0)) / Double(LevelGenerator.totalLevels)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text(LevelGenerator.zoneName(currentLevel))
                    .font(.system(size: 20))

                Text("\(currentLevel)")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.08))
                    Capsule()
                        .fill(.blue.opacity(0.4))
                        .frame(width: max(4, progress * 140))
                }
                .frame(width: 140, height: 3)
                .padding(.bottom, 4)

                NavigationLink(destination: GameContainerView(startLevel: currentLevel)) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                        if hasProgress {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.3, green: 0.9, blue: 0.4).opacity(0.15))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                if hasProgress {
                    NavigationLink(destination: GameContainerView(startLevel: 1)) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12))
                            Text("1")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.06))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink(destination: SimulationView()) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.yellow.opacity(0.7))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(.white.opacity(0.06))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                NavigationLink(destination: SettingsView()) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.5))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(.white.opacity(0.06))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
    }
}
