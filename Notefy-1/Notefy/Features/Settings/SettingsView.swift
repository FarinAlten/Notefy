struct SettingsView: View {
    @State private var isNotificationsEnabled: Bool = true
    @State private var selectedTheme: String = "Light"
    
    var body: some View {
        Form {
            Section(header: Text("Allgemein")) {
                Text("Notefy Version 1.0")
                Text("Erstellt von Farin")
            }
            
            Section(header: Text("Benachrichtigungen")) {
                Toggle("Benachrichtigungen aktivieren", isOn: $isNotificationsEnabled)
            }
            
            Section(header: Text("Erscheinungsbild")) {
                Picker("Thema auswählen", selection: $selectedTheme) {
                    Text("Hell").tag("Light")
                    Text("Dunkel").tag("Dark")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section {
                Button("Zurücksetzen auf Werkseinstellungen") {
                    resetSettings()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Einstellungen")
        .padding()
    }
    
    private func resetSettings() {
        // Logic to reset settings to default values
        isNotificationsEnabled = true
        selectedTheme = "Light"
    }
}