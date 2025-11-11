import Foundation

actor NoteStore {
    static let shared = NoteStore()
    private init() {}

    private let fileName = "notes.json"

    // Location for storing notes
    private var fileURL: URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let dir = urls.first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return dir.appendingPathComponent(fileName)
    }

    // Save notes to disk as JSON (off the main thread, serialized by the actor)
    func save(_ notes: [Note]) async {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(notes)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            #if DEBUG
            print("NoteStore save error:", error)
            #endif
        }
    }

    // Load notes from disk, or return empty array if unavailable (off the main thread)
    func load() async -> [Note] {
        do {
            let url = fileURL
            guard FileManager.default.fileExists(atPath: url.path) else {
                return []
            }
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let notes = try decoder.decode([Note].self, from: data)
            return notes
        } catch {
            #if DEBUG
            print("NoteStore load error:", error)
            #endif
            return []
        }
    }
}
