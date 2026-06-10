import CoreGraphics

// Scene: 200w × 240h. Target y: 188. Ship: (100, 28).
// Side walls at x=0 and x=200 always ricochet. Top/bottom are void.
// Difficulty rule: min bounce count climbs continuously with level number.
//   L1-3: direct (teach aim)   L4-10: 1 bounce    L11-20: 2 bounces
//   L21-30: 3 bounces          L31-40: 4 bounces  L41-50: 5+ bounces
// Window width tightens within each band. Validated by Ricochet/Tools/main.swift.

enum LevelData {

    struct Def {
        let targetX: CGFloat
        let obstacles: [Obstacle]
    }

    // MARK: - Shape Primitives

    private static func arc(cx: CGFloat, cy: CGFloat, r: CGFloat,
                            from start: CGFloat, to end: CGFloat,
                            segs: Int = 12, _ type: ObstacleType = .ricochet) -> [Obstacle] {
        var out: [Obstacle] = []
        let step = (end - start) / CGFloat(segs)
        for i in 0..<segs {
            let a1 = start + step * CGFloat(i)
            let a2 = start + step * CGFloat(i + 1)
            out.append(Obstacle(
                from: CGPoint(x: cx + r * cos(a1), y: cy + r * sin(a1)),
                to: CGPoint(x: cx + r * cos(a2), y: cy + r * sin(a2)),
                type: type
            ))
        }
        return out
    }

    private static func ring(cx: CGFloat, cy: CGFloat, r: CGFloat,
                             gapAngle: CGFloat, gapSize: CGFloat,
                             segs: Int = 18, _ type: ObstacleType = .ricochet) -> [Obstacle] {
        arc(cx: cx, cy: cy, r: r,
            from: gapAngle + gapSize / 2,
            to: gapAngle + 2 * .pi - gapSize / 2,
            segs: segs, type)
    }

    private static func line(_ x1: CGFloat, _ y1: CGFloat,
                             _ x2: CGFloat, _ y2: CGFloat,
                             _ type: ObstacleType = .ricochet) -> Obstacle {
        Obstacle(from: CGPoint(x: x1, y: y1), to: CGPoint(x: x2, y: y2), type: type)
    }

    // MARK: - Blocking Helpers

    private static func sideShields(_ y1: CGFloat, _ y2: CGFloat) -> [Obstacle] {
        [line(5, y1, 5, y2, .absorb), line(195, y1, 195, y2, .absorb)]
    }

    /// Standard periscope rig: roof shelf, corner deflector, drop panel over the target.
    private static func periscope() -> [Obstacle] {
        [
            line(40, 160, 160, 160),
            line(150, 222, 180, 192),
            line(85, 200, 115, 230),
        ]
    }

    /// Pocket walls flanking a target at x=100.
    private static func pocket(_ left: CGFloat, _ right: CGFloat) -> [Obstacle] {
        [line(left, 170, left, 198), line(right, 170, right, 198)]
    }

    // MARK: - 50 Levels

    static func build(level n: Int) -> Def {
        switch n {

        // ═══════════════════════════════════════════
        // BAND 1 (1-3) — Learn to aim. Direct shots,
        // the only place they're allowed.
        // ═══════════════════════════════════════════

        case 1: // Open sky — fire straight up
            return Def(targetX: 100, obstacles: [])

        case 2: // Offset — learn Crown aiming
            return Def(targetX: 152, obstacles: [])

        case 3: // Funnel — angled walls guide the shot to a slot
            return Def(targetX: 100, obstacles: [
                line(35, 95, 94, 148),
                line(165, 95, 106, 148),
            ])

        // ═══════════════════════════════════════════
        // BAND 2 (4-10) — One bounce. The roof blocks
        // every straight shot; the wall is the way.
        // ═══════════════════════════════════════════

        case 4: // Teach the bank — wide roof, bounce off either wall
            return Def(targetX: 100, obstacles: [
                line(40, 80, 160, 80),
            ])

        case 5: // One way only — roof seals the right, bank left
            return Def(targetX: 140, obstacles: [
                line(30, 90, 165, 90),
            ])

        case 6: // High gap — bank through the left slot
            return Def(targetX: 100, obstacles: [
                line(55, 140, 199, 140),
            ])

        case 7: // Mirror — bank right through the high slot
            return Def(targetX: 60, obstacles: [
                line(1, 120, 150, 120),
            ])

        case 8: // Bank + thread — bounce left, then through the gate
            return Def(targetX: 100, obstacles: [
                line(42, 80, 199, 80),
                line(1, 150, 44, 150),
                line(66, 150, 199, 150),
            ])

        case 9: // Bank + thread, mirrored and tighter
            return Def(targetX: 100, obstacles: [
                line(1, 80, 158, 80),
                line(1, 150, 140, 150),
                line(156, 150, 199, 150),
            ])

        case 10: // BOSS — precision bank through a tiny slot
            return Def(targetX: 100, obstacles: [
                line(1, 140, 30, 140),
                line(42, 140, 199, 140),
            ])

        // ═══════════════════════════════════════════
        // BAND 3 (11-20) — Two bounces. Wall to wall,
        // floating bumpers, offset staircases.
        // ═══════════════════════════════════════════

        case 11: // Teach the double bank — wall to wall to target
            return Def(targetX: 100, obstacles: [
                line(42, 158, 158, 158),
            ])

        case 12: // Bumper — bank off a floating wall, not the screen edge
            return Def(targetX: 130, obstacles: [
                line(60, 75, 60, 165),
                line(80, 165, 199, 165),
            ])

        case 13: // Bumper, mirrored
            return Def(targetX: 70, obstacles: [
                line(140, 75, 140, 165),
                line(1, 165, 120, 165),
            ])

        case 14: // Double bank through a mid-air gate
            return Def(targetX: 100, obstacles: [
                line(50, 158, 150, 158),
                line(1, 110, 88, 110),
                line(122, 110, 199, 110),
            ])

        case 15: // Gate narrows
            return Def(targetX: 100, obstacles: [
                line(50, 158, 150, 158),
                line(1, 110, 91, 110),
                line(119, 110, 199, 110),
            ])

        case 16: // Bumper run — target deep in the corner
            return Def(targetX: 150, obstacles: [
                line(60, 75, 60, 165),
                line(80, 165, 199, 165),
            ])

        case 17: // Gate narrows
            return Def(targetX: 100, obstacles: [
                line(50, 158, 150, 158),
                line(1, 110, 95, 110),
                line(115, 110, 199, 110),
            ])

        case 18: // Two gates — thread the top slot first
            return Def(targetX: 100, obstacles: [
                line(42, 158, 158, 158),
                line(1, 60, 10, 60),
                line(34, 60, 199, 60),
                line(1, 110, 92, 110),
                line(118, 110, 199, 110),
            ])

        case 19: // Two gates, tighter
            return Def(targetX: 100, obstacles: [
                line(42, 158, 158, 158),
                line(1, 60, 11, 60),
                line(31, 60, 199, 60),
                line(1, 110, 95, 110),
                line(115, 110, 199, 110),
            ])

        case 20: // BOSS — double bank, double gate
            return Def(targetX: 100, obstacles: [
                line(42, 158, 158, 158),
                line(1, 60, 12, 60),
                line(28, 60, 199, 60),
                line(1, 110, 96, 110),
                line(114, 110, 199, 110),
            ])

        // ═══════════════════════════════════════════
        // BAND 4 (21-30) — Three bounces. Deflector
        // panels and walled pockets: hit from above.
        // ═══════════════════════════════════════════

        case 21: // Teach the periscope drop — wide pocket
            return Def(targetX: 100, obstacles: periscope() + pocket(70, 130))

        case 22: // Pocket narrows
            return Def(targetX: 100, obstacles: periscope() + pocket(80, 120))

        case 23: // Periscope, mirrored
            return Def(targetX: 100, obstacles: [
                line(40, 160, 160, 160),
                line(20, 192, 50, 222),
                line(85, 230, 115, 200),
            ] + pocket(80, 120))

        case 24: // Periscope behind a high gate
            return Def(targetX: 100, obstacles: periscope() + [
                line(1, 105, 146, 105),
                line(180, 105, 199, 105),
            ])

        case 25: // Staircase — offset gaps force the zigzag
            return Def(targetX: 130, obstacles: [
                line(1, 100, 140, 100),
                line(60, 158, 199, 158),
            ])

        case 26: // Staircase, mirrored
            return Def(targetX: 70, obstacles: [
                line(60, 100, 199, 100),
                line(1, 158, 140, 158),
            ])

        case 27: // Corner pocket — roofed climb, drop home
            return Def(targetX: 60, obstacles: [
                line(1, 160, 160, 160),
                line(160, 225, 199, 186),
                line(30, 170, 30, 198),
                line(90, 170, 90, 198),
                line(110, 70, 199, 70),
            ])

        case 28: // Periscope gate narrows
            return Def(targetX: 100, obstacles: periscope() + [
                line(1, 105, 150, 105),
                line(174, 105, 199, 105),
            ])

        case 29: // Periscope gate, tighter still
            return Def(targetX: 100, obstacles: periscope() + [
                line(1, 105, 150, 105),
                line(168, 105, 199, 105),
            ])

        case 30: // BOSS — periscope drop through a razor gate
            return Def(targetX: 100, obstacles: periscope() + [
                line(1, 105, 150, 105),
                line(164, 105, 199, 105),
            ])

        // ═══════════════════════════════════════════
        // BAND 5 (31-40) — Four bounces, and the lava
        // arrives: absorb walls kill the shot.
        // ═══════════════════════════════════════════

        case 31: // Teach — bumper run behind a gate
            return Def(targetX: 130, obstacles: [
                line(60, 75, 60, 165),
                line(80, 165, 199, 165),
                line(1, 90, 44, 90),
                line(82, 90, 199, 90),
            ])

        case 32: // The gate turns deadly
            return Def(targetX: 130, obstacles: [
                line(60, 75, 60, 165),
                line(80, 165, 199, 165),
                line(1, 90, 44, 90, .absorb),
                line(82, 90, 199, 90, .absorb),
            ])

        case 33: // Bumper run, mirrored, lava gate
            return Def(targetX: 70, obstacles: [
                line(140, 75, 140, 165),
                line(1, 165, 120, 165),
                line(1, 90, 118, 90, .absorb),
                line(156, 90, 199, 90, .absorb),
            ])

        case 34: // Bumper run, gate tightens
            return Def(targetX: 130, obstacles: [
                line(60, 75, 60, 165),
                line(80, 165, 199, 165),
                line(1, 90, 48, 90, .absorb),
                line(78, 90, 199, 90, .absorb),
            ])

        case 35: // Wide-pocket periscope behind a far gate
            return Def(targetX: 100, obstacles: periscope() + pocket(70, 130) + [
                line(1, 105, 138, 105),
                line(182, 105, 199, 105),
            ])

        case 36: // Bumper run, razor lava gate
            return Def(targetX: 130, obstacles: [
                line(60, 75, 60, 165),
                line(80, 165, 199, 165),
                line(1, 90, 50, 90, .absorb),
                line(76, 90, 199, 90, .absorb),
            ])

        case 37: // Razor bumper run with side shields
            var obs: [Obstacle] = [
                line(60, 75, 60, 165),
                line(80, 165, 199, 165),
                line(1, 90, 50, 90, .absorb),
                line(76, 90, 199, 90, .absorb),
            ]
            obs += sideShields(180, 230)
            return Def(targetX: 130, obstacles: obs)

        case 38: // Lava serpentine — roofed zigzag between deadly shelves
            return Def(targetX: 130, obstacles: [
                line(60, 55, 199, 55),
                line(1, 90, 160, 90, .absorb),
                line(40, 130, 199, 130, .absorb),
                line(1, 170, 160, 170, .absorb),
            ])

        case 39: // Lava serpentine, mirrored
            return Def(targetX: 70, obstacles: [
                line(1, 55, 140, 55),
                line(40, 90, 199, 90, .absorb),
                line(1, 130, 160, 130, .absorb),
                line(40, 170, 199, 170, .absorb),
            ])

        case 40: // BOSS — lava serpentine, tightest weave
            return Def(targetX: 130, obstacles: [
                line(60, 55, 199, 55),
                line(1, 90, 165, 90, .absorb),
                line(35, 130, 199, 130, .absorb),
                line(1, 170, 165, 170, .absorb),
            ])

        // ═══════════════════════════════════════════
        // BAND 6 (41-50) — Mastery. Five-plus bounces,
        // everything combined, windows under 2°.
        // ═══════════════════════════════════════════

        case 41: // Wide-pocket periscope behind a high gate
            return Def(targetX: 100, obstacles: periscope() + pocket(76, 124) + [
                line(1, 105, 140, 105),
                line(178, 105, 199, 105),
            ])

        case 42: // Serpentine into the pocket
            return Def(targetX: 100, obstacles: periscope() + pocket(80, 120) + [
                line(1, 60, 150, 60),
                line(50, 105, 199, 105),
            ])

        case 43: // Pocket narrows
            return Def(targetX: 100, obstacles: periscope() + pocket(80, 120) + [
                line(1, 105, 140, 105),
                line(176, 105, 199, 105),
            ])

        case 44: // Gate narrows
            return Def(targetX: 100, obstacles: periscope() + pocket(80, 120) + [
                line(1, 105, 143, 105),
                line(173, 105, 199, 105),
            ])

        case 45: // Razor gate
            return Def(targetX: 100, obstacles: periscope() + pocket(80, 120) + [
                line(1, 105, 146, 105),
                line(170, 105, 199, 105),
            ])

        case 46: // Shields up — the easy wall lanes burn
            var obs: [Obstacle] = periscope() + pocket(80, 120) + [
                line(1, 105, 146, 105),
                line(170, 105, 199, 105),
            ]
            obs += sideShields(170, 225)
            return Def(targetX: 100, obstacles: obs)

        case 47: // The gate turns deadly
            return Def(targetX: 100, obstacles: periscope() + pocket(80, 120) + [
                line(1, 105, 143, 105, .absorb),
                line(173, 105, 199, 105, .absorb),
            ])

        case 48: // Narrow pocket, deadly gate
            return Def(targetX: 100, obstacles: periscope() + pocket(84, 116) + [
                line(1, 105, 146, 105, .absorb),
                line(170, 105, 199, 105, .absorb),
            ])

        case 49: // Everything tightens
            var obs: [Obstacle] = periscope() + pocket(84, 116) + [
                line(1, 105, 147, 105, .absorb),
                line(171, 105, 199, 105, .absorb),
            ]
            obs += sideShields(175, 225)
            return Def(targetX: 100, obstacles: obs)

        case 50: // FINALE — gate, panel, pocket, shields. Everything at once.
            var obs: [Obstacle] = periscope() + pocket(80, 120) + [
                line(1, 105, 148, 105, .absorb),
                line(170, 105, 199, 105, .absorb),
            ]
            obs += sideShields(170, 225)
            return Def(targetX: 100, obstacles: obs)

        default:
            return Def(targetX: 100, obstacles: [])
        }
    }
}
