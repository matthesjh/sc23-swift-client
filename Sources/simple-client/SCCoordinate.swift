/// A coordinate consists of an x- and y-coordinate and points to a field on the
/// game board.
struct SCCoordinate: Hashable {
    // MARK: - Properties

    /// The x-coordinate of the field.
    let x: Int
    /// The y-coordinate of the field.
    let y: Int

    /// The coordinate represented as a doubled coordinate.
    var doubledCoordinate: SCCoordinate {
        SCCoordinate(x: self.x * 2 + self.y % 2, y: self.y)
    }

    // MARK: - Initializers

    /// Creates a new coordinate with the given x- and y-coordinate.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate of the field.
    ///   - y: The y-coordinate of the field.
    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}