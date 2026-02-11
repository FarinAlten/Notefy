import Foundation

struct WhatsNewEntry: Identifiable, Hashable {
    let id = UUID()
    let version: String
    let title: String
    let highlights: [String]
    let accentKey: String
    let date: Date?
}

let whatsNewEntries: [WhatsNewEntry] = [
    WhatsNewEntry(
        version: "1.0",
        title: "Initial Release",
        highlights: [
            "Create and edit notes",
            "Markdown-style formatting toolbar",
            "Quick share as Markdown or Plain Text",
            "Accent color customization"
        ],
        accentKey: "indigo",
        date: Date(timeIntervalSince1970: 1_726_000_000)
    ),
    WhatsNewEntry(
        version: "1.1",
        title: "Formatting Improvements",
        highlights: [
            "Bulleted list auto-continue and smart backspace",
            "Quote and Heading toggles",
            "Refined editor styling"
        ],
        accentKey: "teal",
        date: Date(timeIntervalSince1970: 1_728_000_000)
    ),
    WhatsNewEntry(
        version: "1.2",
        title: "Sharing & Settings",
        highlights: [
            "Share via system sheet",
            "New Settings screen",
            "Accent color preview revamp"
        ],
        accentKey: "pink",
        date: Date(timeIntervalSince1970: 1_730_000_000)
    )
]
