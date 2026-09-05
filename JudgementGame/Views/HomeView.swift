import SwiftUI

public struct HomeView: View {
    @EnvironmentObject var stateManager: GameStateManager
    @Binding var currentNavigation: AppScreen
    
    public var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 20)
            
            // App Header
            VStack(spacing: 8) {
                Text("♠ Judgement")
                    .font(.system(size: 38, weight: .black, design: .serif))
                    .foregroundColor(AppTheme.gold)
                    .shadow(color: AppTheme.gold.opacity(0.4), radius: 8, x: 0, y: 4)
                
                Text("Score keeper for friends & family")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.textDim)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Actions
            VStack(spacing: 14) {
                PrimaryGoldButton(title: "New Game", iconName: "plus.circle.fill") {
                    stateManager.initNewGameSetup()
                    currentNavigation = .setup
                }
                
                if stateManager.activeGame != nil && stateManager.activeGame?.status == .active {
                    SecondaryFeltButton(title: "Resume Game in Progress", iconName: "play.circle.fill") {
                        routeToActiveGameScreen()
                    }
                }
                
                SecondaryFeltButton(title: "Game History", iconName: "clock.arrow.circlepath") {
                    currentNavigation = .history
                }
                
                SecondaryFeltButton(title: "Rules / How to Play", iconName: "book.fill") {
                    currentNavigation = .rules
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Footer
            Text("Works fully offline. Your games stay on this device.")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(AppTheme.textDim)
                .multilineTextAlignment(.center)
                .padding(.bottom, 24)
        }
        .feltBackground()
    }
    
    private func routeToActiveGameScreen() {
        guard let activeGame = stateManager.activeGame, let round = activeGame.rounds.last else {
            return
        }
        switch round.phase {
        case .announce:
            currentNavigation = .announce
        case .actual:
            currentNavigation = .actual
        case .summary:
            currentNavigation = .summary
        }
    }
}
