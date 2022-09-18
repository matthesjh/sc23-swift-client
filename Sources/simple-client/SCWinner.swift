/// The winner of a game.
struct SCWinner {
    // MARK: - Properties

    /// The name of the player who won the game.
    let displayName: String?
    /// The player who won the game.
    let player: SCPlayer

    // MARK: - Initializers

    /// Creates a new winner with the given player who won the game and the
    /// given optional name.
    ///
    /// - Parameters:
    ///   - player: The player who won the game.
    ///   - displayName: The name of the player who won the game.
    init(player: SCPlayer, displayName: String? = nil) {
        self.displayName = displayName
        self.player = player
    }
}