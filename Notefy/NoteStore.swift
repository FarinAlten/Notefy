// NoteStore.swift
// Notefy
//
// Persists notes as JSON in the app's Documents directory using Swift Concurrency.

import Foundation

struct StoredData: Codable {
    var notes: [Note]
    var folders: [Folder]
}

actor NoteStore {
    static let shared = NoteStore()

    private let fileName = "notes.json"

    private var cachedData: StoredData? = nil

    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(fileName)
    }

    func load() async -> StoredData {
        if let cached = cachedData {
            return cached
        }

        do {
            let url = fileURL
            guard FileManager.default.fileExists(atPath: url.path) else {
                let empty = StoredData(notes: [], folders: [Folder(name: "All Notes")])
                cachedData = empty
                return empty
            }

            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(StoredData.self, from: data)
            cachedData = decoded
            return decoded
        } catch {
            let fallback = StoredData(notes: [], folders: [Folder(name: "All Notes")])
            cachedData = fallback
            return fallback
        }
    }

    func save(notes: [Note], folders: [Folder]) async {
        do {
            let stored = StoredData(notes: notes, folders: folders)
            let data = try JSONEncoder().encode(stored)
            try data.write(to: fileURL, options: [.atomic])
            cachedData = stored
        } catch {
            // handle save failure if needed
        }
    }
}
