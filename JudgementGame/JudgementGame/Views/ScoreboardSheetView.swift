import SwiftUI

public struct ScoreboardSheetView: View {
    @EnvironmentObject var stateManager: GameStateManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showAbortConfirmAlert: Bool = false
    @State private var isManagePlayersPresented: Bool = false
    
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
                    ScoreboardTableView(game: game)
                        .padding(.horizontal, 16)
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
