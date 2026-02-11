import SwiftUI

struct ContentView: View {
    @State private var notes: [Note] = []
    @State private var isPresentingSettings = false
    @State private var isPresentingShare = false
    @State private var shareItems: [Any] = []
    @State private var didLoad = false
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool

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

    // Gallery UI helpers
    @Namespace private var galleryNamespace
    @State private var openingNoteID: UUID? = nil
    @State private var peekNoteID: UUID? = nil
    @State private var showEditorOverlay: Bool = false

    private var accentColor: Color { colorForKey(accentColorKey) }

    private var isFiltering: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var filteredNotes: [Note] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return notes }
        return notes.filter { note in
            note.title.lowercased().contains(needle) ||
            note.content.lowercased().contains(needle)
        }
    }

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

                if peekNoteID != nil {
                    Color.black.opacity(0.03)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }

                if let openID = openingNoteID,
                   let note = notes.first(where: { $0.id == openID }),
                   showEditorOverlay {
                    NoteEditor(
                        note: Binding(get: { note }, set: { updated in
                            if let idx = notes.firstIndex(where: { $0.id == openID }) {
                                notes[idx] = updated
                            }
                        }),
                        onExportRequest: { format in
                            share(note: note, as: format)
                        },
                        accentColor: accentColor
                    )
                    .background(Color.black.opacity(0.05).ignoresSafeArea())
                    .transition(.identity)
                }

                if editMode?.wrappedValue != .active {
                    floatingAddButton
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.2), value: editMode?.wrappedValue)
            .animation(.easeInOut(duration: 0.25), value: homeLayoutRaw)
            .settingsSheet(isPresented: $isPresentingSettings)
            .shareSheet(isPresented: $isPresentingShare, items: shareItems)
            .tint(accentColor)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search notes")
            .searchFocused($isSearchFocused)
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
                    .keyboardShortcut(",", modifiers: .command)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: createNewNote) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New Note")
                    .keyboardShortcut("n", modifiers: [.command])
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isSearchFocused = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .accessibilityLabel("Search")
                    .keyboardShortcut("f", modifiers: [.command])
                }
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
                            .animation(.easeInOut(duration: 0.2), value: selection)
                    }
                }
            }
        }
    }

    private var notesList: some View {
        List(selection: $selection) {
            if filteredNotes.isEmpty {
                AnyView({
                    if isFiltering {
                        return AnyView(EmptySearchStateView(accentColor: accentColor))
                    } else {
                        return AnyView(EmptyStateView(accentColor: accentColor))
                    }
                }())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                Section {
                    ForEach(filteredNotes) { note in
                        NavigationLink(value: note) {
                            NoteCard(note: note, accentColor: accentColor)
                        }
                        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
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
                    .onDelete(perform: deleteFiltered(at:))
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.9), value: notes)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .refreshable {
            loadNotes()
        }
        .onChange(of: editMode?.wrappedValue) { newMode in
            if newMode != .active {
                selection.removeAll()
            }
        }
    }

    private var notesGallery: some View {
        ScrollView {
            if filteredNotes.isEmpty {
                AnyView({
                    if isFiltering {
                        return AnyView(EmptySearchStateView(accentColor: accentColor))
                    } else {
                        return AnyView(EmptyStateView(accentColor: accentColor))
                    }
                }())
                .padding(.horizontal, 16)
            } else {
                let columns = [GridItem(.adaptive(minimum: 160), spacing: 12)]
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filteredNotes) { note in
                        ZStack {
                            GalleryCard(
                                note: note,
                                selected: selection.contains(note.id),
                                accentColor: accentColor,
                                isEditing: editMode?.wrappedValue == .active
                            )
                            .transition(.scale.combined(with: .opacity))
                            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selection)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.clear)
                                    .matchedGeometryEffect(id: "card-bg-\(note.id)", in: galleryNamespace)
                                    .allowsHitTesting(false)
                            )
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) {
                                if editMode?.wrappedValue == .active {
                                    toggleSelection(for: note.id)
                                } else {
                                    openingNoteID = note.id
                                    showEditorOverlay = true
                                    path.append(note)
                                }
                            }
                        }
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.25)
                                .onChanged { _ in
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { peekNoteID = note.id }
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { peekNoteID = nil }
                                }
                        )
                        .overlay(
                            Group {
                                if peekNoteID == note.id {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(accentColor.opacity(0.6), lineWidth: 2)
                                        .shadow(color: accentColor.opacity(0.25), radius: 10)
                                        .scaleEffect(1.02)
                                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: peekNoteID)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .animation(.spring(response: 0.35, dampingFraction: 0.88), value: notes)
            }
        }
        .refreshable {
            loadNotes()
        }
        .background(Color.clear)
        .onChange(of: editMode?.wrappedValue) { newMode in
            if newMode != .active {
                selection.removeAll()
            }
            withAnimation {
                peekNoteID = nil
            }
        }
    }

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

    @ViewBuilder
    private func noteDestination(for note: Note) -> some View {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            NoteEditor(
                note: $notes[idx],
                onExportRequest: { format in
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    share(note: notes[idx], as: format)
                },
                accentColor: accentColor
            )
            .onDisappear {
                scheduleSave()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                    showEditorOverlay = false
                    openingNoteID = nil
                }
            }
        } else {
            Text("Note not found")
                .foregroundStyle(.secondary)
        }
    }

    private func toggleSelection(for id: UUID) {
        if selection.contains(id) {
            selection.remove(id)
        } else {
            selection.insert(id)
        }
    }

    private func createNewNote() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            let newNote = Note(title: "New note", content: "")
            notes.insert(newNote, at: 0)
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            path.append(newNote)
        }
    }

    private func delete(note: Note) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            withAnimation {
                notes.remove(at: idx)
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func deleteFiltered(at offsets: IndexSet) {
        let ids = offsets.compactMap { idx in
            filteredNotes[safe: idx]?.id
        }
        guard !ids.isEmpty else { return }
        withAnimation {
            notes.removeAll { ids.contains($0.id) }
            selection.subtract(ids)
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
