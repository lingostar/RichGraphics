import SwiftUI

// MARK: - Custom Transition Modifiers

private struct IrisModifier: ViewModifier {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .clipShape(Circle().scale(progress))
            .opacity(progress > 0 ? 1 : 0)
    }
}

private struct BlurTransitionModifier: ViewModifier {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .blur(radius: (1 - progress) * 12)
            .opacity(Double(progress))
    }
}

private struct FlipModifier: ViewModifier {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(Double(1 - progress) * 90), axis: (x: 0, y: 1, z: 0))
            .opacity(Double(progress))
    }
}

private struct SlideAndFadeModifier: ViewModifier {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .offset(y: (1 - progress) * 40)
            .opacity(Double(progress))
    }
}

private struct TypewriterModifier: ViewModifier {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .mask(
                GeometryReader { geo in
                    Rectangle()
                        .frame(width: geo.size.width * progress)
                }
            )
            .opacity(progress > 0 ? 1 : 0)
    }
}

// MARK: - AnyTransition extensions

extension AnyTransition {
    static var iris: AnyTransition {
        .modifier(
            active: IrisModifier(progress: 0),
            identity: IrisModifier(progress: 1)
        )
    }

    static var blurFade: AnyTransition {
        .modifier(
            active: BlurTransitionModifier(progress: 0),
            identity: BlurTransitionModifier(progress: 1)
        )
    }

    static var flip: AnyTransition {
        .modifier(
            active: FlipModifier(progress: 0),
            identity: FlipModifier(progress: 1)
        )
    }

    static var slideFade: AnyTransition {
        .modifier(
            active: SlideAndFadeModifier(progress: 0),
            identity: SlideAndFadeModifier(progress: 1)
        )
    }

    static var typewriter: AnyTransition {
        .modifier(
            active: TypewriterModifier(progress: 0),
            identity: TypewriterModifier(progress: 1)
        )
    }
}

// MARK: - Transition Demo Model

private enum TransitionType: String, CaseIterable, Identifiable {
    case iris = "Iris"
    case blurFade = "Blur"
    case flip = "Flip"
    case slideFade = "Slide & Fade"
    case typewriter = "Typewriter"

    var id: String { rawValue }

    var transition: AnyTransition {
        switch self {
        case .iris: .iris
        case .blurFade: .blurFade
        case .flip: .flip
        case .slideFade: .slideFade
        case .typewriter: .typewriter
        }
    }

    var color: Color {
        switch self {
        case .iris: .purple
        case .blurFade: .blue
        case .flip: .orange
        case .slideFade: .green
        case .typewriter: .pink
        }
    }

    var icon: String {
        switch self {
        case .iris: "circle.dotted"
        case .blurFade: "aqi.medium"
        case .flip: "rectangle.portrait.rotate"
        case .slideFade: "arrow.down.right.and.arrow.up.left"
        case .typewriter: "character.cursor.ibeam"
        }
    }
}

// MARK: - View

struct CustomTransitionsView: View {
    @State private var visibleTransitions: Set<TransitionType> = []
    @State private var randomMode = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Toggle("Random Mode", isOn: $randomMode)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                if randomMode {
                    randomSection
                } else {
                    individualSection
                }
            }
            .padding(.bottom, 32)
        }
    }

    // MARK: - Individual

    private var individualSection: some View {
        ForEach(TransitionType.allCases) { type in
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: type.icon)
                        .foregroundStyle(type.color)
                    Text(type.rawValue)
                        .font(.headline)
                    Spacer()
                    Button(visibleTransitions.contains(type) ? "Hide" : "Show") {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            if visibleTransitions.contains(type) {
                                visibleTransitions.remove(type)
                            } else {
                                visibleTransitions.insert(type)
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(type.color)
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .frame(height: 120)

                    if visibleTransitions.contains(type) {
                        transitionContent(for: type)
                            .transition(type.transition)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Random

    @State private var randomVisible = false
    @State private var randomType: TransitionType = .iris

    private var randomSection: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .frame(height: 200)

                if randomVisible {
                    transitionContent(for: randomType)
                        .transition(randomType.transition)
                }
            }
            .padding(.horizontal, 16)

            Text("Current: \(randomType.rawValue)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                withAnimation(.easeInOut(duration: 0.6)) {
                    randomVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    let allCases = TransitionType.allCases
                    randomType = allCases[Int.random(in: 0..<allCases.count)]
                    withAnimation(.easeInOut(duration: 0.6)) {
                        randomVisible = true
                    }
                }
            } label: {
                Label("Random Transition", systemImage: "dice.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.teal.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Content

    private func transitionContent(for type: TransitionType) -> some View {
        VStack(spacing: 8) {
            Image(systemName: type.icon)
                .font(.largeTitle)
                .foregroundStyle(type.color)
            Text(type.rawValue)
                .font(.headline)
                .foregroundStyle(type.color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(type.color.opacity(0.1))
        )
        .padding(.horizontal, 4)
    }
}

#Preview {
    NavigationStack {
        CustomTransitionsView()
            .navigationTitle("Custom Transitions")
    }
}
