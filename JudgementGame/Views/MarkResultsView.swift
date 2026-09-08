import SwiftUI
import UIKit

public struct MarkResultsView: View {
    @EnvironmentObject var stateManager: GameStateManager
    @Binding var currentNavigation: AppScreen
    
    @State private var showGameOptionsAlert: Bool = false
    @State private var showAbortConfirmAlert: Bool = false
    @State private var isScoreboardModalPresented: Bool = false
    @State private var isManagePlayersPresented: Bool = false
    
    var currentRound: Round? {
        stateManager.activeGame?.rounds.last
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if let game = stateManager.activeGame, let round = currentRound {
                // Header Nav
                HStack {
                    Button(action: {
                        stateManager.returnToAnnouncePhase()
                        currentNavigation = .announce
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                            Text("Edit Bids")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(AppTheme.gold)
                    }
                    Spacer()
                    Text("Round \(round.roundNumber)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.text)
                    Spacer()
                    HStack(spacing: 6) {
                        Button(action: {
                            isManagePlayersPresented = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.2.fill")
                                Text("Players")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(AppTheme.feltLight)
                            .foregroundColor(AppTheme.text)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border, lineWidth: 1))
                        }
                        
                        Button(action: {
                            isScoreboardModalPresented = true
                        }) {
                            Text("Scores")
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(AppTheme.feltLight)
                                .foregroundColor(AppTheme.text)
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
                    VStack(spacing: 14) {
                        // Card info summary with Prominent Yellow Double-Sized Dealer Banner
                        FeltCardView {
                            HStack {
                                Text("Cards this round")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppTheme.textDim)
                                Spacer()
                                Text("\(round.cardsPerPlayer)")
                                    .font(.system(size: 28, weight: .heavy))
                                    .foregroundColor(AppTheme.gold)
                            }
                            
                            Divider()
                                .background(AppTheme.border)
                                .padding(.vertical, 2)
                            
                            // DOUBLE SIZE + DARK BLUE COLOR FOR "Dealer:" AND BLACK FOR DEALER NAME
                            HStack {
                                 Text("Dealer:")
                                     .font(.system(size: 28, weight: .black))
                                     .foregroundColor(AppTheme.goldDim)
                                 Spacer()
                                 let dealerName = game.players.first(where: { $0.position == round.dealerIndex })?.name ?? "Dealer"
                                 Text(dealerName.uppercased())
                                     .font(.system(size: 28, weight: .black))
                                     .lineLimit(1)
                                     .allowsTightening(true)
                                     .minimumScaleFactor(0.35)
                                     .layoutPriority(1)
                                     .foregroundColor(AppTheme.text)
                            }
                            .padding(.vertical, 2)
                            
                            Divider()
                                .background(AppTheme.border)
                                .padding(.vertical, 2)
                            
                            HStack {
                                Text("Total announced (active)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppTheme.textDim)
                                Spacer()
                                Text("\(round.activeTotalAnnounced(players: game.players))")
                                    .font(.system(size: 18, weight: .heavy))
                                    .foregroundColor(AppTheme.gold)
                            }
                        }
                        
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Mark Win or Lost")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppTheme.gold)
                                
                                Text("Everyone defaults to Win (+10 + bid). Select \"Lost\" (-bid) only for players who missed their announcement.")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppTheme.textDim)
                            }
                            Spacer()
                            Button(action: {
                                stateManager.returnToAnnouncePhase()
                                currentNavigation = .announce
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("Edit Bids")
                                        .font(.system(size: 13, weight: .bold))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppTheme.feltLight)
                                .foregroundColor(AppTheme.gold)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.gold.opacity(0.3), lineWidth: 1))
                            }
                        }
                        .padding(.top, 4)
                        
                        // Player Outcome List
                        VStack(spacing: 10) {
                            ForEach(game.players, id: \.position) { player in
                                let announced = round.announcements[player.position] ?? 0
                                let currentOutcome = round.results[player.position] ?? .win
                                let isDealer = player.position == round.dealerIndex
                                let totalScore: Int = {
                                    if game.rounds.count > 1 {
                                        let prevRound = game.rounds[game.rounds.count - 2]
                                        return prevRound.cumulativeScores[player.position] ?? 0
                                    }
                                    return 0
                                }()
                                
                                PlayerResultRow(
                                    player: player,
                                    isDealer: isDealer,
                                    announced: announced,
                                    currentOutcome: currentOutcome,
                                    totalScore: totalScore,
                                    onSelectOutcome: { newOutcome in
                                        stateManager.setActualResult(playerIndex: player.position, outcome: newOutcome)
                                    }
                                )
                            }
                        }
                        
                        let isInvalidAllWin = round.isAllActiveWinningInvalid(players: game.players)
                        
                        PrimaryGoldButton(title: "Submit Round", iconName: "arrow.right.circle.fill") {
                            if stateManager.finishRound() {
                                currentNavigation = .summary
                            }
                        }
                        .disabled(isInvalidAllWin)
                        .opacity(isInvalidAllWin ? 0.4 : 1.0)
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
        .sheet(isPresented: $isScoreboardModalPresented) {
            ScoreboardSheetView()
                .environmentObject(stateManager)
        }
        .sheet(isPresented: $isManagePlayersPresented) {
            ManagePlayersSheetView()
                .environmentObject(stateManager)
        }
    }
}

// Individual Player Result Row with score preview & tactile Win/Lost tabs
struct PlayerResultRow: View {
    let player: Player
    let isDealer: Bool
    let announced: Int
    let currentOutcome: RoundOutcome
    let totalScore: Int
    let onSelectOutcome: (RoundOutcome) -> Void
    
    var previewScore: Int {
        if player.hasQuit { return 0 }
        return currentOutcome == .win ? (10 + announced) : (-announced)
    }
    
    var body: some View {
        HStack(alignment: .center) {
            // Left: Player Name (50% larger font, 24pt) & Dealer/Quit Badge
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(player.name.uppercased())
                        .font(.system(size: 24, weight: .black))
                        .lineLimit(1)
                        .allowsTightening(true)
                        .minimumScaleFactor(0.35)
                        .layoutPriority(1)
                        .foregroundColor(player.hasQuit ? AppTheme.textDim : AppTheme.text)
                    
                    if isDealer && !player.hasQuit {
                        Text("DEALER")
                            .font(.system(size: 11, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.goldDim)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                            .fixedSize()
                    }
                    
                    if player.hasQuit {
                        Text("🧊 QUIT")
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(red: 224/255.0, green: 242/255.0, blue: 254/255.0))
                            .foregroundColor(Color(red: 3/255.0, green: 105/255.0, blue: 161/255.0))
                            .cornerRadius(6)
                            .fixedSize()
                    }
                }
                
                Text("Net Score: \(totalScore)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(totalScore < 0 ? AppTheme.danger : AppTheme.gold)
            }
            
            Spacer()
            
            // Middle / Blank Space: Bid No. & Points preview (+10)
            if player.hasQuit {
                Text("Score Frozen")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 3/255.0, green: 105/255.0, blue: 161/255.0))
            } else {
                VStack(spacing: 1) {
                    Text("Bid: \(announced)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.text)
                    
                    Text(previewScore >= 0 ? "+\(previewScore)" : "\(previewScore)")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(previewScore >= 0 ? AppTheme.success : AppTheme.danger)
                }
            }
            
            Spacer()
            
            // Right: Win / Lost Buttons
            if player.hasQuit {
                Text("Frozen")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(red: 3/255.0, green: 105/255.0, blue: 161/255.0))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.cardBg)
                    .cornerRadius(8)
            } else {
                // Win / Lost Segmented Tabs
                HStack(spacing: 4) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            onSelectOutcome(.win)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                            Text("Win")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .frame(width: 68, height: 38)
                        .background(currentOutcome == .win ? AppTheme.success : AppTheme.feltLight)
                        .foregroundColor(currentOutcome == .win ? .white : AppTheme.textDim)
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            onSelectOutcome(.lost)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                            Text("Lost")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .frame(width: 68, height: 38)
                        .background(currentOutcome == .lost ? AppTheme.danger : AppTheme.feltLight)
                        .foregroundColor(currentOutcome == .lost ? .white : AppTheme.textDim)
                        .cornerRadius(8)
                    }
                }
                .padding(3)
                .background(AppTheme.feltLight)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border, lineWidth: 1))
            }
        }
        .padding(12)
        .background(AppTheme.feltLight)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDealer ? AppTheme.goldDim : (currentOutcome == .lost ? AppTheme.danger.opacity(0.6) : AppTheme.border), lineWidth: isDealer ? 1.5 : 1)
        )
    }
}
