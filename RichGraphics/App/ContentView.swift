import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showingDocs = false
    @State private var showingTest = false
    @State private var selectedModule: DemoModule?     // iPhone path (push)
    @State private var selectedDemo: DemoEntry?         // iPad path (sidebar)

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
            DemoSidebar(
                selectedDemo: $selectedDemo,
                showingDocs: $showingDocs,
                showingTest: $showingTest
            )
            .navigationTitle("RichGraphics")
        } detail: {
            NavigationStack {
                if let demo = selectedDemo {
                    DemoCatalog.destinationView(for: demo)
                        .navigationTitle(demo.title)
                        .navigationBarTitleDisplayMode(.inline)
                        .id(demo.id) // ensure VC swap when selection changes
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
//
// Every sub-demo is exposed directly in the sidebar, grouped by the
// parent module name. Selecting a row swaps the detail pane to that
// demo. There is no intermediate "module list" step on iPad.

private struct DemoSidebar: View {
    @Binding var selectedDemo: DemoEntry?
    @Binding var showingDocs: Bool
    @Binding var showingTest: Bool

    var body: some View {
        List(selection: $selectedDemo) {
            // 정리노트 — pinned at the top (most prominent reference).
            Section {
                Button {
                    showingDocs = true
                } label: {
                    resourceRow(
                        icon: "book.pages.fill",
                        title: "정리노트",
                        subtitle: "프레임워크 가이드",
                        gradient: LinearGradient(
                            colors: [.indigo, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
                .buttonStyle(.plain)
            }

            // Modules — each section has title + description in its header
            // (Gestalt's Proximity Principle: descriptions belong to the
            //  title above them, not the section that follows).
            ForEach(DemoModule.allCases) { module in
                Section {
                    ForEach(DemoCatalog.entries(for: module)) { entry in
                        NavigationLink(value: entry) {
                            sidebarRow(for: entry)
                        }
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(module.name)
                            .font(.subheadline.weight(.bold))
                            .textCase(nil)
                        Text(module.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    }
                    .padding(.vertical, 2)
                }
            }

            // 테스트하기 — at the bottom (conclusion, after exploring modules).
            Section {
                Button {
                    showingTest = true
                } label: {
                    resourceRow(
                        icon: "play.rectangle.fill",
                        title: "테스트하기",
                        subtitle: "확인해 볼까요?",
                        gradient: LinearGradient(
                            colors: [.orange, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
    }

    private func resourceRow(
        icon: String,
        title: String,
        subtitle: String,
        gradient: LinearGradient
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(gradient, in: RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func sidebarRow(for entry: DemoEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: entry.icon)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(entry.color.gradient, in: RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.subheadline.weight(.semibold))
                Text(entry.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - iPad Detail Welcome
//
// Pure visual welcome — no navigation here. All module navigation is
// driven from the sidebar.

private struct WelcomeDetail: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 96))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(spacing: 12) {
                    Text("RichGraphics")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))

                    Text("Apple 그래픽 프레임워크 탐험")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Label("왼쪽 사이드바에서 모듈을 선택하세요", systemImage: "sidebar.left")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
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
