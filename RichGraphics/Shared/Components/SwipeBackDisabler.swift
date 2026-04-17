import SwiftUI

// MARK: - Custom Back Button (hides default back + disables swipe-back gesture)
//
// Setting .navigationBarBackButtonHidden(true) in SwiftUI also disables the
// interactive swipe-back gesture — which is what we want for demo views that
// have full-screen touch interactions (drawing, SpriteKit, particles, drag
// gestures). We then provide our own back button via toolbar.

extension View {
    /// Disables the navigation swipe-back gesture by hiding the default back
    /// button and providing a custom one.
    func disableSwipeBack() -> some View {
        modifier(CustomBackButtonModifier())
    }
}

private struct CustomBackButtonModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                            Text("Back")
                                .font(.body)
                        }
                    }
                    .accessibilityLabel("Back")
                }
            }
    }
}
