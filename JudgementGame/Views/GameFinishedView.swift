import SwiftUI

public struct GameFinishedView: View {
    @EnvironmentObject var stateManager: GameStateManager
    @Binding var currentNavigation: AppScreen
    
    var activeGame: Game? {
        stateManager.activeGame
    }
    
    var rankedPlayers: [(name: String, score: Int, rank: Int, isWinner: Bool)] {
        guard let game = activeGame, let finalScores = game.finalScores else { return [] }
        var list = game.players.map { (name: $0.name, score: finalScores[$0.position] ?? 0) }
        list.sort { $0.score > $1.score }
        
        var result: [(name: String, score: Int, rank: Int, isWinner: Bool)] = []
        let topScore = list.first?.score ?? 0
        
        for (idx, item) in list.enumerated() {
            let isWinner = (item.score == topScore)
            result.append((name: item.name, score: item.score, rank: idx + 1, isWinner: isWinner))
        }
        return result
    }
    
    var winnerText: String {
        guard let game = activeGame, let winners = game.winner, !winners.isEmpty else { return "Winner" }
        if winners.count == 1 {
            return winners[0]
        } else {
            return "Tied: " + winners.joined(separator: " & ")
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Text("Game Finished")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.text)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Trophy Emblem
                    Text("🏆")
                        .font(.system(size: 64))
                        .padding(.top, 10)
                    
                    VStack(spacing: 4) {
                        Text("WINNER")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppTheme.goldDim)
                        
                        Text(winnerText)
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(AppTheme.gold)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Final Scores Card
                    FeltCardView {
                        Text("Final Scores")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.gold)
                            .padding(.bottom, 4)
                        
                        VStack(spacing: 10) {
                            ForEach(rankedPlayers, id: \.name) { item in
                                HStack {
                                    Text("\(item.rank).")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppTheme.textDim)
                                        .frame(width: 24, alignment: .leading)
                                    
                                    HStack(spacing: 6) {
                                        Text(item.name.uppercased())
                                            .font(.system(size: 16, weight: item.isWinner ? .heavy : .bold))
                                            .foregroundColor(item.isWinner ? AppTheme.gold : AppTheme.text)
                                        
                                        if item.isWinner {
                                            Text("🏆")
                                                .font(.system(size: 14))
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(item.score)")
                                        .font(.system(size: 18, weight: .black))
                                        .foregroundColor(item.isWinner ? AppTheme.gold : AppTheme.text)
                                }
                                .padding(10)
                                .background(item.isWinner ? AppTheme.feltLight : AppTheme.cardBg)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(item.isWinner ? AppTheme.gold : AppTheme.border, lineWidth: item.isWinner ? 1.5 : 1)
                                )
                            }
                        }
                    }
                    
                    VStack(spacing: 12) {
                        PrimaryGoldButton(title: "Back to Home", iconName: "house.fill") {
                            stateManager.archiveCurrentGameToHistory()
                            currentNavigation = .home
                        }
                        
                        SecondaryFeltButton(title: "View Full Scorecard", iconName: "list.bullet.rectangle.fill") {
                            stateManager.archiveCurrentGameToHistory()
                            currentNavigation = .history
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 16)
            }
        }
        .feltBackground()
    }
}
