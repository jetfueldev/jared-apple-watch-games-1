enum StageData {

    static let totalStages = 6

    static func stage(_ number: Int) -> Stage {
        let n = max(1, min(number, totalStages))
        switch n {
        case 1:
            return Stage(number: 1,
                         colors: [.red, .blue],
                         startLength: 3, endLength: 5)
        case 2:
            return Stage(number: 2,
                         colors: [.red, .blue, .yellow],
                         startLength: 3, endLength: 6)
        case 3:
            return Stage(number: 3,
                         colors: [.red, .blue, .yellow, .green],
                         startLength: 4, endLength: 7)
        case 4:
            return Stage(number: 4,
                         colors: [.red, .blue, .yellow, .green, .orange],
                         startLength: 4, endLength: 8)
        case 5:
            return Stage(number: 5,
                         colors: [.red, .blue, .yellow, .green, .orange, .purple],
                         startLength: 5, endLength: 9)
        case 6:
            return Stage(number: 6,
                         colors: [.red, .blue, .yellow, .green, .orange, .purple, .white],
                         startLength: 5, endLength: 10)
        default:
            return stage(totalStages)
        }
    }
}
