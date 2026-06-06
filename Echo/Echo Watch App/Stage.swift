struct Stage {
    let number: Int
    let colors: [PadColor]
    let startLength: Int
    let endLength: Int

    var totalRounds: Int { endLength - startLength + 1 }
}
