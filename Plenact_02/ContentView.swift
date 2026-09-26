// --------------------------------------------------------------------------------------------------
// @file       ContentView.swift
// @brief      Kanban board screen and reusable board views
// @details    Defines the board container, lists, cards, and navigation into card details
//
// @notes      Views remain composable and keep presentation logic close to the rendered component
//
// --------------------------------------------------------------------------------------------------
import SwiftUI


// -------------------------------------- MARK: - Board View ------------------------------------ //

///
/// Displays the horizontally scrollable Plenact kanban board
///
/// @section    Purpose
///     Install the board background, header, paged list surface, and navigation path into card details
///
struct ContentView: View {

    @State private var lists: [KanbanList] = SampleData.lists


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
                        BoardHeader()

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(lists.enumerated()), id: \.element.id) { listIndex, list in
                                    KanbanListView(
                                        list: list,
                                        screenSize: screen.size,
                                        toggleCardTitle: { cardID in
                                            toggleCardTitle(in: listIndex, cardID: cardID)
                                        }
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

            Button(action: {}) {

                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .accessibilityLabel("Add list")

            Button(action: {}) {

                Image(systemName: "ellipsis.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .accessibilityLabel("Board options")
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 10)
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

    let list: KanbanList
    let screenSize: CGSize
    let toggleCardTitle: (Int) -> Void

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

                Text("\(list.cards.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 8) {
                    ForEach(list.cards) { card in
                        NavigationLink(value: card) {
                            KanbanCardView(card: card, height: cardHeight) {
                                toggleCardTitle(card.id)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: {}) {
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
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 5)
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

                Label("\(card.commentCount)", systemImage: "text.bubble")
                Label("\(card.completedChecklistItems)/\(card.checklistItems.count)", systemImage: "checklist")

                if card.hasDueDate {
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
