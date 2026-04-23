import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    Text("Choose a Module")
                        .font(.title2.weight(.bold))
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 20)

                    FeaturedCarousel()

                    Spacer(minLength: 0)
                }
            }
            .navigationTitle("RichGraphics")
            .navigationDestination(for: DemoModule.self) { module in
                DemoDetailView(module: module)
            }
        }
    }
}

// MARK: - Featured 3D Carousel

private struct FeaturedCarousel: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 20) {
                ForEach(DemoModule.allCases) { module in
                    NavigationLink(value: module) {
                        CarouselCard(module: module)
                    }
                    .buttonStyle(.plain)
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, 50)
        }
        .scrollTargetBehavior(.viewAligned)
        .frame(height: 460)
    }
}

private struct CarouselCard: View {
    let module: DemoModule

    var body: some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(module.gradient)
            .frame(width: 300, height: 420)
            .overlay(
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: module.iconName)
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)

                    Spacer()

                    Text(module.name)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                    Text(module.description)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                .padding(28),
                alignment: .topLeading
            )
            .shadow(color: .black.opacity(0.25), radius: 16, y: 10)
            .scrollTransition(.animated(.spring(response: 0.5, dampingFraction: 0.85)),
                              axis: .horizontal) { content, phase in
                // Amplify phase so cards start folding/scaling while still mostly
                // on-screen (nearer the center) rather than only at the edges.
                let amplified = max(-1.0, min(1.0, phase.value * 2.2))
                return content
                    .rotation3DEffect(
                        .degrees(amplified * 45),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.6
                    )
                    .scaleEffect(1.0 - abs(amplified) * 0.22)
                    .opacity(1.0 - abs(amplified) * 0.45)
            }
    }
}

#Preview {
    ContentView()
}
