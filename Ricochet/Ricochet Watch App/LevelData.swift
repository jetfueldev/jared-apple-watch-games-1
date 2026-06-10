import CoreGraphics

// Scene: 200w × 240h. Target y: 188. Ship: (100, 28).
// Side walls at x=0 and x=200 always ricochet. Top/bottom are void.
// Side shields (absorb walls at x=5/195) block easy wall-bounce bypasses.

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

    private static func star(cx: CGFloat, cy: CGFloat, outerR: CGFloat, innerR: CGFloat,
                             points: Int = 5, skip: Set<Int> = [],
                             _ type: ObstacleType = .ricochet) -> [Obstacle] {
        var out: [Obstacle] = []
        let total = points * 2
        for i in 0..<total {
            if skip.contains(i) { continue }
            let a1 = CGFloat(i) / CGFloat(total) * 2 * .pi - .pi / 2
            let a2 = CGFloat(i + 1) / CGFloat(total) * 2 * .pi - .pi / 2
            let r1: CGFloat = (i % 2 == 0) ? outerR : innerR
            let r2: CGFloat = ((i + 1) % 2 == 0) ? outerR : innerR
            out.append(Obstacle(
                from: CGPoint(x: cx + r1 * cos(a1), y: cy + r1 * sin(a1)),
                to: CGPoint(x: cx + r2 * cos(a2), y: cy + r2 * sin(a2)),
                type: type
            ))
        }
        return out
    }

    private static func heart(cx: CGFloat, cy: CGFloat, size: CGFloat,
                              segs: Int = 24, skip: Set<Int> = [],
                              _ type: ObstacleType = .ricochet) -> [Obstacle] {
        var pts: [CGPoint] = []
        for i in 0..<segs {
            let t = CGFloat(i) / CGFloat(segs) * 2 * .pi
            let x = 16 * pow(sin(t), 3)
            let y = 13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)
            let s = size / 34
            pts.append(CGPoint(x: cx + x * s, y: cy + y * s))
        }
        var out: [Obstacle] = []
        for i in 0..<segs {
            if skip.contains(i) { continue }
            out.append(Obstacle(from: pts[i], to: pts[(i + 1) % segs], type: type))
        }
        return out
    }

    private static func spiral(cx: CGFloat, cy: CGFloat,
                               startR: CGFloat, endR: CGFloat,
                               turns: CGFloat, startAngle: CGFloat = 0,
                               segs: Int = 30, skip: Set<Int> = [],
                               _ type: ObstacleType = .ricochet) -> [Obstacle] {
        var out: [Obstacle] = []
        let totalAngle = turns * 2 * .pi
        for i in 0..<segs {
            if skip.contains(i) { continue }
            let t1 = CGFloat(i) / CGFloat(segs)
            let t2 = CGFloat(i + 1) / CGFloat(segs)
            let a1 = startAngle + totalAngle * t1
            let a2 = startAngle + totalAngle * t2
            let r1 = startR + (endR - startR) * t1
            let r2 = startR + (endR - startR) * t2
            out.append(Obstacle(
                from: CGPoint(x: cx + r1 * cos(a1), y: cy + r1 * sin(a1)),
                to: CGPoint(x: cx + r2 * cos(a2), y: cy + r2 * sin(a2)),
                type: type
            ))
        }
        return out
    }

    private static func ellipse(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat,
                                gapAngle: CGFloat = -.pi / 2, gapSize: CGFloat = .pi / 3,
                                segs: Int = 18, _ type: ObstacleType = .ricochet) -> [Obstacle] {
        var out: [Obstacle] = []
        let start = gapAngle + gapSize / 2
        let end = gapAngle + 2 * .pi - gapSize / 2
        let step = (end - start) / CGFloat(segs)
        for i in 0..<segs {
            let a1 = start + step * CGFloat(i)
            let a2 = start + step * CGFloat(i + 1)
            out.append(Obstacle(
                from: CGPoint(x: cx + rx * cos(a1), y: cy + ry * sin(a1)),
                to: CGPoint(x: cx + rx * cos(a2), y: cy + ry * sin(a2)),
                type: type
            ))
        }
        return out
    }

    // MARK: - Blocking Helpers

    private static func sideShields(_ y1: CGFloat, _ y2: CGFloat) -> [Obstacle] {
        [line(5, y1, 5, y2, .absorb), line(195, y1, 195, y2, .absorb)]
    }

    // MARK: - 50 Levels

    static func build(level n: Int) -> Def {
        switch n {

        // ═══════════════════════════════════════════
        // ZONE 1: EARTH 🌍 (1-10) — Learn to aim
        // Skill: Crown precision. Direct shots allowed,
        // windows narrow from ~11° to ~4°. L10 previews banks.
        // ═══════════════════════════════════════════

        case 1: // Open sky — fire straight up
            return Def(targetX: 100, obstacles: [])

        case 2: // Offset — learn Crown aiming
            return Def(targetX: 152, obstacles: [])

        case 3: // First gate — thread the gap
            return Def(targetX: 100, obstacles: [
                line(1, 112, 94, 112),
                line(106, 112, 199, 112),
            ])

        case 4: // Offset gate — gap and target both off-center
            return Def(targetX: 47, obstacles: [
                line(1, 118, 64, 118),
                line(76, 118, 199, 118),
            ])

        case 5: // Narrow gate — tighter thread
            return Def(targetX: 100, obstacles: [
                line(1, 130, 95, 130),
                line(105, 130, 199, 130),
            ])

        case 6: // Double gate — align ship, two gaps, target on one line
            return Def(targetX: 67, obstacles: [
                line(1, 100, 77, 100),
                line(93, 100, 199, 100),
                line(1, 150, 69, 150),
                line(81, 150, 199, 150),
            ])

        case 7: // Funnel — angled walls guide the shot to a slot
            return Def(targetX: 100, obstacles: [
                line(35, 95, 94, 148),
                line(165, 95, 106, 148),
            ])

        case 8: // Breather — open chamber around the target
            var obs: [Obstacle] = []
            obs += ring(cx: 100, cy: 188, r: 34, gapAngle: -.pi / 2, gapSize: .pi / 2.2, segs: 16)
            return Def(targetX: 100, obstacles: obs)

        case 9: // Precision — tiny gate, target on the diagonal
            return Def(targetX: 150, obstacles: [
                line(1, 140, 130, 140),
                line(140, 140, 199, 140),
            ])

        case 10: // BOSS — shelf blocks the sky, bank off the left wall
            return Def(targetX: 100, obstacles: [
                line(50, 160, 199, 160),
            ])

        // ═══════════════════════════════════════════
        // ZONE 2: MOON 🌙 (11-20) — The bank shot
        // Skill: bounce off side walls. Direct path is
        // always blocked; the wall is the way.
        // ═══════════════════════════════════════════

        case 11: // Teach — wide roof, bank off either wall
            return Def(targetX: 100, obstacles: [
                line(40, 80, 160, 80),
            ])

        case 12: // One way only — roof seals the right, bank left
            return Def(targetX: 140, obstacles: [
                line(30, 90, 165, 90),
            ])

        case 13: // High gap — bank through the left slot
            return Def(targetX: 100, obstacles: [
                line(55, 140, 199, 140),
            ])

        case 14: // Mirror — bank right through the high slot
            return Def(targetX: 60, obstacles: [
                line(1, 120, 150, 120),
            ])

        case 15: // Bank + thread — bounce left, then through the gate
            return Def(targetX: 100, obstacles: [
                line(42, 80, 199, 80),
                line(1, 150, 44, 150),
                line(61, 150, 199, 150),
            ])

        case 16: // Bank + thread, mirrored and tighter
            return Def(targetX: 100, obstacles: [
                line(1, 80, 158, 80),
                line(1, 150, 140, 150),
                line(156, 150, 199, 150),
            ])

        case 17: // Double bank — wall to wall to target
            return Def(targetX: 100, obstacles: [
                line(42, 158, 158, 158),
            ])

        case 18: // Breather — easy bank, either side
            return Def(targetX: 100, obstacles: [
                line(35, 85, 165, 85),
            ])

        case 19: // Precision bank — tiny slot on the left
            return Def(targetX: 100, obstacles: [
                line(1, 140, 30, 140),
                line(42, 140, 199, 140),
            ])

        case 20: // BOSS — double bank threading a mid-air gate
            return Def(targetX: 100, obstacles: [
                line(50, 158, 150, 158),
                line(1, 110, 95, 110),
                line(115, 110, 199, 110),
            ])

        // ═══════════════════════════════════════════
        // ZONE 3: STAR ⭐ (21-30) — Deflector panels
        // Skill: ricochet off angled obstacles. 45° panels
        // redirect shots sideways and even downward.
        // ═══════════════════════════════════════════

        case 21: // Teach — panel up top deflects the shot left into the target
            return Def(targetX: 60, obstacles: [
                line(1, 160, 110, 160),
                line(130, 225, 175, 180),
            ])

        case 22: // Mirror — climb the left side, deflect right
            return Def(targetX: 140, obstacles: [
                line(90, 160, 199, 160),
                line(30, 185, 62, 217),
            ])

        case 23: // Periscope — two panels, hit the target from above
            return Def(targetX: 100, obstacles: [
                line(40, 160, 160, 160),
                line(150, 222, 180, 192),
                line(85, 200, 115, 230),
            ])

        case 24: // Bumper — bank off a floating wall, not the screen edge
            return Def(targetX: 130, obstacles: [
                line(60, 75, 60, 165),
                line(80, 165, 199, 165),
            ])

        case 25: // Panel + gate — thread the gate on the way up
            return Def(targetX: 60, obstacles: [
                line(1, 160, 110, 160),
                line(130, 225, 175, 180),
                line(1, 120, 156, 120),
                line(172, 120, 199, 120),
            ])

        case 26: // Pocket drop — periscope into a walled pocket
            return Def(targetX: 100, obstacles: [
                line(40, 160, 160, 160),
                line(150, 222, 180, 192),
                line(85, 200, 115, 230),
                line(80, 170, 80, 198),
                line(120, 170, 120, 198),
            ])

        case 27: // Bumper + gate — combine the bank with a thread
            return Def(targetX: 130, obstacles: [
                line(60, 75, 60, 165),
                line(80, 165, 199, 165),
                line(1, 90, 50, 90),
                line(76, 90, 199, 90),
            ])

        case 28: // Breather — one big friendly panel
            return Def(targetX: 100, obstacles: [
                line(1, 158, 128, 158),
                line(140, 230, 185, 185),
            ])

        case 29: // Precision — narrow climb, tight deflect
            return Def(targetX: 140, obstacles: [
                line(90, 160, 199, 160),
                line(30, 185, 62, 217),
                line(1, 120, 30, 120),
                line(44, 120, 199, 120),
            ])

        case 30: // BOSS — periscope drop through a high gate
            return Def(targetX: 100, obstacles: [
                line(40, 160, 160, 160),
                line(150, 222, 180, 192),
                line(85, 200, 115, 230),
                line(1, 105, 150, 105),
                line(168, 105, 199, 105),
            ])

        // ═══════════════════════════════════════════
        // ZONE 4: PLANET 🪐 (31-40) — Complex shapes
        // ═══════════════════════════════════════════

        case 31: // Teach — the gate is deadly now. Thread it clean.
            return Def(targetX: 100, obstacles: [
                line(1, 130, 92, 130, .absorb),
                line(108, 130, 199, 130, .absorb),
            ])

        case 32: // Lava funnel — converging absorb walls
            return Def(targetX: 100, obstacles: [
                line(40, 170, 94, 110, .absorb),
                line(160, 170, 106, 110, .absorb),
            ])

        case 33: // Bank over lava — direct shots burn
            return Def(targetX: 100, obstacles: [
                line(30, 120, 199, 120, .absorb),
            ])

        case 34: // Stacked gates — the high one is deadly
            return Def(targetX: 67, obstacles: [
                line(1, 100, 77, 100),
                line(93, 100, 199, 100),
                line(1, 150, 69, 150, .absorb),
                line(81, 150, 199, 150, .absorb),
            ])

        case 35: // Bank + lava gate
            return Def(targetX: 100, obstacles: [
                line(42, 80, 199, 80),
                line(1, 150, 44, 150, .absorb),
                line(61, 150, 199, 150, .absorb),
            ])

        case 36: // Approach angle — shielded target, door faces down-left
            var obs: [Obstacle] = []
            obs += ring(cx: 100, cy: 188, r: 30, gapAngle: -.pi * 0.8, gapSize: .pi / 3.6, segs: 16, .absorb)
            return Def(targetX: 100, obstacles: obs)

        case 37: // Lava ladder — bank threading two deadly gates
            return Def(targetX: 100, obstacles: [
                line(42, 80, 199, 80),
                line(1, 130, 20, 130, .absorb),
                line(36, 130, 199, 130, .absorb),
                line(1, 160, 57, 160, .absorb),
                line(73, 160, 199, 160, .absorb),
            ])

        case 38: // Breather — wide lava gate
            return Def(targetX: 100, obstacles: [
                line(1, 130, 70, 130, .absorb),
                line(130, 130, 199, 130, .absorb),
            ])

        case 39: // Precision — deadly diagonal thread
            return Def(targetX: 150, obstacles: [
                line(1, 140, 130, 140, .absorb),
                line(140, 140, 199, 140, .absorb),
            ])

        case 40: // BOSS — double bank through a lava gate
            var obs: [Obstacle] = [
                line(42, 158, 158, 158),
                line(1, 110, 95, 110, .absorb),
                line(115, 110, 199, 110, .absorb),
            ]
            obs += sideShields(170, 220)
            return Def(targetX: 100, obstacles: obs)

        // ═══════════════════════════════════════════
        // ZONE 5: SUN ☀️ (41-50) — Mastery
        // Skill: combine everything — banks, panels,
        // pockets, and lava in multi-bounce runs.
        // ═══════════════════════════════════════════

        case 41: // Corner pocket — climb the right edge, deflect home
            return Def(targetX: 60, obstacles: [
                line(1, 160, 160, 160),
                line(160, 225, 199, 186),
            ])

        case 42: // Bank to panel — the climb lane is sealed from below
            return Def(targetX: 60, obstacles: [
                line(1, 160, 110, 160),
                line(130, 225, 175, 180),
                line(110, 70, 199, 70),
            ])

        case 43: // Bank to periscope — three walls, one thread
            return Def(targetX: 100, obstacles: [
                line(40, 160, 160, 160),
                line(150, 222, 180, 192),
                line(85, 200, 115, 230),
                line(105, 65, 199, 65),
            ])

        case 44: // Double bank, double gate
            return Def(targetX: 100, obstacles: [
                line(42, 158, 158, 158),
                line(1, 60, 12, 60),
                line(28, 60, 199, 60),
                line(1, 110, 97, 110),
                line(113, 110, 199, 110),
            ])

        case 45: // Lava vault — bank under the shelf, panel finish
            return Def(targetX: 100, obstacles: [
                line(38, 120, 199, 120, .absorb),
                line(40, 165, 160, 165, .absorb),
                line(150, 235, 190, 195),
            ])

        case 46: // Razor — double bank through a deadly slot
            return Def(targetX: 100, obstacles: [
                line(42, 158, 158, 158),
                line(1, 110, 99, 110, .absorb),
                line(111, 110, 199, 110, .absorb),
                line(1, 60, 10, 60),
                line(30, 60, 199, 60),
            ])

        case 47: // Pocket periscope behind a high gate
            return Def(targetX: 100, obstacles: [
                line(40, 160, 160, 160),
                line(150, 222, 180, 192),
                line(85, 200, 115, 230),
                line(80, 170, 80, 198),
                line(120, 170, 120, 198),
                line(1, 105, 146, 105),
                line(170, 105, 199, 105),
            ])

        case 48: // Lava corner — the climb is deadly on both sides
            return Def(targetX: 60, obstacles: [
                line(1, 160, 165, 160, .absorb),
                line(160, 225, 199, 186),
                line(1, 120, 145, 120, .absorb),
            ])

        case 49: // Breather — pick your wall
            return Def(targetX: 75, obstacles: [
                line(40, 90, 160, 90),
            ])

        case 50: // FINALE — gate, wall, panel, drop. Everything at once.
            var obs: [Obstacle] = [
                line(40, 160, 160, 160),
                line(150, 222, 180, 192),
                line(85, 200, 115, 230),
                line(80, 170, 80, 198),
                line(120, 170, 120, 198),
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
