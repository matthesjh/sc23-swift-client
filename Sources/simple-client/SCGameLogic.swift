/// The logic of the simple client.
class SCGameLogic: SCGameHandlerDelegate {
    // MARK: - Properties

    /// The current game state.
    private var gameState: SCGameState!

    let player: SCPlayer

    // MARK: - Initializers

    /// Creates a new game logic with the given player.
    ///
    /// - Parameter player: The player using this game logic.
    init(player: SCPlayer) {
        self.player = player
    }

    // MARK: - SCGameHandlerDelegate

    func onGameEnded() {
        print("*** The game has been ended!")
    }

    func onGameResultReceived(_ gameResult: SCGameResult) {
        print("*** The game result has been received!")
    }

    func onGameStateUpdated(_ gameState: SCGameState) {
        print("*** The game state has been updated!")

        self.gameState = gameState
    }

    func onMoveRequested() -> SCMove? {
        print("*** A move is requested by the game server!")

        // TODO: Add your own logic here.

        return self.gameState.possibleMoves().randomElement()
    }
}