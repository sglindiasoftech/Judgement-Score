import SwiftUI

public struct ManagePlayersSheetView: View {
    @EnvironmentObject var stateManager: GameStateManager
    @Environment(\.dismiss) var dismiss
    
    @State private var playerToToggle: Player? = nil
    @State private var showConfirmAlert: Bool = false
    
    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Manage Players")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.gold)
                    Text("Freeze player score by quitting at any time")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textDim)
                }
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
                    VStack(spacing: 12) {
                        ForEach(game.players, id: \.position) { player in
                            let currentTotal = game.rounds.last?.cumulativeScores[player.position] ?? 0
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(player.name.uppercased())
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(AppTheme.text)
                                        
                                        if player.hasQuit {
                                            Text("🧊 QUIT (FROZEN)")
                                                .font(.system(size: 10, weight: .black))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color(red: 224/255.0, green: 242/255.0, blue: 254/255.0))
                                                .foregroundColor(Color(red: 3/255.0, green: 105/255.0, blue: 161/255.0))
                                                .cornerRadius(6)
                                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(red: 3/255.0, green: 105/255.0, blue: 161/255.0).opacity(0.3), lineWidth: 1))
                                        } else {
                                            Text("ACTIVE")
                                                .font(.system(size: 10, weight: .black))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(AppTheme.feltLight)
                                                .foregroundColor(AppTheme.success)
                                                .cornerRadius(6)
                                        }
                                    }
                                    
                                    Text("Score: \(currentTotal) pts")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppTheme.textDim)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    playerToToggle = player
                                    showConfirmAlert = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: player.hasQuit ? "arrow.uturn.backward.circle.fill" : "snowflake")
                                        Text(player.hasQuit ? "Rejoin" : "Quit Game")
                                    }
                                    .font(.system(size: 13, weight: .bold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(player.hasQuit ? AppTheme.feltLight : AppTheme.danger.opacity(0.2))
                                    .foregroundColor(player.hasQuit ? AppTheme.gold : AppTheme.danger)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(player.hasQuit ? AppTheme.border : AppTheme.danger.opacity(0.6), lineWidth: 1)
                                    )
                                }
                            }
                            .padding(12)
                            .background(AppTheme.cardBg)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 16)
                }
            } else {
                Text("No active game")
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.textDim)
                    .padding()
            }
            
            PrimaryGoldButton(title: "Done", iconName: nil) {
                dismiss()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .feltBackground()
        .alert(isPresented: $showConfirmAlert) {
            if let p = playerToToggle {
                let isQuitting = !p.hasQuit
                let actionText = isQuitting ? "Quit Game & Freeze Score?" : "Rejoin Game?"
                let messageText = isQuitting ? "\(p.name)'s score will be frozen at its current total and will not increase or decrease for any remaining rounds." : "\(p.name) will rejoin active play for upcoming rounds."
                
                return Alert(
                    title: Text(actionText),
                    message: Text(messageText),
                    primaryButton: .destructive(Text(isQuitting ? "Yes, Quit Game" : "Rejoin")) {
                        stateManager.togglePlayerQuitStatus(playerIndex: p.position)
                    },
                    secondaryButton: .cancel()
                )
            } else {
                return Alert(title: Text("Manage Player"))
            }
        }
    }
}
