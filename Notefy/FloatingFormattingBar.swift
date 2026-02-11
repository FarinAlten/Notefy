import SwiftUI

struct FloatingFormattingBar: View {
    var accentColor: Color
    var onAction: (RichTextAction) -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button {
                onAction(.bold)
            } label: {
                Image(systemName: "bold")
            }
            .accessibilityLabel("Bold")

            Button {
                onAction(.italic)
            } label: {
                Image(systemName: "italic")
            }
            .accessibilityLabel("Italic")

            Button {
                onAction(.underline)
            } label: {
                Image(systemName: "underline")
            }
            .accessibilityLabel("Underline")

            Divider().frame(height: 18)
                .padding(.horizontal, 2)
                .opacity(0.6)

            Button {
                onAction(.bulletList)
            } label: {
                Image(systemName: "list.bullet")
            }
            .accessibilityLabel("Bullet list")

            Button {
                onAction(.link)
            } label: {
                Image(systemName: "link")
            }
            .accessibilityLabel("Insert link")
        }
        .font(.system(size: 16, weight: .semibold))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 2)
        .tint(accentColor)
        .buttonStyle(.plain)
    }
}

#Preview("FloatingFormattingBar") {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        FloatingFormattingBar(accentColor: .blue) { action in
            // Preview action
            print("Action: \(action)")
        }
        .padding()
    }
}
