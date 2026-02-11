import SwiftUI

struct PreviewCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
            .frame(height: 58)
            .overlay(
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.35))
                        .frame(width: 120, height: 10)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.25))
                        .frame(width: 200, height: 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
            )
    }
}
