import Foundation

final class NoteStore {
    static let shared = NoteStore()

    private let fileName = "notes.json"
    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(fileName)
    }

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    func save(_ notes: [Note]) {
        do {
            let data = try encoder.encode(notes)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            #if DEBUG
            print("NoteStore save error:", error)
            #endif
        }
    }

    func load() -> [Note] {
        do {
            let url = fileURL
            guard FileManager.default.fileExists(atPath: url.path) else {
                return []
            }
            let data = try Data(contentsOf: url)
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
