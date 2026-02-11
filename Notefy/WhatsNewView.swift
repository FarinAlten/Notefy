import SwiftUI

struct WhatsNewView: View {
    @State private var index: Int = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            TabView(selection: $index) {
                ForEach(Array(whatsNewEntries.enumerated()), id: \.offset) { i, entry in
                    WhatsNewPage(entry: entry)
                        .tag(i)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .interactive))

            let current = whatsNewEntries[safe: index] ?? whatsNewEntries.first!

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(colorForKey(current.accentKey))
                        .frame(width: 18, height: 18)
                    Text("Version \(current.version)")
                        .font(.headline)
                    Spacer()
                    if let date = current.date {
                        Text(date, style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                if !current.title.isEmpty {
                    Text(current.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)

            HStack {
                Spacer()
                Button {
                    index = max(0, whatsNewEntries.count - 1)
                } label: {
                    Label("Latest", systemImage: "arrow.uturn.right.circle")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(colorForKey(current.accentKey))

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(colorForKey(current.accentKey))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .navigationTitle("What’s New")
    }
}
