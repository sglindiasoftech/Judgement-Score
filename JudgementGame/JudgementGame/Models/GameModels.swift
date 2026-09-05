import Foundation

public enum RoundPhase: String, Codable, Hashable {
    case announce
    case actual
    case summary
}

public enum RoundOutcome: String, Codable, Hashable {
    case win
    case lost
}

public enum GameStatus: String, Codable, Hashable {
    case active
    case finished
}

public struct Player: Identifiable, Codable, Hashable {
    public var id: Int { position }
    public var name: String
    public var position: Int
    public var hasQuit: Bool
    public var quitRound: Int?
    
    public init(name: String, position: Int, hasQuit: Bool = false, quitRound: Int? = nil) {
        self.name = name
        self.position = position
        self.hasQuit = hasQuit
        self.quitRound = quitRound
    }
}

public struct Round: Identifiable, Codable, Hashable {
    public var id: Int { roundNumber }
    public var roundNumber: Int
    public var cardsPerPlayer: Int
    public var dealerIndex: Int
    public var announcementOrder: [Int]
    public var announcements: [Int: Int] // Key: player position index
    public var results: [Int: RoundOutcome] // Key: player position index
    public var roundScores: [Int: Int] // Key: player position index
    public var cumulativeScores: [Int: Int] // Key: player position index
    public var phase: RoundPhase
    
    public init(roundNumber: Int, cardsPerPlayer: Int, dealerIndex: Int, announcementOrder: [Int], phase: RoundPhase = .announce) {
        self.roundNumber = roundNumber
        self.cardsPerPlayer = cardsPerPlayer
        self.dealerIndex = dealerIndex
        self.announcementOrder = announcementOrder
        self.announcements = [:]
        self.results = [:]
        self.roundScores = [:]
        self.cumulativeScores = [:]
        self.phase = phase
        
        // Default announcements to 0 for all players
        for idx in announcementOrder {
            self.announcements[idx] = 0
        }
    }
    
    public var totalAnnounced: Int {
        announcements.values.reduce(0, +)
    }
    
    public func activeTotalAnnounced(players: [Player]) -> Int {
        var sum = 0
        for p in players {
            if !p.hasQuit {
                sum += (announcements[p.position] ?? 0)
            }
        }
        return sum
    }
    
    public var isDealerRestrictionViolated: Bool {
        totalAnnounced == cardsPerPlayer
    }
    
    public func isDealerRestrictionViolated(players: [Player]) -> Bool {
        activeTotalAnnounced(players: players) == cardsPerPlayer
    }
}

public struct Game: Identifiable, Codable, Hashable {
    public var id: String { gameId }
    public var gameId: String
    public var date: Date
    public var numPlayers: Int
    public var players: [Player]
    public var startingCards: Int
    public var currentDealerIndex: Int
    public var status: GameStatus
    public var rounds: [Round]
    public var finalScores: [Int: Int]?
    public var winner: [String]?
    
    public init(numPlayers: Int, players: [Player], startingCards: Int, dealerIndex: Int) {
        self.gameId = "g_\(Int(Date().timeIntervalSince1970 * 1000))"
        self.date = Date()
        self.numPlayers = numPlayers
        self.players = players
        self.startingCards = startingCards
        self.currentDealerIndex = dealerIndex
        self.status = .active
        self.rounds = []
        self.finalScores = nil
        self.winner = nil
    }
    
    public static func maxStartCards(for numPlayers: Int) -> Int {
        guard numPlayers > 0 else { return 26 }
        return 104 / numPlayers
    }
    
    public var activePlayers: [Player] {
        players.filter { !$0.hasQuit }
    }
    
    public static func buildAnnouncementOrder(dealerIndex: Int, numPlayers: Int, players: [Player] = []) -> [Int] {
        var order: [Int] = []
        for i in 1...numPlayers {
            let pos = (dealerIndex + i) % numPlayers
            order.append(pos)
        }
        return order
    }
    
    public func nextActiveDealerIndex(from currentDealer: Int) -> Int {
        var candidate = (currentDealer + 1) % numPlayers
        for _ in 0..<numPlayers {
            if let p = players.first(where: { $0.position == candidate }), !p.hasQuit {
                return candidate
            }
            candidate = (candidate + 1) % numPlayers
        }
        return currentDealer
    }
}
