import SwiftUI

public struct ScoreboardSheetView: View {
    @EnvironmentObject var stateManager: GameStateManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showAbortConfirmAlert: Bool = false
    @State private var isManagePlayersPresented: Bool = false
    @State private var roundToEdit: Round? = nil
    
    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Score Sheet")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.gold)
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.textDim)
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
            
            if let game = stateManager.activeGame {
                ScrollView {
                    VStack(spacing: 16) {
                        ScoreboardTableView(game: game)
                        
                        let completedRounds = game.rounds.filter { !$0.roundScores.isEmpty }
                        if !completedRounds.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("EDIT COMPLETED ROUNDS")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(AppTheme.goldDim)
                                
                                ForEach(completedRounds, id: \.roundNumber) { round in
                                    FeltCardView {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Round \(round.roundNumber) — \(round.cardsPerPlayer) cards")
                                                    .font(.system(size: 15, weight: .bold))
                                                    .foregroundColor(AppTheme.gold)
                                                Text("Tap Edit to adjust announced sets or win/lost outcomes")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(AppTheme.textDim)
                                            }
                                            Spacer()
                                            Button(action: {
                                                roundToEdit = round
                                            }) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "pencil")
                                                        .font(.system(size: 12, weight: .bold))
                                                    Text("Edit")
                                                        .font(.system(size: 13, weight: .bold))
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(AppTheme.gold)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .sheet(item: $roundToEdit) { round in
                    EditRoundSheetView(game: game, round: round)
                        .environmentObject(stateManager)
                }
            } else {
                Text("No active game")
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.textDim)
                    .padding()
            }
            
            VStack(spacing: 10) {
                Button(action: {
                    isManagePlayersPresented = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.minus")
                        Text("Manage Players (Quit Game / Freeze Score)")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.gold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.feltLight)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border, lineWidth: 1))
                }
                
                PrimaryGoldButton(title: "Close Score Sheet", iconName: nil) {
                    dismiss()
                }
                
                Button(action: {
                    showAbortConfirmAlert = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.octagon.fill")
                        Text("Abort Running Game")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.danger)
                    .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .feltBackground()
        .alert("Abort Game?", isPresented: $showAbortConfirmAlert) {
            Button("Yes, Abort Game", role: .destructive) {
                dismiss()
                stateManager.clearSavedGame()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to abort the running game? All current game progress will be permanently cleared.")
        }
        .sheet(isPresented: $isManagePlayersPresented) {
            ManagePlayersSheetView()
                .environmentObject(stateManager)
        }
    }
}
