import SwiftUI

struct SplashView: View {
    @Environment(\.colorScheme) private var colorScheme

    private let lightImageBaseName = "lightmode"
    private let darkImageBaseName = "darkmode"

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            if let uiImage = loadUIImage(named: colorScheme == .dark ? darkImageBaseName : lightImageBaseName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 240, maxHeight: 240)
                    .accessibilityLabel("App Logo")
                    .transition(.opacity.combined(with: .scale))
            } else {
                // Fallback if image not found
                Text("Logo not found")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func loadUIImage(named baseName: String) -> UIImage? {
        let exts = ["png", "jpg", "jpeg", "pdf"]
        let bundle = Bundle.main
        for ext in exts {
            if let url = bundle.url(forResource: baseName, withExtension: ext) {
                if ext == "pdf" {
                    if let data = try? Data(contentsOf: url),
                       let provider = CGDataProvider(data: data as CFData),
                       let pdfDoc = CGPDFDocument(provider),
                       let page = pdfDoc.page(at: 1) {
                        let pageRect = page.getBoxRect(.mediaBox)
                        let scale: CGFloat = UIScreen.main.scale
                        let size = CGSize(width: pageRect.width, height: pageRect.height)
                        let format = UIGraphicsImageRendererFormat()
                        format.scale = scale
                        let renderer = UIGraphicsImageRenderer(size: size, format: format)
                        let img = renderer.image { ctx in
                            UIColor.clear.set()
                            ctx.fill(CGRect(origin: .zero, size: size))
                            ctx.cgContext.translateBy(x: 0, y: size.height)
                            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                            ctx.cgContext.drawPDFPage(page)
                        }
                        return img
                    }
                } else {
                    return UIImage(contentsOfFile: url.path)
                }
            }
        }
        return nil
    }
}
