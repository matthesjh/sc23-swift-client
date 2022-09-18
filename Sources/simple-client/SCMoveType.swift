/// The type of a move.
enum SCMoveType: String, CaseIterable, CustomStringConvertible {
    /// An existing penguin on the game board is moved to a new field.
    case dragMove = "DRAG_MOVE"
    /// A penguin is placed on the game board.
    case setMove = "SET_MOVE"

    // MARK: - CustomStringConvertible

    var description: String {
        self.rawValue
    }
}