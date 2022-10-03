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

    /// The start coordinate of the last move.
    private var lastMoveStart: SCCoordinate?
    /// The destination coordinate of the last move.
    private var lastMoveDestination: SCCoordinate?

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
                    case "moveRequest":
                        var moveData = ""

                        if let delegate {
                            // Adjust the game state if no move is sent by the
                            // opponent player.
                            if delegate.player != self.gameState.currentPlayer {
                                self.gameState.skipMove()
                                delegate.onGameStateUpdated(SCGameState(withGameState: self.gameState))
                            }

                            // Request a move by the delegate (game logic).
                            if var move = delegate.onMoveRequested() {
                                switch move.type {
                                    case .dragMove(let start, let destination):
                                        let from = start.doubledCoordinate
                                        let to = destination.doubledCoordinate

                                        moveData += #"<from x="\#(from.x)" y="\#(from.y)" /><to x="\#(to.x)" y="\#(to.y)" />"#
                                    case .setMove(let destination):
                                        let to = destination.doubledCoordinate

                                        moveData += #"<to x="\#(to.x)" y="\#(to.y)" />"#
                                }

                                moveData += move.debugHints.reduce(into: "") { $0 += #"<hint content="\#($1)" />"# }
                            }
                        }

                        // Send the move returned by the delegate (game logic)
                        // to the game server.
                        self.socket.send(message: #"<room roomId="\#(self.roomId!)"><data class="move">\#(moveData)</data></room>"#)
                    case "result":
                        self.gameResultReceived = true
                    case "welcomeMessage":
                        guard let playerAttr = attributeDict["color"],
                              let player = SCPlayer(rawValue: playerAttr) else {
                            parser.abortParsing()
                            self.exitGame(withError: "The player of the welcome message is missing or could not be parsed!")

                            break
                        }

                        // TODO: Select the game logic based on the strategy.

                        // Create the delegate (game logic).
                        self.delegate = SCGameLogic(player: player)
                    default:
                        break
                }
            case "from":
                guard let xAttr = attributeDict["x"],
                      let x = Int(xAttr),
                      let yAttr = attributeDict["y"],
                      let y = Int(yAttr) else {
                    parser.abortParsing()
                    self.exitGame(withError: "The start coordinate of the last move could not be parsed!")

                    break
                }

                // Save the start coordinate of the last move.
                self.lastMoveStart = SCCoordinate(doubledX: x, doubledY: y)
            case "joined":
                guard let roomId = attributeDict["roomId"] else {
                    parser.abortParsing()
                    self.exitGame(withError: "The room ID is missing!")

                    break
                }

                // Save the room id of the game.
                self.roomId = roomId
            case "lastMove":
                // Reset the coordinates of the last move.
                self.lastMoveStart = nil
                self.lastMoveDestination = nil
            case "left":
                parser.abortParsing()

                // Notify the delegate (game logic) that the game has ended.
                self.delegate?.onGameEnded()

                // Leave the game.
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
            case "to":
                guard let xAttr = attributeDict["x"],
                      let x = Int(xAttr),
                      let yAttr = attributeDict["y"],
                      let y = Int(yAttr) else {
                    parser.abortParsing()
                    self.exitGame(withError: "The destination coordinate of the last move could not be parsed!")

                    break
                }

                // Save the destination coordinate of the last move.
                self.lastMoveDestination = SCCoordinate(doubledX: x, doubledY: y)
            case "winner":
                guard let playerAttr = attributeDict["team"],
                      let player = SCPlayer(rawValue: playerAttr) else {
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
                if !self.gameStateCreated {
                    let coordinate = SCCoordinate(x: self.fieldIndex % SCConstants.boardSize, y: self.fieldIndex / SCConstants.boardSize)

                    // Update the game state with the initial field
                    // configuration.
                    if let player = SCPlayer(rawValue: foundChars) {
                        self.gameState.setField(field: SCField(coordinate: coordinate, state: .occupied(player: player)))
                    } else if let fish = Int(foundChars),
                              fish >= 0 {
                        self.gameState.setField(field: SCField(coordinate: coordinate, state: fish == 0 ? .empty : .iceFloe(fish: fish)))
                    } else {
                        parser.abortParsing()
                        self.exitGame(withError: "The field data could not be parsed!")

                        break
                    }

                    self.fieldIndex += 1
                }
            case "lastMove":
                if self.gameStateCreated {
                    var lastMove: SCMove? = nil

                    if let lastMoveStart,
                       let lastMoveDestination {
                        if case .occupied(player: let player) = self.gameState[lastMoveStart],
                           player != self.gameState.currentPlayer {
                            self.gameState.skipMove()
                        }

                        lastMove = SCMove(start: lastMoveStart, destination: lastMoveDestination)
                    } else if let lastMoveDestination {
                        lastMove = SCMove(destination: lastMoveDestination)
                    }

                    // Reset the coordinates of the last move.
                    self.lastMoveStart = nil
                    self.lastMoveDestination = nil

                    // Perform the last move on the game state.
                    if let lastMove {
                        if !self.gameState.performMove(move: lastMove) {
                            parser.abortParsing()
                            self.exitGame(withError: "The last move could not be performed on the game state!")
                        }
                    } else {
                        self.gameState.skipMove()
                    }
                }
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
                }
            case "state":
                self.gameStateCreated = true

                // Notify the delegate that the game state has been updated.
                self.delegate?.onGameStateUpdated(SCGameState(withGameState: self.gameState))
            default:
                break
        }
    }
}