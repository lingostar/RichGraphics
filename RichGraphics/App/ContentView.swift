import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showingDocs = false
    @State private var showingTest = false
    @State private var selectedModule: DemoModule?

    var body: some View {
        Group {
            if sizeClass == .regular {
                // iPad / regular width — sidebar + detail (HIG-recommended)
                iPadLayout
            } else {
                // iPhone / compact width — stack-based navigation
                iPhoneLayout
            }
        }
        .fullScreenCover(isPresented: $showingDocs) {
            DocsWebSheet()
        }
        .fullScreenCover(isPresented: $showingTest) {
            TestQuizSheet()
        }
    }

    // MARK: iPhone Layout

    private var iPhoneLayout: some View {
        NavigationStack {
            HomeContent(
                showingDocs: $showingDocs,
                showingTest: $showingTest
            )
            .navigationTitle("RichGraphics")
            .navigationDestination(for: DemoModule.self) { module in
                DemoDetailView(module: module)
            }
        }
    }

    // MARK: iPad Layout (NavigationSplitView)

    private var iPadLayout: some View {
        NavigationSplitView {
            ModuleSidebar(
                selectedModule: $selectedModule,
                showingDocs: $showingDocs,
                showingTest: $showingTest
            )
            .navigationTitle("RichGraphics")
        } detail: {
            NavigationStack {
                if let module = selectedModule {
                    DemoDetailView(module: module)
                        .id(module.id) // force fresh detail when sidebar selection changes
                } else {
                    WelcomeDetail()
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

// MARK: - Home Content (iPhone)

private struct HomeContent: View {
    @Binding var showingDocs: Bool
    @Binding var showingTest: Bool

    var body: some View {
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
    }
}

// MARK: - iPad Sidebar

private struct ModuleSidebar: View {
    @Binding var selectedModule: DemoModule?
    @Binding var showingDocs: Bool
    @Binding var showingTest: Bool

    var body: some View {
        List(selection: $selectedModule) {
            Section("Modules") {
                ForEach(DemoModule.allCases) { module in
                    NavigationLink(value: module) {
                        HStack(spacing: 12) {
                            Image(systemName: module.iconName)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(module.gradient, in: RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(module.name)
                                    .font(.subheadline.weight(.semibold))
                                Text(module.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Resources") {
                Button {
                    showingDocs = true
                } label: {
                    Label("정리노트", systemImage: "book.pages.fill")
                }

                Button {
                    showingTest = true
                } label: {
                    Label("테스트하기", systemImage: "play.rectangle.fill")
                }
            }
        }
        .listStyle(.sidebar)
    }
}

// MARK: - iPad Detail Welcome

private struct WelcomeDetail: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 80))
                    .foregroundStyle(.purple.gradient)

                VStack(spacing: 8) {
                    Text("RichGraphics")
                        .font(.largeTitle.bold())
                    Text("왼쪽 사이드바에서 모듈을 선택하세요")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                FeaturedCarousel()
                    .padding(.top, 20)
            }
            .padding()
        }
        .navigationTitle("Welcome")
        .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Action Card (iPhone)

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

#Preview("iPhone") {
    ContentView()
}
