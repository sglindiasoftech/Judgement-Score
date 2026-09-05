import Foundation
import SwiftUI
import Combine

@MainActor
public class GameStateManager: ObservableObject {
    @Published public var activeGame: Game?
    @Published public var history: [Game] = []
    @Published public var nameHistory: [String] = []
    
    // New game setup draft state (all names default to empty strings)
    @Published public var setupNumPlayers: Int = 4
    @Published public var setupPlayerNames: [String] = ["", "", "", ""]
    @Published public var setupStartCards: Int = 7
    @Published public var setupDealerIndex: Int = 0
    
    // Undo & Editing state
    private var undoStack: [String] = [] // Game JSON snapshots
    @Published public var isScoreboardPresented: Bool = false
    
    private let keyActiveGame = "judgement_current_game"
    private let keyHistory = "judgement_history"
    private let keyNameHistory = "judgement_name_history"
    
    public init() {
        loadSavedGame()
        loadHistory()
        loadNameHistory()
    }
    
    // MARK: - Persistence
    
    public func loadSavedGame() {
        if let data = UserDefaults.standard.data(forKey: keyActiveGame) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let decoded = try? decoder.decode(Game.self, from: data) {
                self.activeGame = decoded
                return
            }
        }
        self.activeGame = nil
    }
    
    public func saveGame() {
        guard let activeGame = activeGame else {
            UserDefaults.standard.removeObject(forKey: keyActiveGame)
            return
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let encoded = try? encoder.encode(activeGame) {
            UserDefaults.standard.set(encoded, forKey: keyActiveGame)
        }
    }
    
    public func clearSavedGame() {
        activeGame = nil
        UserDefaults.standard.removeObject(forKey: keyActiveGame)
    }
    
    public func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: keyHistory) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let decoded = try? decoder.decode([Game].self, from: data) {
                self.history = decoded
                return
            }
        }
        self.history = []
    }
    
    public func saveHistory() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let encoded = try? encoder.encode(history) {
            UserDefaults.standard.set(encoded, forKey: keyHistory)
        }
    }
    
    public func deleteGameFromHistory(gameId: String) {
        history.removeAll { $0.gameId == gameId }
        saveHistory()
    }
    
    public func clearAllHistory() {
        history.removeAll()
        saveHistory()
    }
    
    public func loadNameHistory() {
        if !UserDefaults.standard.bool(forKey: "hasClearedInitialDefaults_v2") {
            // Start fresh with a completely BLANK dropdown list as requested
            self.nameHistory = []
            UserDefaults.standard.set([], forKey: keyNameHistory)
            UserDefaults.standard.set(true, forKey: "hasClearedInitialDefaults_v2")
            return
        }
        
        if let raw = UserDefaults.standard.array(forKey: keyNameHistory) as? [String] {
            self.nameHistory = raw.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        } else {
            self.nameHistory = []
        }
    }
    
    public func clearAllNameHistory() {
        self.nameHistory = []
        UserDefaults.standard.set([], forKey: keyNameHistory)
    }
    
    public func saveNameToHistory(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        var list = nameHistory.filter { $0.lowercased() != trimmed.lowercased() }
        list.append(trimmed)
        list.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        if list.count > 60 {
            list = Array(list.prefix(60))
        }
        self.nameHistory = list
        UserDefaults.standard.set(list, forKey: keyNameHistory)
    }
    
    public func updateNameInHistory(oldName: String, newName: String) {
        let trimmedNew = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNew.isEmpty else { return }
        
        var list = nameHistory.filter { $0.lowercased() != oldName.lowercased() && $0.lowercased() != trimmedNew.lowercased() }
        list.append(trimmedNew)
        list.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        self.nameHistory = list
        UserDefaults.standard.set(list, forKey: keyNameHistory)
    }
    
    public func deleteNameFromHistory(_ name: String) {
        let list = nameHistory.filter { $0.lowercased() != name.lowercased() }
        self.nameHistory = list
        UserDefaults.standard.set(list, forKey: keyNameHistory)
    }
    
    private func pushUndoSnapshot() {
        guard let game = activeGame else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(game),
           let jsonStr = String(data: data, encoding: .utf8) {
            undoStack.append(jsonStr)
            if undoStack.count > 15 {
                undoStack.removeFirst()
            }
        }
    }
    
    // MARK: - Game Setup Controls
    
    public func initNewGameSetup() {
        setupNumPlayers = 4
        setupPlayerNames = ["", "", "", ""]
        setupStartCards = min(7, Game.maxStartCards(for: 4))
        setupDealerIndex = 0
    }
    
    public func removePlayerRow(at index: Int) {
        guard setupPlayerNames.indices.contains(index) else { return }
        setupPlayerNames.remove(at: index)
        setupNumPlayers = max(2, setupPlayerNames.count)
        while setupPlayerNames.count < setupNumPlayers {
            setupPlayerNames.append("")
        }
        let maxCards = Game.maxStartCards(for: setupNumPlayers)
        if setupStartCards > maxCards {
            setupStartCards = maxCards
        }
        if setupDealerIndex >= setupNumPlayers {
            setupDealerIndex = 0
        }
    }
    
    public func updatePlayerCount(delta: Int) {
        let newCount = max(2, min(15, setupNumPlayers + delta))
        setupNumPlayers = newCount
        
        while setupPlayerNames.count < newCount {
            setupPlayerNames.append("")
        }
        if setupPlayerNames.count > newCount {
            setupPlayerNames = Array(setupPlayerNames.prefix(newCount))
        }
        
        let maxCards = Game.maxStartCards(for: newCount)
        if setupStartCards > maxCards {
            setupStartCards = maxCards
        }
        if setupDealerIndex >= newCount {
            setupDealerIndex = 0
        }
    }
    
    public func updateStartCards(delta: Int) {
        let maxCards = Game.maxStartCards(for: setupNumPlayers)
        let newCards = max(1, min(maxCards, setupStartCards + delta))
        setupStartCards = newCards
    }
    
    public func startGame() {
        var players: [Player] = []
        for i in 0..<setupNumPlayers {
            let raw = setupPlayerNames[i].trimmingCharacters(in: .whitespacesAndNewlines)
            let finalName = raw.isEmpty ? "Player \(i + 1)" : raw
            players.append(Player(name: finalName, position: i))
            if !raw.isEmpty {
                saveNameToHistory(raw)
            }
        }
        
        var newGame = Game(
            numPlayers: setupNumPlayers,
            players: players,
            startingCards: setupStartCards,
            dealerIndex: setupDealerIndex
        )
        
        let firstRoundOrder = Game.buildAnnouncementOrder(dealerIndex: setupDealerIndex, numPlayers: setupNumPlayers, players: players)
        let firstRound = Round(
            roundNumber: 1,
            cardsPerPlayer: setupStartCards,
            dealerIndex: setupDealerIndex,
            announcementOrder: firstRoundOrder,
            phase: .announce
        )
        
        newGame.rounds.append(firstRound)
        self.activeGame = newGame
        self.undoStack.removeAll()
        saveGame()
    }
    
    // MARK: - Gameplay Actions
    
    public func togglePlayerQuitStatus(playerIndex: Int) {
        guard activeGame != nil else { return }
        if let pIdx = activeGame!.players.firstIndex(where: { $0.position == playerIndex }) {
            let currentStatus = activeGame!.players[pIdx].hasQuit
            let newStatus = !currentStatus
            let currentRoundNumber = activeGame!.rounds.count
            activeGame!.players[pIdx].hasQuit = newStatus
            activeGame!.players[pIdx].quitRound = newStatus ? currentRoundNumber : nil
            
            // Re-compute round scores for all completed rounds
            for rIdx in 0..<activeGame!.rounds.count {
                if !activeGame!.rounds[rIdx].roundScores.isEmpty {
                    computeRoundScores(roundIndex: rIdx)
                }
            }
            saveGame()
        }
    }
    
    public func updateAnnouncement(playerIndex: Int, bid: Int) {
        guard activeGame != nil, !activeGame!.rounds.isEmpty else { return }
        let roundIdx = activeGame!.rounds.count - 1
        let maxBid = activeGame!.rounds[roundIdx].cardsPerPlayer
        let clampedBid = max(0, min(maxBid, bid))
        activeGame!.rounds[roundIdx].announcements[playerIndex] = clampedBid
        saveGame()
    }
    
    public func confirmAnnouncements() -> Bool {
        guard activeGame != nil, !activeGame!.rounds.isEmpty else { return false }
        let roundIdx = activeGame!.rounds.count - 1
        let round = activeGame!.rounds[roundIdx]
        
        if round.isDealerRestrictionViolated(players: activeGame!.players) {
            return false // Blocked due to dealer restriction
        }
        
        activeGame!.rounds[roundIdx].phase = .actual
        // Default everyone to 'win' initially if results empty
        for player in activeGame!.players {
            if activeGame!.rounds[roundIdx].results[player.position] == nil {
                activeGame!.rounds[roundIdx].results[player.position] = .win
            }
        }
        
        saveGame()
        return true
    }
    
    public func setActualResult(playerIndex: Int, outcome: RoundOutcome) {
        guard activeGame != nil, !activeGame!.rounds.isEmpty else { return }
        let roundIdx = activeGame!.rounds.count - 1
        activeGame!.rounds[roundIdx].results[playerIndex] = outcome
        saveGame()
    }
    
    public func finishRound() {
        guard activeGame != nil, !activeGame!.rounds.isEmpty else { return }
        pushUndoSnapshot()
        
        let roundIdx = activeGame!.rounds.count - 1
        computeRoundScores(roundIndex: roundIdx)
        activeGame!.rounds[roundIdx].phase = .summary
        saveGame()
    }
    
    public func computeRoundScores(roundIndex: Int) {
        guard activeGame != nil, roundIndex >= 0, roundIndex < activeGame!.rounds.count else { return }
        
        var prevCumulative: [Int: Int] = [:]
        if roundIndex > 0 {
            prevCumulative = activeGame!.rounds[roundIndex - 1].cumulativeScores
        } else {
            for p in activeGame!.players {
                prevCumulative[p.position] = 0
            }
        }
        
        for player in activeGame!.players {
            let idx = player.position
            if player.hasQuit {
                // Score is fridged/frozen: 0 round score, cumulative remains at last saved value
                activeGame!.rounds[roundIndex].roundScores[idx] = 0
                activeGame!.rounds[roundIndex].cumulativeScores[idx] = prevCumulative[idx] ?? 0
            } else {
                let announced = activeGame!.rounds[roundIndex].announcements[idx] ?? 0
                let won = (activeGame!.rounds[roundIndex].results[idx] == .win)
                let roundScore = won ? (10 + announced) : (-announced)
                
                activeGame!.rounds[roundIndex].roundScores[idx] = roundScore
                activeGame!.rounds[roundIndex].cumulativeScores[idx] = (prevCumulative[idx] ?? 0) + roundScore
            }
        }
    }
    
    public func goNextRound() {
        guard activeGame != nil, let currentRound = activeGame!.rounds.last else { return }
        
        if currentRound.cardsPerPlayer == 1 {
            finishGame()
            return
        }
        
        let nextDealer = activeGame!.nextActiveDealerIndex(from: currentRound.dealerIndex)
        let nextCards = currentRound.cardsPerPlayer - 1
        let nextRoundNumber = currentRound.roundNumber + 1
        let order = Game.buildAnnouncementOrder(dealerIndex: nextDealer, numPlayers: activeGame!.numPlayers, players: activeGame!.players)
        
        let newRound = Round(
            roundNumber: nextRoundNumber,
            cardsPerPlayer: nextCards,
            dealerIndex: nextDealer,
            announcementOrder: order,
            phase: .announce
        )
        
        activeGame!.rounds.append(newRound)
        activeGame!.currentDealerIndex = nextDealer
        saveGame()
    }
    
    public func undoLastRound() {
        if !undoStack.isEmpty {
            let jsonStr = undoStack.removeLast()
            if let data = jsonStr.data(using: .utf8) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                if let decoded = try? decoder.decode(Game.self, from: data) {
                    self.activeGame = decoded
                    saveGame()
                    return
                }
            }
        }
        
        // Fallback undo: revert current round to actual phase
        if activeGame != nil, !activeGame!.rounds.isEmpty {
            let roundIdx = activeGame!.rounds.count - 1
            activeGame!.rounds[roundIdx].phase = .actual
            activeGame!.rounds[roundIdx].roundScores.removeAll()
            activeGame!.rounds[roundIdx].cumulativeScores.removeAll()
            saveGame()
        }
    }
    
    public func finishGame() {
        guard activeGame != nil, let lastRound = activeGame!.rounds.last else { return }
        
        activeGame!.status = .finished
        activeGame!.finalScores = lastRound.cumulativeScores
        
        var scoreList: [(name: String, score: Int)] = []
        for p in activeGame!.players {
            let score = lastRound.cumulativeScores[p.position] ?? 0
            scoreList.append((p.name, score))
        }
        scoreList.sort { $0.score > $1.score }
        
        if let topScore = scoreList.first?.score {
            let winners = scoreList.filter { $0.score == topScore }.map { $0.name }
            activeGame!.winner = winners
        }
        
        saveGame()
    }
    
    public func archiveCurrentGameToHistory() {
        guard let activeGame = activeGame else { return }
        history.insert(activeGame, at: 0)
        saveHistory()
        clearSavedGame()
        undoStack.removeAll()
    }
    
    // MARK: - Round Editing (History & Live)
    
    public func saveEditedRound(roundNumber: Int, newAnnouncements: [Int: Int], newResults: [Int: RoundOutcome]) -> Bool {
        guard activeGame != nil else { return false }
        guard let rIdx = activeGame!.rounds.firstIndex(where: { $0.roundNumber == roundNumber }) else { return false }
        
        let cardsPerPlayer = activeGame!.rounds[rIdx].cardsPerPlayer
        let totalAnnounced = newAnnouncements.values.reduce(0, +)
        if totalAnnounced == cardsPerPlayer {
            return false // Total cannot equal cards per player
        }
        
        pushUndoSnapshot()
        
        activeGame!.rounds[rIdx].announcements = newAnnouncements
        activeGame!.rounds[rIdx].results = newResults
        
        // Re-calculate scores for this round and all subsequent rounds
        for idx in rIdx..<activeGame!.rounds.count {
            if activeGame!.rounds[idx].roundScores.isEmpty && idx > rIdx { break }
            computeRoundScores(roundIndex: idx)
        }
        
        // Update final scores if game finished
        if activeGame!.status == .finished, let lastRound = activeGame!.rounds.last {
            activeGame!.finalScores = lastRound.cumulativeScores
            var scoreList: [(name: String, score: Int)] = []
            for p in activeGame!.players {
                let score = lastRound.cumulativeScores[p.position] ?? 0
                scoreList.append((p.name, score))
            }
            scoreList.sort { $0.score > $1.score }
            if let top = scoreList.first?.score {
                activeGame!.winner = scoreList.filter { $0.score == top }.map { $0.name }
            }
        }
        
        saveGame()
        return true
    }
}
