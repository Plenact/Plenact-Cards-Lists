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
                                ForEach(SampleData.lists) { list in
                                    KanbanListView(list: list, screenSize: screen.size)
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
                            KanbanCardView(card: card, height: cardHeight)
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
        .navigationDestination(for: KanbanCard.self) { card in
            CardDetailView(card: card)
        }
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


    /// Builds a fixed-height card summary within its parent list.
    var body: some View {

        VStack(alignment: .leading, spacing: 9) {
            Text(card.word.capitalized)
                .font(.headline)
                .foregroundStyle(.primary)

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
