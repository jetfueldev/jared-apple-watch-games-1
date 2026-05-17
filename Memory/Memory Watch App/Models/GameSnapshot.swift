import Foundation

struct GameSnapshot: Codable {
    let themeID: String
    let pairs: Int
    let cards: [Card]
    let moves: Int
    let elapsedTime: TimeInterval
    let savedAt: Date
}
