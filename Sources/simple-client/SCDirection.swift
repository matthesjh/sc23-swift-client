/// The directions on the game board.
enum SCDirection: String, CaseIterable, CustomStringConvertible {
    /// Move to northeast.
    case upRight = "UP_RIGHT"
    /// Move to east.
    case right = "RIGHT"
    /// Move to southeast.
    case downRight = "DOWN_RIGHT"
    /// Move to southwest.
    case downLeft = "DOWN_LEFT"
    /// Move to west.
    case left = "LEFT"
    /// Move to northwest.
    case upLeft = "UP_LEFT"

    // MARK: - CustomStringConvertible

    var description: String {
        self.rawValue
    }
}