import SwiftUI

public enum AppScreen: Hashable {
    case home
    case setup
    case announce
    case actual
    case summary
    case finished
    case history
    case rules
}

public struct ContentView: View {
    @StateObject private var stateManager = GameStateManager()
    @State private var currentNavigation: AppScreen = .home
    
    public var body: some View {
        ZStack {
            switch currentNavigation {
            case .home:
                HomeView(currentNavigation: $currentNavigation)
            case .setup:
                NewGameSetupView(currentNavigation: $currentNavigation)
            case .announce:
                AnnounceRoundView(currentNavigation: $currentNavigation)
            case .actual:
                MarkResultsView(currentNavigation: $currentNavigation)
            case .summary:
                RoundSummaryView(currentNavigation: $currentNavigation)
            case .finished:
                GameFinishedView(currentNavigation: $currentNavigation)
            case .history:
                GameHistoryView(currentNavigation: $currentNavigation)
            case .rules:
                RulesView(currentNavigation: $currentNavigation)
            }
        }
        .environmentObject(stateManager)
    }
}
