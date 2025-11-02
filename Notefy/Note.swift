// Note.swift
// Notefy

import Foundation

struct Note: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var content: String
    var createdAt: Date

    init(id: UUID = UUID(), title: String = "", content: String = "", createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
    }
}
