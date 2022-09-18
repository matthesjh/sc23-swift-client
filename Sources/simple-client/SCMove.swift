/// A move of a player. Depending on the type of the move, it consists of a
/// start and destination coordinate or a destination coordinate.
struct SCMove {
    // MARK: - Properties

    /// The type of the move.
    let type: SCMoveType
    /// The start coordinate of a drag move.
    let start: SCCoordinate?
    /// The destination coordinate of a drag or set move.
    let destination: SCCoordinate
    /// The debug hints associated with the move.
    lazy var debugHints = [String]()

    // MARK: - Initializers

    /// Creates a new drag move from the given start coordinate to the given
    /// destination coordinate.
    ///
    /// - Parameters:
    ///   - start: The start coordinate of the drag move.
    ///   - destination: The destination coordinate of the drag move.
    init(start: SCCoordinate, destination: SCCoordinate) {
        self.type = .dragMove
        self.start = start
        self.destination = destination
    }

    /// Creates a new set move to the given destination coordinate.
    ///
    /// - Parameter destination: The destination coordinate of the set move.
    init(destination: SCCoordinate) {
        self.type = .setMove
        self.start = nil
        self.destination = destination
    }
}