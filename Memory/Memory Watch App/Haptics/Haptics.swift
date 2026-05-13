import WatchKit

enum Haptics {
    static func playFlip() {
        WKInterfaceDevice.current().play(.click)
    }

    static func playMatch() {
        WKInterfaceDevice.current().play(.success)
    }

    static func playMismatch() {
        WKInterfaceDevice.current().play(.retry)
    }

    static func playWin() {
        WKInterfaceDevice.current().play(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            WKInterfaceDevice.current().play(.success)
        }
    }
}
