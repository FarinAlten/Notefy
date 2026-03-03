import SwiftUI

struct EmptyStateView: View {
    let accentColor: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(accentColor.opacity(0.9))
            Text("No notes yet")
                .font(.headline)
            Text("Tap the plus to create your first note.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 40)
    }
}
