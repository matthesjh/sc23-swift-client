/// The possible players.
enum SCPlayer: String, CaseIterable, CustomStringConvertible {
    /// The first player.
    case one = "ONE"
    /// The second player.
    case two = "TWO"

    // MARK: - Properties

    /// The opponent player.
    var opponent: SCPlayer {
        self == .one ? .two : .one
    }

    // MARK: - Methods

    /// Switches the player to the opponent player.
    mutating func switchPlayer() {
        self = self.opponent
    }

    // MARK: - CustomStringConvertible

    var description: String {
        self.rawValue
    }
}