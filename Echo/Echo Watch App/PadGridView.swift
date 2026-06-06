import SwiftUI

struct PadGridView: View {
    let colors: [PadColor]
    let litPad: PadColor?
    let isInputEnabled: Bool
    let onTap: (PadColor) -> Void

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 4
            switch colors.count {
            case 2: layout2(geo: geo, spacing: spacing)
            case 3: layout3(geo: geo, spacing: spacing)
            case 4: layout4(geo: geo, spacing: spacing)
            case 5: layout5(geo: geo, spacing: spacing)
            case 6: layout6(geo: geo, spacing: spacing)
            case 7: layout7(geo: geo, spacing: spacing)
            default: layout4(geo: geo, spacing: spacing)
            }
        }
    }

    private func pad(_ color: PadColor) -> PadView {
        PadView(
            padColor: color,
            isLit: litPad == color,
            isEnabled: isInputEnabled,
            onTap: { onTap(color) }
        )
    }

    // 2 pads: stacked vertically
    private func layout2(geo: GeometryProxy, spacing: CGFloat) -> some View {
        let h = (geo.size.height - spacing) / 2
        return VStack(spacing: spacing) {
            pad(colors[0]).frame(height: h)
            pad(colors[1]).frame(height: h)
        }
    }

    // 3 pads: 2 top, 1 full-width bottom
    private func layout3(geo: GeometryProxy, spacing: CGFloat) -> some View {
        let h = (geo.size.height - spacing) / 2
        return VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                pad(colors[0])
                pad(colors[1])
            }
            .frame(height: h)
            pad(colors[2]).frame(height: h)
        }
    }

    // 4 pads: classic 2x2 grid
    private func layout4(geo: GeometryProxy, spacing: CGFloat) -> some View {
        let h = (geo.size.height - spacing) / 2
        return VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                pad(colors[0])
                pad(colors[1])
            }
            .frame(height: h)
            HStack(spacing: spacing) {
                pad(colors[2])
                pad(colors[3])
            }
            .frame(height: h)
        }
    }

    // 5 pads: 2 top, 3 bottom
    private func layout5(geo: GeometryProxy, spacing: CGFloat) -> some View {
        let h = (geo.size.height - spacing) / 2
        return VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                pad(colors[0])
                pad(colors[1])
            }
            .frame(height: h)
            HStack(spacing: spacing) {
                pad(colors[2])
                pad(colors[3])
                pad(colors[4])
            }
            .frame(height: h)
        }
    }

    // 6 pads: 3x2 grid
    private func layout6(geo: GeometryProxy, spacing: CGFloat) -> some View {
        let h = (geo.size.height - spacing) / 2
        return VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                pad(colors[0])
                pad(colors[1])
                pad(colors[2])
            }
            .frame(height: h)
            HStack(spacing: spacing) {
                pad(colors[3])
                pad(colors[4])
                pad(colors[5])
            }
            .frame(height: h)
        }
    }

    // 7 pads: 4 top, 3 bottom
    private func layout7(geo: GeometryProxy, spacing: CGFloat) -> some View {
        let h = (geo.size.height - spacing) / 2
        return VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                pad(colors[0])
                pad(colors[1])
                pad(colors[2])
                pad(colors[3])
            }
            .frame(height: h)
            HStack(spacing: spacing) {
                pad(colors[4])
                pad(colors[5])
                pad(colors[6])
            }
            .frame(height: h)
        }
    }
}
