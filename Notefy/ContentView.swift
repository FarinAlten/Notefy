import SwiftUI

struct Folder: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
}

struct ContentView: View {
    @State private var notes: [Note] = []
    @State private var folders: [Folder] = [
        Folder(name: "All Notes"),
        Folder(name: "Personal"),
        Folder(name: "Work")
    ]

    // nil = All Notes
    @State private var selectedFolderID: UUID? = nil
    @State private var folderToRename: Folder? = nil
    @State private var folderRenameText: String = ""
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
        let needle = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        var base = notes

        if let selectedFolderID {
            base = notes.filter { $0.folderID == selectedFolderID }
        }

        guard !needle.isEmpty else { return base }

        return base.filter { note in
            note.title.lowercased().contains(needle) ||
            note.content.lowercased().contains(needle)
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            NavigationStack(path: $path) {
                mainContent
                    .navigationDestination(for: Note.self) { note in
                        noteDestination(for: note)
                    }
            }
        }
        .onAppear {
            if !didLoad {
                didLoad = true
                loadAll()
            }
        }
        .onChange(of: notes) { _ in
            scheduleSave()
        }
    }

    // MARK: - Platform Adaptive Containers

    @ViewBuilder
    private var sidebar: some View {
        List(selection: $selectedFolderID) {
            Section("Folders") {
                ForEach(folders) { folder in
                    HStack {
                        Image(systemName: folder.name == "All Notes" ? "tray.full" : "folder")
                        Text(folder.name)
                    }
                    .tag(folder.name == "All Notes" ? nil as UUID? : folder.id)
                    .contextMenu {
                        if folder.name != "All Notes" {
                            Button("Rename") {
                                folderToRename = folder
                                folderRenameText = folder.name
                            }
                            Button("Delete", role: .destructive) {
                                delete(folder: folder)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Notefy")
        .onChange(of: selectedFolderID) { _ in
            path = NavigationPath()
        }
        .alert("Rename Folder", isPresented: Binding(
            get: { folderToRename != nil },
            set: { if !$0 { folderToRename = nil } }
        )) {
            TextField("Folder name", text: $folderRenameText)
            Button("Cancel", role: .cancel) {
                folderToRename = nil
            }
            Button("Save") {
                if let folder = folderToRename,
                   let index = folders.firstIndex(where: { $0.id == folder.id }) {
                    folders[index].name = folderRenameText
                }
                folderToRename = nil
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
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

            #if os(iOS)
            if editMode?.wrappedValue != .active {
                floatingAddButton
                    .transition(.scale.combined(with: .opacity))
            }
            #endif
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: editMode?.wrappedValue)
        .animation(.easeInOut(duration: 0.25), value: homeLayoutRaw)
        .sheet(isPresented: $isPresentingSettings) {
            SettingsView()
        }
        .shareSheet(isPresented: $isPresentingShare, items: shareItems)
        .tint(accentColor)
        .searchable(text: $searchText, prompt: "Search notes")
        .navigationTitle("Notes")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    openSettings()
                } label: {
                    Image(systemName: "gearshape")
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
                            Menu("Move to Folder") {
                                ForEach(folders.filter { $0.name != "All Notes" }) { folder in
                                    Button(folder.name) {
                                        move(note: note, to: folder.id)
                                    }
                                }
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
            loadAll()
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
            loadAll()
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
                .contextMenu {
                    Button {
                        createNewNote()
                    } label: {
                        Label("New Note", systemImage: "note.text")
                    }

                    Button {
                        createNewFolder()
                    } label: {
                        Label("New Folder", systemImage: "folder")
                    }
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
            let newNote = Note(
                title: "New note",
                content: "",
                folderID: selectedFolderID
            )
            notes.insert(newNote, at: 0)
            scheduleSave()
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    private func createNewFolder() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            let newFolder = Folder(name: "New Folder")
            folders.append(newFolder)
            selectedFolderID = newFolder.id
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    private func delete(folder: Folder) {
        guard folder.name != "All Notes" else { return }
        withAnimation {
            folders.removeAll { $0.id == folder.id }
            notes = notes.map { note in
                var updated = note
                if updated.folderID == folder.id {
                    updated.folderID = nil
                }
                return updated
            }
            if selectedFolderID == folder.id {
                selectedFolderID = nil
            }
        }
    }

    private func delete(note: Note) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            withAnimation {
                notes.remove(at: idx)
                scheduleSave()
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func move(note: Note, to folderID: UUID) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].folderID = folderID
            scheduleSave()
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    private func deleteFiltered(at offsets: IndexSet) {
        let ids = offsets.compactMap { idx in
            filteredNotes[safe: idx]?.id
        }
        guard !ids.isEmpty else { return }
        withAnimation {
            notes.removeAll { ids.contains($0.id) }
            scheduleSave()
            selection.subtract(ids)
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func deleteSelected() {
        guard !selection.isEmpty else { return }
        withAnimation {
            notes.removeAll { selection.contains($0.id) }
            scheduleSave()
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

    private func toggleSidebar() {
        #if os(iOS)
        UIApplication.shared.sendAction(
            #selector(UISplitViewController.toggleSidebar),
            to: nil,
            from: nil,
            for: nil
        )
        #endif
    }

    private func scheduleSave() {
        pendingSaveTask?.cancel()
        let currentNotes = notes
        let currentFolders = folders
        pendingSaveTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            await NoteStore.shared.save(notes: currentNotes, folders: currentFolders)
        }
    }

    private func loadAll() {
        Task {
            let loaded = await NoteStore.shared.load()
            await MainActor.run {
                self.notes = loaded.notes
                self.folders = loaded.folders
            }
        }
    }
}
