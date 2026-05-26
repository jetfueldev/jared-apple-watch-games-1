import XCTest
@testable import Memory_Watch_App

final class GridSizeTests: XCTestCase {

    func testAllSizesHaveValidCardCount() {
        for size in GridSizes.all {
            XCTAssertEqual(size.totalCards, size.pairs * 2)
            XCTAssertGreaterThanOrEqual(
                size.rows * size.cols, size.totalCards,
                "Grid \(size.rows)x\(size.cols) can't fit \(size.totalCards) cards")
        }
    }

    func testSizesAreInAscendingOrder() {
        for i in 1..<GridSizes.all.count {
            XCTAssertGreaterThan(
                GridSizes.all[i].pairs, GridSizes.all[i - 1].pairs,
                "Sizes must be in ascending pair order")
        }
    }

    func testNextSizeWalksFullProgression() {
        var current = GridSizes.startingSize
        var visited = [current]
        while let next = GridSizes.nextSize(after: current) {
            visited.append(next)
            current = next
        }
        XCTAssertEqual(visited.count, GridSizes.all.count,
                       "nextSize should walk through all \(GridSizes.all.count) sizes")
    }

    func testStartingSizeIsFirst() {
        XCTAssertEqual(GridSizes.startingSize, GridSizes.all.first)
    }

    func testSmallSizesUseFewerColumns() {
        let two = GridSizes.all.first { $0.pairs == 2 }!
        XCTAssertEqual(two.cols, 2, "2-pair grid should be 2x2")
        XCTAssertEqual(two.rows, 2)

        let three = GridSizes.all.first { $0.pairs == 3 }!
        XCTAssertEqual(three.cols, 3, "3-pair grid should be 3x2")
        XCTAssertEqual(three.rows, 2)
    }

    func testLargeSizesUseFourColumns() {
        for size in GridSizes.all where size.pairs >= 4 {
            XCTAssertEqual(size.cols, 4, "\(size.pairs)-pair grid should use 4 columns")
        }
    }
}
