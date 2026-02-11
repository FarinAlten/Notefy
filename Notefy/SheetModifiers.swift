import SwiftUI

struct SettingsSheetModifier: ViewModifier {
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                NavigationStack {
                    SettingsView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Export") {
                                    isPresented = false
                                }
                            }
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    
                                }
                            }
                        }
                }
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(16)
            }
    }
}

struct ShareSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let items: [Any]

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                ActivityView(activityItems: items)
                    .ignoresSafeArea()
            }
    }
}

extension View {
    func settingsSheet(isPresented: Binding<Bool>) -> some View {
        modifier(SettingsSheetModifier(isPresented: isPresented))
    }

    func shareSheet(isPresented: Binding<Bool>, items: [Any]) -> some View {
        modifier(ShareSheetModifier(isPresented: isPresented, items: items))
    }
}
