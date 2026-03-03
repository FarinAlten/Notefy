import SwiftUI

struct EmptySearchStateView: View {
    let accentColor: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(accentColor.opacity(0.85))
            Text("No matches")
                .font(.headline)
            Text("Try a different keyword.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 40)
    }
}
