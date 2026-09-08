import SwiftUI

public struct GameHistoryDetailView: View {
    let game: Game
    @EnvironmentObject var stateManager: GameStateManager
    @Environment(\.dismiss) var dismiss
    
    @State private var roundToEdit: Round?
    @State private var showDeleteConfirmAlert: Bool = false
    
    var currentGame: Game {
        if stateManager.activeGame?.gameId == game.gameId {
            return stateManager.activeGame!
        }
        return game
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Nav Bar
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(AppTheme.gold)
                }
                Spacer()
                Text(formattedDate(currentGame.date))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.text)
                Spacer()
                Color.clear.frame(width: 50, height: 34)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            ScrollView {
                VStack(spacing: 14) {
                    // Summary Card
                    FeltCardView {
                        HStack {
                            Text("Players")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.textDim)
                            Spacer()
                            Text(currentGame.players.map { $0.name.uppercased() }.joined(separator: ", "))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.text)
                                .lineLimit(1)
                        }
                        
                        HStack {
                            Text("Starting cards")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.textDim)
                            Spacer()
                            Text("\(currentGame.startingCards)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.text)
                        }
                        
                        HStack {
                            Text("Winner")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.textDim)
                            Spacer()
                            let winnerStr = currentGame.winner?.joined(separator: " & ") ?? "-"
                            Text(winnerStr)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.gold)
                        }
                    }
                    
                    // Scoreboard Overview Table
                    ScoreboardTableView(game: currentGame)
                    
                    // Detailed Round Cards
                    ForEach(currentGame.rounds.filter { !$0.roundScores.isEmpty }, id: \.roundNumber) { round in
                        FeltCardView {
                            HStack {
                                Text("Round \(round.roundNumber) — \(round.cardsPerPlayer) cards")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppTheme.gold)
                                Spacer()
                                Button(action: {
                                    roundToEdit = round
                                }) {
                                    Text("Edit")
                                        .font(.system(size: 13, weight: .semibold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(AppTheme.feltLight)
                                        .foregroundColor(AppTheme.text)
                                        .cornerRadius(6)
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppTheme.border, lineWidth: 1))
                                }
                            }
                            .padding(.bottom, 6)
                            
                            VStack(spacing: 6) {
                                HStack {
                                    Text("PLAYER")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text("ANN")
                                        .frame(width: 36, alignment: .center)
                                    Text("OUTCOME")
                                        .frame(width: 66, alignment: .center)
                                    Text("SCORE")
                                        .frame(width: 50, alignment: .trailing)
                                    Text("TOTAL")
                                        .frame(width: 50, alignment: .trailing)
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AppTheme.goldDim)
                                
                                Divider().background(AppTheme.border)
                                
                                ForEach(currentGame.players, id: \.position) { player in
                                    let ann = round.announcements[player.position] ?? 0
                                    let won = round.results[player.position] == .win
                                    let sc = round.roundScores[player.position] ?? 0
                                    let cum = round.cumulativeScores[player.position] ?? 0
                                    
                                    HStack {
                                        Text(player.name.uppercased())
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(AppTheme.text)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Text("\(ann)")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(AppTheme.text)
                                            .frame(width: 36, alignment: .center)
                                        
                                        Text(won ? "WIN" : "LOST")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(won ? AppTheme.success : AppTheme.danger)
                                            .frame(width: 66, alignment: .center)
                                        
                                        Text(sc >= 0 ? "+\(sc)" : "\(sc)")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(sc >= 0 ? AppTheme.success : AppTheme.danger)
                                            .frame(width: 50, alignment: .trailing)
                                        
                                        Text("\(cum)")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(AppTheme.text)
                                            .frame(width: 50, alignment: .trailing)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                    
                    // Delete Game Record Button
                    Button(action: {
                        showDeleteConfirmAlert = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash.fill")
                            Text("Delete Game Record")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppTheme.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.danger.opacity(0.15))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.danger.opacity(0.4), lineWidth: 1))
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
        }
        .feltBackground()
        .sheet(item: $roundToEdit) { round in
            EditRoundSheetView(game: currentGame, round: round)
                .environmentObject(stateManager)
        }
        .alert("Delete Game Record?", isPresented: $showDeleteConfirmAlert) {
            Button("Delete", role: .destructive) {
                stateManager.deleteGameFromHistory(gameId: currentGame.gameId)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to permanently delete this game record from your history?")
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
