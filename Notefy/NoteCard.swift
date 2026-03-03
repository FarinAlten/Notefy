import SwiftUI

struct NoteCard: View {
    let note: Note
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(accentColor.opacity(0.6))
                .frame(width: 4)
                .padding(.vertical, 6)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(note.title.isEmpty ? "Untitled" : note.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .animation(.easeInOut(duration: 0.2), value: note.title)
                    Spacer()
                    Text(note.createdAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !note.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(note.content)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .animation(.easeInOut(duration: 0.2), value: note.content)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .contentShape(Rectangle())
        #if canImport(UIKit)
        .hoverEffect(.highlight)
        #endif
    }
}
