import SwiftUI
import WatchGameKit

struct MenuView: View {
    @AppStorage("ricochet_currentLevel") private var currentLevel = 1
    @AppStorage("ricochet_highestLevel") private var highestLevel = 1

    private var hasProgress: Bool { currentLevel > 1 }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                LevelHeader(icon: LevelGenerator.zoneName(currentLevel), level: currentLevel, totalLevels: LevelGenerator.totalLevels)

                NavigationLink(destination: GameContainerView(startLevel: currentLevel)) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16))
                        if hasProgress {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                }
                .watchButton(Color(red: 0.3, green: 0.9, blue: 0.4).opacity(0.15))

                if hasProgress {
                    NavigationLink(destination: GameContainerView(startLevel: 1)) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14))
                            Text("1")
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .watchButton()
                }

                NavigationLink(destination: SimulationView()) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.yellow.opacity(0.7))
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                }
                .watchButton()

                NavigationLink(destination: SettingsView()) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                }
                .watchButton()
            }
            .padding(.horizontal, 4)
        }
    }
}
