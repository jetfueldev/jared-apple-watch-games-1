import Foundation

enum GridSizes {
    static let viewportRows = 3
    static let viewportCols = 4

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
        let cols = Int(ceil(sqrt(Double(total))))
        let rows = Int(ceil(Double(total) / Double(cols)))
        return GridSize(pairs: pairs, rows: rows, cols: cols)
    }

    static func needsVerticalScroll(_ gridSize: GridSize) -> Bool {
        gridSize.rows > viewportRows
    }

    static func needsHorizontalScroll(_ gridSize: GridSize) -> Bool {
        gridSize.cols > viewportCols
    }

    static func needsScroll(_ gridSize: GridSize) -> Bool {
        needsVerticalScroll(gridSize) || needsHorizontalScroll(gridSize)
    }
}
