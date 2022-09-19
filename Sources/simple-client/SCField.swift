/// A field on the game board. It consists of a coordinate and a field state.
struct SCField {
    // MARK: - Properties

    /// The coordinate of the field.
    let coordinate: SCCoordinate
    /// The state of the field.
    var state: SCFieldState

    // MARK: - Initializers

    /// Creates a new field with the given coordinate and the given field state.
    /// If no state is provided an empty field is created.
    ///
    /// - Parameters:
    ///   - coordinate: The coordinate of the field.
    ///   - state: The state of the field.
    init(coordinate: SCCoordinate, state: SCFieldState = .empty) {
        self.coordinate = coordinate
        self.state = state
    }

    // MARK: - Methods

    /// Returns a Boolean value indicating whether the field is occupiable.
    ///
    /// - Returns: `true` if the field is occupiable; otherwise, `false`.
    func isOccupiable() -> Bool {
        switch self.state {
            case .iceFloe(_):
                return true
            default:
                return false
        }
    }
}