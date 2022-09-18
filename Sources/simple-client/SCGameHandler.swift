import Foundation

#if os(Linux)
import FoundationXML
#endif

/// The game handler is responsible for the communication with the game server
/// and the selection of the game logic.
class SCGameHandler: NSObject, XMLParserDelegate {
    // MARK: - Properties

    /// The TCP socket used for the communication with the game server.
    private let socket: SCSocket
    /// The reservation code to join a prepared game.
    private let reservation: String
    /// The strategy selected by the user.
    private let strategy: String

    /// The room id associated with the joined game.
    private var roomId: String!
    /// The player of the delegate (game logic).
    private var player: SCPlayer!
    /// The current state of the game.
    private var gameState: SCGameState!
    /// Indicates whether the game state has been initially created.
    private var gameStateCreated = false
    /// Indicates whether the game loop should be left.
    private var leaveGame = false

    /// The current player score which is parsed.
    private var score: SCScore!
    /// The scores of the players.
    private var scores = [SCScore]()
    /// The winner of the game.
    private var winner: SCWinner?
    /// Indicates whether the game result has been received.
    private var gameResultReceived = false

    /// The field that is currently processed.
    private var fieldIndex = 0

    /// The characters found by the parser.
    private var foundChars = ""

    /// The delegate (game logic) which handles the requests of the game server.
    var delegate: SCGameHandlerDelegate?

    // MARK: - Initializers

    /// Creates a new game handler with the given TCP socket, the given
    /// reservation code and the given strategy.
    ///
    /// - Parameters:
    ///   - socket: The socket used for the communication with the game server.
    ///   - reservation: The reservation code to join a prepared game.
    ///   - strategy: The selected strategy.
    init(socket: SCSocket, reservation: String, strategy: String) {
        self.socket = socket
        self.reservation = reservation
        self.strategy = strategy
    }

    // MARK: - Methods

    /// Handles the game.
    ///
    /// The TCP socket must already be connected before using this method.
    func handleGame() {
        if self.reservation.isEmpty {
            // Join a game.
            self.socket.send(message: "<protocol><join />")
        } else {
            // Join a prepared game.
            self.socket.send(message: #"<protocol><joinPrepared reservationCode="\#(self.reservation)" />"#)
        }

        // The root element for the received XML document. A temporary fix for
        // the XMLParser.
        guard let rootElem = "<root>".data(using: .utf8) else {
            return
        }

        // Loop until the game is over.
        while !self.leaveGame {
            // Receive the message from the game server.
            var data = Data()
            self.socket.receive(into: &data)

            // Parse the received XML document.
            let parser = XMLParser(data: rootElem + data)
            parser.delegate = self
            _ = parser.parse()
        }
    }

    /// Exits the game with the given error message.
    ///
    /// - Parameter error: The error message to print into the standard output.
    private func exitGame(withError error: String = "") {
        if !error.isEmpty {
            print("ERROR: \(error)")
        }

        self.leaveGame = true
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        // Reset the found characters.
        self.foundChars = ""

        switch elementName {
            case "data":
                // Check whether a class attribute exists.
                guard let classAttr = attributeDict["class"] else {
                    parser.abortParsing()
                    self.exitGame(withError: "The class attribute of the data element is missing!")

                    break
                }

                switch classAttr {
                    case "result":
                        self.gameResultReceived = true
                    case "moveRequest":
                        guard var move = self.delegate?.onMoveRequested() else {
                            parser.abortParsing()
                            self.exitGame(withError: "No move has been sent!")

                            break
                        }

                        var mv = ""

                        switch move.type {
                            case .dragMove:
                                let from = move.start!.doubledCoordinate
                                mv += #"<from x="\#(from.x)" y="\#(from.y)" />"#
                            default:
                                break
                        }

                        let to = move.destination.doubledCoordinate
                        mv += #"<to x="\#(to.x)" y="\#(to.y)" />"#

                        mv += move.debugHints.reduce(into: "") { $0 += #"<hint content="\#($1)" />"# }

                        // Send the move returned by the game logic to the game
                        // server.
                        self.socket.send(message: #"<room roomId="\#(self.roomId!)"><data class="move">\#(mv)</data></room>"#)
                    case "welcomeMessage":
                        guard let playerAttr = attributeDict["color"],
                              let player = SCPlayer(rawValue: playerAttr.uppercased()) else {
                            parser.abortParsing()
                            self.exitGame(withError: "The player of the welcome message is missing or could not be parsed!")

                            break
                        }

                        // Save the player of this game client.
                        self.player = player
                    default:
                        break
                }
            case "joined":
                guard let roomId = attributeDict["roomId"] else {
                    parser.abortParsing()
                    self.exitGame(withError: "The room ID is missing!")

                    break
                }

                // Save the room id of the game.
                self.roomId = roomId
            case "left":
                // Leave the game.
                parser.abortParsing()

                self.delegate?.onGameEnded()

                self.exitGame()
            case "score":
                guard let causeAttr = attributeDict["cause"],
                      let cause = SCScoreCause(rawValue: causeAttr) else {
                    parser.abortParsing()
                    self.exitGame(withError: "The score could not be parsed!")

                    break
                }

                // Create the score object.
                self.score = SCScore(cause: cause, reason: attributeDict["reason"])
            case "state":
                self.fieldIndex = 0
            case "winner":
                guard let colorAttr = attributeDict["color"],
                      let player = SCPlayer(rawValue: colorAttr) else {
                    parser.abortParsing()
                    self.exitGame(withError: "The winner could not be parsed!")

                    break
                }

                // Save the winner of the game.
                self.winner = SCWinner(player: player, displayName: attributeDict["displayName"])
            default:
                break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        self.foundChars += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
            case "data":
                if self.gameResultReceived {
                    // Notify the delegate that the game result has been
                    // received.
                    self.delegate?.onGameResultReceived(SCGameResult(scores: self.scores, winner: self.winner))
                }
            case "field":
                let coordinate = SCCoordinate(x: self.fieldIndex % SCConstants.boardSize, y: self.fieldIndex / SCConstants.boardSize)

                if let player = SCPlayer(rawValue: foundChars) {
                    self.gameState.setField(field: SCField(coordinate: coordinate, state: .occupied(player: player)))
                } else if let fish = Int(foundChars), fish >= 0 {
                    self.gameState.setField(field: SCField(coordinate: coordinate, state: fish == 0 ? .empty : .iceFloe(fish: fish)))
                }

                self.fieldIndex += 1
            case "part":
                // Add the found value to the current score object.
                self.score.values.append(self.foundChars)
            case "score":
                // Append the current score object to the array of scores.
                self.scores.append(self.score)
            case "startTeam":
                if !self.gameStateCreated {
                    guard let startPlayer = SCPlayer(rawValue: foundChars) else {
                        parser.abortParsing()
                        self.exitGame(withError: "The start player could not be parsed!")

                        break
                    }

                    // Create the initial game state.
                    self.gameState = SCGameState(startPlayer: startPlayer)

                    // TODO: Select the game logic based on the strategy.

                    // Create the game logic.
                    self.delegate = SCGameLogic(player: self.player)
                }
            case "state":
                if self.gameStateCreated {
                    self.gameState.skipMove()
                }

                self.gameStateCreated = true

                // Notify the delegate that the game state has been updated.
                self.delegate?.onGameStateUpdated(SCGameState(withGameState: self.gameState))
            default:
                break
        }
    }
}