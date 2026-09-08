import SwiftUI

public struct NewGameSetupView: View {
    @EnvironmentObject var stateManager: GameStateManager
    @Binding var currentNavigation: AppScreen
    @FocusState private var activeFieldIndex: Int?
    @State private var isManageSavedNamesPresented: Bool = false
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Nav
            HStack {
                Button(action: {
                    currentNavigation = .home
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.gold)
                }
                Spacer()
                Text("New Game")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.text)
                Spacer()
                Color.clear.frame(width: 34, height: 34)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Number of Players Card
                    FeltCardView {
                        Text("Number of Players")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textDim)
                        
                        HStack(spacing: 20) {
                            Button(action: {
                                activeFieldIndex = nil
                                stateManager.updatePlayerCount(delta: -1)
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppTheme.gold)
                                    .frame(width: 44, height: 44)
                                    .background(AppTheme.feltLight)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
                            }
                            
                            Text("\(stateManager.setupNumPlayers)")
                                .font(.system(size: 36, weight: .heavy))
                                .foregroundColor(AppTheme.text)
                                .frame(minWidth: 60)
                            
                            Button(action: {
                                activeFieldIndex = nil
                                stateManager.updatePlayerCount(delta: 1)
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppTheme.gold)
                                    .frame(width: 44, height: 44)
                                    .background(AppTheme.feltLight)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    
                    // Player Names Card with Alphabetically Sorted Dropdown List
                    FeltCardView {
                        HStack {
                            Text("Player Names")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.textDim)
                            Spacer()
                            Button(action: {
                                isManageSavedNamesPresented = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 11))
                                    Text("Manage Saved Names")
                                        .font(.system(size: 11, weight: .bold))
                                }
                                .foregroundColor(AppTheme.gold)
                            }
                        }
                        
                        VStack(spacing: 12) {
                            ForEach(0..<stateManager.setupNumPlayers, id: \.self) { idx in
                                PlayerNameRow(
                                    idx: idx,
                                    name: $stateManager.setupPlayerNames[idx],
                                    allCurrentNames: stateManager.setupPlayerNames,
                                    nameHistory: stateManager.nameHistory,
                                    canDelete: stateManager.setupNumPlayers > 2,
                                    activeFieldIndex: _activeFieldIndex,
                                    onDelete: {
                                        activeFieldIndex = nil
                                        stateManager.removePlayerRow(at: idx)
                                    },
                                    onManageSavedNames: {
                                        isManageSavedNamesPresented = true
                                    }
                                )
                            }
                        }
                    }
                    
                    // Starting Cards Card
                    FeltCardView {
                        let maxCards = Game.maxStartCards(for: stateManager.setupNumPlayers)
                        
                        HStack {
                            Text("Starting Cards")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.textDim)
                            Spacer()
                            Text("(max \(maxCards))")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.goldDim)
                        }
                        
                        HStack(spacing: 20) {
                            Button(action: {
                                activeFieldIndex = nil
                                stateManager.updateStartCards(delta: -1)
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppTheme.gold)
                                    .frame(width: 44, height: 44)
                                    .background(AppTheme.feltLight)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
                            }
                            
                            Text("\(stateManager.setupStartCards)")
                                .font(.system(size: 36, weight: .heavy))
                                .foregroundColor(AppTheme.text)
                                .frame(minWidth: 60)
                            
                            Button(action: {
                                activeFieldIndex = nil
                                stateManager.updateStartCards(delta: 1)
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppTheme.gold)
                                    .frame(width: 44, height: 44)
                                    .background(AppTheme.feltLight)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        
                        Text("\(stateManager.setupNumPlayers) players × \(stateManager.setupStartCards) cards = \(stateManager.setupNumPlayers * stateManager.setupStartCards) of 104 cards")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textDim)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    // First Dealer Selection Card
                    FeltCardView {
                        Text("First Dealer")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textDim)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(0..<stateManager.setupNumPlayers, id: \.self) { idx in
                                    let rawName = stateManager.setupPlayerNames[idx].trimmingCharacters(in: .whitespacesAndNewlines)
                                    let displayName = rawName.isEmpty ? "Player \(idx + 1)" : rawName
                                    let isSelected = stateManager.setupDealerIndex == idx
                                    
                                    Button(action: {
                                        activeFieldIndex = nil
                                        stateManager.setupDealerIndex = idx
                                    }) {
                                        Text(displayName)
                                            .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(isSelected ? AppTheme.gold : AppTheme.feltLight)
                                            .foregroundColor(isSelected ? .white : AppTheme.text)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(AppTheme.border, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    PrimaryGoldButton(title: "Start Game", iconName: "play.fill") {
                        activeFieldIndex = nil
                        stateManager.startGame()
                        currentNavigation = .announce
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 16)
            }
        .feltBackground()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    activeFieldIndex = nil
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppTheme.gold)
            }
        }
        .sheet(isPresented: $isManageSavedNamesPresented) {
            ManageSavedNamesSheetView()
                .environmentObject(stateManager)
        }
    }
}
}

// Butter-smooth Player Name Input Row with inline Alphabetically Sorted Dropdown List
struct PlayerNameRow: View {
    let idx: Int
    @Binding var name: String
    let allCurrentNames: [String]
    let nameHistory: [String]
    let canDelete: Bool
    @FocusState var activeFieldIndex: Int?
    let onDelete: () -> Void
    let onManageSavedNames: () -> Void
    
    var isFocused: Bool {
        activeFieldIndex == idx
    }
    
    // Always alphabetically sorted list of past names excluding names chosen for other players
    var sortedAvailableNames: [String] {
        let usedOtherNames = Set(allCurrentNames.enumerated().filter { $0.offset != idx }.map { $0.element.lowercased() })
        return nameHistory.filter { historyName in
            !usedOtherNames.contains(historyName.lowercased())
        }.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(idx + 1).")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.textDim)
                .frame(width: 24, alignment: .trailing)
            
            HStack(spacing: 8) {
                TextField("PLAYER \(idx + 1) NAME", text: $name)
                    .focused($activeFieldIndex, equals: idx)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.text)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.characters)
                    .onChange(of: name) { newValue in
                        if newValue != newValue.uppercased() {
                            name = newValue.uppercased()
                        }
                    }
                
                if !name.isEmpty || canDelete {
                    Button(action: {
                        if canDelete {
                            onDelete()
                        } else {
                            name = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.textDim)
                    }
                }
                
                // Alphabetically Sorted Dropdown Menu Button (A to Z)
                if !sortedAvailableNames.isEmpty {
                    Menu {
                        Section {
                            Button(action: {
                                activeFieldIndex = nil
                                onManageSavedNames()
                            }) {
                                HStack {
                                    Image(systemName: "gearshape.fill")
                                    Text("Manage Saved Names...")
                                }
                            }
                        }
                        
                        Section(header: Text("Past Player Names (A-Z)")) {
                            ForEach(sortedAvailableNames, id: \.self) { historyName in
                                Button(action: {
                                    name = historyName
                                    activeFieldIndex = nil
                                }) {
                                    HStack {
                                        Text(historyName)
                                        if name.lowercased() == historyName.lowercased() {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("▾")
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(AppTheme.gold)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(AppTheme.feltLight)
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(AppTheme.gold.opacity(0.8), lineWidth: 1))
                    }
                }
            }
            .padding(10)
            .background(AppTheme.inputBg)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isFocused ? AppTheme.gold : AppTheme.border, lineWidth: isFocused ? 1.5 : 1)
            )
        }
    }
}
