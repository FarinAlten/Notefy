import SwiftUI

struct AccentPreviewPage: View {
    let accent: AccentChoice

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)

            VStack {
                HStack {
                    Text("Notes")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "gearshape")
                        .foregroundStyle(accent.color)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                VStack(spacing: 10) {
                    PreviewCard()
                    PreviewCard()
                    PreviewCard()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                HStack {
                    Spacer()
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(16)
                        .background(
                            Circle()
                                .fill(accent.color)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 5)
                        )
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                }
            }
            .padding(.vertical, 8)
        }
        .frame(height: 340)
    }
}
