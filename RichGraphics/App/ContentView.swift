import SwiftUI

struct ContentView: View {
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // MARK: - Featured 3D Carousel
                    // Demonstrates SwiftUI's scrollTransition + rotation3DEffect
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Featured")
                            .font(.title3.bold())
                            .padding(.horizontal, 16)
                            .padding(.top, 4)

                        FeaturedCarousel()
                    }

                    // MARK: - All Modules Grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("All Modules")
                            .font(.title3.bold())
                            .padding(.horizontal, 16)

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(DemoModule.allCases) { module in
                                NavigationLink(value: module) {
                                    DemoCard(module: module)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
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
            LazyHStack(spacing: 16) {
                ForEach(DemoModule.allCases) { module in
                    NavigationLink(value: module) {
                        CarouselCard(module: module)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 48)
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .frame(height: 260)
    }
}

private struct CarouselCard: View {
    let module: DemoModule

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(module.gradient)
            .frame(width: 200, height: 260)
            .overlay(
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: module.iconName)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(module.name)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                    Text(module.description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(20),
                alignment: .topLeading
            )
            .shadow(color: .black.opacity(0.2), radius: 10, y: 6)
            .scrollTransition(.animated(.spring()), axis: .horizontal) { content, phase in
                content
                    .rotation3DEffect(
                        .degrees(phase.value * 35),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.5
                    )
                    .scaleEffect(1.0 - abs(phase.value) * 0.15)
                    .opacity(1.0 - abs(phase.value) * 0.3)
            }
    }
}

#Preview {
    ContentView()
}
