import Foundation

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

    /// Creates a new coordinate with the given x- and y-coordinate in doubled
    /// representation.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate in doubled representation of the field.
    ///   - y: The y-coordinate in doubled representation of the field.
    init(doubledX: Int, doubledY: Int) {
        self.x = Int(ceil(Double(doubledX) / 2.0)) - doubledY % 2
        self.y = doubledY
    }

    // MARK: - Methods

    /// Returns the coordinate on the game board in the given direction with
    /// the given distance from this coordinate.
    ///
    /// - Parameters:
    ///   - direction: The direction on the game board.
    ///   - distance: The number of steps to be taken.
    ///
    /// - Returns: The coordinate on the game board in the given direction with
    ///   the given distance from this coordinate.
    func coordinate(inDirection direction: SCDirection, withDistance distance: Int = 1) -> SCCoordinate {
        let doubledCoordinate = self.doubledCoordinate

        switch direction {
            case .upRight:
                return SCCoordinate(doubledX: doubledCoordinate.x + 1 * distance, doubledY: doubledCoordinate.y - 1 * distance)
            case .right:
                return SCCoordinate(doubledX: doubledCoordinate.x + 2 * distance, doubledY: doubledCoordinate.y)
            case .downRight:
                return SCCoordinate(doubledX: doubledCoordinate.x + 1 * distance, doubledY: doubledCoordinate.y + 1 * distance)
            case .downLeft:
                return SCCoordinate(doubledX: doubledCoordinate.x - 1 * distance, doubledY: doubledCoordinate.y + 1 * distance)
            case .left:
                return SCCoordinate(doubledX: doubledCoordinate.x - 2 * distance, doubledY: doubledCoordinate.y)
            case .upLeft:
                return SCCoordinate(doubledX: doubledCoordinate.x - 1 * distance, doubledY: doubledCoordinate.y - 1 * distance)
        }
    }
}