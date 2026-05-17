import SwiftUI

struct GameView: View {
    let theme: Theme
    let startSize: GridSize
    let resumeSnapshot: GameSnapshot?

    @State private var currentSize: GridSize
    @State private var gameID = UUID()
    @State private var activeSnapshot: GameSnapshot?
    @Environment(\.dismiss) private var dismiss

    init(theme: Theme, startSize: GridSize? = nil, snapshot: GameSnapshot? = nil) {
        self.theme = theme
        let size = startSize
            ?? ScoreStore.shared.firstUnbeatenSize(themeID: theme.id)
            ?? GridSizes.startingSize
        self.startSize = size
        self.resumeSnapshot = snapshot
        self._currentSize = State(initialValue: size)
        self._activeSnapshot = State(initialValue: snapshot)
    }

    var body: some View {
        GameBoardView(theme: theme, gridSize: currentSize, snapshot: activeSnapshot) {
            if let next = GridSizes.nextSize(after: currentSize) {
                currentSize = next
                activeSnapshot = nil
                gameID = UUID()
            } else {
                ScoreStore.shared.clearGameSnapshot(themeID: theme.id)
                dismiss()
            }
        }
        .id(gameID)
    }
}

private struct GameBoardView: View {
    let theme: Theme
    let gridSize: GridSize
    let snapshot: GameSnapshot?
    let onWinDismissed: () -> Void

    @StateObject private var state: GameState
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    init(theme: Theme, gridSize: GridSize, snapshot: GameSnapshot? = nil, onWinDismissed: @escaping () -> Void) {
        self.theme = theme
        self.gridSize = gridSize
        self.snapshot = snapshot
        self.onWinDismissed = onWinDismissed
        if let snapshot {
            self._state = StateObject(wrappedValue: GameState(theme: theme, gridSize: gridSize, snapshot: snapshot))
        } else {
            self._state = StateObject(wrappedValue: GameState(theme: theme, gridSize: gridSize))
        }
    }

    @State private var panX: CGFloat = 0
    @State private var panY: CGFloat = 0
    @State private var dragStartPanX: CGFloat = 0
    @State private var dragStartPanY: CGFloat = 0
    @State private var zoomLevel: CGFloat = 1.0
    @State private var showIndicators: Bool = false
    @State private var indicatorTimer: Timer?

    private var needsHoneycomb: Bool {
        gridSize.rows > GridSizes.viewportRows || gridSize.cols > GridSizes.viewportCols
    }

    private var minZoom: CGFloat {
        guard needsHoneycomb else { return 1.0 }
        let zoomForRows = CGFloat(GridSizes.viewportRows) / CGFloat(gridSize.rows)
        let zoomForCols = CGFloat(GridSizes.viewportCols) / CGFloat(gridSize.cols)
        return min(zoomForRows, zoomForCols)
    }

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 3
            let barHeight: CGFloat = 2
            let viewportW = geo.size.width
            let viewportH = geo.size.height - barHeight - 4

            let baseCardW = (viewportW - spacing * CGFloat(GridSizes.viewportCols - 1)) / CGFloat(GridSizes.viewportCols)
            let baseCardH = (viewportH - spacing * CGFloat(GridSizes.viewportRows - 1)) / CGFloat(GridSizes.viewportRows)
            let baseCardSize = min(baseCardW, baseCardH)
            let cellSpacing = baseCardSize + spacing

            let gridCenterX = CGFloat(gridSize.cols - 1) / 2.0
            let gridCenterY = CGFloat(gridSize.rows - 1) / 2.0

            let gridHalfW = gridCenterX * cellSpacing * zoomLevel
            let gridHalfH = gridCenterY * cellSpacing * zoomLevel
            let maxPanX = max(0, gridHalfW - viewportW / 2 + baseCardSize * zoomLevel / 2)
            let maxPanY = max(0, gridHalfH - viewportH / 2 + baseCardSize * zoomLevel / 2)

            let clampedPanX = min(max(panX, -maxPanX), maxPanX)
            let clampedPanY = min(max(panY, -maxPanY), maxPanY)

            let panNormX: CGFloat = maxPanX > 0 ? (clampedPanX + maxPanX) / (2 * maxPanX) : 0.5
            let panNormY: CGFloat = maxPanY > 0 ? (clampedPanY + maxPanY) / (2 * maxPanY) : 0.5
            let zoomFraction: CGFloat = needsHoneycomb ? (1.0 - zoomLevel) / (1.0 - minZoom) : 0

            let matchedPairs = state.cards.filter { $0.isMatched }.count / 2
            let matchProgress = gridSize.pairs > 0 ? CGFloat(matchedPairs) / CGFloat(gridSize.pairs) : 0

            VStack(spacing: 4) {
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.06))
                    Capsule()
                        .fill(.white.opacity(0.25))
                        .frame(width: geo.size.width * matchProgress)
                        .animation(.easeInOut(duration: 0.5), value: matchProgress)
                }
                .frame(height: barHeight)

                ZStack {
                    ForEach(0..<state.cards.count, id: \.self) { index in
                        let row = index / gridSize.cols
                        let col: Int = {
                            let r = index / gridSize.cols
                            let c = index % gridSize.cols
                            if r == gridSize.rows - 1 && gridSize.lastRowCount < gridSize.cols {
                                return c
                            }
                            return c
                        }()

                        let isLastRow = row == gridSize.rows - 1
                        let lastRowOffset: CGFloat = isLastRow && gridSize.lastRowCount < gridSize.cols
                            ? CGFloat(gridSize.cols - gridSize.lastRowCount) * cellSpacing * zoomLevel / 2
                            : 0

                        let worldX = (CGFloat(col) - gridCenterX) * cellSpacing * zoomLevel + lastRowOffset
                        let worldY = (CGFloat(row) - gridCenterY) * cellSpacing * zoomLevel

                        let screenX = worldX + clampedPanX
                        let screenY = worldY + clampedPanY

                        let nx = screenX / (viewportW / 2)
                        let ny = screenY / (viewportH / 2)
                        let dist = nx * nx + ny * ny
                        let scale = needsHoneycomb ? max(0, 1.0 - dist * 0.5) : 1.0

                        let cardSize = baseCardSize * zoomLevel * scale
                        let canTap = cardSize >= baseCardSize * 0.5

                        if scale > 0.05 {
                            CardView(card: state.cards[index], cardSize: cardSize)
                                .opacity(Double(min(1, scale * 2)))
                                .position(
                                    x: viewportW / 2 + screenX,
                                    y: viewportH / 2 + screenY
                                )
                                .onTapGesture {
                                    if canTap {
                                        state.tapCard(at: index)
                                    }
                                }
                        }
                    }

                    if needsHoneycomb {
                        ScrollPositionIndicators(
                            panNormX: panNormX,
                            panNormY: panNormY,
                            zoomFraction: zoomFraction,
                            viewportSize: CGSize(width: viewportW, height: viewportH)
                        )
                        .opacity(showIndicators ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3), value: showIndicators)
                    }
                }
                .frame(width: viewportW, height: viewportH)
                .gesture(needsHoneycomb ? DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        panX = dragStartPanX + value.translation.width
                        panY = dragStartPanY + value.translation.height
                        flashIndicators()
                    }
                    .onEnded { value in
                        panX = min(max(panX, -maxPanX), maxPanX)
                        panY = min(max(panY, -maxPanY), maxPanY)
                        dragStartPanX = panX
                        dragStartPanY = panY
                    } : nil)
            }
            .focusable(needsHoneycomb)
            .digitalCrownRotation(
                $zoomLevel,
                from: Double(minZoom),
                through: 1.0,
                sensitivity: .low,
                isContinuous: false,
                isHapticFeedbackEnabled: true
            )
            .onChange(of: zoomLevel) { _, _ in
                panX = min(max(panX, -maxPanX), maxPanX)
                panY = min(max(panY, -maxPanY), maxPanY)
                dragStartPanX = panX
                dragStartPanY = panY
                flashIndicators()
            }
        }
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
        .fullScreenCover(isPresented: $state.isComplete, onDismiss: onWinDismissed) {
            WinView(state: state, theme: theme, gridSize: gridSize)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive || newPhase == .background {
                if !state.isComplete && !GameLogic.isComplete(state.cards) {
                    ScoreStore.shared.saveGameSnapshot(state.snapshot())
                }
            }
        }
        .onDisappear {
            if !state.isComplete && !GameLogic.isComplete(state.cards) {
                ScoreStore.shared.saveGameSnapshot(state.snapshot())
            }
        }
        .onAppear {
            if GameLogic.isComplete(state.cards) {
                state.isComplete = true
            } else {
                ScoreStore.shared.saveGameSnapshot(state.snapshot())
            }
            if needsHoneycomb {
                flashIndicators()
            }
        }
    }

    private func flashIndicators() {
        showIndicators = true
        indicatorTimer?.invalidate()
        indicatorTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
            showIndicators = false
        }
    }
}

private struct ScrollPositionIndicators: View {
    let panNormX: CGFloat
    let panNormY: CGFloat
    let zoomFraction: CGFloat
    let viewportSize: CGSize

    private let maxThickness: CGFloat = 2.5
    private let borderThickness: CGFloat = 1

    private var indicatorLength: CGFloat {
        let base: CGFloat = 0.15
        let zoomed: CGFloat = 1.0
        return base + (zoomed - base) * zoomFraction
    }

    private var thickness: CGFloat {
        let minT: CGFloat = 1.0
        return minT + (maxThickness - minT) * zoomFraction
    }

    private var opacity: CGFloat {
        0.10 + 0.15 * zoomFraction
    }

    var body: some View {
        ZStack {
            // Top indicator — position follows horizontal pan
            VStack(spacing: 0) {
                horizontalIndicator(atEdge: panNormY < 0.02, position: panNormX)
                Spacer()
            }
            // Bottom indicator — position follows horizontal pan
            VStack(spacing: 0) {
                Spacer()
                horizontalIndicator(atEdge: panNormY > 0.98, position: panNormX)
            }
            // Left indicator — position follows vertical pan
            HStack(spacing: 0) {
                verticalIndicator(atEdge: panNormX < 0.02, position: panNormY)
                Spacer()
            }
            // Right indicator — position follows vertical pan
            HStack(spacing: 0) {
                Spacer()
                verticalIndicator(atEdge: panNormX > 0.98, position: panNormY)
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func horizontalIndicator(atEdge: Bool, position: CGFloat) -> some View {
        if atEdge {
            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(height: borderThickness)
        } else {
            let len = indicatorLength * viewportSize.width
            let travel = viewportSize.width - len
            let xOffset = position * travel

            Rectangle()
                .fill(.white.opacity(opacity))
                .frame(width: len, height: thickness)
                .cornerRadius(thickness / 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .offset(x: xOffset)
        }
    }

    @ViewBuilder
    private func verticalIndicator(atEdge: Bool, position: CGFloat) -> some View {
        if atEdge {
            Rectangle()
                .fill(.white.opacity(0.15))
                .frame(width: borderThickness)
        } else {
            let len = indicatorLength * viewportSize.height
            let travel = viewportSize.height - len
            let yOffset = position * travel

            Rectangle()
                .fill(.white.opacity(opacity))
                .frame(width: thickness, height: len)
                .cornerRadius(thickness / 2)
                .frame(maxHeight: .infinity, alignment: .top)
                .offset(y: yOffset)
        }
    }
}
