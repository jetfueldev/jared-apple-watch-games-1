import Foundation

enum GridSizes {
    static let all: [GridSize] = [
        GridSize(pairs: 1,  rows: 1, cols: 2),
        GridSize(pairs: 2,  rows: 2, cols: 2),
        GridSize(pairs: 3,  rows: 2, cols: 3),
        GridSize(pairs: 4,  rows: 2, cols: 4),
        GridSize(pairs: 6,  rows: 3, cols: 4),
        GridSize(pairs: 10, rows: 4, cols: 5),
        GridSize(pairs: 12, rows: 4, cols: 6),
        GridSize(pairs: 16, rows: 4, cols: 8),
    ]

    static var startingSize: GridSize { all[1] }

    static func nextSize(after current: GridSize) -> GridSize? {
        guard let index = all.firstIndex(of: current),
              index + 1 < all.count else { return nil }
        return all[index + 1]
    }
}
