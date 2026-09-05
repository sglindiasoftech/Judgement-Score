import SwiftUI

public struct RulesView: View {
    @Binding var currentNavigation: AppScreen
    
    let rules: [String] = [
        "Two decks are used = 104 cards, for 2 to 15 players.",
        "Before the game starts, players agree on the starting number of cards per player.",
        "Cards per player decrease by 1 each round, down to 1 card in the final round.",
        "The dealer rotates to the next player after every round.",
        "The player to the dealer's left announces first; the dealer always announces last.",
        "The total of all announced sets can never equal the number of cards dealt that round. The app blocks the dealer from making it equal.",
        "If a player's actual sets made equal their announcement, they score 10 + announced sets.",
        "If a player misses their announcement (over or under), they score minus their announced sets.",
        "The game ends after the round with 1 card each. Highest total score wins."
    ]
    
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
                Text("How to Play")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.text)
                Spacer()
                Color.clear.frame(width: 34, height: 34)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            ScrollView {
                VStack(spacing: 16) {
                    FeltCardView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(rules.enumerated()), id: \.offset) { idx, rule in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("•")
                                        .font(.system(size: 16, weight: .black))
                                        .foregroundColor(AppTheme.gold)
                                    
                                    Text(rule)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppTheme.text)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            
                            Divider()
                                .background(AppTheme.border)
                                .padding(.vertical, 4)
                            
                            Text("Example: 7 cards, announcements are 3, 2, then the dealer cannot say 2 (since 3+2+2=7). If the dealer says 1 and makes it, they score 10+1=11. If a player announces 3 but only makes 2, they score -3.")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(AppTheme.textDim)
                                .italic()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
        }
        .feltBackground()
    }
}
