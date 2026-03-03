import SwiftUI

struct SplashView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            Image(colorScheme == .dark ? "darkmode" : "lightmode")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 240, maxHeight: 240)
                .accessibilityLabel("App Logo")
                .transition(.opacity.combined(with: .scale))
        }
    }
}
