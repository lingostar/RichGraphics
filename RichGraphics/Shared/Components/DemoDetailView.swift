import SwiftUI

struct DemoDetailView: View {
    let module: DemoModule

    var body: some View {
        module.destinationView
            .navigationTitle(module.name)
            .navigationBarTitleDisplayMode(.inline)
    }
}
