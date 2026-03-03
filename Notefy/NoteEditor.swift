// NoteEditor.swift
// Neue Tastatur-Accessory-Leiste mit Formatierungs-Buttons unterhalb des TextEditors
// Der TextEditor erhält keine Toolbar mehr, sondern die Buttons sind immer direkt über der Tastatur sichtbar
// Toolbar in der Navigationsleiste wurde entfernt
// Formatierungsbuttons unterstützen Markdown-ähnliche Syntax-Manipulation direkt im Text
// Zusätzliche Buttons wie Codeblock, Durchgestrichen, Trennlinie und Checkbox (ToDo) wurden ergänzt
// Leiste ist horizontal scrollbar und passt sich auch auf kleinen Geräten an

import SwiftUI

struct NoteEditor: View {
    @Binding var note: Note
    @ObservedObject private var localization = AppLocalization.shared

    @State private var pendingAction: RichTextAction? = nil

    var onExportRequest: (ContentView.ExportFormat) -> Void
    var accentColor: Color

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    // Für TextEditor Selektion & Text Manipulation
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)

    enum Field {
        case title
        case content
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    TextField(localization.text("Title"), text: $note.title, axis: .vertical)
                        .font(.system(.title2, design: .default).weight(.semibold))
                        .focused($focusedField, equals: .title)
                        .textInputAutocapitalization(.sentences)
                        .disableAutocorrection(false)
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .transaction { transaction in
                            transaction.animation = Animation.easeInOut(duration: 0.2)
                        }

                    // CustomTextEditor to get selection and text manipulation support
                    CustomTextEditor(text: $note.content, selectedRange: $selectedRange)
                        .frame(minHeight: 240, maxHeight: .infinity, alignment: .topLeading)
                        .background(Color.clear)
                        .focused($focusedField, equals: .content)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 80)
                        .transaction { transaction in
                            transaction.animation = Animation.easeInOut(duration: 0.2)
                        }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.clear)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(localization.text("Note"))
            .navigationBarTitleDisplayMode(.inline)
            
            // Neue Tastatur-Accessory-Leiste
            if focusedField == .content {
                FormattingAccessoryBar(
                    accentColor: accentColor,
                    localization: localization,
                    onAction: { action in
                        apply(action: action)
                    },
                    onExportRequest: { format in
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        onExportRequest(format)
                    },
                    onDone: {
                        dismiss()
                    }
                )
                .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity))
                .animation(Animation.easeInOut(duration: 0.25), value: focusedField)
            }
        }
        .onChange(of: focusedField) { new in
            if new == .content {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }

    // MARK: - Text Manipulation Helpers

    private func apply(action: RichTextAction) {
        // Only apply inline formatting if text is selected
        if selectedRange.length == 0 {
            switch action {
            case .heading1, .heading2, .heading3, .quote, .bullet, .checkbox:
                break
            default:
                return
            }
        }
        switch action {
        case .bold:
            applyFontTrait(.traitBold)
        case .italic:
            applyFontTrait(.traitItalic)
        case .underline:
            NotificationCenter.default.post(name: .applyUnderline, object: selectedRange)
        case .strikethrough:
            NotificationCenter.default.post(name: .applyStrikethrough, object: selectedRange)
        case .heading1:
            NotificationCenter.default.post(
                name: .applyHeading,
                object: (selectedRange, 1)
            )
        case .heading2:
            NotificationCenter.default.post(
                name: .applyHeading,
                object: (selectedRange, 2)
            )
        case .heading3:
            NotificationCenter.default.post(
                name: .applyHeading,
                object: (selectedRange, 3)
            )
        case .quote:
            toggleLinePrefix(selectedRange: &selectedRange, prefix: "> ")
        case .bullet:
            toggleLinePrefix(selectedRange: &selectedRange, prefix: "- ")
        case .codeblock:
            toggleCodeBlock(selectedRange: &selectedRange)
        case .horizontalRule:
            insertHorizontalRule()
        case .checkbox:
            toggleLinePrefix(selectedRange: &selectedRange, prefix: "- [ ] ")
        }
    }

    private func applyFontTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
        guard selectedRange.length > 0 else { return }

        NotificationCenter.default.post(
            name: .applyFontTrait,
            object: (selectedRange, trait)
        )
    }
    
    
    /// Toggle prefix at the beginning of each selected line
    private func toggleLinePrefix(selectedRange: inout NSRange, prefix: String) {
        guard let textRange = Range(selectedRange, in: note.content) else { return }
        
        // Get lines that intersect with selection
        let nsContent = note.content as NSString
        let startLineRange = nsContent.lineRange(for: NSRange(location: selectedRange.location, length: 0))
        let selectionEndLocation = selectedRange.location + selectedRange.length
        let endLineRange = nsContent.lineRange(for: NSRange(location: max(selectionEndLocation - 1, 0), length: 0))
        
        let fullRange = NSRange(location: startLineRange.location, length: endLineRange.location + endLineRange.length - startLineRange.location)
        
        guard let fullTextRange = Range(fullRange, in: note.content) else { return }

        let lines = note.content[fullTextRange].split(separator: "\n", omittingEmptySubsequences: false)
        var newLines: [String] = []
        var linesChanged = false
        
        for line in lines {
            if line.hasPrefix(prefix) {
                // Remove prefix
                let newLine = String(line.dropFirst(prefix.count))
                newLines.append(newLine)
                linesChanged = true
            } else {
                // Add prefix
                let newLine = prefix + line
                newLines.append(newLine)
            }
        }
        
        if linesChanged {
            // Remove prefixes
            let replacedText = newLines.joined(separator: "\n")
            note.content.replaceSubrange(fullTextRange, with: replacedText)
            // Adjust selection range length accordingly
            selectedRange.length -= prefix.count * lines.filter { $0.hasPrefix(prefix) }.count
        } else {
            // Add prefixes
            let replacedText = newLines.joined(separator: "\n")
            note.content.replaceSubrange(fullTextRange, with: replacedText)
            selectedRange.length += prefix.count * lines.count
        }
    }
    
    /// Toggle fenced code block markdown ``` around selected text
    private func toggleCodeBlock(selectedRange: inout NSRange) {
        guard let range = Range(selectedRange, in: note.content) else { return }
        let selectedText = note.content[range]
        
        let fence = "```\n"
        let wrappedText = fence + selectedText + "\n" + fence
        
        if selectedText.hasPrefix(fence) && selectedText.hasSuffix("\n" + fence) {
            // Remove fence
            let start = selectedText.index(selectedText.startIndex, offsetBy: fence.count)
            let end = selectedText.index(selectedText.endIndex, offsetBy: -(fence.count + 1))
            let newText = selectedText[start..<end]
            note.content.replaceSubrange(range, with: newText)
            selectedRange.length -= (2 * fence.count + 1)
        } else {
            // Add fence
            note.content.replaceSubrange(range, with: wrappedText)
            selectedRange.length += (2 * fence.count + 1)
        }
    }
    
    /// Insert horizontal rule at current cursor position or selection
    private func insertHorizontalRule() {
        let hr = "\n---\n"
        if let range = Range(selectedRange, in: note.content) {
            note.content.replaceSubrange(range, with: hr)
            selectedRange.location += hr.count
            selectedRange.length = 0
        }
    }
}

// MARK: - FormattingAccessoryBar

private struct FormattingAccessoryBar: View {
    let accentColor: Color
    @ObservedObject var localization: AppLocalization

    let onAction: (RichTextAction) -> Void
    let onExportRequest: (ContentView.ExportFormat) -> Void
    let onDone: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Group {
                    Button(action: { onAction(RichTextAction.bold) }) {
                        Image(systemName: "bold")
                    }
                    .accessibilityLabel(localization.text("Bold"))

                    Button(action: { onAction(RichTextAction.italic) }) {
                        Image(systemName: "italic")
                    }
                    .accessibilityLabel(localization.text("Italic"))

                    Button(action: { onAction(RichTextAction.underline) }) {
                        Image(systemName: "underline")
                    }
                    .accessibilityLabel(localization.text("Underline"))

                    Button(action: { onAction(RichTextAction.strikethrough) }) {
                        Image(systemName: "strikethrough")
                    }
                    .accessibilityLabel(localization.text("Strikethrough"))

                    Button(action: { onAction(RichTextAction.heading1) }) {
                        Text("H1").bold()
                    }
                    .accessibilityLabel(localization.text("Heading 1"))

                    Button(action: { onAction(RichTextAction.heading2) }) {
                        Text("H2").bold()
                    }
                    .accessibilityLabel(localization.text("Heading 2"))

                    Button(action: { onAction(RichTextAction.heading3) }) {
                        Text("H3").bold()
                    }
                    .accessibilityLabel(localization.text("Heading 3"))

                    Button(action: { onAction(RichTextAction.quote) }) {
                        Image(systemName: "text.quote")
                    }
                    .accessibilityLabel(localization.text("Quote"))

                    Button(action: { onAction(RichTextAction.bullet) }) {
                        Image(systemName: "list.bullet")
                    }
                    .accessibilityLabel(localization.text("Bullet List"))

                    Button(action: { onAction(RichTextAction.checkbox) }) {
                        Image(systemName: "checkmark.square")
                    }
                    .accessibilityLabel(localization.text("Checkbox"))

                    Button(action: { onAction(RichTextAction.codeblock) }) {
                        Image(systemName: "chevron.left.slash.chevron.right")
                    }
                    .accessibilityLabel(localization.text("Code Block"))

                    Button(action: { onAction(RichTextAction.horizontalRule) }) {
                        Image(systemName: "minus")
                    }
                    .accessibilityLabel(localization.text("Horizontal Rule"))
                }

                Divider()
                    .frame(height: 24)

                Menu {
                    Button {
                        onExportRequest(.markdown)
                    } label: {
                        Label("Markdown (.md)", systemImage: "doc")
                    }
                    Button {
                        onExportRequest(.plainText)
                    } label: {
                        Label("Plain Text (.txt)", systemImage: "doc.plaintext")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel(localization.text("Export"))

                Button {
                    onDone()
                } label: {
                    Text(localization.text("Done"))
                        .font(.body.weight(.semibold))
                }
                .accessibilityLabel(localization.text("Done"))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundColor(accentColor)
            .buttonStyle(GlassPillButtonStyle(accentColor: accentColor))
        }
        .frame(height: 52)
        .background(.clear)
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
    }
}


// MARK: - Glass Capsule Button Style

private struct GlassPillButtonStyle: ButtonStyle {
    let accentColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                }
            )
            .overlay(
                Capsule(style: .continuous)
                    .fill(accentColor.opacity(configuration.isPressed ? 0.15 : 0.08))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}



// MARK: - RichTextAction Erweiterung

enum RichTextAction {
    case bold, italic, underline, strikethrough
    case heading1, heading2, heading3
    case quote, bullet, checkbox
    case codeblock
    case horizontalRule
}

// MARK: - CustomTextEditor mit Selektionserkennung

/// UIKit basierter TextView Wrapper zur Unterstützung der Selektion im SwiftUI TextEditor
struct CustomTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var selectedRange: NSRange

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.backgroundColor = UIColor.clear
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.delegate = context.coordinator
        context.coordinator.parentView = textView
        textView.autocapitalizationType = .sentences
        textView.autocorrectionType = .yes
        textView.keyboardDismissMode = .interactive
        textView.text = text
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        // Observing selection changes via delegate only, no notification for selection changes
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.textDidChangeNotification),
            name: UITextView.textDidChangeNotification,
            object: textView)
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.textDidBeginEditingNotification),
            name: UITextView.textDidBeginEditingNotification,
            object: textView)
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.handleFontTrait),
            name: .applyFontTrait,
            object: nil
        )
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.handleUnderline),
            name: .applyUnderline,
            object: nil
        )
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.handleStrikethrough),
            name: .applyStrikethrough,
            object: nil
        )
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.handleHeading),
            name: .applyHeading,
            object: nil
        )
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if uiView.selectedRange != selectedRange {
            uiView.selectedRange = selectedRange
        }
    }

    class Coordinator: NSObject, UITextViewDelegate {
        let parent: CustomTextEditor
        weak var parentView: UITextView?

        init(parent: CustomTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.selectedRange = textView.selectedRange
        }
        @objc func handleFontTrait(_ notification: Notification) {
            guard let (range, trait) = notification.object as? (NSRange, UIFontDescriptor.SymbolicTraits),
                  let textView = parentView else { return }

            textView.textStorage.beginEditing()

            textView.textStorage.enumerateAttribute(.font, in: range, options: []) { value, subRange, _ in
                let currentFont = (value as? UIFont) ?? UIFont.preferredFont(forTextStyle: .body)
                var traits = currentFont.fontDescriptor.symbolicTraits

                if traits.contains(trait) {
                    traits.remove(trait)
                } else {
                    traits.insert(trait)
                }

                if let descriptor = currentFont.fontDescriptor.withSymbolicTraits(traits) {
                    let newFont = UIFont(descriptor: descriptor, size: currentFont.pointSize)
                    textView.textStorage.addAttribute(.font, value: newFont, range: subRange)
                }
            }

            textView.textStorage.endEditing()
        }

        @objc func handleUnderline(_ notification: Notification) {
            guard let range = notification.object as? NSRange,
                  let textView = parentView else { return }

            textView.textStorage.addAttribute(
                .underlineStyle,
                value: NSUnderlineStyle.single.rawValue,
                range: range
            )
        }

        @objc func handleStrikethrough(_ notification: Notification) {
            guard let range = notification.object as? NSRange,
                  let textView = parentView else { return }

            textView.textStorage.addAttribute(
                .strikethroughStyle,
                value: NSUnderlineStyle.single.rawValue,
                range: range
            )
        }

        @objc func handleHeading(_ notification: Notification) {
            guard let (range, level) = notification.object as? (NSRange, Int),
                  let textView = parentView else { return }

            let nsText = textView.text as NSString
            let startLineRange = nsText.lineRange(for: NSRange(location: range.location, length: 0))
            let endLocation = range.location + range.length
            let endLineRange = nsText.lineRange(for: NSRange(location: max(endLocation - 1, 0), length: 0))

            let fullRange = NSRange(
                location: startLineRange.location,
                length: endLineRange.location + endLineRange.length - startLineRange.location
            )

            let baseFont = UIFont.preferredFont(forTextStyle: .body)

            let fontSize: CGFloat
            switch level {
            case 1:
                fontSize = baseFont.pointSize * 1.8
            case 2:
                fontSize = baseFont.pointSize * 1.5
            case 3:
                fontSize = baseFont.pointSize * 1.3
            default:
                fontSize = baseFont.pointSize
            }

            let descriptor = baseFont.fontDescriptor.withSymbolicTraits(.traitBold) ?? baseFont.fontDescriptor
            let headingFont = UIFont(descriptor: descriptor, size: fontSize)

            textView.textStorage.beginEditing()
            textView.textStorage.addAttribute(.font, value: headingFont, range: fullRange)
            textView.textStorage.endEditing()
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            DispatchQueue.main.async {
                self.parent.selectedRange = textView.selectedRange
            }
        }
        
        @objc func textDidChangeNotification(_ notification: Notification) {
            guard let textView = notification.object as? UITextView else { return }
            DispatchQueue.main.async {
                self.parent.text = textView.text
                self.parent.selectedRange = textView.selectedRange
            }
        }
        
        @objc func textDidBeginEditingNotification(_ notification: Notification) {
            guard let textView = notification.object as? UITextView else { return }
            DispatchQueue.main.async {
                self.parent.selectedRange = textView.selectedRange
            }
        }
    }
}

// MARK: - VisualEffectBlur for background blur

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}
// MARK: - Settings View

struct SettingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localization = AppLocalization.shared

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(localization.text("Language"))) {
                    Picker(localization.text("Language"), selection: $localization.languageRaw) {
                        ForEach(AppLanguage.allCases, id: \.self) { lang in
                            Text(lang.rawValue.capitalized).tag(lang.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(localization.text("Settings"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(localization.text("Done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}


// MARK: - Notification Extensions

extension Notification.Name {
    static let applyFontTrait = Notification.Name("applyFontTrait")
    static let applyUnderline = Notification.Name("applyUnderline")
    static let applyStrikethrough = Notification.Name("applyStrikethrough")
    static let applyHeading = Notification.Name("applyHeading")
}
