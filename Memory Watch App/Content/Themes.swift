import Foundation

enum Themes {
    static let animals = Theme(
        id: "animals",
        displayIcon: .emoji("🐱"),
        symbols: [
            .emoji("🐶"), .emoji("🐱"), .emoji("🐭"), .emoji("🐹"),
            .emoji("🐰"), .emoji("🦊"), .emoji("🐻"), .emoji("🐼"),
            .emoji("🐨"), .emoji("🐯"), .emoji("🦁"), .emoji("🐮"),
            .emoji("🐷"), .emoji("🐸"), .emoji("🐵"), .emoji("🐔")
        ]
    )

    static let food = Theme(
        id: "food",
        displayIcon: .emoji("🍕"),
        symbols: [
            .emoji("🍕"), .emoji("🍔"), .emoji("🌮"), .emoji("🍜"),
            .emoji("🍣"), .emoji("🍦"), .emoji("🍩"), .emoji("🍪"),
            .emoji("🥐"), .emoji("🥗"), .emoji("🍎"), .emoji("🍓"),
            .emoji("🍇"), .emoji("🍌"), .emoji("🥑"), .emoji("🥕")
        ]
    )

    static let vacation = Theme(
        id: "vacation",
        displayIcon: .emoji("🏖️"),
        symbols: [
            .emoji("🏖️"), .emoji("🗽"), .emoji("🗼"), .emoji("🎡"),
            .emoji("🏔️"), .emoji("🗻"), .emoji("🏝️"), .emoji("🏜️"),
            .emoji("🌋"), .emoji("🏰"), .emoji("⛺"), .emoji("🚢"),
            .emoji("✈️"), .emoji("🎢"), .emoji("🎪"), .emoji("🎠")
        ]
    )

    static let all: [Theme] = [animals, food, vacation]
}
