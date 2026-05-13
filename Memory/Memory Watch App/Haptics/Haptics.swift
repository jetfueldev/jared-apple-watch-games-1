import WatchKit

enum Haptics {
    static func playFlip() {
        WKInterfaceDevice.current().play(.click)
    }

    static func playMatch() {
        WKInterfaceDevice.current().play(.click)
    }

    static func playMismatch() {
        // silence — no punishment, just flip back quietly
    }

    static func playWin() {
        WKInterfaceDevice.current().play(.click)
    }
}
