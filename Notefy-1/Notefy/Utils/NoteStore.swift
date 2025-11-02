class NoteStore {
    static let shared = NoteStore()
    private let notesKey = "notes"

    private init() {}

    func save(_ notes: [Note]) {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: notesKey)
        }
    }

    func load() -> [Note] {
        if let data = UserDefaults.standard.data(forKey: notesKey),
           let notes = try? JSONDecoder().decode([Note].self, from: data) {
            return notes
        }
        return []
    }
}