// --------------------------------------------------------------------------------------------------
// @file       CardDetailView.swift
// @brief      Detailed kanban card presentation and supporting components
// @details    Defines the card detail screen, sections, actions, metadata rows, and activity feed
//
// @notes      Supporting views are intentionally small and reusable within the detail screen
//
// --------------------------------------------------------------------------------------------------
import SwiftUI


// -------------------------------------- MARK: - Card Detail View ------------------------------ //

///
/// Presents the complete detail view for a selected kanban card
///
/// @section    Purpose
///     Render the selected card's title, context, metadata, checklists, activity, and navigation action
///
/// @note   The detail surface is intentionally scrollable so every card section remains accessible on iPhone
///
struct CardDetailView: View {

    let card: KanbanCard   /* The kanban card being displayed in detail */


    @Environment(\.dismiss) private var dismiss

    ///
    /// @brief      Build the card detail presentation
    /// @details    Composes the Trello-inspired sections and keeps the Back action in the bottom safe area
    ///
    /// @return     (some View) rendered card detail screen
    ///
    var body: some View {

        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "circle")
                            .font(.title2)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 5) {
                            Text(card.word.capitalized)
                                .font(.title2.weight(.bold))
                            Text("In list \(card.listTitle)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "ellipsis")
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)

                    DetailSection(title: "Quick Actions") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ActionTile(title: "Add Checklist", icon: "checklist", color: .green)
                            ActionTile(title: "Add Attachment", icon: "paperclip", color: .cyan)
                            ActionTile(title: "Members", icon: "person.2", color: .purple)
                        }
                    }

                    DetailSection(title: "Description") {
                        Text(card.funParagraph)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    DetailSection(title: "Details") {
                        DetailRow(icon: "calendar", title: "Start date", value: "Today")
                        Divider()
                        DetailRow(icon: "calendar.badge.clock", title: "Due date", value: card.hasDueDate ? "Tomorrow" : "None")
                        Divider()
                        DetailRow(icon: "tag", title: "Labels", value: "Planning")
                        Divider()
                        DetailRow(icon: "person", title: "Members", value: "Justin Reina")
                    }

                    DetailSection(title: "Checklists", trailing: "plus") {
                        ChecklistBlock(title: "Focus", items: card.checklistItems, completed: card.completedChecklistItems)
                        ChecklistBlock(title: "Plan", items: ["Choose the next useful step", "Stop building", "Start producing"], completed: 1)
                        ChecklistBlock(title: "Routine", items: ["Home", "Gym", "Work"], completed: 0)
                    }

                    DetailSection(title: "Activity", trailing: "gearshape") {
                        ActivityRow(text: "Justin Reina added \(card.word.capitalized) to this card")
                        ActivityRow(text: "Justin Reina created this card in \(card.listTitle)")
                        ActivityRow(text: "Justin Reina: \"This is going to be surprisingly useful.\"")
                    }
                }
            }
            .padding(.bottom, 12)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                dismiss()
            } label: {
                Text("Back")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .foregroundStyle(.white)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
        .navigationTitle(card.word.capitalized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}


// -------------------------------------- MARK: - Detail Section ------------------------------- //

///
/// Groups a detail subsection with an optional trailing symbol
///
/// @section    Purpose
///     Provide a consistent heading, content area, spacing, and divider for card detail sections
///
/// @note   The generic content keeps this component reusable for text, controls, metadata, and activity
///
struct DetailSection<Content: View>: View {

    let title:    String    /* The title of the detail section                    */
    var trailing: String?   /* The optional trailing symbol of the detail section */

    @ViewBuilder let content: () -> Content

    ///
    /// @brief      Initialize a detail section
    /// @details    Stores the section title, optional trailing symbol, and view-builder content
    ///
    /// @param[in]  title       Display title for the section
    /// @param[in]  trailing    Optional SF Symbol name shown at the trailing edge
    /// @param[in]  content     Content rendered below the section heading
    ///
    /// @return     (DetailSection) configured detail section
    ///
    init(title: String, trailing: String? = nil, @ViewBuilder content: @escaping () -> Content) {

        self.title    = title      /* The title of the detail section                    */
        self.trailing = trailing   /* The optional trailing symbol of the detail section */
        self.content  = content    /* The content of the detail section                  */
    }


    ///
    /// @brief      Build the detail section presentation
    /// @details    Renders the heading, optional trailing symbol, supplied content, and section divider
    ///
    /// @return     (some View) rendered detail section
    ///
    var body: some View {

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if let trailing {
                    Image(systemName: trailing)
                        .foregroundStyle(.secondary)
                }
            }
            content()
        }
        .padding(16)
        .background(.background)
        .overlay(alignment: .bottom) { Divider() }
    }
}


// -------------------------------------- MARK: - Action Tile ---------------------------------- //

///
/// Displays a compact action button within a detail section
///
/// @section    Purpose
///     Present a labeled action with a symbol and accent color in the quick-actions grid
///
struct ActionTile: View {

    let title: String   /* The title of the action tile          */
    let icon:  String   /* The icon representing the action tile */
    let color: Color    /* The color of the action tile          */

    ///
    /// @brief      Build the compact action tile
    /// @details    Renders the action label and symbol as a plain, consistently sized button
    ///
    /// @return     (some View) rendered action tile
    ///
    var body: some View {

        Button(action: {}) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .tint(color)
        }
        .buttonStyle(.plain)
    }
}


// -------------------------------------- MARK: - Detail Row ----------------------------------- //

///
/// Displays one icon, label, and value row in the card metadata
///
/// @section    Purpose
///     Keep related card metadata visually aligned and easy to scan
///
struct DetailRow: View {

    let icon:  String   /* The icon representing the detail row     */
    let title: String   /* The title or label of the detail row     */
    let value: String   /* The value associated with the detail row */

    ///
    /// @brief      Build one metadata row
    /// @details    Aligns the supplied icon, title, and trailing value within the detail section
    ///
    /// @return     (some View) rendered metadata row
    ///
    var body: some View {

        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 22)
                .foregroundStyle(.secondary)
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
        .padding(.vertical, 5)
    }
}


// -------------------------------------- MARK: - Checklist ------------------------------------ //

///
/// Displays a checklist group and its completion count
///
/// @section    Purpose
///     Present checklist progress together with each item and its completion state
///
/// @note   Completion is supplied by the parent so this view remains presentation-focused
///
struct ChecklistBlock: View {

    let title:     String   /* The title of the checklist block */
    let items:     [String] /* The list of checklist items      */
    let completed: Int      /* The number of completed items    */


    ///
    /// @brief      Build the checklist group
    /// @details    Renders the group title, completed-item count, and checklist rows
    ///
    /// @return     (some View) rendered checklist group
    ///
    var body: some View {

        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(completed)/\(items.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 6)

            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 10) {
                    Image(systemName: index < completed ? "checkmark.square.fill" : "square")
                        .foregroundStyle(index < completed ? .blue : .secondary)
                    Text(item)
                        .font(.subheadline)
                    Spacer()
                }
                .padding(.vertical, 6)
            }
        }
        .padding(.vertical, 6)
    }
}


// -------------------------------------- MARK: - Activity ------------------------------------- //

///
/// Displays one activity event associated with the card
///
/// @section    Purpose
///     Render a compact activity entry with actor styling, event text, and timestamp
///
struct ActivityRow: View {

    let text: String    /* The main text content of the activity row */


    ///
    /// @brief      Build the activity event row
    /// @details    Places the activity text and timestamp beside the actor symbol
    ///
    /// @return     (some View) rendered activity row
    ///
    var body: some View {

        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "person.crop.circle.fill")
                .foregroundStyle(.teal)
            VStack(alignment: .leading, spacing: 3) {
                Text(text)
                    .font(.subheadline)
                Text("Today at 7:00 AM")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 7)
    }
}


// -------------------------------------- MARK: - Previews -------------------------------------- //

///
/// Preview the card detail presentation with representative sample data
///
/// @section    Purpose
///     Provide a fast Xcode canvas preview for the complete detail flow
///
#Preview {
    NavigationStack {
        CardDetailView(card: SampleData.lists[0].cards[0])
    }
}

