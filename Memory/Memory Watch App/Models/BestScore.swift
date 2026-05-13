import Foundation

struct BestScore: Codable, Hashable {
    let moves: Int
    let timeSeconds: Double
    let achievedAt: Date
}
