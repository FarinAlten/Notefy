//  ContentView.swift
//  Notefy
//
//  Created by Farin Altenhöner on 05.08.25.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Accent Color Management

fileprivate struct AccentChoice: Identifiable, Hashable {
    let id = UUID()
    let key: String
    let name: String
    let color: Color
}

fileprivate let predefinedAccentChoices: [AccentChoice] = [
    .init(key: "indigo", name: "Indigo", color: .indigo),
    .init(key: "blue", name: "Blue", color: .blue),
    .init(key: "teal", name: "Teal", color: .teal),
    .init(key: "mint", name: "Mint", color: .mint),
    .init(key: "green", name: "Green", color: .green),
    .init(key: "yellow", name: "Yellow", color: .yellow),
    .init(key: "orange", name: "Orange", color: .orange),
    .init(key: "red", name: "Red", color: .red),
    .init(key: "pink", name: "Pink", color: .pink),
    .init(key: "purple", name: "Purple", color: .purple),
    .init(key: "gray", name: "Gray", color: .gray)
]

// Persist the selected key; default to "indigo"
fileprivate func colorForKey(_ key: String) -> Color {
    predefinedAccentChoices.first(where: { $0.key == key })?.color ?? .indigo
}

fileprivate func nameForKey(_ key: String) -> String {
    predefinedAccentChoices.first(where: { $0.key == key })?.name ?? "Indigo"
}

// MARK: - Home Layout Preference

enum HomeLayout: String, CaseIterable, Codable, Identifiable {
    case list
    case gallery

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .list: return "Liste"
        case .gallery: return "Galerie"
        }
    }

    var systemImage: String {
        switch self {
        case .list: return "list.bullet"
        case .gallery: return "square.grid.2x2"
        }
    }
}

struct ContentView: View {
    @State private var notes: [Note] = []
    @State private var isPresentingSettings = false
    @State private var isPresentingShare = false
    @State private var shareItems: [Any] = []
    @State private var didLoad = false

    // Debounced save task
    @State private var pendingSaveTask: Task<Void, Never>? = nil

    // Navigation using value-based routing
    @State private var path: NavigationPath = NavigationPath()

    // Accent color preference
    @AppStorage("accentColorKey") private var accentColorKey: String = "indigo"

    // Home layout preference
    @AppStorage("homeLayout") private var homeLayoutRaw: String = HomeLayout.list.rawValue
    private var homeLayout: HomeLayout {
        get { HomeLayout(rawValue: homeLayoutRaw) ?? .list }
        set { homeLayoutRaw = newValue.rawValue }
    }

    // Selection for edit mode (multi-select)
    @State private var selection: Set<UUID> = []

    // Edit mode environment
    @Environment(\.editMode) private var editMode

    var accentColor: Color { colorForKey(accentColorKey) }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                Group {
                    switch homeLayout {
                    case .list:
                        notesList
                    case .gallery:
                        notesGallery
                    }
                }

                // FAB nur anzeigen, wenn nicht im Editiermodus
                if editMode?.wrappedValue != .active {
                    floatingAddButton
                }
            }
            .settingsSheet(isPresented: $isPresentingSettings)
            .shareSheet(isPresented: $isPresentingShare, items: shareItems)
            .navigationDestination(for: Note.self) { note in
                noteDestination(for: note)
            }
            .onChange(of: notes) { _ in
                scheduleSave()
            }
            .onAppear {
                if !didLoad {
                    loadNotes()
                    didLoad = true
                }
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        openSettings()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
                // Lösch-Button nur im Editiermodus anzeigen
                ToolbarItemGroup(placement: .bottomBar) {
                    if editMode?.wrappedValue == .active {
                        Button(role: .destructive) {
                            deleteSelected()
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                        .disabled(selection.isEmpty)

                        Spacer()
                        Text("\(selection.count) ausgewählt")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    // MARK: - List Layout

    private var notesList: some View {
        List(selection: $selection) {
            if notes.isEmpty {
                emptyState
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                Section {
                    ForEach(notes) { note in
                        NavigationLink(value: note) {
                            NoteCard(note: note)
                        }
                        .contextMenu {
                            Button {
                                share(note: note, as: .markdown)
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            Button(role: .destructive) {
                                delete(note: note)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                delete(note: note)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                share(note: note, as: .markdown)
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .tint(accentColor)
                        }
                    }
                    .onDelete(perform: delete(at:))
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            loadNotes()
        }
        .onChange(of: editMode?.wrappedValue) { newMode in
            if newMode != .active {
                selection.removeAll()
            }
        }
    }

    // MARK: - Gallery Layout

    private var notesGallery: some View {
        ScrollView {
            if notes.isEmpty {
                emptyState
                    .padding(.horizontal, 16)
            } else {
                let columns = [GridItem(.adaptive(minimum: 160), spacing: 12)]
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(notes) { note in
                        GalleryCard(
                            note: note,
                            selected: selection.contains(note.id),
                            accentColor: accentColor,
                            isEditing: editMode?.wrappedValue == .active
                        )
                        .onTapGesture {
                            if editMode?.wrappedValue == .active {
                                toggleSelection(for: note.id)
                            } else {
                                path.append(note)
                            }
                        }
                        .contextMenu {
                            Button {
                                share(note: note, as: .markdown)
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            Button(role: .destructive) {
                                delete(note: note)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .refreshable {
            loadNotes()
        }
        .onChange(of: editMode?.wrappedValue) { newMode in
            if newMode != .active {
                selection.removeAll()
            }
        }
    }

    private func toggleSelection(for id: UUID) {
        if selection.contains(id) {
            selection.remove(id)
        } else {
            selection.insert(id)
        }
    }

    // Split FAB out of body
    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: createNewNote) {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(20)
                        .background(
                            Circle()
                                .fill(accentColor)
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 6)
                        )
                }
                .accessibilityLabel("New Note")
                .padding(.trailing, 20)
                .padding(.bottom, 24)
            }
        }
    }

    // Destination builder extracted
    @ViewBuilder
    private func noteDestination(for note: Note) -> some View {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            NoteEditor(
                note: $notes[idx],
                onExportRequest: { format in
                    share(note: notes[idx], as: format)
                }, accentColor: accentColor
            )
            .onDisappear {
                scheduleSave()
            }
        } else {
            Text("Note not found")
                .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("No notes yet")
                .font(.headline)
            Text("Tap the plus to create your first note.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 40)
    }

    // MARK: - Actions

    private func createNewNote() {
        let newNote = Note(title: "New note", content: "")
        notes.insert(newNote, at: 0)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        path.append(newNote)
    }

    private func delete(note: Note) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            withAnimation {
                notes.remove(at: idx)
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func delete(at offsets: IndexSet) {
        withAnimation {
            notes.remove(atOffsets: offsets)
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func deleteSelected() {
        guard !selection.isEmpty else { return }
        withAnimation {
            notes.removeAll { selection.contains($0.id) }
            selection.removeAll()
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - Export

    enum ExportFormat {
        case markdown
        case plainText

        var fileExtension: String { self == .markdown ? "md" : "txt" }
    }

    private func share(note: Note, as format: ExportFormat) {
        let content: String
        switch format {
        case .markdown:
            let titleLine = note.title.isEmpty ? "" : "# \(note.title)\n\n"
            content = titleLine + note.content
        case .plainText:
            let titleLine = note.title.isEmpty ? "" : "\(note.title)\n\n"
            content = titleLine + note.content
        }

        let tempDir = FileManager.default.temporaryDirectory
        let sanitizedTitle = note.title.isEmpty ? "Note" : note.title.replacingOccurrences(of: "/", with: "-")
        let fileURL = tempDir.appendingPathComponent("\(sanitizedTitle).\(format.fileExtension)")

        do {
            try content.data(using: .utf8)?.write(to: fileURL, options: .atomic)
            shareItems = [fileURL]
            isPresentingShare = true
        } catch {
            shareItems = [content]
            isPresentingShare = true
        }
    }

    private func openSettings() {
        isPresentingSettings = true
    }

    // MARK: - Persistence (async, debounced)

    private func scheduleSave() {
        pendingSaveTask?.cancel()
        pendingSaveTask = Task { [notes] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            await NoteStore.shared.save(notes)
        }
    }

    private func loadNotes() {
        Task {
            let loaded = await NoteStore.shared.load()
            await MainActor.run {
                self.notes = loaded
            }
        }
    }
}

// MARK: - Note Card Cell (List)

struct NoteCard: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
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
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Gallery Card

fileprivate struct GalleryCard: View {
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
                    .stroke(selected ? accentColor : Color.clear, lineWidth: 2)
            )

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
            }
        }
    }
}

// MARK: - Editor

struct NoteEditor: View {
    @Binding var note: Note

    @State private var pendingAction: RichTextAction? = nil

    @State private var showExportChoice = false
    var onExportRequest: (ContentView.ExportFormat) -> Void

    var accentColor: Color

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField("Title", text: $note.title)
                        .font(.title3.weight(.semibold))
                        .textInputAutocapitalization(.sentences)
                        .disableAutocorrection(false)
                }
                Section {
                    RichTextView(text: $note.content, action: $pendingAction)
                        .frame(minHeight: 240, maxHeight: .infinity, alignment: .topLeading)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.secondary.opacity(0.15))
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                } header: {
                    Text("Content")
                }
            }
            .scrollDismissesKeyboard(.interactively)

            HStack(alignment: .center, spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    FormattingToolbar { action in
                        pendingAction = action
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

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
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(accentColor)

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Note")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - UIKit Share Sheet Wrapper

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Rich Text (plain text with Markdown markers)

enum RichTextAction {
    case bold
    case italic
    case strikethrough
    case bullet
    case quote
    case heading1
}

struct RichTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var action: RichTextAction?

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = UIColor.secondarySystemGroupedBackground
        textView.layer.cornerRadius = 12
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        textView.delegate = context.coordinator
        textView.allowsEditingTextAttributes = false
        textView.tintColor = .label
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }

        if let pending = action {
            context.coordinator.apply(action: pending, to: uiView)
            DispatchQueue.main.async {
                self.action = nil
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String

        private let bullet = "•"
        private let bulletWithSpace = "• "
        private let dash = "-"
        private let dashWithSpace = "- "
        private let newline = "\n"

        init(text: Binding<String>) {
            _text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
        }

        private func clampRange(_ range: NSRange, length: Int) -> NSRange {
            let loc = max(0, min(range.location, length))
            let len = max(0, min(range.length, length - loc))
            return NSRange(location: loc, length: len)
        }

        private func safeSubstring(_ s: NSString, range: NSRange) -> String {
            let r = clampRange(range, length: s.length)
            if r.length == 0 { return "" }
            return s.substring(with: r)
        }

        func apply(action: RichTextAction, to textView: UITextView) {
            let ns = (textView.text ?? "") as NSString
            let sel = textView.selectedRange
            let fullLen = ns.length
            let safeSel = clampRange(sel, length: fullLen)

            func selectionOrWord() -> NSRange {
                if safeSel.length > 0 { return safeSel }
                let delimiters = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
                var start = safeSel.location
                var end = safeSel.location

                while start > 0 {
                    let ch = ns.character(at: start - 1)
                    if let scalar = UnicodeScalar(ch), delimiters.contains(scalar) { break }
                    start -= 1
                }
                while end < fullLen {
                    let ch = ns.character(at: end)
                    if let scalar = UnicodeScalar(ch), delimiters.contains(scalar) { break }
                    end += 1
                }
                return NSRange(location: start, length: max(0, end - start))
            }

            func toggleInline(prefix: String, suffix: String) {
                var range = selectionOrWord()
                let selected = safeSubstring(ns, range: range) as NSString
                let beforeRange = NSRange(location: max(0, range.location - prefix.count), length: min(prefix.count, range.location))
                let afterRange = NSRange(location: min(fullLen, range.location + range.length), length: min(suffix.count, fullLen - (range.location + range.length)))

                let hasPrefix = safeSubstring(ns, range: beforeRange) == prefix
                let hasSuffix = safeSubstring(ns, range: afterRange) == suffix

                var newText = ns as String
                var newCursorLocation = range.location

                if hasPrefix && hasSuffix {
                    let nsNew = NSMutableString(string: newText)
                    nsNew.replaceCharacters(in: afterRange, with: "")
                    nsNew.replaceCharacters(in: beforeRange, with: "")
                    newText = nsNew as String
                    newCursorLocation = range.location - prefix.count
                } else {
                    let nsNew = NSMutableString(string: newText)
                    nsNew.insert(suffix, at: range.location + range.length)
                    nsNew.insert(prefix, at: range.location)
                    newText = nsNew as String
                    newCursorLocation = range.location + prefix.count
                }

                textView.text = newText
                text = newText
                textView.becomeFirstResponder()
                textView.selectedRange = NSRange(location: newCursorLocation, length: selected.length)
            }

            func toggleLinePrefix(_ marker: String) {
                let start = safeSel.location
                let end = safeSel.location + safeSel.length
                var cursor = start
                let mutable = NSMutableString(string: ns as String)

                var pos = start
                var delta = 0

                while pos <= end {
                    let lineRange = (mutable as NSString).lineRange(for: NSRange(location: pos, length: 0))
                    let line = (mutable as NSString).substring(with: lineRange)
                    let trimmed = line.trimmingCharacters(in: .newlines)

                    let hasMarker = trimmed.hasPrefix(marker)
                    let prefixLen = (line as NSString).range(of: trimmed).location

                    let markerRange = NSRange(location: lineRange.location + prefixLen, length: min(marker.count, max(0, lineRange.length - prefixLen)))
                    if hasMarker {
                        mutable.replaceCharacters(in: markerRange, with: "")
                        delta -= marker.count
                        if cursor >= markerRange.location { cursor = max(lineRange.location, cursor - marker.count) }
                    } else {
                        mutable.insert(marker, at: lineRange.location + prefixLen)
                        delta += marker.count
                        if cursor >= lineRange.location + prefixLen { cursor += marker.count }
                    }

                    pos = lineRange.location + lineRange.length + (hasMarker ? -marker.count : marker.count)
                }

                let newText = mutable as String
                textView.text = newText
                text = newText
                textView.becomeFirstResponder()
                textView.selectedRange = NSRange(location: cursor, length: safeSel.length + delta)
            }

            switch action {
            case .bold:
                toggleInline(prefix: "**", suffix: "**")
            case .italic:
                toggleInline(prefix: "_", suffix: "_")
            case .strikethrough:
                toggleInline(prefix: "~~", suffix: "~~")
            case .bullet:
                toggleLinePrefix("- ")
            case .quote:
                toggleLinePrefix("> ")
            case .heading1:
                toggleLinePrefix("# ")
            }
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText replacement: String) -> Bool {
            let nsText = (textView.text ?? "") as NSString
            let fullLen = nsText.length
            let safeRange = clampRange(range, length: fullLen)

            func apply(replacing r: NSRange, with str: String, cursor: Int) {
                let clampedR = clampRange(r, length: (textView.text as NSString?)?.length ?? 0)
                let newText = ((textView.text ?? "") as NSString).replacingCharacters(in: clampedR, with: str)
                textView.text = newText
                let newLen = (newText as NSString).length
                let newCursor = max(0, min(cursor, newLen))
                textView.selectedRange = NSRange(location: newCursor, length: 0)
                text = newText
            }

            let lineRange = nsText.lineRange(for: NSRange(location: safeRange.location, length: 0))
            let lineText = safeSubstring(nsText, range: lineRange)
            let lineTextNoNewline = lineText.trimmingCharacters(in: .newlines)

            let prefixLen = max(0, safeRange.location - lineRange.location)
            let prefixRange = NSRange(location: lineRange.location, length: prefixLen)
            let prefix = safeSubstring(nsText, range: prefixRange)

            let bullet = "•"
            let bulletWithSpace = "• "
            let dash = "-"
            let dashWithSpace = "- "
            let newline = "\n"

            if replacement == " " {
                if prefix == dash {
                    let replaceRange = NSRange(location: lineRange.location, length: prefixLen + 1)
                    let newCursor = lineRange.location + (bulletWithSpace as NSString).length
                    apply(replacing: replaceRange, with: bulletWithSpace, cursor: newCursor)
                    return false
                }
                if prefix == dashWithSpace {
                    let replaceRange = NSRange(location: lineRange.location, length: (dashWithSpace as NSString).length)
                    apply(replacing: replaceRange, with: bulletWithSpace, cursor: safeRange.location)
                    return false
                }
            }

            if replacement == newline {
                if lineTextNoNewline.hasPrefix(bulletWithSpace) || lineTextNoNewline == bullet {
                    let afterBullet = String(lineTextNoNewline.dropFirst((bulletWithSpace as NSString).length))
                    let isEmptyBulletLine = afterBullet.trimmingCharacters(in: .whitespaces).isEmpty

                    if isEmptyBulletLine {
                        let bulletPrefixRange = NSRange(location: lineRange.location, length: min((bulletWithSpace as NSString).length, lineRange.length))
                        let withoutBullet = nsText.replacingCharacters(in: bulletPrefixRange, with: "") as NSString
                        let adjustedCaret = max(0, safeRange.location - (bulletWithSpace as NSString).length)
                        let newText = withoutBullet.replacingCharacters(in: NSRange(location: adjustedCaret, length: 0), with: newline)
                        let cursor = adjustedCaret + 1
                        textView.text = newText
                        textView.selectedRange = NSRange(location: cursor, length: 0)
                        text = newText
                        return false
                    } else {
                        let insertion = newline + bulletWithSpace
                        let cursor = safeRange.location + (insertion as NSString).length
                        apply(replacing: safeRange, with: insertion, cursor: cursor)
                        return false
                    }
                }

                if lineTextNoNewline.hasPrefix(dashWithSpace) || prefix == dashWithSpace {
                    let convertRange = NSRange(location: lineRange.location, length: (dashWithSpace as NSString).length)
                    var interim = nsText.replacingCharacters(in: convertRange, with: bulletWithSpace) as NSString
                    let caretShift = (bulletWithSpace as NSString).length - (dashWithSpace as NSString).length
                    let adjustedCaret = safeRange.location + max(0, caretShift)
                    interim = interim.replacingCharacters(in: NSRange(location: adjustedCaret, length: 0), with: newline + bulletWithSpace) as NSString
                    let cursor = adjustedCaret + 1 + (bulletWithSpace as NSString).length
                    textView.text = interim as String
                    textView.selectedRange = NSRange(location: cursor, length: 0)
                    text = interim as String
                    return false
                }
            }

            if replacement.isEmpty && range.length == 1 {
                if lineTextNoNewline.hasPrefix(bulletWithSpace) {
                    let bulletStart = lineRange.location
                    let bulletEnd = bulletStart + (bulletWithSpace as NSString).length
                    if safeRange.location == bulletEnd {
                        let bulletPrefixRange = NSRange(location: bulletStart, length: (bulletWithSpace as NSString).length)
                        apply(replacing: bulletPrefixRange, with: "", cursor: bulletStart)
                        return false
                    }
                }
            }

            return true
        }
    }
}

// MARK: - Formatting Toolbar

struct FormattingToolbar: View {
    var onAction: (RichTextAction) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button {
                onAction(.bold)
            } label: {
                Image(systemName: "bold")
            }
            .buttonStyle(.bordered)

            Button {
                onAction(.italic)
            } label: {
                Image(systemName: "italic")
            }
            .buttonStyle(.bordered)

            Button {
                onAction(.strikethrough)
            } label: {
                Image(systemName: "strikethrough")
            }
            .buttonStyle(.bordered)

            Button {
                onAction(.bullet)
            } label: {
                Image(systemName: "list.bullet")
            }
            .buttonStyle(.bordered)

            Button {
                onAction(.quote)
            } label: {
                Image(systemName: "text.quote")
            }
            .buttonStyle(.bordered)

            Button {
                onAction(.heading1)
            } label: {
                Image(systemName: "textformat.size.larger")
            }
            .buttonStyle(.bordered)
        }
        .labelStyle(.iconOnly)
    }
}

// MARK: - Settings

struct SettingsView: View {
    @AppStorage("accentColorKey") private var accentColorKey: String = "indigo"
    @AppStorage("homeLayout") private var homeLayoutRaw: String = HomeLayout.list.rawValue

    var selectedLayout: HomeLayout {
        get { HomeLayout(rawValue: homeLayoutRaw) ?? .list }
        set { homeLayoutRaw = newValue.rawValue }
    }

    var body: some View {
        Form {
            Section(header: Text("General")) {
                HStack {
                    Image(systemName: "app.badge.fill")
                        .foregroundStyle(.indigo)
                    VStack(alignment: .leading) {
                        Text("Notefy")
                        Text("Version 0.1")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            
                    }
                    .tint(.accentColor)
                }
                HStack {
                    Image(systemName: "person.crop.circle")
                        .tint(.accentColor)
                    Text("Created by Farin")
                }
                .tint(.accentColor)
            }
            Section("Personalization") {
                NavigationLink {
                    AccentColorPickerView(selectedKey: $accentColorKey)
                } label: {
                    HStack {
                        Label("Accent Color", systemImage: "paintpalette")
                        Spacer()
                        Circle()
                            .fill(colorForKey(accentColorKey))
                            .frame(width: 20, height: 20)
                        Text(nameForKey(accentColorKey))
                            .foregroundStyle(.secondary)
                    }
                }

                Picker("HomeView", selection: $homeLayoutRaw) {
                    ForEach(HomeLayout.allCases) { layout in
                        Label(layout.localizedName, systemImage: layout.systemImage)
                            .tag(layout.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 4)
            }
            Section("What’s New") {
                NavigationLink {
                    WhatsNewView()
                } label: {
                    Label("What’s New", systemImage: "sparkles")
                }
            }
            Section("About me") {
                Link(destination: URL(string: "https://farinalten.com")!) {
                    Label("Website", systemImage: "globe")
                }
                Link(destination: URL(string: "https://farinalten.com/websites/legal")!) {
                    Label("Support", systemImage: "envelope")
                }
            }
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Accent Color Picker (Swipeable Preview)

struct AccentColorPickerView: View {
    @Binding var selectedKey: String
    @State private var currentIndex: Int = 0

    var body: some View {
        VStack(spacing: 16) {
            TabView(selection: $currentIndex) {
                ForEach(Array(predefinedAccentChoices.enumerated()), id: \.offset) { index, choice in
                    AccentPreviewPage(accent: choice)
                        .tag(index)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .interactive))

            let currentChoice = predefinedAccentChoices[safe: currentIndex] ?? predefinedAccentChoices.first!

            HStack(spacing: 12) {
                Circle()
                    .fill(currentChoice.color)
                    .frame(width: 22, height: 22)
                Text(currentChoice.name)
                    .font(.headline)
                Spacer()
                Button {
                    selectedKey = currentChoice.key
                } label: {
                    Text("Use Color")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(currentChoice.color)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .navigationTitle("Accent Color")
        .onAppear {
            if let idx = predefinedAccentChoices.firstIndex(where: { $0.key == selectedKey }) {
                currentIndex = idx
            }
        }
    }
}

fileprivate struct AccentPreviewPage: View {
    let accent: AccentChoice

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)

            VStack {
                HStack {
                    Text("Notes")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "gearshape")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                VStack(spacing: 10) {
                    PreviewCard()
                    PreviewCard()
                    PreviewCard()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                HStack {
                    Spacer()
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(16)
                        .background(
                            Circle()
                                .fill(accent.color)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 5)
                        )
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                }
            }
            .padding(.vertical, 8)
        }
        .frame(height: 340)
    }
}

fileprivate struct PreviewCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
            .frame(height: 58)
            .overlay(
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.secondary.opacity(0.35)).frame(width: 120, height: 10)
                    RoundedRectangle(cornerRadius: 3).fill(Color.secondary.opacity(0.25)).frame(width: 200, height: 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
            )
    }
}

// MARK: - Whats New

fileprivate struct WhatsNewEntry: Identifiable, Hashable {
    let id = UUID()
    let version: String
    let title: String
    let highlights: [String]
    let accentKey: String
    let date: Date?
}

fileprivate let whatsNewEntries: [WhatsNewEntry] = [
    WhatsNewEntry(
        version: "1.0",
        title: "Initial Release",
        highlights: [
            "Create and edit notes",
            "Markdown-style formatting toolbar",
            "Quick share as Markdown or Plain Text",
            "Accent color customization"
        ],
        accentKey: "indigo",
        date: Date(timeIntervalSince1970: 1_726_000_000)
    ),
    WhatsNewEntry(
        version: "1.1",
        title: "Formatting Improvements",
        highlights: [
            "Bulleted list auto-continue and smart backspace",
            "Quote and Heading toggles",
            "Refined editor styling"
        ],
        accentKey: "teal",
        date: Date(timeIntervalSince1970: 1_728_000_000)
    ),
    WhatsNewEntry(
        version: "1.2",
        title: "Sharing & Settings",
        highlights: [
            "Share via system sheet",
            "New Settings screen",
            "Accent color preview revamp"
        ],
        accentKey: "pink",
        date: Date(timeIntervalSince1970: 1_730_000_000)
    )
]

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

fileprivate struct WhatsNewPage: View {
    let entry: WhatsNewEntry

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)

            VStack(spacing: 12) {
                HStack {
                    Label("Version \(entry.version)", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    if let date = entry.date {
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                if !entry.title.isEmpty {
                    Text(entry.title)
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                }

                VStack(spacing: 10) {
                    ForEach(entry.highlights, id: \.self) { line in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(colorForKey(entry.accentKey))
                                .frame(width: 8, height: 8)
                                .padding(.top, 6)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(line)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.secondary.opacity(0.18))
                                    .frame(height: 6)
                                    .opacity(0.7)
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                }
                .padding(.top, 6)

                Spacer()

                HStack {
                    Spacer()
                    Image(systemName: "star.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(16)
                        .background(
                            Circle()
                                .fill(colorForKey(entry.accentKey))
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 5)
                        )
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 8)
        }
        .frame(height: 340)
    }
}

// MARK: - Safe Index helper

fileprivate extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

// MARK: - Sheet helpers to reduce builder size in body

fileprivate struct SettingsSheetModifier: ViewModifier {
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                NavigationStack {
                    SettingsView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    isPresented = false
                                }
                            }
                        }
                }
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(16)
            }
    }
}

fileprivate struct ShareSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let items: [Any]

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                ActivityView(activityItems: items)
                    .ignoresSafeArea()
            }
    }
}

fileprivate extension View {
    func settingsSheet(isPresented: Binding<Bool>) -> some View {
        modifier(SettingsSheetModifier(isPresented: isPresented))
    }

    func shareSheet(isPresented: Binding<Bool>, items: [Any]) -> some View {
        modifier(ShareSheetModifier(isPresented: isPresented, items: items))
    }
}

@main
struct NotefyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
