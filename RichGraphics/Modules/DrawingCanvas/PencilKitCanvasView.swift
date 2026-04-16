import SwiftUI
import PencilKit

struct PencilKitCanvasView: View {
    @State private var canvasView = PKCanvasView()
    @State private var isToolPickerVisible = true
    @State private var showExportSheet = false
    @State private var exportedImage: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            PKCanvasRepresentable(
                canvasView: $canvasView,
                isToolPickerVisible: $isToolPickerVisible
            )

            Divider()

            toolBar
        }
        .sheet(isPresented: $showExportSheet) {
            if let image = exportedImage {
                exportSheet(image: image)
            }
        }
    }

    // MARK: - Toolbar

    private var toolBar: some View {
        HStack(spacing: 16) {
            Button {
                isToolPickerVisible.toggle()
            } label: {
                Label(
                    isToolPickerVisible ? "Hide Tools" : "Show Tools",
                    systemImage: isToolPickerVisible ? "paintpalette.fill" : "paintpalette"
                )
                .font(.subheadline)
            }
            .buttonStyle(.bordered)

            Spacer()

            Button {
                canvasView.undoManager?.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }

            Button {
                canvasView.undoManager?.redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
            }

            Button {
                exportDrawing()
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)
            .tint(.blue)

            Button("Clear", role: .destructive) {
                canvasView.drawing = PKDrawing()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }

    private func exportDrawing() {
        let bounds = canvasView.bounds
        let image = canvasView.drawing.image(from: bounds, scale: UIScreen.main.scale)
        exportedImage = image
        showExportSheet = true
    }

    @MainActor
    private func exportSheet(image: UIImage) -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Exported Drawing")
                    .font(.headline)

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    .padding(.horizontal)

                Text("\(Int(image.size.width))x\(Int(image.size.height)) points")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.top, 20)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showExportSheet = false
                    }
                }
            }
        }
    }
}

// MARK: - UIViewRepresentable

private struct PKCanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var isToolPickerVisible: Bool

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .white
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 5)

        let toolPicker = PKToolPicker()
        context.coordinator.toolPicker = toolPicker
        toolPicker.setVisible(isToolPickerVisible, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()

        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if let toolPicker = context.coordinator.toolPicker {
            toolPicker.setVisible(isToolPickerVisible, forFirstResponder: uiView)
            if isToolPickerVisible {
                uiView.becomeFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject {
        var toolPicker: PKToolPicker?
    }
}

#Preview {
    NavigationStack {
        PencilKitCanvasView()
            .navigationTitle("PencilKit Canvas")
    }
}
