// --------------------------------------------------------------------------------------------------
// @file       ContentView.swift
// @brief      Kanban board screen and reusable board views
// @details    Defines the board container, lists, cards, and navigation into card details
//
// @notes      Views remain composable and keep presentation logic close to the rendered component
//
// --------------------------------------------------------------------------------------------------
import SwiftUI


struct BoardDisplaySettings {
    var showChecklistProgress = true    /* Display checklist progress on cards */
    var showCommentCounts     = true    /* Display comment counts on cards     */
    var showDueDateBadges     = true    /* Display due date badges on cards    */
}


// -------------------------------------- MARK: - Board View ------------------------------------ //

///
/// Displays the horizontally scrollable Plenact kanban board
///
/// @section    Purpose
///     Install the board background, header, paged list surface, and navigation path into card details
///
struct ContentView: View {

    @State private var lists: [KanbanList] = SampleData.lists
    @State private var displaySettings     = BoardDisplaySettings()

    ///
    /// @fcn        ContentView.addList
    /// @brief      Append a new empty list to the board
    /// @details    Assigns the next available list identifier and generates a title that does not duplicate an existing list name
    ///
    /// @return     (Void) updates the board's in-memory list collection
    ///
    /// @pre        The board list collection has been initialized
    /// @post       A uniquely identified empty list is appended to the board
    ///
    private func addList() {
        let nextListID     = (lists.map(\.id).max() ?? -1) + 1
        let existingTitles = Set(lists.map { $0.title.lowercased() })
        var newTitle       = "New List"
        var suffix         = 2

        while existingTitles.contains(newTitle.lowercased()) {
            newTitle = "New List \(suffix)"
            suffix  += 1
        }

        lists.append(KanbanList(id: nextListID, title: newTitle, cards: []))
    }


    ///
    /// @fcn        ContentView.addCard(to:title:description:)
    /// @brief      Add a completed card form to the end of the selected list
    /// @details    Allocates a board-wide unique card identifier and stores the supplied title and description
    ///
    /// @param[in]  listID  Stable identifier of the list receiving the card
    /// @param[in]  title   User-entered card title
    /// @param[in]  description User-entered card description
    ///
    /// @return     (Void) updates the matching list in the board state
    ///
    /// @pre        listID identifies a list in the current board
    /// @post       The new card appears as the last card in the selected list
    ///
    private func addCard(to listID: Int, title: String, description: String) {
        
        guard let listIndex = lists.firstIndex(where: { $0.id == listID }) else { return }

        let nextCardID  = (lists.flatMap { $0.cards.map(\.id) }.max() ?? -1) + 1
        var updatedList = lists[listIndex]

        updatedList.cards.append(
            KanbanCard(
                id:                  nextCardID,
                word:                title,
                listTitle:           updatedList.title,
                descriptionOverride: description
            )
        )

        lists[listIndex] = updatedList
    }


    ///
    /// @fcn        ContentView.copyList(with:)
    /// @brief      Insert a copy of the selected list beside its source
    /// @details    Creates new list and card identifiers while copying card content and current card state
    ///
    /// @param[in]  listID  Stable identifier of the list to copy
    ///
    /// @return     (Void) inserts the copied list immediately after the source list
    ///
    /// @pre        listID identifies a list in the current board
    /// @post       The board contains a distinct copy with unique list and card identifiers
    ///
    private func copyList(with listID: Int) {
        guard let sourceIndex = lists.firstIndex(where: { $0.id == listID }) else { return }

        let source       = lists[sourceIndex]
        let copiedTitle  = "\(source.title) Copy"
        let copiedListID = (lists.map(\.id).max() ?? -1) + 1
        var nextCardID   = (lists.flatMap { $0.cards.map(\.id) }.max() ?? -1) + 1

        let copiedCards = source.cards.map { card in
        
            let copy = KanbanCard(
                id:                   nextCardID,
                word:                 card.word,
                listTitle:            copiedTitle,
                isTitleChecked:       card.isTitleChecked,
                startDate:            card.startDate,
                dueDate:              card.dueDate,
                checklists:           card.checklists,
                comments:             card.comments,
                dismissedActivityIDs: card.dismissedActivityIDs,
                descriptionOverride:  card.descriptionOverride
            )

            nextCardID += 1
            
            return copy
        }

        lists.insert(KanbanList(id: copiedListID, title: copiedTitle, cards: copiedCards), at: sourceIndex + 1)
    }


    ///
    /// @fcn        ContentView.moveList(with:by:)
    /// @brief      Move a list relative to its current board position
    /// @details    Removes the matching list and reinserts it at the index specified by the offset
    ///
    /// @param[in]  listID  Stable identifier of the list to move
    /// @param[in]  offset  Number of positions to move; negative moves earlier and positive moves later
    ///
    /// @return     (Void) reorders the board when the destination index is valid
    ///
    /// @pre        listID identifies a list in the current board
    /// @post       The list occupies its destination index, or the board is unchanged for an invalid destination
    ///
    private func moveList(with listID: Int, by offset: Int) {

        guard let sourceIndex = lists.firstIndex(where: { $0.id == listID }) else { return }

        let destinationIndex = sourceIndex + offset

        guard lists.indices.contains(destinationIndex) else { return }

        let movedList = lists.remove(at: sourceIndex)

        lists.insert(movedList, at: destinationIndex)
    }


    ///
    /// @fcn        ContentView.sortList(with:ascending:)
    /// @brief      Sort a list's cards by their titles
    /// @details    Uses localized standard comparison to order card titles in the requested direction
    ///
    /// @param[in]  listID     Stable identifier of the list to sort
    /// @param[in]  ascending  Whether to sort from A to Z; false sorts from Z to A
    ///
    /// @return     (Void) replaces the card order in the matching board list
    ///
    /// @pre        listID identifies a list in the current board
    /// @post       Cards in the list are ordered by title in the requested direction
    ///
    private func sortList(with listID: Int, ascending: Bool) {

        guard let listIndex = lists.firstIndex(where: { $0.id == listID }) else { return }

        var updatedList = lists[listIndex]

        updatedList.cards.sort {
            let comparison = $0.word.localizedStandardCompare($1.word)
            return ascending ? comparison == .orderedAscending : comparison == .orderedDescending
        }

        lists[listIndex] = updatedList
    }


    ///
    /// @fcn        ContentView.archiveCompletedCards(in:)
    /// @brief      Remove completed cards from a list
    /// @details    Filters out cards whose title checkbox is selected
    ///
    /// @param[in]  listID  Stable identifier of the list to update
    ///
    /// @return     (Void) updates the matching list in the board state
    ///
    /// @pre        listID identifies a list in the current board
    /// @post       Cards marked complete no longer appear in the active list
    ///
    private func archiveCompletedCards(in listID: Int) {

        guard let listIndex = lists.firstIndex(where: { $0.id == listID }) else { return }

        lists[listIndex].cards.removeAll(where: \.isTitleChecked)
    }


    ///
    /// @fcn        ContentView.archiveList(with:)
    /// @brief      Remove a list from the active board
    /// @details    Deletes the list entry matching the supplied stable identifier
    ///
    /// @param[in]  listID  Stable identifier of the list to remove
    ///
    /// @return     (Void) updates the board's in-memory list collection
    ///
    /// @pre        listID identifies a list in the current board
    /// @post       The list and its cards no longer appear on the active board
    ///
    private func archiveList(with listID: Int) {
        lists.removeAll { $0.id == listID }
    }


    ///
    /// @fcn        ContentView.toggleCardTitle
    /// @brief      Toggle the selected state for one board card title checkbox
    /// @details    Finds the matching card within the selected list and flips its persisted
    ///             checked state so the root board view and detail view stay in sync
    ///
    /// @param[in]  listIndex   Zero-based index of the list containing the card
    /// @param[in]  cardID      Stable identifier of the card whose title checkbox is toggled
    ///
    /// @return     (Void) updates the local board state in place
    ///
    /// @pre        listIndex must reference a valid list in the board state
    /// @post       The selected card's checked state is inverted and the board re-renders
    ///
    private func toggleCardTitle(in listIndex: Int, cardID: Int) {

        guard lists.indices.contains(listIndex) else { return }

        var updatedList     = lists[listIndex]

        guard let cardIndex = updatedList.cards.firstIndex(where: { $0.id == cardID }) else { return }

        var updatedCard = updatedList.cards[cardIndex]

        updatedCard.isTitleChecked.toggle()

        updatedList.cards[cardIndex] = updatedCard
        lists[listIndex]             = updatedList
    }


    ///
    /// @fcn        ContentView.updateCard
    /// @brief      Replace an existing card with the latest edited version
    /// @details    Scans the current board data for the matching card identifier and stores the
    ///             latest value so navigation changes persist across list and detail views
    ///
    /// @param[in]  updatedCard   Card instance containing the latest state to save
    ///
    /// @return     (Void) updates the board's in-memory card collection
    ///
    /// @pre        updatedCard must contain a valid id that exists within the board state
    /// @post       The matching card in the list state reflects the updated values
    ///
    private func updateCard(_ updatedCard: KanbanCard) {

        for listIndex in lists.indices {

            var updatedList = lists[listIndex]

            guard let cardIndex = updatedList.cards.firstIndex(where: { $0.id == updatedCard.id }) else {
                continue
            }

            updatedList.cards[cardIndex] = updatedCard
            lists[listIndex]             = updatedList

            return
        }
    }
    

    /// Builds the board scene and its horizontally scrollable list collection.
    var body: some View {
        NavigationStack {
            GeometryReader { screen in
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.10, green: 0.18, blue: 0.25), Color(red: 0.22, green: 0.34, blue: 0.38)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    VStack(spacing: 0) {
                        BoardHeader(settings: $displaySettings, onAddList: addList)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(lists.enumerated()), id: \.element.id) { listIndex, list in
                                    KanbanListView(
                                        list: list,
                                        screenSize: screen.size,
                                        displaySettings: displaySettings,
                                        toggleCardTitle: { cardID in
                                            toggleCardTitle(in: listIndex, cardID: cardID)
                                        },
                                        canMoveEarlier: listIndex > 0,
                                        canMoveLater: listIndex < lists.count - 1,
                                        onAddCard: { title, description in
                                            addCard(to: list.id, title: title, description: description)
                                        },
                                        onCopyList: { copyList(with: list.id) },
                                        onMoveList: { offset in moveList(with: list.id, by: offset) },
                                        onSortList: { ascending in sortList(with: list.id, ascending: ascending) },
                                        onArchiveCompleted: { archiveCompletedCards(in: list.id) },
                                        onArchiveList: { archiveList(with: list.id) }
                                    )
                                    .frame(width: screen.size.width - 28, height: screen.size.height - 86)
                                }
                            }
                            .scrollTargetLayout()
                            .padding(.horizontal, 14)
                        }
                        .scrollTargetBehavior(.viewAligned)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: KanbanCard.self) { card in
                CardDetailView(card: card, onTitleToggle: { updatedCard in
                    updateCard(updatedCard)
                })
            }
        }
    }
}


// -------------------------------------- MARK: - Board Header ---------------------------------- //

///
/// Displays the board title and board-level actions
///
/// @section    Purpose
///     Establish the visual identity of the board and expose board-level controls
///
struct BoardHeader: View {

    @Binding var settings: BoardDisplaySettings     /* Board display settings                              */

    let onAddList: () -> Void                       /* Callback for adding a new list                      */

    @State private var showingSettings = false      /* Controls the visibility of the board settings sheet */

    /// Builds the title block and board action controls.
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {

                Text("Plenact")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)

                Text("Work Week Board")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
            }

            Spacer()

            Menu {
                Button("Add blank list", systemImage: "rectangle.stack.badge.plus", action: onAddList)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .accessibilityLabel("Add list")

            Button {
                showingSettings = true
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .accessibilityLabel("Board options")
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .sheet(isPresented: $showingSettings) {
            BoardSettingsView(settings: $settings)
        }
    }
}


/// Presents board-level display preferences in a dismissible settings sheet.
///
/// @section    Purpose
///     Let the user control which metadata badges appear on board cards
///
/// @note   Settings are bound to ContentView and take effect immediately
///
private struct BoardSettingsView: View {

    @Binding var settings: BoardDisplaySettings     /* Bound to the board's display preferences */
    @Environment(\.dismiss) private var dismiss     /* Dismiss action for the settings sheet    */

    ///
    /// @fcn        BoardSettingsView.body
    /// @brief      Build the board settings form
    /// @details    Presents toggles for checklist progress, comment counts, and due-date badges
    ///
    /// @return     (some View) settings sheet content with a Done action
    ///
    /// @pre        settings is bound to the board's display preferences
    /// @post       Changes update the bound settings and are reflected by the board cards
    ///
    var body: some View {

        NavigationStack {
            Form {
                Section("Card badges") {
                    Toggle("Checklist progress", isOn: $settings.showChecklistProgress)
                    Toggle("Comment counts",     isOn: $settings.showCommentCounts)
                    Toggle("Due-date badges",    isOn: $settings.showDueDateBadges)
                }
            }
            .navigationTitle("Board Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}


// -------------------------------------- MARK: - Kanban List ----------------------------------- //

///
/// Displays one kanban list and its cards
///
/// @section    Purpose
///     Keep a list title, list metadata, add-card action, and vertically scrollable card collection together
///
struct KanbanListView: View {

    private enum ActiveSheet: String, Identifiable {
        case listActions
        case newCard

        var id: String { rawValue }
    }

    let list: KanbanList
    let screenSize: CGSize
    let displaySettings: BoardDisplaySettings
    let toggleCardTitle: (Int) -> Void
    let canMoveEarlier: Bool
    let canMoveLater:  Bool
    let onAddCard: (String, String) -> Void
    let onCopyList: () -> Void
    let onMoveList: (Int) -> Void
    let onSortList: (Bool) -> Void
    let onArchiveCompleted: () -> Void
    let onArchiveList: () -> Void

    @State private var activeSheet: ActiveSheet?
    @State private var isWatching = false
    @State private var listTint: KanbanListTint = .neutral

    /// Maintains the original quarter-screen card sizing requirement.
    private var cardHeight: CGFloat {
        screenSize.height * 0.25
    }

    /// Builds one list panel and its card navigation destinations.
    var body: some View {

        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(list.title)
                        .font(.title3.weight(.bold))
                    Text(list.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isWatching {
                    Image(systemName: "eye.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("\(list.cards.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Button {
                    activeSheet = .listActions
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(list.title) list actions")
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 8) {
                    ForEach(list.cards) { card in
                        NavigationLink(value: card) {
                            KanbanCardView(card: card, height: cardHeight, displaySettings: displaySettings) {
                                toggleCardTitle(card.id)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        activeSheet = .newCard
                    } label: {
                        Label("Add card", systemImage: "plus")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    }
                }
                .padding(8)
            }
        }
        .background(listTint.color)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 5)
        .sheet(item: $activeSheet) { presentedSheet in
            switch presentedSheet {
            case .listActions:
                KanbanListActionsSheet(
                    list: list,
                    canMoveEarlier: canMoveEarlier,
                    canMoveLater: canMoveLater,
                    isWatching: $isWatching,
                    listTint: $listTint,
                    onAddCard: { activeSheet = .newCard },
                    onCopyList: onCopyList,
                    onMoveList: onMoveList,
                    onSortList: onSortList,
                    onArchiveCompleted: onArchiveCompleted,
                    onArchiveList: onArchiveList
                )
            case .newCard:
                NewKanbanCardSheet(listTitle: list.title, onCreate: onAddCard)
            }
        }
    }
}


private struct NewKanbanCardSheet: View {

    let listTitle: String
    let onCreate: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Card details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onCreate(trimmedTitle, description.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .disabled(trimmedTitle.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}


private enum KanbanListTint: String, CaseIterable, Identifiable {
    case neutral
    case blue
    case green
    case orange
    case red

    var id: String { rawValue }

    var title: String {
        switch self {
        case .neutral: "Default"
        case .blue:    "Blue"
        case .green:   "Green"
        case .orange:  "Orange"
        case .red:     "Red"
        }
    }

    var color: Color {
        switch self {
        case .neutral: Color(.systemGray6)
        case .blue:    Color.blue.opacity(0.12)
        case .green:   Color.green.opacity(0.12)
        case .orange:  Color.orange.opacity(0.12)
        case .red:     Color.red.opacity(0.12)
        }
    }
}


private struct KanbanListActionsSheet: View {

    let list: KanbanList
    let canMoveEarlier: Bool
    let canMoveLater: Bool
    @Binding var isWatching: Bool
    @Binding var listTint: KanbanListTint
    let onAddCard: () -> Void
    let onCopyList: () -> Void
    let onMoveList: (Int) -> Void
    let onSortList: (Bool) -> Void
    let onArchiveCompleted: () -> Void
    let onArchiveList: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var confirmingArchive = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        onAddCard()
                        dismiss()
                    } label: {
                        Label("Add card", systemImage: "plus")
                    }

                    Button {
                        onCopyList()
                        dismiss()
                    } label: {
                        Label("Copy list", systemImage: "doc.on.doc")
                    }

                    Menu {
                        Button("Move earlier") {
                            onMoveList(-1)
                            dismiss()
                        }
                        .disabled(!canMoveEarlier)

                        Button("Move later") {
                            onMoveList(1)
                            dismiss()
                        }
                        .disabled(!canMoveLater)
                    } label: {
                        Label("Move list", systemImage: "arrow.left.arrow.right")
                            .foregroundStyle(.primary)
                    }

                    Menu {
                        Button("Title A to Z") {
                            onSortList(true)
                            dismiss()
                        }
                        Button("Title Z to A") {
                            onSortList(false)
                            dismiss()
                        }
                    } label: {
                        Label("Sort list", systemImage: "arrow.up.arrow.down")
                            .foregroundStyle(.primary)
                    }

                    Menu {
                        ForEach(KanbanListTint.allCases) { tint in
                            Button {
                                listTint = tint
                            } label: {
                                Label(tint.title, systemImage: listTint == tint ? "checkmark.circle.fill" : "circle.fill")
                            }
                        }
                    } label: {
                        Label("Change list color", systemImage: "paintpalette")
                            .foregroundStyle(.primary)
                    }

                    Button {
                        isWatching.toggle()
                    } label: {
                        Label(isWatching ? "Unwatch" : "Watch", systemImage: isWatching ? "eye.slash" : "eye")
                    }
                }

                Section {
                    Button {
                        onArchiveCompleted()
                        dismiss()
                    } label: {
                        Label("Archive completed cards", systemImage: "archivebox")
                    }

                    Button(role: .destructive) {
                        confirmingArchive = true
                    } label: {
                        Label("Archive list", systemImage: "archivebox")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("List actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Archive \(list.title)?", isPresented: $confirmingArchive, titleVisibility: .visible) {
                Button("Archive list", role: .destructive) {
                    onArchiveList()
                    dismiss()
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
    }
}


// -------------------------------------- MARK: - Kanban Card ----------------------------------- //

///
/// Displays a compact summary of a kanban card
///
/// @section    Purpose
///     Present the title, supporting copy, and compact metadata used to scan cards on the board
///
struct KanbanCardView: View {

    let card: KanbanCard
    let height: CGFloat
    let displaySettings: BoardDisplaySettings
    let onToggle: () -> Void

    /// Builds a fixed-height card summary within its parent list.
    var body: some View {

        VStack(alignment: .leading, spacing: 9) {

            HStack(alignment: .center, spacing: 8) {
                Button {
                    onToggle()
                } label: {
                    Image(systemName: card.isTitleChecked ? "checkmark.square.fill" : "square")
                        .font(.headline)
                        .foregroundStyle(card.isTitleChecked ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(card.isTitleChecked ? "Uncheck card title" : "Check card title")

                Text(card.word.capitalized)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }

            Text(card.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: 14) {

                if displaySettings.showCommentCounts {
                    Label("\(card.commentCount)", systemImage: "text.bubble")
                }

                if displaySettings.showChecklistProgress {
                    Label("\(card.completedChecklistItems)/\(card.checklistItems.count)", systemImage: "checklist")
                }

                if displaySettings.showDueDateBadges && card.hasDueDate {
                    Label("Today", systemImage: "calendar")
                }

                Spacer()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: max(height - 8, 40), alignment: .top)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.10), radius: 3, y: 2)
        .padding(.horizontal, 4)
    }
}


// -------------------------------------- MARK: - Previews -------------------------------------- //

/// Preview the complete board presentation with deterministic sample data.
#Preview {
    ContentView()
}
