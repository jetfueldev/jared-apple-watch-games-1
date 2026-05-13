import Foundation

struct GridSize: Identifiable, Hashable {
    let pairs: Int
    let rows: Int
    let cols: Int

    var id: Int { pairs }
    var totalCards: Int { pairs * 2 }

    init(pairs: Int, rows: Int, cols: Int) {
        assert(rows * cols == pairs * 2, "Grid dimensions must equal pairs * 2")
        self.pairs = pairs
        self.rows = rows
        self.cols = cols
    }
}
