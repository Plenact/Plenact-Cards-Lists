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


    @Environment(\.dismiss) private var dismiss             /* Dismiss action for the card detail view                */
    @State private var checklists: [KanbanChecklist]        /* The checklist groups associated with the selected card */

    ///
    /// @brief      Initialize the card detail state
    /// @details    Seeds the card with the Focus, Plan, and Routine checklist groups shown in the detail view
    ///
    /// @param[in]  card        The kanban card being displayed in detail
    ///
    /// @return     (CardDetailView) configured card detail presentation
    ///
    init(card: KanbanCard) {
        self.card = card
        _checklists = State(initialValue: [
            KanbanChecklist(title: "Focus",   items: card.checklistItems,            completed: card.completedChecklistItems),
            KanbanChecklist(title: "Plan",    items: ["Choose the next useful step", "Stop building", "Start producing"], completed: 1),
            KanbanChecklist(title: "Routine", items: ["Home",                        "Gym",           "Work"])
        ])
    }


    ///
    /// @brief      Append a new empty checklist to the selected card's detail state
    /// @details    Adds a checklist with the common default title and no items
    ///
    /// @post       The new checklist appears in the Checklists section with zero items and zero completion
    ///
    private func addChecklist() {
        checklists.append(KanbanChecklist(title: "Checklist"))
    }


    ///
    /// @brief      Remove a checklist from the selected card's detail state
    /// @details    Filters the checklist collection by its stable identifier
    ///
    /// @param[in]  checklistID  Identifier of the checklist to remove
    ///
    /// @post       The selected checklist is no longer rendered in the Checklists section
    ///
    private func deleteChecklist(with checklistID: UUID) {
        checklists.removeAll { $0.id == checklistID }
    }
    
    ///
    /// @brief      Append a new item to a checklist
    /// @details    Replaces the matching value-type checklist with a copy containing one additional item
    ///
    /// @param[in]  checklistID  Identifier of the checklist receiving the new item
    ///
    /// @post       The new item appears above the checklist's Add item... control
    ///
    private func addItem(to checklistID: UUID) {

        // Find the index of the checklist to which the new item will be added
        guard let checklistIndex = checklists.firstIndex(where: { $0.id == checklistID }) else {
            return
        }

        let checklist = checklists[checklistIndex]
        let itemNumber = checklist.items.count + 1

        checklists[checklistIndex] = KanbanChecklist(
            id:        checklist.id,
            title:     checklist.title,
            items:     checklist.items + ["Item \(itemNumber)"],
            completed: checklist.completed
        )
    }


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

                    //***********************************************************************************************//
                    // SECTION: Quick Actions                                                                        //
                    //                                                                                               //
                    //          Presents the primary actions available for the selected card                         //
                    //***********************************************************************************************//
                    DetailSection(title: "Quick Actions") {

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {

                            ActionTile(title: "Add Checklist",  icon: "checklist", color: .green,  action: addChecklist)
                            ActionTile(title: "Add Attachment", icon: "paperclip", color: .cyan,   action: {})
                            ActionTile(title: "Members",        icon: "person.2",  color: .purple, action: {})
                        }
                    }

                    //***********************************************************************************************//
                    // SECTION: Description                                                                          //
                    //                                                                                               //
                    //          Presents the humorous context associated with the selected card. The text expands    //
                    //          vertically so the complete description remains readable                              //
                    //***********************************************************************************************//
                    DetailSection(title: "Description") {
                        Text(card.funParagraph)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    //***********************************************************************************************//
                    // SECTION: Details                                                                              //
                    //                                                                                               //
                    //          Presents the selected card's dates, labels, and member metadata in aligned rows      //
                    //***********************************************************************************************//
                    DetailSection(title: "Details") {
                        DetailRow(icon: "calendar", title: "Start date", value: "Today")
                        Divider()
                        DetailRow(icon: "calendar.badge.clock", title: "Due date", value: card.hasDueDate ? "Tomorrow" : "None")
                        Divider()
                        DetailRow(icon: "tag", title: "Labels", value: "Planning")
                        Divider()
                        DetailRow(icon: "person", title: "Members", value: "Justin Reina")
                    }

                    //***********************************************************************************************//
                    // SECTION: Checklists                                                                           //
                    //                                                                                               //
                    //          Presents the card's checklist groups and their completion state. Checklist creation  //
                    //          and deletion update the local collection rendered here                               //
                    //***********************************************************************************************//
                    DetailSection(title: "Checklists", trailing: "plus", trailingAction: addChecklist) {

                        ForEach(checklists) { checklist in

                            ChecklistBlock(

                                checklist: checklist,

                                onDelete: {
                                    deleteChecklist(with: checklist.id)
                                },
                                
                                onAddItem: {
                                    addItem(to: checklist.id)
                                }
                            )
                        }
                    }

                    //***********************************************************************************************//
                    // SECTION: Activity                                                                             //
                    //                                                                                               //
                    //          Presents the recent events associated with the selected card                         //
                    //***********************************************************************************************//
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

    let title:          String          /* The title of the detail section                    */
    var trailing:       String?         /* The optional trailing symbol of the detail section */
    var trailingAction: (() -> Void)?   /* The optional action for the trailing symbol       */

    @ViewBuilder let content: () -> Content

    ///
    /// @brief      Initialize a detail section
    /// @details    Stores the section title, optional trailing symbol/action, and view-builder content
    ///
    /// @param[in]  title       Display title for the section
    /// @param[in]  trailing    Optional SF Symbol name shown at the trailing edge
    /// @param[in]  trailingAction Optional action invoked by the trailing symbol
    /// @param[in]  content     Content rendered below the section heading
    ///
    /// @return     (DetailSection) configured detail section
    ///
    init(title: String, trailing: String? = nil, trailingAction: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) {

        self.title          = title          /* The title of the detail section                    */
        self.trailing       = trailing       /* The optional trailing symbol of the detail section */
        self.trailingAction = trailingAction /* The optional action for the trailing symbol       */
        self.content        = content        /* The content of the detail section                  */
    }


    ///
    /// @brief      Build the detail section presentation
    /// @details    Renders the heading, optional trailing symbol/action, supplied content, and divider
    ///
    /// @return     (some View) rendered detail section
    ///
    var body: some View {

        // Build the detail section container with heading, optional trailing symbol/action, content, and divider
        VStack(alignment: .leading, spacing: 10) {

            // Build the heading row with title and optional trailing symbol/action
            HStack {

                // Render the section title
                Text(title)
                    .font(.headline)
                Spacer()

                // Render the trailing symbol and optional action if provided
                if let trailing {

                    // Check if a trailing action is provided
                    if let trailingAction {

                        Button(action: trailingAction) {
                            Image(systemName: trailing)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add \(title.lowercased())")
                    } else {

                        // Render the trailing symbol without an action
                        Image(systemName: trailing)
                            .foregroundStyle(.secondary)
                    }
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
    let action: () -> Void

    ///
    /// @brief      Build the compact action tile
    /// @details    Renders the action label and symbol as a plain, consistently sized button
    ///
    /// @return     (some View) rendered action tile
    ///
    var body: some View {

        Button(action: action) {
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

    let checklist: KanbanChecklist   /* The checklist data rendered by the block           */
    let onDelete: () -> Void         /* The action invoked when the checklist is deleted   */
    let onAddItem: () -> Void        /* The action invoked when a new item is added        */


    ///
    /// @brief      Build the checklist group
    /// @details    Renders the group title, completed-item count, and checklist rows
    ///
    /// @return     (some View) rendered checklist group
    ///
    var body: some View {

        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(checklist.title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(checklist.completed)/\(checklist.items.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(action: onDelete) {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete checklist")
            }
            .padding(.bottom, 6)

            ForEach(Array(checklist.items.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 10) {
                    Image(systemName: index < checklist.completed ? "checkmark.square.fill" : "square")
                        .foregroundStyle(index < checklist.completed ? .blue : .secondary)
                    Text(item)
                        .font(.subheadline)
                    Spacer()
                }
                .padding(.vertical, 6)
            }

            Button(action: onAddItem) {
                Text("Add item...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
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

