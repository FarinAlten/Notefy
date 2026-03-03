import SwiftUI

struct RootAppView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            ContentView()
                .opacity(showSplash ? 0 : 1)
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 900_000_000)
                withAnimation(.easeInOut(duration: 0.35)) {
                    showSplash = false
                }
            }
        }
    }
}

// Dummy placeholders for compilation

struct ContentView: View {
    var body: some View {
        Text("Content View")
    }
}

struct SplashView: View {
    var body: some View {
        Text("Splash View")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
    }
}
