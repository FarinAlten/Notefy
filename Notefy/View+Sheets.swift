import SwiftUI
import UIKit

struct SettingsSheetModifier: ViewModifier {
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            SettingsView()
        }
    }
}

extension View {
    func settingsSheet(isPresented: Binding<Bool>) -> some View {
        modifier(SettingsSheetModifier(isPresented: isPresented))
    }
}

struct ShareSheetPresenter: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ShareSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    var items: [Any]

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            ShareSheetPresenter(items: items)
        }
    }
}

extension View {
    func shareSheet(isPresented: Binding<Bool>, items: [Any]) -> some View {
        modifier(ShareSheetModifier(isPresented: isPresented, items: items))
    }
}

