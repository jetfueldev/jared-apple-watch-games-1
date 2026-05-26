import XCTest
@testable import Memory_Watch_App

final class ThemeTests: XCTestCase {

    func testAllThemesHaveEnoughSymbols() {
        for theme in Themes.all {
            XCTAssertGreaterThanOrEqual(
                theme.symbols.count, 16,
                "\(theme.id) needs at least 16 symbols, has \(theme.symbols.count)")
        }
    }

    func testAllThemesHaveUniqueSymbols() {
        for theme in Themes.all {
            let unique = Set(theme.symbols)
            XCTAssertEqual(unique.count, theme.symbols.count,
                           "\(theme.id) has duplicate symbols")
        }
    }

    func testAllThemesHaveDisplayIcon() {
        for theme in Themes.all {
            if case .emoji(let e) = theme.displayIcon {
                XCTAssertFalse(e.isEmpty, "\(theme.id) has empty display icon")
            } else if case .image(let name) = theme.displayIcon {
                XCTAssertFalse(name.isEmpty, "\(theme.id) has empty image name")
            }
        }
    }

    func testAllThemesHaveUniqueIDs() {
        let ids = Themes.all.map { $0.id }
        XCTAssertEqual(Set(ids).count, ids.count, "Theme IDs must be unique")
    }

    func testExpectedThemeCount() {
        XCTAssertEqual(Themes.all.count, 4, "v1 ships with 4 themes")
    }
}
