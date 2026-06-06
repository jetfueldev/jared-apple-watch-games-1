import WatchKit

enum Haptics {
    static func playPad(_ color: PadColor) {
        WKInterfaceDevice.current().play(color.hapticType)
    }

    static func playSuccess() {
        WKInterfaceDevice.current().play(.success)
    }

    static func playFailure() {
        WKInterfaceDevice.current().play(.failure)
    }

    static func playStageComplete() {
        WKInterfaceDevice.current().play(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            WKInterfaceDevice.current().play(.success)
        }
    }
}
