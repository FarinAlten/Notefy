struct NoteList: View {
    @Binding var notes: [Note]
    @Binding var selectedNote: Note?
    
    var body: some View {
        List(selection: $selectedNote) {
            ForEach(notes) { note in
                NavigationLink(destination: NoteEditor(note: binding(for: note))) {
                    VStack(alignment: .leading) {
                        Text(note.title)
                            .font(.headline)
                        Text(note.createdAt, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteNote)
        }
        .navigationTitle("Notizen")
    }
    
    private func binding(for note: Note) -> Binding<Note> {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else {
            fatalError("Note not found")
        }
        return $notes[index]
    }
    
    private func deleteNote(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
    }
}