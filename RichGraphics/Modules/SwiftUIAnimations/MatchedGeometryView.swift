import SwiftUI

private struct CardItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let description: String
}

struct MatchedGeometryView: View {
    @Namespace private var heroNamespace
    @State private var selectedCard: CardItem?

    private let cards: [CardItem] = [
        CardItem(title: "Weather", icon: "cloud.sun.fill", color: .blue,
                 description: "Check current conditions, forecasts, and weather alerts for your location."),
        CardItem(title: "Fitness", icon: "figure.run", color: .green,
                 description: "Track your workouts, set goals, and monitor your daily activity rings."),
        CardItem(title: "Music", icon: "music.note", color: .pink,
                 description: "Discover new music, create playlists, and listen to your favorites."),
        CardItem(title: "Photos", icon: "photo.stack.fill", color: .orange,
                 description: "Browse your memories, edit photos, and share albums with friends."),
        CardItem(title: "Travel", icon: "airplane", color: .purple,
                 description: "Plan trips, book flights, and explore destinations around the world."),
        CardItem(title: "Finance", icon: "chart.line.uptrend.xyaxis", color: .teal,
                 description: "Track expenses, manage budgets, and view investment performance."),
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ZStack {
            gridView
            if let card = selectedCard {
                detailView(card: card)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: selectedCard?.id)
    }

    // MARK: - Grid

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(cards) { card in
                    if selectedCard?.id != card.id {
                        cardCell(card: card)
                            .onTapGesture {
                                selectedCard = card
                            }
                    } else {
                        Color.clear
                            .frame(height: 150)
                    }
                }
            }
            .padding(16)
        }
    }

    private func cardCell(card: CardItem) -> some View {
        VStack(spacing: 12) {
            Image(systemName: card.icon)
                .font(.largeTitle)
                .foregroundStyle(.white)
                .matchedGeometryEffect(id: "\(card.id)-icon", in: heroNamespace)

            Text(card.title)
                .font(.headline)
                .foregroundStyle(.white)
                .matchedGeometryEffect(id: "\(card.id)-title", in: heroNamespace)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(card.color.gradient)
                .matchedGeometryEffect(id: "\(card.id)-bg", in: heroNamespace)
        )
        .shadow(color: card.color.opacity(0.3), radius: 8, y: 4)
    }

    // MARK: - Detail

    private func detailView(card: CardItem) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    Button {
                        selectedCard = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.top, 16)
                .padding(.trailing, 20)

                Image(systemName: card.icon)
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .matchedGeometryEffect(id: "\(card.id)-icon", in: heroNamespace)
                    .padding(.top, 20)

                Text(card.title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .matchedGeometryEffect(id: "\(card.id)-title", in: heroNamespace)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(card.color.gradient)
                    .matchedGeometryEffect(id: "\(card.id)-bg", in: heroNamespace)
            )

            VStack(alignment: .leading, spacing: 16) {
                Text(card.description)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .padding(.top, 20)

                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(card.color.opacity(0.15))
                            .frame(width: 44, height: 44)
                        VStack(alignment: .leading, spacing: 4) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.quaternary)
                                .frame(width: 140, height: 12)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.quaternary)
                                .frame(width: 100, height: 10)
                        }
                        Spacer()
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 20)
        .padding(8)
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    NavigationStack {
        MatchedGeometryView()
            .navigationTitle("Matched Geometry")
    }
}
