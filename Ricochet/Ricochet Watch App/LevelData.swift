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
        // ZONE 1: EARTH 🌍 (1-10) — Learn the basics
        // ═══════════════════════════════════════════

        case 1: // Tutorial — fire straight up
            return Def(targetX: 100, obstacles: [])

        case 2: // Offset — learn Crown aiming
            return Def(targetX: 145, obstacles: [])

        case 3: // First wall — learn bouncing off obstacles
            // Wide wall directly in the path, must angle around or bounce off it
            return Def(targetX: 100, obstacles: [
                line(30, 140, 170, 140),
            ])

        case 4: // V-funnel — converging walls force a precise angle
            return Def(targetX: 100, obstacles: [
                line(20, 100, 85, 160),
                line(180, 100, 115, 160),
            ])

        case 5: // 🌙 Crescent — arc blocks center, must thread through opening
            var obs: [Obstacle] = []
            obs += arc(cx: 100, cy: 143, r: 40, from: .pi * 0.2, to: .pi * 0.85, segs: 14)
            obs += sideShields(105, 175)
            return Def(targetX: 100, obstacles: obs)

        case 6: // ⭕ Ring — gap at bottom, thread up through it
            var obs: [Obstacle] = []
            obs += ring(cx: 100, cy: 148, r: 35, gapAngle: -.pi / 2, gapSize: .pi / 2.5)
            obs += sideShields(110, 175)
            return Def(targetX: 100, obstacles: obs)

        case 7: // ⭕ Ring — gap on right, must bounce to enter
            var obs: [Obstacle] = []
            obs += ring(cx: 95, cy: 143, r: 35, gapAngle: 0, gapSize: .pi / 3)
            obs += sideShields(105, 175)
            return Def(targetX: 80, obstacles: obs)

        case 8: // ⚡ Lightning — zigzag blocks direct path
            var obs: [Obstacle] = []
            obs.append(line(25, 105, 130, 105))
            obs.append(line(130, 105, 80, 135))
            obs.append(line(80, 135, 175, 135))
            obs.append(line(175, 135, 100, 165))
            obs.append(line(100, 165, 180, 165))
            obs += sideShields(95, 175)
            return Def(targetX: 100, obstacles: obs)

        case 9: // ⭐ Star — target inside, enter through missing edge
            var obs: [Obstacle] = []
            obs += star(cx: 100, cy: 143, outerR: 44, innerR: 20, points: 5, skip: [5, 6])
            obs += sideShields(98, 175)
            return Def(targetX: 100, obstacles: obs)

        case 10: // 🪐 Saturn — inner ring + tilted ellipse ring
            var obs: [Obstacle] = []
            obs += ring(cx: 100, cy: 148, r: 18, gapAngle: -.pi / 2, gapSize: .pi / 2, segs: 12)
            obs += ellipse(cx: 100, cy: 148, rx: 55, ry: 20,
                          gapAngle: -.pi * 0.4, gapSize: .pi / 2, segs: 14)
            obs += sideShields(100, 175)
            return Def(targetX: 100, obstacles: obs)

        // ═══════════════════════════════════════════
        // ZONE 2: MOON 🌙 (11-20) — Space shapes
        // ═══════════════════════════════════════════

        case 11: // 🚀 Rocket — body blocks center, enter through exhaust
            var obs: [Obstacle] = []
            obs.append(line(100, 175, 70, 145))         // nose left
            obs.append(line(100, 175, 130, 145))         // nose right
            obs.append(line(70, 145, 70, 95))            // body left
            obs.append(line(130, 145, 130, 95))          // body right
            obs.append(line(70, 95, 55, 73))             // fin left
            obs.append(line(130, 95, 145, 73))           // fin right
            obs += sideShields(70, 175)
            return Def(targetX: 100, obstacles: obs)

        case 12: // 🛸 UFO — dome + disc blocks path, gap in disc center
            var obs: [Obstacle] = []
            obs += arc(cx: 100, cy: 148, r: 30, from: 0, to: .pi, segs: 10) // dome
            obs.append(line(35, 148, 70, 148))    // disc left
            obs.append(line(130, 148, 165, 148))  // disc right (gap in middle)
            obs.append(line(35, 138, 35, 148))    // disc edge left
            obs.append(line(165, 138, 165, 148))  // disc edge right
            obs.append(line(35, 138, 55, 138))    // bottom rim left
            obs.append(line(145, 138, 165, 138))  // bottom rim right
            obs += sideShields(100, 175)
            return Def(targetX: 100, obstacles: obs)

        case 13: // ☄️ Comet — head near target, must navigate through tail gap
            var obs: [Obstacle] = []
            obs += arc(cx: 130, cy: 155, r: 24, from: -.pi * 0.3, to: .pi * 1.3, segs: 10)
            obs.append(line(130, 131, 40, 95))    // tail upper
            obs.append(line(130, 131, 50, 80))    // tail lower
            obs += sideShields(75, 175)
            return Def(targetX: 120, obstacles: obs)

        case 14: // 🌍 Planet — concentric rings with staggered gaps
            var obs: [Obstacle] = []
            obs += ring(cx: 100, cy: 148, r: 25, gapAngle: -.pi / 2, gapSize: .pi / 2.5, segs: 14)
            obs += ring(cx: 100, cy: 148, r: 45, gapAngle: .pi / 2, gapSize: .pi / 3, segs: 18)
            obs += sideShields(100, 175)
            return Def(targetX: 100, obstacles: obs)

        case 15: // ✨ Constellation — three small rings connected by lines
            var obs: [Obstacle] = []
            obs += ring(cx: 55, cy: 108, r: 18, gapAngle: .pi * 0.3, gapSize: .pi / 2, segs: 10)
            obs += ring(cx: 140, cy: 135, r: 18, gapAngle: .pi, gapSize: .pi / 2, segs: 10)
            obs += ring(cx: 80, cy: 165, r: 18, gapAngle: -.pi / 3, gapSize: .pi / 2, segs: 10)
            obs.append(line(73, 108, 122, 135))
            obs.append(line(122, 135, 80, 147))
            obs += sideShields(88, 175)
            return Def(targetX: 100, obstacles: obs)

        case 16: // 🌀 Galaxy — double spiral arms
            var obs: [Obstacle] = []
            obs += spiral(cx: 100, cy: 143, startR: 48, endR: 12,
                         turns: 1.0, startAngle: 0, segs: 22, skip: [0, 21])
            obs += spiral(cx: 100, cy: 143, startR: 48, endR: 12,
                         turns: 1.0, startAngle: .pi, segs: 22, skip: [0, 21])
            obs += sideShields(93, 175)
            return Def(targetX: 100, obstacles: obs)

        case 17: // 🔭 Telescope — two circles connected by tube corridor
            var obs: [Obstacle] = []
            obs += ring(cx: 60, cy: 113, r: 22, gapAngle: 0, gapSize: .pi / 2, segs: 12)
            obs += ring(cx: 145, cy: 158, r: 18, gapAngle: .pi, gapSize: .pi / 2, segs: 10)
            obs.append(line(82, 113, 127, 158))   // tube top
            obs.append(line(60, 91, 145, 140))    // tube bottom
            obs += sideShields(88, 175)
            return Def(targetX: 80, obstacles: obs)

        case 18: // 🌑 Eclipse — overlapping arcs with narrow passage
            var obs: [Obstacle] = []
            obs += arc(cx: 82, cy: 143, r: 40, from: -.pi * 0.3, to: .pi * 1.3, segs: 12)
            obs += arc(cx: 118, cy: 143, r: 40, from: .pi * 0.7 - .pi, to: .pi * 0.3, segs: 12)
            obs += sideShields(100, 175)
            return Def(targetX: 100, obstacles: obs)

        case 19: // 🕳️ Wormhole — two rings connected by narrow corridor
            var obs: [Obstacle] = []
            obs += ring(cx: 55, cy: 108, r: 22, gapAngle: 0, gapSize: .pi / 2.5, segs: 12)
            obs += ring(cx: 145, cy: 158, r: 22, gapAngle: .pi, gapSize: .pi / 2.5, segs: 12)
            obs.append(line(77, 108, 123, 158))   // corridor wall top
            obs.append(line(55, 86, 145, 136))    // corridor wall bottom
            obs += sideShields(82, 175)
            return Def(targetX: 75, obstacles: obs)

        case 20: // 🎯 Bullseye — three concentric rings, staggered gaps
            var obs: [Obstacle] = []
            obs += ring(cx: 100, cy: 143, r: 18, gapAngle: .pi / 2, gapSize: .pi / 2, segs: 10)
            obs += ring(cx: 100, cy: 143, r: 35, gapAngle: -.pi / 2, gapSize: .pi / 3, segs: 14)
            obs += ring(cx: 100, cy: 143, r: 52, gapAngle: .pi * 0.8, gapSize: .pi / 3, segs: 18)
            obs += sideShields(88, 175)
            return Def(targetX: 100, obstacles: obs)

        // ═══════════════════════════════════════════
        // ZONE 3: STAR ⭐ (21-30) — Food shapes + absorb
        // ═══════════════════════════════════════════

        case 21: // 🍩 Donut — absorb outer ring, navigate through the hole
            var obs: [Obstacle] = []
            obs += ring(cx: 100, cy: 143, r: 42, gapAngle: -.pi / 2, gapSize: .pi / 3, .absorb)
            obs += ring(cx: 100, cy: 143, r: 18, gapAngle: .pi / 2, gapSize: .pi / 2)
            obs += sideShields(98, 175)
            return Def(targetX: 100, obstacles: obs)

        case 22: // 🍕 Pizza slice — triangle with curved crust
            var obs: [Obstacle] = []
            obs.append(line(100, 85, 40, 170))                // left edge
            obs.append(line(100, 85, 160, 170))               // right edge
            obs += arc(cx: 100, cy: 170, r: 60, from: .pi * 1.05, to: .pi * 1.95, segs: 10)
            obs += sideShields(80, 175)
            return Def(targetX: 100, obstacles: obs)

        case 23: // 🍔 Burger — stacked arcs block center path
            var obs: [Obstacle] = []
            obs += arc(cx: 100, cy: 168, r: 48, from: 0, to: .pi, segs: 10)       // top bun
            obs += arc(cx: 100, cy: 100, r: 48, from: .pi, to: 2 * .pi, segs: 10) // bottom bun
            obs.append(line(55, 143, 145, 143, .absorb))  // patty (absorb)
            obs.append(line(52, 128, 90, 128))             // lettuce left
            obs.append(line(110, 128, 148, 128))           // lettuce right (gap)
            obs += sideShields(92, 175)
            return Def(targetX: 100, obstacles: obs)

        case 24: // 🍦 Ice cream cone — cone + dome scoop blocks path
            var obs: [Obstacle] = []
            obs.append(line(100, 80, 55, 145))               // cone left
            obs.append(line(100, 80, 145, 145))              // cone right
            obs += arc(cx: 100, cy: 160, r: 45, from: .pi * 0.05, to: .pi * 0.95, segs: 10) // scoop
            obs += sideShields(75, 175)
            return Def(targetX: 100, obstacles: obs)

        case 25: // 🌮 Taco — U-shaped shell blocks center
            var obs: [Obstacle] = []
            obs += arc(cx: 100, cy: 150, r: 48, from: .pi * 1.15, to: .pi * 1.85, segs: 12)
            obs.append(line(60, 110, 90, 110, .absorb))       // filling left
            obs.append(line(110, 110, 140, 110, .absorb))      // filling right (gap center)
            obs += sideShields(95, 175)
            return Def(targetX: 100, obstacles: obs)

        case 26: // 🧁 Cupcake — dome + wrapper blocks path
            var obs: [Obstacle] = []
            obs += arc(cx: 100, cy: 153, r: 35, from: 0, to: .pi, segs: 10) // frosting dome
            obs.append(line(65, 153, 50, 100))                 // wrapper left
            obs.append(line(135, 153, 150, 100))               // wrapper right
            obs.append(line(50, 100, 68, 100))                 // bottom left
            obs.append(line(132, 100, 150, 100))               // bottom right (gap)
            obs += sideShields(92, 175)
            return Def(targetX: 100, obstacles: obs)

        case 27: // 🥨 Pretzel — figure-8 with absorb crossings
            var obs: [Obstacle] = []
            obs += ring(cx: 70, cy: 125, r: 28, gapAngle: .pi * 0.3, gapSize: .pi / 2.5)
            obs += ring(cx: 130, cy: 155, r: 28, gapAngle: .pi * 1.3, gapSize: .pi / 2.5)
            obs.append(line(90, 107, 110, 137, .absorb))      // crossing
            obs.append(line(90, 143, 110, 173, .absorb))       // crossing
            obs += sideShields(95, 175)
            return Def(targetX: 100, obstacles: obs)

        case 28: // 🍎 Apple — absorb ring blocks center, stem + leaf above
            var obs: [Obstacle] = []
            obs += ring(cx: 100, cy: 140, r: 40, gapAngle: .pi / 2, gapSize: .pi / 3, .absorb)
            obs.append(line(100, 175, 100, 180))              // stem
            obs += arc(cx: 115, cy: 175, r: 18, from: .pi * 0.5, to: .pi * 1.1, segs: 5)
            obs += sideShields(97, 175)
            return Def(targetX: 100, obstacles: obs)

        case 29: // 🍬 Candy — oval with absorb wrapper ends block sides
            var obs: [Obstacle] = []
            obs += ellipse(cx: 100, cy: 140, rx: 42, ry: 28,
                          gapAngle: -.pi / 2, gapSize: .pi / 3)
            obs.append(line(58, 140, 30, 155, .absorb))       // wrapper left top
            obs.append(line(58, 140, 30, 125, .absorb))       // wrapper left bottom
            obs.append(line(142, 140, 170, 155, .absorb))     // wrapper right top
            obs.append(line(142, 140, 170, 125, .absorb))     // wrapper right bottom
            obs += sideShields(100, 175)
            return Def(targetX: 100, obstacles: obs)

        case 30: // 🥚 Cosmic egg — absorb shell with crack opening
            var obs: [Obstacle] = []
            obs += ellipse(cx: 100, cy: 143, rx: 38, ry: 50,
                          gapAngle: -.pi * 0.45, gapSize: .pi / 3, .absorb)
            obs.append(line(73, 107, 83, 113))                 // crack detail
            obs.append(line(83, 113, 76, 120))                 // crack detail
            obs += sideShields(90, 175)
            return Def(targetX: 100, obstacles: obs)

        // ═══════════════════════════════════════════
        // ZONE 4: PLANET 🪐 (31-40) — Complex shapes
        // ═══════════════════════════════════════════

        case 31: // ❤️ Heart — parametric heart, gap at bottom point
            var obs: [Obstacle] = []
            obs += heart(cx: 100, cy: 145, size: 72, segs: 24, skip: [11, 12, 13])
            obs += sideShields(100, 175)
            return Def(targetX: 100, obstacles: obs)

        case 32: // 💎 Diamond — faceted gem with absorb outer facets
            var obs: [Obstacle] = []
            obs.append(line(100, 175, 60, 145))          // top left facet
            obs.append(line(100, 175, 140, 145))         // top right facet
            obs.append(line(60, 145, 50, 125, .absorb))  // upper left absorb
            obs.append(line(140, 145, 150, 125, .absorb)) // upper right absorb
            obs.append(line(50, 125, 75, 88))            // lower left
            obs.append(line(150, 125, 125, 88))          // lower right
            obs.append(line(75, 88, 100, 125))           // inner left
            obs.append(line(125, 88, 100, 125))          // inner right
            obs += sideShields(82, 175)
            return Def(targetX: 100, obstacles: obs)

        case 33: // ⚓ Anchor — cross + absorb curved hooks block sides
            var obs: [Obstacle] = []
            obs.append(line(100, 175, 100, 118))              // vertical shaft
            obs.append(line(75, 160, 125, 160))               // crossbar
            obs += arc(cx: 70, cy: 108, r: 22, from: -.pi / 2, to: .pi / 2, segs: 8, .absorb)
            obs += arc(cx: 130, cy: 108, r: 22, from: .pi / 2, to: .pi * 1.5, segs: 8, .absorb)
            obs += sideShields(85, 175)
            return Def(targetX: 100, obstacles: obs)

        case 34: // 👑 Crown — zigzag points, absorb base blocks bottom
            var obs: [Obstacle] = []
            obs.append(line(35, 118, 35, 168))           // left wall
            obs.append(line(165, 118, 165, 168))         // right wall
            obs.append(line(35, 118, 68, 158))           // point 1 up
            obs.append(line(68, 158, 100, 118))          // point 1 down
            obs.append(line(100, 118, 132, 158))         // point 2 up
            obs.append(line(132, 158, 165, 118))         // point 2 down
            obs.append(line(35, 168, 80, 168, .absorb))  // base left absorb
            obs.append(line(120, 168, 165, 168, .absorb)) // base right absorb (gap center)
            obs += sideShields(100, 175)
            return Def(targetX: 100, obstacles: obs)

        case 35: // ☯️ Yin-yang — interlocking arcs with absorb inner
            var obs: [Obstacle] = []
            obs += arc(cx: 100, cy: 140, r: 44, from: .pi / 2, to: .pi * 1.5, segs: 10)
            obs += arc(cx: 100, cy: 140, r: 44, from: -.pi / 2, to: .pi / 2, segs: 10)
            obs += arc(cx: 100, cy: 162, r: 22, from: -.pi / 2, to: .pi / 2, segs: 7, .absorb)
            obs += arc(cx: 100, cy: 118, r: 22, from: .pi / 2, to: .pi * 1.5, segs: 7)
            obs += sideShields(93, 175)
            return Def(targetX: 100, obstacles: obs)

        case 36: // ∞ Infinity — figure-8, absorb right loop
            var obs: [Obstacle] = []
            obs += ring(cx: 65, cy: 140, r: 32, gapAngle: 0, gapSize: .pi / 2.5)
            obs += ring(cx: 135, cy: 140, r: 32, gapAngle: .pi, gapSize: .pi / 2.5, segs: 18, .absorb)
            obs += sideShields(105, 175)
            return Def(targetX: 100, obstacles: obs)

        case 37: // 🦋 Butterfly — wing arcs + absorb body divider
            var obs: [Obstacle] = []
            obs += arc(cx: 55, cy: 140, r: 38, from: .pi * 0.2, to: .pi * 1.8, segs: 12)
            obs += arc(cx: 145, cy: 140, r: 38, from: -.pi * 0.8, to: .pi * 0.8, segs: 12)
            obs.append(line(98, 100, 98, 175, .absorb))  // body left
            obs.append(line(102, 100, 102, 175, .absorb)) // body right
            obs += sideShields(100, 175)
            return Def(targetX: 100, obstacles: obs)

        case 38: // 🛡️ Shield crest — oval + absorb cross interior
            var obs: [Obstacle] = []
            obs += ellipse(cx: 100, cy: 140, rx: 42, ry: 52,
                          gapAngle: .pi / 2, gapSize: .pi / 3)
            obs.append(line(62, 140, 138, 140, .absorb))     // horizontal cross
            obs.append(line(100, 100, 100, 172, .absorb))    // vertical cross
            obs += sideShields(85, 175)
            return Def(targetX: 100, obstacles: obs)

        case 39: // ❄️ Snowflake — 6-fold radial pattern
            var obs: [Obstacle] = []
            for i in 0..<6 {
                if i == 0 { continue }
                let angle = CGFloat(i) / 6 * 2 * .pi - .pi / 2
                let x1 = 100 + 12 * cos(angle)
                let y1 = 140 + 12 * sin(angle)
                let x2 = 100 + 48 * cos(angle)
                let y2 = 140 + 48 * sin(angle)
                let t: ObstacleType = (i == 3) ? .absorb : .ricochet
                obs.append(line(x1, y1, x2, y2, t))
                let bx = 100 + 32 * cos(angle)
                let by = 140 + 32 * sin(angle)
                let perpA = angle + .pi / 2
                obs.append(line(bx + 10 * cos(perpA), by + 10 * sin(perpA),
                               bx - 10 * cos(perpA), by - 10 * sin(perpA), t))
            }
            obs += sideShields(90, 175)
            return Def(targetX: 100, obstacles: obs)

        case 40: // 🐚 Nautilus shell — golden spiral
            var obs: [Obstacle] = []
            obs += spiral(cx: 100, cy: 140, startR: 52, endR: 8,
                         turns: 1.8, startAngle: -.pi / 2, segs: 40, skip: [0, 1, 38, 39])
            obs += sideShields(85, 175)
            return Def(targetX: 100, obstacles: obs)

        // ═══════════════════════════════════════════
        // ZONE 5: SUN ☀️ (41-50) — Master challenges
        // ═══════════════════════════════════════════

        case 41: // ⚙️ Clockwork — absorb inner ring + outer ring + spokes
            var obs: [Obstacle] = []
            obs += ring(cx: 100, cy: 140, r: 22, gapAngle: .pi * 0.7, gapSize: .pi / 3, segs: 12, .absorb)
            obs += ring(cx: 100, cy: 140, r: 44, gapAngle: -.pi / 3, gapSize: .pi / 3.5)
            obs.append(line(100, 78, 100, 118))   // spoke bottom
            obs.append(line(56, 140, 78, 140))    // spoke left
            obs.append(line(122, 140, 144, 140))  // spoke right
            obs += sideShields(75, 175)
            return Def(targetX: 100, obstacles: obs)

        case 42: // 🧬 DNA helix — double spiral with absorb rungs
            var obs: [Obstacle] = []
            obs += spiral(cx: 100, cy: 140, startR: 38, endR: 38,
                         turns: 1.5, startAngle: 0, segs: 30, skip: [0, 14, 15, 29])
            obs += spiral(cx: 100, cy: 140, startR: 38, endR: 38,
                         turns: 1.5, startAngle: .pi, segs: 30, skip: [0, 14, 15, 29])
            for i in stride(from: 0, to: 30, by: 6) {
                let t = CGFloat(i) / 30
                let a = 1.5 * 2 * .pi * t
                let x1 = 100 + 38 * cos(a)
                let y1 = 140 + 38 * sin(a)
                let x2 = 100 + 38 * cos(a + .pi)
                let y2 = 140 + 38 * sin(a + .pi)
                obs.append(line(x1, y1, x2, y2, .absorb))
            }
            obs += sideShields(100, 175)
            return Def(targetX: 100, obstacles: obs)

        case 43: // 🌪️ Tight maze spiral — absorb spiral with narrow gaps
            var obs: [Obstacle] = []
            obs += spiral(cx: 100, cy: 140, startR: 55, endR: 10,
                         turns: 2.0, startAngle: -.pi / 2, segs: 48,
                         skip: [0, 1, 11, 12, 23, 24, 35, 36, 46, 47], .absorb)
            obs += sideShields(82, 175)
            return Def(targetX: 100, obstacles: obs)

        case 44: // 🔗 Chain links — three interlocking rings
            var obs: [Obstacle] = []
            obs += ring(cx: 60, cy: 112, r: 28, gapAngle: 0, gapSize: .pi / 2.5, segs: 14, .absorb)
            obs += ring(cx: 100, cy: 140, r: 28, gapAngle: .pi, gapSize: .pi / 2.5)
            obs += ring(cx: 140, cy: 165, r: 28, gapAngle: 0, gapSize: .pi / 2.5, segs: 14, .absorb)
            obs += sideShields(82, 175)
            return Def(targetX: 100, obstacles: obs)

        case 45: // ⚛️ Atom — absorb nucleus + two electron orbit ellipses
            var obs: [Obstacle] = []
            obs += ring(cx: 100, cy: 140, r: 14, gapAngle: -.pi / 2, gapSize: .pi / 2, segs: 10, .absorb)
            obs += ellipse(cx: 100, cy: 140, rx: 52, ry: 25,
                          gapAngle: -.pi * 0.4, gapSize: .pi / 3)
            obs += ellipse(cx: 100, cy: 140, rx: 25, ry: 52,
                          gapAngle: .pi * 0.6, gapSize: .pi / 3)
            obs += sideShields(85, 175)
            return Def(targetX: 100, obstacles: obs)

        case 46: // 🐉 Serpent — S-curve body with absorb scales
            var obs: [Obstacle] = []
            obs += arc(cx: 60, cy: 112, r: 35, from: 0, to: .pi, segs: 10)
            obs += arc(cx: 140, cy: 155, r: 35, from: .pi, to: 2 * .pi, segs: 10)
            obs.append(line(95, 112, 105, 155, .absorb))  // spine absorb
            obs += arc(cx: 60, cy: 112, r: 22, from: .pi * 0.2, to: .pi * 0.8, segs: 5, .absorb)
            obs += arc(cx: 140, cy: 155, r: 22, from: .pi * 1.2, to: .pi * 1.8, segs: 5, .absorb)
            obs += sideShields(75, 175)
            return Def(targetX: 100, obstacles: obs)

        case 47: // 🔥 Phoenix — spread wings with absorb fire
            var obs: [Obstacle] = []
            obs += arc(cx: 45, cy: 140, r: 42, from: .pi * 0.1, to: .pi * 0.9, segs: 10)
            obs += arc(cx: 155, cy: 140, r: 42, from: .pi * 0.1, to: .pi * 0.9, segs: 10)
            obs += arc(cx: 100, cy: 170, r: 15, from: 0, to: 2 * .pi, segs: 10, .absorb)
            obs.append(line(90, 80, 100, 100, .absorb))    // fire left
            obs.append(line(110, 80, 100, 100, .absorb))   // fire right
            obs.append(line(100, 75, 100, 100, .absorb))   // fire center
            obs += sideShields(75, 175)
            return Def(targetX: 100, obstacles: obs)

        case 48: // 💀 Skull — absorb head ring + eye sockets + jaw gap
            var obs: [Obstacle] = []
            obs += ring(cx: 100, cy: 150, r: 42, gapAngle: -.pi / 2, gapSize: .pi / 4, segs: 18, .absorb)
            obs += ring(cx: 82, cy: 157, r: 10, gapAngle: 0, gapSize: .pi, segs: 8)
            obs += ring(cx: 118, cy: 157, r: 10, gapAngle: .pi, gapSize: .pi, segs: 8)
            obs.append(line(92, 137, 100, 130, .absorb))  // nose left
            obs.append(line(108, 137, 100, 130, .absorb)) // nose right
            obs.append(line(78, 113, 90, 108))             // jaw left
            obs.append(line(122, 113, 110, 108))           // jaw right
            obs += sideShields(85, 175)
            return Def(targetX: 100, obstacles: obs)

        case 49: // 🌌 Black hole — absorb spiral pulling inward
            var obs: [Obstacle] = []
            obs += spiral(cx: 100, cy: 140, startR: 55, endR: 12,
                         turns: 1.5, startAngle: 0, segs: 36,
                         skip: [0, 8, 9, 17, 18, 26, 27, 35], .absorb)
            obs += ring(cx: 100, cy: 140, r: 8, gapAngle: -.pi / 2, gapSize: .pi / 2, segs: 8)
            obs += sideShields(82, 175)
            return Def(targetX: 100, obstacles: obs)

        case 50: // 💥 Supernova — absorb star burst + concentric ring maze
            var obs: [Obstacle] = []
            obs += star(cx: 100, cy: 140, outerR: 52, innerR: 30,
                       points: 6, skip: [0, 1, 6, 7], .absorb)
            obs += ring(cx: 100, cy: 140, r: 20, gapAngle: .pi * 0.3, gapSize: .pi / 2.5, segs: 12)
            obs += ring(cx: 100, cy: 140, r: 40, gapAngle: -.pi * 0.4, gapSize: .pi / 3, segs: 14)
            obs += sideShields(85, 175)
            return Def(targetX: 100, obstacles: obs)

        default:
            return Def(targetX: 100, obstacles: [])
        }
    }
}
