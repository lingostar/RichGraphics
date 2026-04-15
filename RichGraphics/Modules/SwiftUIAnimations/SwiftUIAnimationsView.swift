import SwiftUI

struct SwiftUIAnimationsView: View {
    @State private var dampingFraction: Double = 0.5
    @State private var animated = false

    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                    Circle()
                        .fill(color.gradient)
                        .frame(width: 60, height: 60)
                        .offset(
                            x: animated ? cos(Double(index) * .pi / 3) * 100 : 0,
                            y: animated ? sin(Double(index) * .pi / 3) * 100 : 0
                        )
                        .scaleEffect(animated ? 1.0 : 0.3)
                        .opacity(animated ? 1.0 : 0.5)
                }
            }
            .frame(height: 280)

            Spacer()

            VStack(spacing: 12) {
                Text("Damping Fraction: \(dampingFraction, specifier: "%.2f")")
                    .font(.subheadline.monospaced())

                Slider(value: $dampingFraction, in: 0.05...1.0, step: 0.05)
                    .padding(.horizontal, 32)

                Button {
                    withAnimation(.spring(duration: 0.8, bounce: 1.0 - dampingFraction)) {
                        animated.toggle()
                    }
                } label: {
                    Text(animated ? "Collapse" : "Expand")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.purple.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
            }
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    NavigationStack {
        SwiftUIAnimationsView()
            .navigationTitle("SwiftUI Animations")
    }
}
