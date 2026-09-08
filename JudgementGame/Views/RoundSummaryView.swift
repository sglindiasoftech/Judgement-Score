import SwiftUI

public struct RoundSummaryView: View {
    @EnvironmentObject var stateManager: GameStateManager
    @Binding var currentNavigation: AppScreen
    
    @State private var showGameOptionsAlert: Bool = false
    @State private var showAbortConfirmAlert: Bool = false
    @State private var showUndoConfirmAlert: Bool = false
    
    var currentRound: Round? {
        stateManager.activeGame?.rounds.last
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if let game = stateManager.activeGame, let round = currentRound {
                // Header Nav
                HStack {
                    Button(action: {
                        showGameOptionsAlert = true
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppTheme.gold)
                    }
                    Spacer()
                    Text("Round \(round.roundNumber) Result")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.text)
                    Spacer()
                    HStack(spacing: 8) {
                        Button(action: {
                            showUndoConfirmAlert = true
                        }) {
                            Text("Undo")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppTheme.feltLight)
                                .foregroundColor(AppTheme.gold)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border, lineWidth: 1))
                        }
                        
                        Button(action: {
                            showAbortConfirmAlert = true
                        }) {
                            Image(systemName: "xmark.octagon.fill")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.danger)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Current Round Results Table Card
                        FeltCardView {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("PLAYER")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text("ANN")
                                        .frame(width: 44, alignment: .center)
                                    Text("OUTCOME")
                                        .frame(width: 70, alignment: .center)
                                    Text("SCORE")
                                        .frame(width: 54, alignment: .trailing)
                                }
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.goldDim)
                                
                                Divider().background(AppTheme.border)
                                
                                ForEach(round.announcementOrder, id: \.self) { playerIdx in
                                    if let player = game.players.first(where: { $0.position == playerIdx }) {
                                        let ann = round.announcements[playerIdx] ?? 0
                                        let won = round.results[playerIdx] == .win
                                        let score = round.roundScores[playerIdx] ?? 0
                                        
                                        HStack {
                                            Text(player.name.uppercased())
                                                .font(.system(size: 14, weight: .bold))
                                                .lineLimit(1)
                                                .allowsTightening(true)
                                                .minimumScaleFactor(0.4)
                                                .foregroundColor(AppTheme.text)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            Text("\(ann)")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(AppTheme.text)
                                                .frame(width: 44, alignment: .center)
                                            
                                            Text(won ? "WIN" : "LOST")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(won ? AppTheme.success : AppTheme.danger)
                                                .frame(width: 70, alignment: .center)
                                            
                                            Text(score >= 0 ? "+\(score)" : "\(score)")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(score >= 0 ? AppTheme.success : AppTheme.danger)
                                                .frame(width: 54, alignment: .trailing)
                                        }
                                        .padding(.vertical, 4)
                                        
                                        if playerIdx != round.announcementOrder.last {
                                            Divider().background(AppTheme.border.opacity(0.5))
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Full Scoreboard Standings with 25%+ enlarged digits
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Scoresheet (All rounds & Total Sum)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppTheme.gold)
                            
                            ScoreboardTableView(game: game)
                        }
                        .padding(.top, 4)
                        
                        let isLastRound = round.cardsPerPlayer == 1
                        PrimaryGoldButton(
                            title: isLastRound ? "Finish Game" : "Next Round",
                            iconName: isLastRound ? "trophy.fill" : "arrow.right.circle.fill"
                        ) {
                            if isLastRound {
                                stateManager.finishGame()
                                currentNavigation = .finished
                            } else {
                                stateManager.goNextRound()
                                currentNavigation = .announce
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .feltBackground()
        .confirmationDialog("Game Options", isPresented: $showGameOptionsAlert, titleVisibility: .visible) {
            Button("Pause & Save (Resume Later)") {
                currentNavigation = .home
            }
            Button("Abort & End Game", role: .destructive) {
                showAbortConfirmAlert = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("What would you like to do with the current running game?")
        }
        .alert("Abort Game?", isPresented: $showAbortConfirmAlert) {
            Button("Yes, Abort Game", role: .destructive) {
                stateManager.clearSavedGame()
                currentNavigation = .home
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to abort the running game? All current game progress will be permanently cleared.")
        }
        .alert("Undo Last Round?", isPresented: $showUndoConfirmAlert) {
            Button("Undo", role: .destructive) {
                stateManager.undoLastRound()
                if let r = stateManager.activeGame?.rounds.last {
                    switch r.phase {
                    case .announce: currentNavigation = .announce
                    case .actual: currentNavigation = .actual
                    case .summary: currentNavigation = .summary
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the most recently submitted round result so you can re-enter it.")
        }
    }
}

// Scoreboard Table Component with +25% enlarged digits for supreme clarity
public struct ScoreboardTableView: View {
    let game: Game
    
    var totalGameRounds: Int {
        game.startingCards
    }
    
    var playedRounds: [Round] {
        game.rounds.filter { !$0.roundScores.isEmpty }
    }
    
    var currentTotals: [Int: Int] {
        if let last = playedRounds.last {
            return last.cumulativeScores
        }
        var res: [Int: Int] = [:]
        for p in game.players { res[p.position] = 0 }
        return res
    }
    
    var topScore: Int {
        currentTotals.values.max() ?? 0
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Played \(playedRounds.count) of \(totalGameRounds) rounds")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppTheme.textDim)
                .padding(.leading, 2)
            
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    // Table Header
                    HStack(spacing: 0) {
                        Text("Round")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(AppTheme.goldDim)
                            .frame(width: 102, alignment: .leading)
                        
                        ForEach(game.players, id: \.position) { player in
                            VStack(spacing: 1) {
                                Text(player.name.uppercased())
                                    .font(.system(size: 15, weight: .black))
                                    .lineLimit(1)
                                    .allowsTightening(true)
                                    .minimumScaleFactor(0.4)
                                    .foregroundColor(player.hasQuit ? AppTheme.textDim : AppTheme.gold)
                                if player.hasQuit {
                                    Text("🧊 QUIT")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(Color(red: 3/255.0, green: 105/255.0, blue: 161/255.0))
                                }
                            }
                            .frame(width: 96, alignment: .center)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(AppTheme.feltLight)
                    
                    Divider().background(AppTheme.border)
                    
                    // Display all 1 to N rounds (e.g. 7 down to 1 cards) with 25% larger digits (17pt)
                    ForEach(1...totalGameRounds, id: \.self) { roundNum in
                        let cards = game.startingCards - (roundNum - 1)
                        let roundObj = playedRounds.first(where: { $0.roundNumber == roundNum })
                        let isPlayed = roundObj != nil
                        
                        HStack(spacing: 0) {
                            Text("R\(roundNum) (\(cards)c)")
                                .font(.system(size: 15, weight: isPlayed ? .bold : .regular))
                                .foregroundColor(isPlayed ? AppTheme.text : AppTheme.textDim.opacity(0.6))
                                .frame(width: 102, alignment: .leading)
                            
                            ForEach(game.players, id: \.position) { player in
                                if let r = roundObj, let sc = r.roundScores[player.position] {
                                    if player.hasQuit && roundNum >= (player.quitRound ?? 0) {
                                        Text("🧊 0")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(Color(red: 3/255.0, green: 105/255.0, blue: 161/255.0))
                                            .frame(width: 96, alignment: .center)
                                    } else {
                                        Text(sc >= 0 ? "+\(sc)" : "\(sc)")
                                            .font(.system(size: 17, weight: .heavy))
                                            .foregroundColor(sc >= 0 ? AppTheme.success : AppTheme.danger)
                                            .frame(width: 96, alignment: .center)
                                    }
                                } else {
                                    Text("-")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(AppTheme.textDim.opacity(0.4))
                                        .frame(width: 96, alignment: .center)
                                }
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(isPlayed ? AppTheme.cardBg : AppTheme.feltGreen.opacity(0.3))
                        
                        Divider().background(AppTheme.border.opacity(0.4))
                    }
                    
                    // TOTAL SCORE Sum Row with 25% larger digits (20pt)
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("TOTAL SCORE")
                                .font(.system(size: 13, weight: .black))
                                .foregroundColor(AppTheme.gold)
                            Text("Sum till now")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AppTheme.textDim)
                        }
                        .frame(width: 102, alignment: .leading)
                        
                        ForEach(game.players, id: \.position) { player in
                            let val = currentTotals[player.position] ?? 0
                            let isLeader = (playedRounds.count > 0 && val == topScore && !player.hasQuit)
                            
                            VStack(spacing: 1) {
                                HStack(spacing: 3) {
                                    Text("\(val)")
                                        .font(.system(size: 20, weight: .black))
                                        .foregroundColor(player.hasQuit ? Color(red: 3/255.0, green: 105/255.0, blue: 161/255.0) : (isLeader ? AppTheme.gold : AppTheme.text))
                                    if isLeader {
                                        Text("⭐")
                                            .font(.system(size: 13))
                                    }
                                }
                                if player.hasQuit {
                                    Text("FROZEN")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(Color(red: 3/255.0, green: 105/255.0, blue: 161/255.0))
                                }
                            }
                            .frame(width: 96, alignment: .center)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 12)
                    .background(AppTheme.cardBg)
                    .overlay(Rectangle().frame(height: 2.5).foregroundColor(AppTheme.gold), alignment: .top)
                }
                .background(AppTheme.cardBg)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
            }
        }
    }
}
