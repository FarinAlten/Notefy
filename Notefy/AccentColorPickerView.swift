import SwiftUI

struct AccentColorPickerView: View {
    @Binding var selectedKey: String
    @State private var currentIndex: Int = 0

    var body: some View {
        VStack(spacing: 16) {
            TabView(selection: $currentIndex) {
                ForEach(Array(predefinedAccentChoices.enumerated()), id: \.offset) { index, choice in
                    AccentPreviewPage(accent: choice)
                        .tag(index)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .interactive))

            let currentChoice = predefinedAccentChoices[safe: currentIndex] ?? predefinedAccentChoices.first!

            HStack(spacing: 12) {
                Circle()
                    .fill(currentChoice.color)
                    .frame(width: 22, height: 22)
                Text(currentChoice.name)
                    .font(.headline)
                Spacer()
                Button {
                    selectedKey = currentChoice.key
                } label: {
                    Text("Use Color")
                        .font(.body.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(currentChoice.color)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .navigationTitle("Accent Color")
        .onAppear {
            if let idx = predefinedAccentChoices.firstIndex(where: { $0.key == selectedKey }) {
                currentIndex = idx
            }
        }
    }
}
