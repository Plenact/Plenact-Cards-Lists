import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            GeometryReader { screen in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(SampleData.lists) { list in
                            KanbanListView(list: list, screenSize: screen.size)
                                .frame(width: screen.size.width, height: screen.size.height)
                        }
                    }
                }
                .scrollTargetBehavior(.paging)
            }
            .navigationTitle("Plenact Board")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct KanbanListView: View {
    let list: KanbanList
    let screenSize: CGSize

    private var cardHeight: CGFloat {
        screenSize.height * 0.25
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(list.title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 8) {
                    ForEach(list.cards) { card in
                        NavigationLink(value: card) {
                            KanbanCardView(card: card, height: cardHeight)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
            }
        }
        .navigationDestination(for: KanbanCard.self) { card in
            CardDetailView(card: card)
        }
    }
}

struct KanbanCardView: View {
    let card: KanbanCard
    let height: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.85))
                .shadow(color: .black.opacity(0.15), radius: 3, y: 2)

            Text(card.word)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(height: max(height - 8, 40))
        .padding(.horizontal, 4)
    }
}

#Preview {
    ContentView()
}
