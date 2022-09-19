/// Represents the state of a game, as received from the game server.
class SCGameState {
    // MARK: - Properties

    /// The player starting the game.
    let startPlayer: SCPlayer
    /// The current player.
    private(set) var currentPlayer: SCPlayer
    /// The current turn number.
    private(set) var turn = 0
    /// The two-dimensional array of fields representing the game board.
    private(set) var board: [[SCField]]
    /// The fish count of the first player.
    private(set) var playerOneFishCount = 0
    /// The fish count of the second player.
    private(set) var playerTwoFishCount = 0

    // MARK: - Initializers

    /// Creates a new game state with the given start player.
    ///
    /// - Parameter startPlayer: The player starting the game.
    init(startPlayer: SCPlayer) {
        self.startPlayer = startPlayer
        self.currentPlayer = startPlayer

        // Initialize the board with empty fields.
        let range = 0..<SCConstants.boardSize
        self.board = range.map { x in
            range.map { SCField(coordinate: SCCoordinate(x: x, y: $0)) }
        }
    }

    /// Creates a new game state by copying the given game state.
    ///
    /// - Parameter gameState: The game state to copy.
    init(withGameState gameState: SCGameState) {
        self.startPlayer = gameState.startPlayer
        self.currentPlayer = gameState.currentPlayer
        self.turn = gameState.turn
        self.board = gameState.board
        self.playerOneFishCount = gameState.playerOneFishCount
        self.playerTwoFishCount = gameState.playerTwoFishCount
    }

    // MARK: - Subscripts

    /// Accesses the field state of the field with the given x- and
    /// y-coordinate.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate of the field.
    ///   - y: The y-coordinate of the field.
    subscript(x: Int, y: Int) -> SCFieldState {
        get {
            self.getField(x: x, y: y).state
        }
    }

    /// Accesses the field state of the field with the given coordinate.
    ///
    /// - Parameter coordinate: The coordinate of the field.
    subscript(coordinate: SCCoordinate) -> SCFieldState {
        get {
            self[coordinate.x, coordinate.y]
        }
    }

    // MARK: - Methods

    /// Returns the field with the given x- and y-coordinate.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate of the field.
    ///   - y: The y-coordinate of the field.
    ///
    /// - Returns: The field with the given x- and y-coordinate.
    func getField(x: Int, y: Int) -> SCField {
        self.board[x][y]
    }

    /// Returns the field with the given coordinate.
    ///
    /// - Parameter coordinate: The coordinate of the field.
    ///
    /// - Returns: The field with the given coordinate.
    func getField(coordinate: SCCoordinate) -> SCField {
        self.getField(x: coordinate.x, y: coordinate.y)
    }

    /// Returns the field state of the field with the given x- and y-coordinate.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate of the field.
    ///   - y: The y-coordinate of the field.
    ///
    /// - Returns: The state of the field.
    func getFieldState(x: Int, y: Int) -> SCFieldState {
        self[x, y]
    }

    /// Returns the field state of the field with the given coordinate.
    ///
    /// - Parameter coordinate: The coordinate of the field.
    ///
    /// - Returns: The state of the field.
    func getFieldState(coordinate: SCCoordinate) -> SCFieldState {
        self[coordinate]
    }

    /// Replaces the field that has the same coordinate as the given field with
    /// the given field.
    ///
    /// - Parameter field: The field to be placed on the game board.
    func setField(field: SCField) {
        self.board[field.coordinate.x][field.coordinate.y] = field
    }

    /// Returns the possible set moves of the current player.
    ///
    /// - Returns: The array of possible set moves.
    private func possibleSetMoves() -> [SCMove] {
        self.board.joined().compactMap {
            if case .iceFloe(fish: 1) = $0.state {
                return SCMove(destination: $0.coordinate)
            }

            return nil
        }
    }

    /// Returns the possible drag moves of the current player.
    ///
    /// - Returns: The array of possible drag moves.
    private func possibleDragMoves() -> [SCMove] {
        self.board.joined().compactMap { (field: SCField) -> SCCoordinate? in
            if case .occupied(player: let player) = field.state,
               player == self.currentPlayer {
                return field.coordinate
            }

            return nil
        }.flatMap { start in
            SCDirection.allCases.flatMap { direction in
                var moves = [SCMove]()

                for distance in 1..<SCConstants.boardSize {
                    let destination = start.coordinate(inDirection: direction, withDistance: distance)

                    if destination.x >= 0,
                       destination.x < SCConstants.boardSize,
                       destination.y >= 0,
                       destination.y < SCConstants.boardSize,
                       case .iceFloe(_) = self[destination] {
                        moves.append(SCMove(start: start, destination: destination))
                    } else {
                        break
                    }
                }

                return moves
            }
        }
    }

    /// Returns the possible moves of the current player.
    ///
    /// - Returns: The array of possible moves.
    func possibleMoves() -> [SCMove] {
        self.turn < 8 ? self.possibleSetMoves() : self.possibleDragMoves()
    }

    /// Performs the given move on the game board.
    ///
    /// Due to performance reasons the given move is not validated prior to
    /// performing it on the game board.
    ///
    /// - Parameter move: The move to be performed.
    ///
    /// - Returns: `true` if the move could be performed; otherwise, `false`.
    func performMove(move: SCMove) -> Bool {
        switch move.type {
            case .dragMove(let start, let destination):
                if case .occupied(let player) = self[start],
                   player == self.currentPlayer,
                   case .iceFloe(let fish) = self[destination] {
                    self.setField(field: SCField(coordinate: start))
                    self.setField(field: SCField(coordinate: destination, state: .occupied(player: self.currentPlayer)))

                    switch self.currentPlayer {
                        case .one:
                            self.playerOneFishCount += fish
                        case .two:
                            self.playerTwoFishCount += fish
                    }
                } else {
                    return false
                }
            case .setMove(let destination):
                if case .iceFloe(fish: 1) = self[destination] {
                    self.setField(field: SCField(coordinate: destination, state: .occupied(player: self.currentPlayer)))

                    switch self.currentPlayer {
                        case .one:
                            self.playerOneFishCount += 1
                        case .two:
                            self.playerTwoFishCount += 1
                    }
                } else {
                    return false
                }
        }

        self.turn += 1
        self.currentPlayer.switchPlayer()

        return true
    }

    /// Skips the move of the current player.
    func skipMove() {
        self.currentPlayer.switchPlayer()
    }
}