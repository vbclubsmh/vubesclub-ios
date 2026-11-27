import CoreImage.CIFilterBuiltins
import SwiftUI

/// Gerçek QR kodu: içerik sunucunun verdiği opak değerdir.
struct QRCodeView: View {
    let payload: String

    var body: some View {
        if let image = Self.render(payload) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .accessibilityLabel(L("Event QR code"))
        }
    }

    static func render(_ text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "Q"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 12, y: 12)),
              let cgImage = CIContext().createCGImage(output, from: output.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}

/// Beyaz plaka üzerinde büyük QR; stantta okutmak için.
struct LargePassQR: View {
    let payload: String?
    var size: CGFloat = 230

    var body: some View {
        VStack(spacing: 12) {
            Group {
                if let payload {
                    QRCodeView(payload: payload)
                } else {
                    ProgressView().tint(.black)
                }
            }
            .frame(width: size, height: size)
            .padding(14)
            .background(Color.white, in: .rect(cornerRadius: 18))

            Text(L("Show this code at the stand when you arrive."))
                .font(Afterglow.body(12.5))
                .foregroundStyle(Afterglow.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
