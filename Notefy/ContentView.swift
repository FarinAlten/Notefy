//  ContentView.swift
//  Notefy
//
//  Created by Farin Altenhöner on 05.08.25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var notes: [Note] = []
    @State private var isPresentingSettings = false
    @State private var isPresentingShare = false
    @State private var shareText: String = ""
    @State private var didLoad = false

    // Navigation using value-based routing
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                // Tonal surface background (Material-like)
                Color(.systemGroupedBackground).ignoresSafeArea()

                List {
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
                                        share(note: note)
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
                                        share(note: note)
                                    } label: {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }
                                    .tint(.indigo)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    loadNotes()
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
                }

                // Floating Action Button (Material-like)
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
                                        .fill(.indigo)
                                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 6)
                                )
                        }
                        .accessibilityLabel("New Note")
                        .padding(.trailing, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .sheet(isPresented: $isPresentingSettings) {
                NavigationStack {
                    SettingsView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    isPresentingSettings = false
                                }
                            }
                        }
                }
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(16)
            }
            .sheet(isPresented: $isPresentingShare) {
                ActivityView(activityItems: [shareText])
                    .ignoresSafeArea()
            }
            // Route to editor using Note as value
            .navigationDestination(for: Note.self) { note in
                // Bind to the note inside the array by id
                if let idx = notes.firstIndex(where: { $0.id == note.id }) {
                    NoteEditor(note: $notes[idx], onExport: {
                        share(note: notes[idx])
                    })
                    .onDisappear {
                        saveNotes()
                    }
                } else {
                    // If note no longer exists, present a fallback view
                    Text("Note not found")
                        .foregroundStyle(.secondary)
                }
            }
            .onChange(of: notes) { _ in
                saveNotes()
            }
            .onAppear {
                if !didLoad {
                    loadNotes()
                    didLoad = true
                }
            }
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
        saveNotes()
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        // Navigate to the new note
        path.append(newNote)
    }

    private func delete(note: Note) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            withAnimation {
                notes.remove(at: idx)
            }
            saveNotes()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func share(note: Note) {
        shareText = "\(note.title)\n\n\(note.content)"
        isPresentingShare = true
    }

    private func openSettings() {
        isPresentingSettings = true
    }

    private func saveNotes() {
        NoteStore.shared.save(notes)
    }

    private func loadNotes() {
        notes = NoteStore.shared.load()
    }
}

// MARK: - Note Card Cell

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
            // Tonal filled card with soft elevation (Material-like)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Editor

struct NoteEditor: View {
    @Binding var note: Note
    var onExport: () -> Void

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
                    RichTextView(text: $note.content)
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

            // Sticky bottom action bar (Material-like primary action)
            HStack {
                Button {
                    onExport()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)

                Spacer()

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

// MARK: - Rich Text (plain text for now with attributes enabled)

struct RichTextView: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = UIColor.secondarySystemGroupedBackground
        textView.layer.cornerRadius = 12
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        textView.delegate = context.coordinator
        textView.allowsEditingTextAttributes = true
        textView.tintColor = .label
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("General")) {
                HStack {
                    Image(systemName: "app.badge.fill")
                        .foregroundStyle(.indigo)
                    VStack(alignment: .leading) {
                        Text("Notefy")
                        Text("Version 1.0")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                HStack {
                    Image(systemName: "person.crop.circle")
                        .foregroundStyle(.indigo)
                    Text("Created by Farin")
                }
            }
            Section {
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

@main
struct NotefyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
