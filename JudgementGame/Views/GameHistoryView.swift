import SwiftUI

public struct GameHistoryView: View {
    @EnvironmentObject var stateManager: GameStateManager
    @Binding var currentNavigation: AppScreen
    @State private var selectedGame: Game?
    @State private var gameToDelete: Game? = nil
    @State private var showClearAllAlert: Bool = false
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Nav
            HStack {
                Button(action: {
                    currentNavigation = .home
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppTheme.gold)
                }
                Spacer()
                Text("Game History")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.text)
                Spacer()
                if !stateManager.history.isEmpty {
                    Button(action: {
                        showClearAllAlert = true
                    }) {
                        Text("Clear All")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppTheme.danger)
                    }
                } else {
                    Color.clear.frame(width: 34, height: 34)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            if stateManager.history.isEmpty && stateManager.activeGame == nil {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundColor(AppTheme.textDim)
                    Text("No completed games yet.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.textDim)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        // Active game banner if available
                        if let active = stateManager.activeGame {
                            Button(action: {
                                selectedGame = active
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(formattedDate(active.date))
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(AppTheme.text)
                                            
                                            Text("IN PROGRESS")
                                                .font(.system(size: 10, weight: .black))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(AppTheme.gold)
                                                .foregroundColor(.white)
                                                .cornerRadius(6)
                                        }
                                        
                                        Text("\(active.numPlayers) players · started \(active.startingCards) cards")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(AppTheme.textDim)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppTheme.gold)
                                }
                                .padding(14)
                                .background(AppTheme.feltLight)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.gold, lineWidth: 1.5))
                            }
                        }
                        
                        ForEach(stateManager.history) { game in
                            HStack(spacing: 8) {
                                Button(action: {
                                    selectedGame = game
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(formattedDate(game.date))
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(AppTheme.text)
                                            
                                            let winnerStr = game.winner?.joined(separator: " & ") ?? "-"
                                            Text("\(game.numPlayers) players · started \(game.startingCards) cards · won by \(winnerStr)")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(AppTheme.textDim)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(AppTheme.textDim)
                                    }
                                }
                                
                                Button(action: {
                                    gameToDelete = game
                                }) {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.danger)
                                        .padding(10)
                                        .background(AppTheme.danger.opacity(0.15))
                                        .clipShape(Circle())
                                }
                            }
                            .padding(12)
                            .background(AppTheme.cardBg)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                }
            }
        }
        .feltBackground()
        .sheet(item: $selectedGame) { game in
            GameHistoryDetailView(game: game)
                .environmentObject(stateManager)
        }
        .alert("Clear All History?", isPresented: $showClearAllAlert) {
            Button("Clear All", role: .destructive) {
                stateManager.clearAllHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to permanently delete all completed game records from history?")
        }
        .alert("Delete Game Record?", isPresented: Binding(
            get: { gameToDelete != nil },
            set: { if !$0 { gameToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let target = gameToDelete {
                    stateManager.deleteGameFromHistory(gameId: target.gameId)
                    gameToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                gameToDelete = nil
            }
        } message: {
            if let target = gameToDelete {
                Text("Are you sure you want to delete the game played on \(formattedDate(target.date))?")
            } else {
                Text("Are you sure you want to delete this game record?")
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
