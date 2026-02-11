import SwiftUI

struct LiquidGlassToolbar: View {
    var accentColor: Color
    var onAction: (RichTextAction) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 18) {
                formattingButton(systemImage: "bold", action: .bold)
                formattingButton(systemImage: "italic", action: .italic)
                formattingButton(systemImage: "strikethrough", action: .strikethrough)
                Divider().frame(height: 18).opacity(0.25)
                formattingButton(systemImage: "textformat.size.larger", action: .heading1)
                formattingButton(systemImage: "text.quote", action: .quote)
                formattingButton(systemImage: "list.bullet", action: .bullet)
        }
        .labelStyle(.iconOnly)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.22),
                            Color.white.opacity(0.25),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(Capsule())
                )
        )
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.5),
                            Color.white.opacity(0.6),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.18), radius: 16, x: 0, y: 10)
        .compositingGroup()
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: accentColor)
        .tint(accentColor)
    }

    private func formattingButton(systemImage: String, action: RichTextAction) -> some View {
        Button {
            onAction(action)
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(accentColor)
                .padding(6)
        }
        .buttonStyle(.plain)
    }
}
