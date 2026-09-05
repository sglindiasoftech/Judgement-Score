import SwiftUI

public struct ManageSavedNamesSheetView: View {
    @EnvironmentObject var stateManager: GameStateManager
    @Environment(\.dismiss) var dismiss
    
    @State private var newRegisterNameText: String = ""
    @State private var searchText: String = ""
    
    // States for Edit Warning Alert
    @State private var nameToEdit: String? = nil
    @State private var editingText: String = ""
    @State private var showEditWarningAlert: Bool = false
    
    // States for Delete Warning Alert
    @State private var nameToDelete: String? = nil
    @State private var showDeleteWarningAlert: Bool = false
    
    // State for Clear All Warning Alert
    @State private var showClearAllWarningAlert: Bool = false
    
    var filteredNames: [String] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return stateManager.nameHistory
        } else {
            return stateManager.nameHistory.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Manage Saved Names")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.gold)
                    Text("Register, edit or delete player names in your dropdown list")
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
            
            // Register New Name Row
            HStack(spacing: 10) {
                Image(systemName: "person.badge.plus")
                    .foregroundColor(AppTheme.gold)
                    .font(.system(size: 18))
                
                TextField("Register new player name...", text: $newRegisterNameText)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.text)
                    .autocorrectionDisabled(true)
                
                Button(action: {
                    let trimmed = newRegisterNameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        stateManager.saveNameToHistory(trimmed)
                        newRegisterNameText = ""
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(AppTheme.gold)
                    .foregroundColor(Color(red: 18/255.0, green: 51/255.0, blue: 31/255.0))
                    .cornerRadius(8)
                }
                .disabled(newRegisterNameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(newRegisterNameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
            }
            .padding(10)
            .background(AppTheme.cardBg)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.gold.opacity(0.4), lineWidth: 1))
            .padding(.horizontal, 16)
            
            // Search Bar (Only shown if history has items)
            if !stateManager.nameHistory.isEmpty {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.textDim)
                    TextField("Search saved names...", text: $searchText)
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.text)
                        .autocorrectionDisabled(true)
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppTheme.textDim)
                        }
                    }
                }
                .padding(10)
                .background(AppTheme.inputBg)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border, lineWidth: 1))
                .padding(.horizontal, 16)
            }
            
            if stateManager.nameHistory.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 44))
                        .foregroundColor(AppTheme.gold.opacity(0.7))
                    Text("Dropdown list is currently blank.")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.text)
                    Text("Register player names above or type player names when setting up a game to save them to your dropdown list.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textDim)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    Spacer()
                }
            } else if filteredNames.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "person.slash")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.textDim)
                    Text("No matching saved names found.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textDim)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(filteredNames, id: \.self) { name in
                            HStack {
                                Text(name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppTheme.text)
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    // Edit Name Button
                                    Button(action: {
                                        nameToEdit = name
                                        editingText = name
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "pencil")
                                            Text("Edit")
                                        }
                                        .font(.system(size: 13, weight: .bold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(AppTheme.feltLight)
                                        .foregroundColor(AppTheme.gold)
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.border, lineWidth: 1))
                                    }
                                    
                                    // Delete Name Button
                                    Button(action: {
                                        nameToDelete = name
                                        showDeleteWarningAlert = true
                                    }) {
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppTheme.danger)
                                            .padding(8)
                                            .background(AppTheme.danger.opacity(0.15))
                                            .clipShape(Circle())
                                    }
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
            }
            
            HStack(spacing: 12) {
                if !stateManager.nameHistory.isEmpty {
                    Button(action: {
                        showClearAllWarningAlert = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("Clear All")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(AppTheme.danger.opacity(0.2))
                        .foregroundColor(AppTheme.danger)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.danger, lineWidth: 1))
                    }
                }
                
                PrimaryGoldButton(title: "Done", iconName: nil) {
                    dismiss()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .feltBackground()
        // Prompt for editing name
        .alert("Edit Saved Name", isPresented: Binding(
            get: { nameToEdit != nil && !showEditWarningAlert },
            set: { if !$0 { nameToEdit = nil } }
        )) {
            TextField("New name", text: $editingText)
            Button("Save Changes", role: .none) {
                if !editingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && editingText != nameToEdit {
                    showEditWarningAlert = true
                } else {
                    nameToEdit = nil
                }
            }
            Button("Cancel", role: .cancel) {
                nameToEdit = nil
            }
        } message: {
            Text("Enter a new name for '\(nameToEdit ?? "")':")
        }
        // WARNING ALERT for Edit Action
        .alert("⚠️ Warning: Edit Saved Name?", isPresented: $showEditWarningAlert) {
            Button("Yes, Update Name", role: .destructive) {
                if let old = nameToEdit {
                    stateManager.updateNameInHistory(oldName: old, newName: editingText)
                }
                nameToEdit = nil
            }
            Button("Cancel", role: .cancel) {
                nameToEdit = nil
            }
        } message: {
            Text("Are you sure you want to change '\(nameToEdit ?? "")' to '\(editingText)' in your saved dropdown name list?")
        }
        // WARNING ALERT for Delete Action
        .alert("⚠️ Warning: Delete Saved Name?", isPresented: $showDeleteWarningAlert) {
            Button("Yes, Delete Name", role: .destructive) {
                if let target = nameToDelete {
                    stateManager.deleteNameFromHistory(target)
                    nameToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                nameToDelete = nil
            }
        } message: {
            if let target = nameToDelete {
                Text("Are you sure you want to permanently delete '\(target)' from your saved dropdown name list?")
            } else {
                Text("Are you sure you want to delete this saved name?")
            }
        }
        // WARNING ALERT for Clear All Action
        .alert("⚠️ Warning: Clear All Saved Names?", isPresented: $showClearAllWarningAlert) {
            Button("Yes, Clear All", role: .destructive) {
                stateManager.clearAllNameHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete ALL saved names from your dropdown list? This action cannot be undone.")
        }
    }
}
