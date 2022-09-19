/// The type of a move.
enum SCMoveType {
    /// A penguin is moved from the field with the given start coordinate to
    /// the field with the given destination coordinate.
    case dragMove(start: SCCoordinate, destination: SCCoordinate)
    /// A penguin is placed on the field with the given coordinate.
    case setMove(destination: SCCoordinate)
}