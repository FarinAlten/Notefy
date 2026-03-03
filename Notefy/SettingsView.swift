import SwiftUI
import Combine

// MARK: - Language Support

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "English"
    case german = "Deutsch"
    case french = "Français"
    case spanish = "Español"
    case arabic = "العربية"

    var id: String { rawValue }
}

@MainActor final class AppLocalization: ObservableObject {
    static let shared = AppLocalization()

    private let languageDefaultsKey = "appLanguage"

    @Published var languageRaw: String {
        didSet {
            UserDefaults.standard.set(languageRaw, forKey: languageDefaultsKey)
        }
    }

    private init() {
        // Load from UserDefaults or default to English
        self.languageRaw = UserDefaults.standard.string(forKey: languageDefaultsKey) ?? AppLanguage.english.rawValue
    }

    var language: AppLanguage {
        get { AppLanguage(rawValue: languageRaw) ?? .english }
        set {
            languageRaw = newValue.rawValue
            UserDefaults.standard.set(newValue.rawValue, forKey: languageDefaultsKey)
        }
    }

    func text(_ key: String) -> String {
        switch language {
        case .english:
            return key
        case .german:
            switch key {
            case "Settings": return "Einstellungen"
            case "General": return "Allgemein"
            case "Personalization": return "Personalisierung"
            case "Release Notes": return "Versionshinweise"
            case "About me": return "Über mich"
            case "Accent Color": return "Akzentfarbe"
            case "HomeView": return "Startansicht"
            case "What’s New": return "Was ist neu"
            case "Website": return "Webseite"
            case "Support": return "Support"
            case "Language": return "Sprache"
            case "Appearance": return "Darstellung"
            default: return key
            }
        case .french:
            switch key {
            case "Settings": return "Réglages"
            case "General": return "Général"
            case "Personalization": return "Personnalisation"
            case "Release Notes": return "Notes de version"
            case "About me": return "À propos"
            case "Accent Color": return "Couleur d’accent"
            case "HomeView": return "Vue d’accueil"
            case "What’s New": return "Nouveautés"
            case "Website": return "Site web"
            case "Support": return "Support"
            case "Language": return "Langue"
            case "Appearance": return "Apparence"
            default: return key
            }
        case .spanish:
            switch key {
            case "Settings": return "Ajustes"
            case "General": return "General"
            case "Personalization": return "Personalización"
            case "Release Notes": return "Notas de la versión"
            case "About me": return "Acerca de mí"
            case "Accent Color": return "Color de acento"
            case "HomeView": return "Vista de inicio"
            case "What’s New": return "Qué hay de nuevo"
            case "Website": return "Sitio web"
            case "Support": return "Apoyo"
            case "Language": return "Idioma"
            case "Appearance": return "Apariencia"
            default: return key
            }
        case .arabic:
            switch key {
            case "Settings": return "الإعدادات"
            case "General": return "عام"
            case "Personalization": return "التخصيص"
            case "Release Notes": return "ملاحظات الإصدار"
            case "About me": return "نبذة عني"
            case "Accent Color": return "لون التمييز"
            case "HomeView": return "الواجهة الرئيسية"
            case "What’s New": return "ما الجديد"
            case "Website": return "الموقع الإلكتروني"
            case "Support": return "الدعم"
            case "Language": return "اللغة"
            case "Appearance": return "المظهر"
            default: return key
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localization = AppLocalization.shared
    @AppStorage("accentColorKey") private var accentColorKey: String = "indigo"
    @AppStorage("homeLayout") private var homeLayoutRaw: String = HomeLayout.list.rawValue

    private var accentColor: Color { colorForKey(accentColorKey) }

    var body: some View {
        NavigationStack {
            Form {
                Section(localization.text("Personalization")) {
                    
                    NavigationLink {
                        AccentColorPickerView(selectedKey: $accentColorKey)
                    } label: {
                        HStack {
                            Label(localization.text("Accent Color"), systemImage: "paintpalette")
                                .tint(accentColor)
                            Spacer()
                            Circle()
                                .fill(colorForKey(accentColorKey))
                                .frame(width: 20, height: 20)
                            Text(nameForKey(accentColorKey))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Picker(localization.text("HomeView"), systemImage: "house.fill", selection: $homeLayoutRaw) {
                        ForEach(HomeLayout.allCases) { layout in
                            Label(layout.localizedName, systemImage: layout.systemImage)
                                .tag(layout.rawValue)
                        }
                    }
                        Picker(localization.text("Language"),systemImage: "person.wave.2.fill",  selection: $localization.languageRaw) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.rawValue).tag(lang.rawValue)
                            }
                        }
                        .pickerStyle(.menu)

                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                }
                Section(localization.text("About")) {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundStyle(accentColor)
                        Text("Created by Farin Altenhöner")
                    }
                    NavigationLink {
                        WhatsNewView()
                    } label: {
                        Label(localization.text("Version 0.1"), systemImage: "app.badge.fill")
                            .tint(accentColor)
                    }
                    Link(destination: URL(string: "https://farinalten.com")!) {
                        Label(localization.text("Website"), systemImage: "globe")
                            .tint(accentColor)
                    }
                    Link(destination: URL(string: "https://farinalten.com/websites/legal")!) {
                        Label(localization.text("Support"), systemImage: "envelope")
                            .tint(accentColor)
                    }
                }
            }
            .navigationTitle(localization.text("Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .tint(accentColor)
    }
}

