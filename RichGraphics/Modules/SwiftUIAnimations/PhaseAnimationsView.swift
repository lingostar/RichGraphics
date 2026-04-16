import SwiftUI

// MARK: - Loading Phases

private enum LoadingPhase: CaseIterable {
    case start, mid, end

    var scale: CGFloat {
        switch self {
        case .start: 0.6
        case .mid: 1.0
        case .end: 0.6
        }
    }

    var opacity: Double {
        switch self {
        case .start: 0.3
        case .mid: 1.0
        case .end: 0.3
        }
    }

    var rotation: Double {
        switch self {
        case .start: 0
        case .mid: 180
        case .end: 360
        }
    }
}

// MARK: - Notification Phases

private enum PulsePhase: CaseIterable {
    case rest, expand, contract

    var scale: CGFloat {
        switch self {
        case .rest: 1.0
        case .expand: 1.3
        case .contract: 0.95
        }
    }

    var glowRadius: CGFloat {
        switch self {
        case .rest: 0
        case .expand: 14
        case .contract: 2
        }
    }
}

// MARK: - Status Phases

private enum StatusPhase: String, CaseIterable {
    case connecting = "Connecting..."
    case connected = "Connected"
    case synced = "Synced"

    var color: Color {
        switch self {
        case .connecting: .orange
        case .connected: .blue
        case .synced: .green
        }
    }

    var icon: String {
        switch self {
        case .connecting: "wifi.exclamationmark"
        case .connected: "wifi"
        case .synced: "checkmark.circle.fill"
        }
    }

    var scale: CGFloat {
        switch self {
        case .connecting: 0.9
        case .connected: 1.05
        case .synced: 1.0
        }
    }
}

// MARK: - View

struct PhaseAnimationsView: View {
    @State private var showLoading = true
    @State private var notificationCount = 3
    @State private var showStatus = true

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                loadingSection
                notificationSection
                statusSection
            }
            .padding(.vertical, 16)
        }
    }

    // MARK: - Loading Indicator

    private var loadingSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "Loading Indicator", icon: "arrow.trianglehead.2.counterclockwise")

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .frame(height: 160)

                if showLoading {
                    HStack(spacing: 16) {
                        ForEach(0..<3, id: \.self) { index in
                            PhaseAnimator(LoadingPhase.allCases) { phase in
                                Circle()
                                    .fill([Color.blue, .purple, .pink][index].gradient)
                                    .frame(width: 24, height: 24)
                                    .scaleEffect(phase.scale)
                                    .opacity(phase.opacity)
                            } animation: { phase in
                                    .easeInOut(duration: 0.5).delay(Double(index) * 0.15)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)

            Toggle("Show Loading", isOn: $showLoading.animation())
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Notification Badge

    private var notificationSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "Pulsing Badge", icon: "bell.badge.fill")

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .frame(height: 160)

                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.gray)

                    if notificationCount > 0 {
                        PhaseAnimator(PulsePhase.allCases) { phase in
                            Text("\(notificationCount)")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.red)
                                .clipShape(Circle())
                                .scaleEffect(phase.scale)
                                .shadow(color: .red.opacity(0.6), radius: phase.glowRadius)
                        } animation: { _ in
                            .easeInOut(duration: 0.6)
                        }
                        .offset(x: 6, y: -6)
                    }
                }
            }
            .padding(.horizontal, 16)

            Stepper("Notifications: \(notificationCount)", value: $notificationCount, in: 0...99)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Status Indicator

    private var statusSection: some View {
        VStack(spacing: 16) {
            sectionHeader(title: "Status Indicator", icon: "antenna.radiowaves.left.and.right")

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .frame(height: 160)

                if showStatus {
                    PhaseAnimator(StatusPhase.allCases) { phase in
                        HStack(spacing: 12) {
                            Image(systemName: phase.icon)
                                .font(.title2)
                                .foregroundStyle(phase.color)
                                .symbolEffect(.pulse)

                            Text(phase.rawValue)
                                .font(.headline)
                                .foregroundStyle(phase.color)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(phase.color.opacity(0.12))
                        )
                        .scaleEffect(phase.scale)
                    } animation: { _ in
                        .easeInOut(duration: 1.2)
                    }
                }
            }
            .padding(.horizontal, 16)

            Toggle("Show Status", isOn: $showStatus.animation())
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    NavigationStack {
        PhaseAnimationsView()
            .navigationTitle("Phase Animations")
    }
}
