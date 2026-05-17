import Foundation

struct GridSize: Identifiable, Hashable {
    let pairs: Int
    let rows: Int
    let cols: Int

    var id: Int { pairs }
    var totalCards: Int { pairs * 2 }

    var lastRowCount: Int {
        let remainder = totalCards % cols
        return remainder == 0 ? cols : remainder
    }

    func cardsInRow(_ row: Int) -> Int {
        if row == rows - 1 {
            return lastRowCount
        }
        return cols
    }

    init(pairs: Int, rows: Int, cols: Int) {
        self.pairs = pairs
        self.rows = rows
        self.cols = cols
    }
}
