import Foundation

enum GridSizes {
    static let all: [GridSize] = (2...30).map { pairs in
        let totalCards = pairs * 2
        let cols = 4
        let rows = Int(ceil(Double(totalCards) / Double(cols)))
        return GridSize(pairs: pairs, rows: rows, cols: cols)
    }

    static var startingSize: GridSize { all[0] }

    static func nextSize(after current: GridSize) -> GridSize? {
        guard let index = all.firstIndex(of: current),
              index + 1 < all.count else { return nil }
        return all[index + 1]
    }

    static func squareSize(pairs: Int) -> GridSize {
        let total = pairs * 2
        let cols = 4
        let rows = Int(ceil(Double(total) / Double(cols)))
        return GridSize(pairs: pairs, rows: rows, cols: cols)
    }
}
