import SwiftUI

struct ImageFilterDemo: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let destination: AnyView

    @MainActor
    init<V: View>(title: String, description: String, icon: String, color: Color, @ViewBuilder destination: () -> V) {
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self.destination = AnyView(destination())
    }
}

struct ImageFiltersView: View {
    @MainActor
    private var demos: [ImageFilterDemo] {
        [
            ImageFilterDemo(
                title: "Filter Gallery",
                description: "Browse 15+ Core Image filters with live preview and intensity control",
                icon: "camera.filters",
                color: .pink
            ) {
                FilterGalleryView()
            },
            ImageFilterDemo(
                title: "Camera Filters",
                description: "Real-time camera feed with live CIFilter processing and FPS counter",
                icon: "video.fill",
                color: .orange
            ) {
                CameraFiltersView()
            },
            ImageFilterDemo(
                title: "Filter Chain Builder",
                description: "Stack up to 5 filters in sequence and see the chained result live",
                icon: "link.badge.plus",
                color: .purple
            ) {
                FilterChainBuilderView()
            },
            ImageFilterDemo(
                title: "Custom Effects",
                description: "Creative effects: Glitch, Vintage, Pop Art, Neon Glow with before/after comparison",
                icon: "sparkles.rectangle.stack",
                color: .teal
            ) {
                CustomEffectsView()
            },
        ]
    }

    var body: some View {
        List(demos) { demo in
            NavigationLink {
                demo.destination
                    .navigationTitle(demo.title)
                    .disableSwipeBack()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: demo.icon)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(demo.color.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(demo.title)
                            .font(.headline)
                        Text(demo.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview {
    NavigationStack {
        ImageFiltersView()
            .navigationTitle("Image Filters")
    }
}
