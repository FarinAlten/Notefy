import SwiftUI

struct WhatsNewPage: View {
    let entry: WhatsNewEntry

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text("v\(entry.version)")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(colorForKey(entry.accentKey).opacity(0.15))
                        )
                        .foregroundStyle(colorForKey(entry.accentKey))
                    Spacer()
                    if let date = entry.date {
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !entry.title.isEmpty {
                    Text(entry.title)
                        .font(.title3.weight(.semibold))
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(entry.highlights, id: \.self) { line in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(colorForKey(entry.accentKey))
                                .padding(.top, 1)
                            Text(line)
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(16)
        }
        .frame(height: 320)
    }
}
