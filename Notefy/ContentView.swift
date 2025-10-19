//  ContentView.swift
//  Notefy
//
//  Created by Farin Altenhöner on 05.08.25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var notes: [Note] = []
    @State private var selectedNote: Note? = nil
    @State private var isPresentingNewNote = false
    @State private var isPresentingSettings = false
    @State private var didLoad = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedNote) {
                ForEach(notes) { note in
                    NavigationLink(value: note) {
                        VStack(alignment: .leading) {
                            Text(note.title).bold()
                            Text(note.createdAt, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteNote)
            }
            .navigationTitle("Notizen")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        openSettings()
                    } label: {
                        Label("Einstellungen", systemImage: "gear")
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        createNewNote()
                    } label: {
                        Label("Neue Notiz", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let note = selectedNote {
                NoteEditor(note: binding(for: note), onExport: {
                    export(note: note)
                    saveNotes()
                })
                .onDisappear {
                    saveNotes()
                }
            } else {
                Text("Wähle eine Notiz aus")
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $isPresentingNewNote) {
            NavigationStack {
                NoteEditor(note: .constant(Note()), onExport: { })
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Abbrechen") {
                                isPresentingNewNote = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Sichern") {
                                // Save note
                                isPresentingNewNote = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $isPresentingSettings) {
            NavigationStack {
                SettingsView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Fertig") {
                                isPresentingSettings = false
                            }
                        }
                    }
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

    private func createNewNote() {
        let newNote = Note(title: "Neue Notiz", content: "")
        notes.insert(newNote, at: 0)
        selectedNote = newNote
        saveNotes()
    }

    private func deleteNote(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
        saveNotes()
    }

    private func export(note: Note) {
        let text = "\(note.title)\n\n\(note.content)"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
    }

    private func openSettings() {
        isPresentingSettings = true
    }

    private func binding(for note: Note) -> Binding<Note> {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            return $notes[index]
        } else {
            let fallback = Note()
            notes.insert(fallback, at: 0)
            return $notes[0]
        }
    }

    private func saveNotes() {
        NoteStore.shared.save(notes)
    }

    private func loadNotes() {
        notes = NoteStore.shared.load()
    }
}

struct NoteEditor: View {
    @Binding var note: Note
    var onExport: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                TextField("Titel", text: $note.title)
                    .font(.title2.weight(.semibold))
                    .padding(.horizontal)
                    .padding(.top)

                Divider()

                RichTextView(text: $note.content)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .frame(maxHeight: .infinity)

                HStack {
                    Button("Exportieren", action: onExport)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding(.top)
        }
        .navigationTitle("Notiz bearbeiten")
    }
}

struct RichTextView: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
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

struct SettingsView: View {
    var body: some View {
        Form {
            Section(header: Text("Allgemein")) {
                Text("Notefy Version 1.0")
                Text("Erstellt von Farin")
            }
        }
        .navigationTitle("Einstellungen")
        .padding()
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
