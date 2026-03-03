import SwiftUI

struct GalleryCard: View {
    let note: Note
    let selected: Bool
    let accentColor: Color
    let isEditing: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !note.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(note.content)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                }

                Spacer(minLength: 0)

                Text(note.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(minHeight: 120, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(accentColor.opacity(0.15), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? accentColor : Color.clear, lineWidth: 2)
            )
            .shadow(color: selected ? accentColor.opacity(0.35) : .clear, radius: selected ? 10 : 0)

            if isEditing {
                Circle()
                    .fill(selected ? accentColor : Color.secondary.opacity(0.25))
                    .frame(width: 22, height: 22)
                    .overlay(
                        Image(systemName: selected ? "checkmark" : "circle")
                            .foregroundStyle(.white)
                            .font(.system(size: 11, weight: .bold))
                    )
                    .padding(8)
                    .accessibilityHidden(true)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selected)
    }
}
