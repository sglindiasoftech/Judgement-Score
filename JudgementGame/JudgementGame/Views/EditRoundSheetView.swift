import SwiftUI
import UIKit
import AudioToolbox

public struct EditRoundSheetView: View {
    let game: Game
    let round: Round
    
    @EnvironmentObject var stateManager: GameStateManager
    @Environment(\.dismiss) var dismiss
    
    @State private var announcements: [Int: Int] = [:]
    @State private var results: [Int: RoundOutcome] = [:]
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    public init(game: Game, round: Round) {
        self.game = game
        self.round = round
        _announcements = State(initialValue: round.announcements)
        _results = State(initialValue: round.results)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Round \(round.roundNumber)")
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
            
            ScrollView {
                VStack(spacing: 16) {
                    Text("Cards this round: \(round.cardsPerPlayer)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textDim)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                    
                    ForEach(game.players, id: \.position) { player in
                        let playerIdx = player.position
                        let currentBid = announcements[playerIdx] ?? 0
                        let currentOutcome = results[playerIdx] ?? .win
                        let previewScore = currentOutcome == .win ? (10 + currentBid) : (-currentBid)
                        
                        FeltCardView {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(player.name)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppTheme.gold)
                                    Spacer()
                                    Text(previewScore >= 0 ? "Score: +\(previewScore)" : "Score: \(previewScore)")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(previewScore >= 0 ? AppTheme.success : AppTheme.danger)
                                }
                                
                                HStack {
                                    Text("Announced Bid:")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppTheme.textDim)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 12) {
                                        Button(action: {
                                            announcements[playerIdx] = max(0, currentBid - 1)
                                        }) {
                                            Image(systemName: "minus")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(AppTheme.gold)
                                                .frame(width: 32, height: 32)
                                                .background(AppTheme.feltLight)
                                                .clipShape(Circle())
                                                .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
                                        }
                                        .disabled(currentBid <= 0)
                                        
                                        Text("\(currentBid)")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(AppTheme.text)
                                            .frame(width: 30, alignment: .center)
                                        
                                        Button(action: {
                                            announcements[playerIdx] = min(round.cardsPerPlayer, currentBid + 1)
                                        }) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(AppTheme.gold)
                                                .frame(width: 32, height: 32)
                                                .background(AppTheme.feltLight)
                                                .clipShape(Circle())
                                                .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
                                        }
                                        .disabled(currentBid >= round.cardsPerPlayer)
                                    }
                                }
                                
                                HStack {
                                    Text("Outcome:")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppTheme.textDim)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 4) {
                                        Button(action: {
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                                results[playerIdx] = .win
                                            }
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 11))
                                                Text("Win")
                                                    .font(.system(size: 13, weight: .bold))
                                            }
                                            .frame(width: 64, height: 34)
                                            .background(currentOutcome == .win ? AppTheme.success : AppTheme.feltGreen)
                                            .foregroundColor(currentOutcome == .win ? Color(red: 11/255.0, green: 46/255.0, blue: 28/255.0) : AppTheme.textDim)
                                            .cornerRadius(6)
                                        }
                                        
                                        Button(action: {
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                                results[playerIdx] = .lost
                                            }
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 11))
                                                Text("Lost")
                                                    .font(.system(size: 13, weight: .bold))
                                            }
                                            .frame(width: 64, height: 34)
                                            .background(currentOutcome == .lost ? AppTheme.danger : AppTheme.feltGreen)
                                            .foregroundColor(currentOutcome == .lost ? .white : AppTheme.textDim)
                                            .cornerRadius(6)
                                        }
                                    }
                                    .padding(3)
                                    .background(AppTheme.feltGreen)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border, lineWidth: 1))
                                }
                            }
                        }
                    }
                    
                    VStack(spacing: 10) {
                        PrimaryGoldButton(title: "Save Changes", iconName: "checkmark.circle.fill") {
                            let totalAnnounced = announcements.values.reduce(0, +)
                            if totalAnnounced == round.cardsPerPlayer {
                                SoundManager.shared.playBellAlertSound()
                                alertMessage = "Total announced cannot equal cards per player (\(round.cardsPerPlayer)). Adjust one value."
                                showAlert = true
                                return
                            }
                            
                            let success = stateManager.saveEditedRound(
                                roundNumber: round.roundNumber,
                                newAnnouncements: announcements,
                                newResults: results
                            )
                            if success {
                                dismiss()
                            } else {
                                alertMessage = "Failed to save edits."
                                showAlert = true
                            }
                        }
                        
                        SecondaryFeltButton(title: "Cancel", iconName: nil) {
                            dismiss()
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 16)
            }
        }
        .feltBackground()
        .alert("Invalid Edits", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
}
