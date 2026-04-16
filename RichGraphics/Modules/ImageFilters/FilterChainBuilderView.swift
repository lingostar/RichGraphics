import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Chain Filter Type

private enum ChainFilterType: String, CaseIterable, Identifiable, Sendable {
    case none = "None"
    case sepia = "Sepia"
    case chrome = "Chrome"
    case noir = "Noir"
    case bloom = "Bloom"
    case vignette = "Vignette"
    case pixellate = "Pixellate"
    case edges = "Edges"
    case crystallize = "Crystallize"
    case comic = "Comic"
    case fade = "Fade"
    case pointillize = "Pointillize"
    case colorInvert = "Invert"

    var id: String { rawValue }

    var supportsIntensity: Bool {
        switch self {
        case .none, .chrome, .noir, .comic, .fade, .colorInvert:
            return false
        default:
            return true
        }
    }
}

// MARK: - Filter Slot

@Observable
@MainActor
private final class FilterSlot: Identifiable {
    let id = UUID()
    var filterType: ChainFilterType = .none
    var intensity: Double = 0.7
}

// MARK: - View

struct FilterChainBuilderView: View {
    @State private var slots: [FilterSlot] = [FilterSlot()]
    @State private var resultImage: CGImage?
    @State private var sourceImage: CGImage?

    private let context = CIContext(options: [.useSoftwareRenderer: false])

    var body: some View {
        VStack(spacing: 0) {
            // Preview
            Group {
                if let img = resultImage ?? sourceImage {
                    Image(decorative: img, scale: 1)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                        .padding(.horizontal, 16)
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray5))
                        .frame(height: 180)
                        .overlay { ProgressView() }
                        .padding(.horizontal, 16)
                }
            }
            .frame(maxHeight: 220)
            .padding(.top, 8)

            // Filter chain
            List {
                Section {
                    ForEach(Array(slots.enumerated()), id: \.element.id) { index, slot in
                        filterSlotRow(slot: slot, index: index)
                    }
                } header: {
                    Text("Filter Chain")
                } footer: {
                    if slots.count < 5 {
                        Text("Add up to 5 filters. Output flows top to bottom.")
                    } else {
                        Text("Maximum 5 filters reached.")
                    }
                }

                Section {
                    HStack {
                        if slots.count < 5 {
                            Button {
                                withAnimation {
                                    slots.append(FilterSlot())
                                }
                            } label: {
                                Label("Add Filter", systemImage: "plus.circle.fill")
                            }
                        }

                        Spacer()

                        Button(role: .destructive) {
                            withAnimation {
                                slots = [FilterSlot()]
                                updateChain()
                            }
                        } label: {
                            Label("Reset All", systemImage: "arrow.counterclockwise")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .task {
            let source = FilterGalleryView.generateProceduralImage()
            sourceImage = source
            resultImage = source
        }
    }

    // MARK: - Slot Row

    @ViewBuilder
    private func filterSlotRow(slot: FilterSlot, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "\(index + 1).circle.fill")
                    .foregroundStyle(.purple)
                    .font(.title3)

                Picker("Filter", selection: Binding(
                    get: { slot.filterType },
                    set: { newValue in
                        slot.filterType = newValue
                        updateChain()
                    }
                )) {
                    ForEach(ChainFilterType.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.menu)

                Spacer()

                if slots.count > 1 {
                    Button(role: .destructive) {
                        withAnimation {
                            slots.removeAll { $0.id == slot.id }
                            updateChain()
                        }
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                }
            }

            if slot.filterType.supportsIntensity {
                HStack {
                    Text("Intensity")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Slider(value: Binding(
                        get: { slot.intensity },
                        set: { newValue in
                            slot.intensity = newValue
                            updateChain()
                        }
                    ), in: 0...1, step: 0.05)
                    .tint(.purple)
                    Text("\(Int(slot.intensity * 100))%")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Chain Processing

    private func updateChain() {
        guard let source = sourceImage else { return }
        var current = CIImage(cgImage: source)
        let extent = current.extent

        for slot in slots where slot.filterType != .none {
            current = applyChainFilter(slot.filterType, to: current, intensity: slot.intensity)
        }

        if let cgImage = context.createCGImage(current, from: extent) {
            resultImage = cgImage
        }
    }

    private func applyChainFilter(_ type: ChainFilterType, to input: CIImage, intensity: Double) -> CIImage {
        switch type {
        case .none:
            return input
        case .sepia:
            let f = CIFilter.sepiaTone()
            f.inputImage = input
            f.intensity = Float(intensity)
            return f.outputImage ?? input
        case .chrome:
            let f = CIFilter.photoEffectChrome()
            f.inputImage = input
            return f.outputImage ?? input
        case .noir:
            let f = CIFilter.photoEffectNoir()
            f.inputImage = input
            return f.outputImage ?? input
        case .bloom:
            let f = CIFilter.bloom()
            f.inputImage = input
            f.intensity = Float(intensity * 2)
            f.radius = Float(intensity * 20)
            return f.outputImage ?? input
        case .vignette:
            let f = CIFilter.vignette()
            f.inputImage = input
            f.intensity = Float(intensity * 5)
            f.radius = Float(intensity * 3)
            return f.outputImage ?? input
        case .pixellate:
            let f = CIFilter.pixellate()
            f.inputImage = input
            f.scale = Float(max(1, intensity * 30))
            return f.outputImage ?? input
        case .edges:
            let f = CIFilter.edges()
            f.inputImage = input
            f.intensity = Float(intensity * 10)
            return f.outputImage ?? input
        case .crystallize:
            let f = CIFilter.crystallize()
            f.inputImage = input
            f.radius = Float(max(1, intensity * 40))
            return f.outputImage ?? input
        case .comic:
            let f = CIFilter.comicEffect()
            f.inputImage = input
            return f.outputImage ?? input
        case .fade:
            let f = CIFilter.photoEffectFade()
            f.inputImage = input
            return f.outputImage ?? input
        case .pointillize:
            let f = CIFilter.pointillize()
            f.inputImage = input
            f.radius = Float(max(1, intensity * 30))
            return f.outputImage ?? input
        case .colorInvert:
            let f = CIFilter.colorInvert()
            f.inputImage = input
            return f.outputImage ?? input
        }
    }
}

#Preview {
    NavigationStack {
        FilterChainBuilderView()
            .navigationTitle("Filter Chain Builder")
    }
}
