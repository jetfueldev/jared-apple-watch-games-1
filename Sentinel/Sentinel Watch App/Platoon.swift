import Foundation

/// Pure platoon economy rules (no SpriteKit) so the merge/growth logic is unit-testable
/// headless via `Tools/verify-sentinel.swift`. A platoon is an array of `slotCount` slots,
/// each an Optional tier (nil = empty).
enum Platoon {
    static let slotCount = 3

    /// One economy growth step (triggered when the kill-charge meter fills):
    /// 1. fill the leftmost empty slot with a fresh tier-1 unit, else
    /// 2. if a tier-1 unit exists, merge it up to tier 2, else
    /// 3. (full, no tier-1) bump the lowest-tier slot up one tier.
    /// Net effect: the platoon fills to `slotCount` firing columns, then steadily climbs.
    static func grow(_ slots: [Int?]) -> [Int?] {
        var s = slots
        if let empty = s.firstIndex(where: { $0 == nil }) {
            s[empty] = 1
        } else if let one = s.firstIndex(where: { $0 == 1 }) {
            s[one] = 2
        } else {
            var lo = 0
            for i in s.indices where (s[i] ?? Int.max) < (s[lo] ?? Int.max) { lo = i }
            s[lo] = (s[lo] ?? 1) + 1
        }
        return s
    }

    /// Normalize carried tiers into a full slot array (padded with nils), seeding a lone
    /// tier-1 if empty.
    static func seed(from tiers: [Int]) -> [Int?] {
        var s = [Int?](repeating: nil, count: slotCount)
        for (i, tier) in tiers.prefix(slotCount).enumerated() { s[i] = tier }
        if s.compactMap({ $0 }).isEmpty { s[0] = 1 }
        return s
    }
}
