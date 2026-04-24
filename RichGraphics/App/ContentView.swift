import SwiftUI

struct ContentView: View {
    @State private var showingDocs = false
    @State private var showingTest = false

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

                    Spacer(minLength: 20)

                    // Two action cards
                    HStack(spacing: 12) {
                        ActionCard(
                            title: "정리노트",
                            subtitle: "프레임워크 가이드",
                            icon: "book.pages.fill",
                            gradient: LinearGradient(
                                colors: [.indigo, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        ) {
                            showingDocs = true
                        }

                        ActionCard(
                            title: "테스트하기",
                            subtitle: "확인해 볼까요?",
                            icon: "play.rectangle.fill",
                            gradient: LinearGradient(
                                colors: [.orange, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        ) {
                            showingTest = true
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("RichGraphics")
            .navigationDestination(for: DemoModule.self) { module in
                DemoDetailView(module: module)
            }
            .fullScreenCover(isPresented: $showingDocs) {
                DocsWebSheet()
            }
            .fullScreenCover(isPresented: $showingTest) {
                TestQuizSheet()
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
        .frame(height: 440)
    }
}

private struct CarouselCard: View {
    let module: DemoModule

    var body: some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(module.gradient)
            .frame(width: 280, height: 400)
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
                // Amplify phase so cards fold/scale while still close to center.
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

// MARK: - Action Card

private struct ActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(gradient, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
