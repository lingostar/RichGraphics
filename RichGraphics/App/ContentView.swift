import SwiftUI

struct ContentView: View {
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(DemoModule.allCases) { module in
                        NavigationLink(value: module) {
                            DemoCard(module: module)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("RichGraphics")
            .navigationDestination(for: DemoModule.self) { module in
                DemoDetailView(module: module)
            }
        }
    }
}

#Preview {
    ContentView()
}
