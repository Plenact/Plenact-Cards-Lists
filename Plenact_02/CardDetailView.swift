import SwiftUI

struct CardDetailView: View {
    let card: KanbanCard
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 24) {
                Text(card.word.capitalized)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(card.funParagraph)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Back")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .navigationTitle(card.listTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        CardDetailView(card: SampleData.lists[0].cards[0])
    }
}
