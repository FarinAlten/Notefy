import SwiftUI

struct SettingsView: View {
    @AppStorage("accentColorKey") private var accentColorKey: String = "indigo"
    @AppStorage("homeLayout") private var homeLayoutRaw: String = HomeLayout.list.rawValue

    private var accentColor: Color { colorForKey(accentColorKey) }

    var body: some View {
        Form {
            Section(header: Text("General")) {
                HStack {
                    Image(systemName: "app.badge.fill")
                        .foregroundStyle(accentColor)
                    VStack(alignment: .leading) {
                        Text("Notefy")
                        Text("Version 0.1")
                            .font(.footnote)
                    }
                }
                HStack {
                    Image(systemName: "person.crop.circle")
                        .foregroundStyle(accentColor)
                    Text("Created by Farin Altenhöner")
                }
            }
            Section("Personalization") {
                NavigationLink {
                    AccentColorPickerView(selectedKey: $accentColorKey)
                } label: {
                    HStack {
                        Label("Accent Color", systemImage: "paintpalette")
                            .tint(accentColor)
                        Spacer()
                        Circle()
                            .fill(colorForKey(accentColorKey))
                            .frame(width: 20, height: 20)
                        Text(nameForKey(accentColorKey))
                            .foregroundStyle(.secondary)
                    }
                }

                Picker("HomeView", selection: $homeLayoutRaw) {
                    ForEach(HomeLayout.allCases) { layout in
                        Label(layout.localizedName, systemImage: layout.systemImage)
                            .tag(layout.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 4)
            }
            Section("Release Notes") {
                NavigationLink {
                    WhatsNewView()
                } label: {
                    Label("What’s New", systemImage: "sparkles")
                        .tint(accentColor)
                }
            }
            Section("About me") {
                Link(destination: URL(string: "https://farinalten.com")!) {
                    Label("Website", systemImage: "globe")
                        .tint(accentColor)
                }
                Link(destination: URL(string: "https://farinalten.com/websites/legal")!) {
                    Label("Support", systemImage: "envelope")
                        .tint(accentColor)
                }
            }
        }
        .navigationTitle("Settings")
        .tint(accentColor)
    }
}
