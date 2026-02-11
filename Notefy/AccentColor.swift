import SwiftUI

struct AccentChoice: Identifiable, Hashable {
    let id = UUID()
    let key: String
    let name: String
    let color: Color
}

let predefinedAccentChoices: [AccentChoice] = [
    .init(key: "indigo", name: "Indigo", color: .indigo),
    .init(key: "blue", name: "Blue", color: .blue),
    .init(key: "teal", name: "Teal", color: .teal),
    .init(key: "mint", name: "Mint", color: .mint),
    .init(key: "green", name: "Green", color: .green),
    .init(key: "yellow", name: "Yellow", color: .yellow),
    .init(key: "orange", name: "Orange", color: .orange),
    .init(key: "red", name: "Red", color: .red),
    .init(key: "pink", name: "Pink", color: .pink),
    .init(key: "purple", name: "Purple", color: .purple),
    .init(key: "gray", name: "Gray", color: .gray)
]

func colorForKey(_ key: String) -> Color {
    predefinedAccentChoices.first(where: { $0.key == key })?.color ?? .indigo
}

func nameForKey(_ key: String) -> String {
    predefinedAccentChoices.first(where: { $0.key == key })?.name ?? "Indigo"
}
