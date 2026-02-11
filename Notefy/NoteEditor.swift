import SwiftUI

struct NoteEditor: View {
    @Binding var note: Note

    @State private var pendingAction: RichTextAction? = nil

    var onExportRequest: (ContentView.ExportFormat) -> Void
    var accentColor: Color

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    enum Field {
        case title
        case content
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Title", text: $note.title, axis: .vertical)
                    .font(.system(.title2, design: .default).weight(.semibold))
                    .focused($focusedField, equals: .title)
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(false)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .transaction { transaction in
                        transaction.animation = .easeInOut(duration: 0.2)
                    }

                RichTextView(text: $note.content, action: $pendingAction)
                    .frame(minHeight: 240, maxHeight: .infinity, alignment: .topLeading)
                    .background(Color.clear)
                    .focused($focusedField, equals: .content)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 80)
                    .transaction { transaction in
                        transaction.animation = .easeInOut(duration: 0.2)
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.systemGroupedBackground))
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    pendingAction = .bold
                } label: {
                    Image(systemName: "bold")
                }
                .keyboardShortcut("b", modifiers: [.command])

                Button {
                    pendingAction = .italic
                } label: {
                    Image(systemName: "italic")
                }
                .keyboardShortcut("i", modifiers: [.command])

                Button {
                    pendingAction = .strikethrough
                } label: {
                    Image(systemName: "strikethrough")
                }

                Menu {
                    Button { pendingAction = .heading1 } label: { Label("Heading", systemImage: "textformat.size.larger") }
                    Button { pendingAction = .quote } label: { Label("Quote", systemImage: "text.quote") }
                    Button { pendingAction = .bullet } label: { Label("List", systemImage: "list.bullet") }
                } label: {
                    Image(systemName: "textformat")
                }

                Menu {
                    Button {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        onExportRequest(.markdown)
                    } label: {
                        Label("Markdown (.md)", systemImage: "doc")
                    }
                    .keyboardShortcut("m", modifiers: [.command, .shift])
                    Button {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        onExportRequest(.plainText)
                    } label: {
                        Label("Plain Text (.txt)", systemImage: "doc.plaintext")
                    }
                    .keyboardShortcut("t", modifiers: [.command, .shift])
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.body.weight(.semibold))
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            ToolbarItemGroup(placement: .keyboard) {
                LiquidGlassToolbar(
                    accentColor: accentColor,
                    onAction: { pendingAction = $0 }
                )
            }
        }
        .onChange(of: focusedField) { new in
            if new == .content {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
}
