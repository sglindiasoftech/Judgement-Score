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
                        showGameOptionsAlert = true
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
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
                            
                            // DOUBLE SIZE + YELLOW COLOR FOR "Dealer:" AND DEALER NAME
                            HStack {
                                Text("Dealer:")
                                    .font(.system(size: 28, weight: .black))
                                    .foregroundColor(Color.yellow)
                                Spacer()
                                let dealerName = game.players.first(where: { $0.position == round.dealerIndex })?.name ?? "Dealer"
                                Text(dealerName)
                                    .font(.system(size: 28, weight: .black))
                                    .foregroundColor(Color.yellow)
                                    .shadow(color: Color.yellow.opacity(0.5), radius: 6, x: 0, y: 2)
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
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mark Win or Lost")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppTheme.gold)
                            
                            Text("Everyone defaults to Win (+10 + bid). Select \"Lost\" (-bid) only for players who missed their announcement.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.textDim)
                        }
                        .padding(.top, 4)
                        
                        // Player Outcome List
                        VStack(spacing: 10) {
                            ForEach(game.players, id: \.position) { player in
                                let announced = round.announcements[player.position] ?? 0
                                let currentOutcome = round.results[player.position] ?? .win
                                let isDealer = player.position == round.dealerIndex
                                
                                PlayerResultRow(
                                    player: player,
                                    isDealer: isDealer,
                                    announced: announced,
                                    currentOutcome: currentOutcome,
                                    onSelectOutcome: { newOutcome in
                                        stateManager.setActualResult(playerIndex: player.position, outcome: newOutcome)
                                    }
                                )
                            }
                        }
                        
                        PrimaryGoldButton(title: "Submit Round", iconName: "arrow.right.circle.fill") {
                            stateManager.finishRound()
                            currentNavigation = .summary
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
    let onSelectOutcome: (RoundOutcome) -> Void
    
    var previewScore: Int {
        if player.hasQuit { return 0 }
        return currentOutcome == .win ? (10 + announced) : (-announced)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(player.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(player.hasQuit ? AppTheme.textDim : AppTheme.text)
                    
                    if isDealer && !player.hasQuit {
                        Text("DEALER")
                            .font(.system(size: 11, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow)
                            .foregroundColor(Color(red: 18/255.0, green: 51/255.0, blue: 31/255.0))
                            .cornerRadius(6)
                    }
                    
                    if player.hasQuit {
                        Text("🧊 QUIT")
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.3))
                            .foregroundColor(Color.cyan)
                            .cornerRadius(6)
                    }
                }
                
                if player.hasQuit {
                    Text("Score Frozen (0 pt this round)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.cyan)
                } else {
                    HStack(spacing: 8) {
                        Text("Bid: \(announced)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textDim)
                        
                        Text(previewScore >= 0 ? "+\(previewScore)" : "\(previewScore)")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(previewScore >= 0 ? AppTheme.success : AppTheme.danger)
                    }
                }
            }
            
            Spacer()
            
            if player.hasQuit {
                Text("Frozen")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.cyan)
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
                        .frame(width: 72, height: 38)
                        .background(currentOutcome == .win ? AppTheme.success : AppTheme.feltGreen)
                        .foregroundColor(currentOutcome == .win ? Color(red: 11/255.0, green: 46/255.0, blue: 28/255.0) : AppTheme.textDim)
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
                        .frame(width: 72, height: 38)
                        .background(currentOutcome == .lost ? AppTheme.danger : AppTheme.feltGreen)
                        .foregroundColor(currentOutcome == .lost ? .white : AppTheme.textDim)
                        .cornerRadius(8)
                    }
                }
                .padding(3)
                .background(AppTheme.feltGreen)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border, lineWidth: 1))
            }
        }
        .padding(12)
        .background(AppTheme.feltLight)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDealer ? Color.yellow : (currentOutcome == .lost ? AppTheme.danger.opacity(0.6) : AppTheme.border), lineWidth: isDealer ? 1.5 : 1)
        )
    }
}
