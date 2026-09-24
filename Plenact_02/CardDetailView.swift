import SwiftUI

struct CardDetailView: View {
    let card: KanbanCard
    @Environment(\.dismiss) private var dismiss

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

struct DetailSection<Content: View>: View {
    let title: String
    var trailing: String?
    @ViewBuilder let content: () -> Content

    init(title: String, trailing: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.trailing = trailing
        self.content = content
    }

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

struct ActionTile: View {
    let title: String
    let icon: String
    let color: Color

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

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String

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

struct ChecklistBlock: View {
    let title: String
    let items: [String]
    let completed: Int

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

struct ActivityRow: View {
    let text: String

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

#Preview {
    NavigationStack {
        CardDetailView(card: SampleData.lists[0].cards[0])
    }
}
