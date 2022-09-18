/// The state of a field.
enum SCFieldState {
    /// The field is empty and has no ice floe.
    case empty
    /// The field has an ice floe with the given number of fish.
    case iceFloe(fish: Int)
    /// The field is occupied by the given player.
    case occupied(player: SCPlayer)
}