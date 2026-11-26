import ImageIO
import SwiftUI
import UIKit

/// Seçilen fotoğrafın bellek dostu, yönü düzeltilmiş kopyası.
enum PhotoLoader {
    static func downsampled(from data: Data, maxPixel: CGFloat = 2400) -> UIImage? {
        let options: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else { return nil }

        let thumbnail: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnail as CFDictionary) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

/// WhatsApp tarzı profil fotoğrafı önizlemesi: fotoğraf sürüklenip yakınlaştırılır, dairenin içi kullanılır.
struct AvatarCropScreen: View {
    let image: UIImage
    var onCancel: () -> Void
    var onDone: (UIImage) -> Void

    /// Tam ekran örtüsünde GeometryReader güvenli alanı bildirmeyebilir; pencerenin gerçek boşlukları kullanılır.
    private static var windowInsets: UIEdgeInsets {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.safeAreaInsets }
            .first ?? .zero
    }

    private static let maxScale: CGFloat = 5
    private static let outputSide: CGFloat = 800

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        // Güvenli alan içindeki tek, sabit boyutlu katman: daire ve fotoğraf aynı merkezi paylaşır.
        GeometryReader { proxy in
            let size = proxy.size
            let diameter = max(120, min(size.width, size.height) - 48)
            let base = baseSize(for: diameter)

            ZStack {
                Color.black

                // Fotoğraf ekrandan büyük olabilir; overlay olduğu için yerleşimi (ve diğer katmanları) etkilemez.
                Color.clear
                    .overlay {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: base.width * scale, height: base.height * scale)
                            .offset(offset)
                            .accessibilityHidden(true)
                    }

                dimming(diameter: diameter, size: size)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                VStack {
                    topBar
                    Spacer()
                    VStack(spacing: 14) {
                        Text(L("Drag and pinch to adjust"))
                            .font(Afterglow.body(13))
                            .foregroundStyle(Afterglow.muted)

                        PrimaryAction(title: "Use photo", icon: "checkmark") {
                            onDone(render(diameter: diameter, base: base))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                }
                .padding(.top, max(proxy.safeAreaInsets.top, Self.windowInsets.top))
                .padding(.bottom, max(proxy.safeAreaInsets.bottom, Self.windowInsets.bottom))
            }
            .frame(width: size.width, height: size.height)
            .clipped()
            .contentShape(Rectangle())
            .gesture(drag(diameter: diameter, base: base))
            .simultaneousGesture(magnify(diameter: diameter, base: base))
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    // MARK: Parts

    private var topBar: some View {
        HStack {
            Button(L("Cancel"), action: onCancel)
                .font(Afterglow.medium(15))
                .foregroundStyle(Afterglow.ivory)
                .frame(minHeight: 44)

            Spacer()

            Text(L("Move and scale"))
                .font(Afterglow.medium(15))
                .foregroundStyle(Afterglow.text)

            Spacer()

            // Başlığı ortalamak için Cancel ile aynı genişlikte boşluk.
            Button(L("Cancel"), action: {})
                .font(Afterglow.medium(15))
                .hidden()
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    private func dimming(diameter: CGFloat, size: CGSize) -> some View {
        let circle = CGRect(
            x: (size.width - diameter) / 2, y: (size.height - diameter) / 2, width: diameter, height: diameter)

        return ZStack {
            Path { path in
                path.addRect(CGRect(origin: .zero, size: size))
                path.addEllipse(in: circle)
            }
            .fill(Color.black.opacity(0.62), style: FillStyle(eoFill: true))

            Circle()
                .strokeBorder(Color.white.opacity(0.85), lineWidth: 1.5)
                .frame(width: diameter, height: diameter)
                .position(x: circle.midX, y: circle.midY)
        }
    }

    // MARK: Geometry

    /// Ölçek 1 iken kısa kenar daireye tam oturur.
    private func baseSize(for diameter: CGFloat) -> CGSize {
        let ratio = image.size.width / max(image.size.height, 1)
        return ratio >= 1
            ? CGSize(width: diameter * ratio, height: diameter)
            : CGSize(width: diameter, height: diameter / max(ratio, 0.0001))
    }

    private func clamped(_ value: CGSize, diameter: CGFloat, base: CGSize, scale: CGFloat) -> CGSize {
        let limitX = max(0, (base.width * scale - diameter) / 2)
        let limitY = max(0, (base.height * scale - diameter) / 2)
        return CGSize(
            width: min(max(value.width, -limitX), limitX),
            height: min(max(value.height, -limitY), limitY))
    }

    private func drag(diameter: CGFloat, base: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                offset = clamped(
                    CGSize(width: lastOffset.width + value.translation.width,
                           height: lastOffset.height + value.translation.height),
                    diameter: diameter, base: base, scale: scale)
            }
            .onEnded { _ in lastOffset = offset }
    }

    private func magnify(diameter: CGFloat, base: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(max(lastScale * value.magnification, 1), Self.maxScale)
                offset = clamped(offset, diameter: diameter, base: base, scale: scale)
            }
            .onEnded { _ in
                lastScale = scale
                lastOffset = offset
            }
    }

    // MARK: Output

    /// Dairenin içindeki bölgeyi 800×800 kare olarak üretir.
    private func render(diameter: CGFloat, base: CGSize) -> UIImage {
        let displayWidth = base.width * scale
        let displayHeight = base.height * scale
        let toImage = image.size.width / max(displayWidth, 1)

        let cropX = (displayWidth - diameter) / 2 - offset.width
        let cropY = (displayHeight - diameter) / 2 - offset.height
        let cropSide = diameter * toImage
        let factor = Self.outputSide / max(cropSide, 1)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let output = CGSize(width: Self.outputSide, height: Self.outputSide)
        return UIGraphicsImageRenderer(size: output, format: format).image { _ in
            image.draw(in: CGRect(
                x: -cropX * toImage * factor,
                y: -cropY * toImage * factor,
                width: image.size.width * factor,
                height: image.size.height * factor))
        }
    }
}
