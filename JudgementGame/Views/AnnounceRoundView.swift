import SwiftUI
import UIKit
import AudioToolbox

public struct AnnounceRoundView: View {
    @EnvironmentObject var stateManager: GameStateManager
    @Binding var currentNavigation: AppScreen
    
    @State private var showGameOptionsAlert: Bool = false
    @State private var showAbortConfirmAlert: Bool = false
    @State private var isScoreboardModalPresented: Bool = false
    @State private var isManagePlayersPresented: Bool = false
    @FocusState private var focusedPlayerIndex: Int?
    
    private func playNativeAlertSound() {
        SoundManager.shared.playBellAlertSound()
    }

    
    var currentRound: Round? {
        stateManager.activeGame?.rounds.last
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if let game = stateManager.activeGame, let round = currentRound {
                // Header Nav
                HStack {
                    Button(action: {
                        showGameOptionsAlert = true
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppTheme.gold)
                    }
                    Spacer()
                    Text("Round \(round.roundNumber)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.text)
                    Spacer()
                    HStack(spacing: 6) {
                        Button(action: {
                            isManagePlayersPresented = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "person.2.fill")
                                Text("Players")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(AppTheme.feltLight)
                            .foregroundColor(AppTheme.text)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border, lineWidth: 1))
                        }
                        
                        Button(action: {
                            isScoreboardModalPresented = true
                        }) {
                            Text("Scores")
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(AppTheme.feltLight)
                                .foregroundColor(AppTheme.text)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border, lineWidth: 1))
                        }
                        
                        Button(action: {
                            showAbortConfirmAlert = true
                        }) {
                            Image(systemName: "xmark.octagon.fill")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.danger)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                ScrollView {
                    VStack(spacing: 14) {
                        // Info Summary Card with Prominent Yellow Double-Sized Dealer Banner
                        FeltCardView {
                            HStack {
                                Text("Cards distributed this round")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppTheme.textDim)
                                Spacer()
                                Text("\(round.cardsPerPlayer)")
                                    .font(.system(size: 28, weight: .heavy))
                                    .foregroundColor(AppTheme.gold)
                            }
                            
                            Divider()
                                .background(AppTheme.border)
                                .padding(.vertical, 2)
                            
                            // DOUBLE SIZE + DARK BLUE COLOR FOR "Dealer:" AND BLACK FOR DEALER NAME
                             HStack {
                                 Text("Dealer:")
                                     .font(.system(size: 28, weight: .black))
                                     .foregroundColor(AppTheme.goldDim)
                                 Spacer()
                                 let dealerName = game.players.first(where: { $0.position == round.dealerIndex })?.name ?? "Dealer"
                                 Text(dealerName.uppercased())
                                     .font(.system(size: 28, weight: .black))
                                     .lineLimit(1)
                                     .allowsTightening(true)
                                     .minimumScaleFactor(0.35)
                                     .foregroundColor(AppTheme.text)
                             }
                            .padding(.vertical, 2)
                            
                            Divider()
                                .background(AppTheme.border)
                                .padding(.vertical, 2)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Total Announced Sets")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(AppTheme.text)
                                    Text(round.isDealerRestrictionViolated ? "Equals cards distributed! (Not allowed)" : "Must not equal \(round.cardsPerPlayer)")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(round.isDealerRestrictionViolated ? AppTheme.danger : AppTheme.textDim)
                                }
                                Spacer()
                                Text("\(round.totalAnnounced)")
                                    .font(.system(size: 28, weight: .heavy))
                                    .foregroundColor(round.isDealerRestrictionViolated ? AppTheme.danger : AppTheme.gold)
                            }
                        }
                        
                        // Dealer Restriction Warning Banner
                        if round.isDealerRestrictionViolated {
                            let dealerName = game.players.first(where: { $0.position == round.dealerIndex })?.name ?? "Dealer"
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppTheme.danger)
                                 Text("Total announced equals \(round.cardsPerPlayer) cards — NOT ALLOWED! The dealer, \(dealerName), must change their number.")
                                     .font(.system(size: 13, weight: .bold))
                                     .foregroundColor(AppTheme.danger)
                            }
                            .padding(12)
                            .background(AppTheme.danger.opacity(0.18))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.danger, lineWidth: 1.5))
                        }
                        
                        // Player Bids Section Title
                        HStack {
                            Text("Announce Sets")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppTheme.gold)
                            Spacer()
                            Text("Type number or tap + / -")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppTheme.textDim)
                        }
                        .padding(.top, 4)
                        
                        // Player Bids List in Dealer Turn Order
                        VStack(spacing: 10) {
                            ForEach(round.announcementOrder, id: \.self) { playerIdx in
                                if let player = game.players.first(where: { $0.position == playerIdx }) {
                                    let currentBid = round.announcements[playerIdx] ?? 0
                                    let isDealer = playerIdx == round.dealerIndex
                                    let totalScore: Int = {
                                        if game.rounds.count > 1 {
                                            let prevRound = game.rounds[game.rounds.count - 2]
                                            return prevRound.cumulativeScores[playerIdx] ?? 0
                                        }
                                        return 0
                                    }()
                                    
                                    PlayerAnnounceRow(
                                        player: player,
                                        isDealer: isDealer,
                                        cardsPerPlayer: round.cardsPerPlayer,
                                        currentBid: currentBid,
                                        totalScore: totalScore,
                                        focusedPlayerIndex: _focusedPlayerIndex,
                                        onBidChanged: { newBid in
                                            stateManager.updateAnnouncement(playerIndex: playerIdx, bid: newBid)
                                        }
                                    )
                                }
                            }
                        }
                        
                        PrimaryGoldButton(title: "Confirm Announcements", iconName: "checkmark.circle.fill") {
                            focusedPlayerIndex = nil
                            if stateManager.confirmAnnouncements() {
                                currentNavigation = .actual
                            }
                        }
                        .disabled(round.isDealerRestrictionViolated)
                        .opacity(round.isDealerRestrictionViolated ? 0.5 : 1.0)
                        .padding(.top, 8)
                        .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .feltBackground()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedPlayerIndex = nil
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.gold)
            }
        }
        .confirmationDialog("Game Options", isPresented: $showGameOptionsAlert, titleVisibility: .visible) {
            Button("Pause & Save (Resume Later)") {
                currentNavigation = .home
            }
            Button("Abort & End Game", role: .destructive) {
                showAbortConfirmAlert = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("What would you like to do with the current running game?")
        }
        .alert("Abort Game?", isPresented: $showAbortConfirmAlert) {
            Button("Yes, Abort Game", role: .destructive) {
                stateManager.clearSavedGame()
                currentNavigation = .home
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to abort the running game? All current game progress will be permanently cleared.")
        }
        .sheet(isPresented: $isScoreboardModalPresented) {
            ScoreboardSheetView()
                .environmentObject(stateManager)
        }
        .sheet(isPresented: $isManagePlayersPresented) {
            ManagePlayersSheetView()
                .environmentObject(stateManager)
        }
        .onAppear {
            if let round = currentRound, round.isDealerRestrictionViolated {
                playNativeAlertSound()
            }
        }
        .onChange(of: currentRound?.totalAnnounced) { _ in
            if let round = currentRound, round.isDealerRestrictionViolated {
                playNativeAlertSound()
            }
        }
    }
}

// Row component for typing bid directly from numeric keyboard or using quick +/- buttons
struct PlayerAnnounceRow: View {
    let player: Player
    let isDealer: Bool
    let cardsPerPlayer: Int
    let currentBid: Int
    let totalScore: Int
    @FocusState var focusedPlayerIndex: Int?
    let onBidChanged: (Int) -> Void
    
    @State private var inputText: String = ""
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(player.name.uppercased())
                        .font(.system(size: 24, weight: .black))
                        .lineLimit(1)
                        .allowsTightening(true)
                        .minimumScaleFactor(0.35)
                        .layoutPriority(1)
                        .foregroundColor(player.hasQuit ? AppTheme.textDim : AppTheme.text)
                    
                    if isDealer && !player.hasQuit {
                        Text("DEALER")
                            .font(.system(size: 12, weight: .black))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.goldDim)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .fixedSize()
                    }
                    
                    if player.hasQuit {
                        Text("🧊 QUIT")
                            .font(.system(size: 11, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(red: 224/255.0, green: 242/255.0, blue: 254/255.0))
                            .foregroundColor(Color(red: 3/255.0, green: 105/255.0, blue: 161/255.0))
                            .cornerRadius(6)
                            .fixedSize()
                    }
                }
                
                Text("Net Score: \(totalScore)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(totalScore < 0 ? AppTheme.danger : AppTheme.gold)
            }
            
            Spacer()
            
            if player.hasQuit {
                Text("Score Frozen")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(red: 3/255.0, green: 105/255.0, blue: 161/255.0))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.cardBg)
                    .cornerRadius(8)
            } else {
                // Numeric Input Box with Direct Keyboard & +/- Buttons
                HStack(spacing: 8) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        let newBid = max(0, currentBid - 1)
                        inputText = "\(newBid)"
                        onBidChanged(newBid)
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.gold)
                            .frame(width: 36, height: 36)
                            .background(AppTheme.feltGreen)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
                    }
                    .disabled(currentBid <= 0)
                    
                    // Direct numeric text field with 100% larger bid quantity font
                    TextField("0", text: $inputText)
                        .focused($focusedPlayerIndex, equals: player.position)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(AppTheme.text)
                        .frame(width: 60, height: 44)
                        .background(AppTheme.inputBg)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(focusedPlayerIndex == player.position ? AppTheme.gold : AppTheme.border, lineWidth: 1.5)
                        )
                        .onAppear {
                            inputText = "\(currentBid)"
                        }
                        .onChange(of: currentBid) { newVal in
                            if focusedPlayerIndex != player.position {
                                inputText = "\(newVal)"
                            }
                        }
                        .onChange(of: focusedPlayerIndex) { newFocusedIndex in
                            if newFocusedIndex == player.position {
                                inputText = ""
                            } else if inputText.isEmpty {
                                inputText = "\(currentBid)"
                            }
                        }
                        .onChange(of: inputText) { rawText in
                            let filtered = rawText.filter { $0.isNumber }
                            if filtered.isEmpty {
                                onBidChanged(0)
                            } else if let num = Int(filtered) {
                                let clamped = max(0, min(cardsPerPlayer, num))
                                onBidChanged(clamped)
                            }
                        }
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        let newBid = min(cardsPerPlayer, currentBid + 1)
                        inputText = "\(newBid)"
                        onBidChanged(newBid)
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.gold)
                            .frame(width: 36, height: 36)
                            .background(AppTheme.feltGreen)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
                    }
                    .disabled(currentBid >= cardsPerPlayer)
                }
            }
        }
        .padding(12)
        .background(AppTheme.feltLight)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDealer ? AppTheme.goldDim : AppTheme.border, lineWidth: isDealer ? 2 : 1)
        )
    }
}
