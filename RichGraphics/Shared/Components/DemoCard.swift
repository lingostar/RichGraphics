import SwiftUI

struct DemoCard: View {
    let module: DemoModule

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: module.iconName)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(module.name)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(module.description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(module.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    DemoCard(module: .swiftUIAnimations)
        .frame(width: 180)
        .padding()
}
