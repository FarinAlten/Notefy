// NoteStore.swift
// Notefy
//
// Persists notes as JSON in the app's Documents directory using Swift Concurrency.

import Foundation

actor NoteStore {
    static let shared = NoteStore()

    private let fileName = "notes.json"

    private var cachedNotes: [Note]? = nil

    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(fileName)
    }

    func load() async -> [Note] {
        // Serve from cache if available
        if let cached = cachedNotes {
            return cached
        }

        do {
            let url = fileURL
            guard FileManager.default.fileExists(atPath: url.path) else {
                cachedNotes = []
                return []
            }

            let data = try Data(contentsOf: url)
            let notes = try JSONDecoder().decode([Note].self, from: data)
            cachedNotes = notes
            return notes
        } catch {
            // If decoding fails, return empty and do not crash
            cachedNotes = []
            return []
        }
    }

    func save(_ notes: [Note]) async {
        do {
            let data = try JSONEncoder().encode(notes)
            try data.write(to: fileURL, options: [.atomic])
            cachedNotes = notes
        } catch {
            // You might want to log this in production
            // print("Failed to save notes: \(error)")
        }
    }
}
