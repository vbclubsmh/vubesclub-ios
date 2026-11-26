import SwiftUI
import UIKit

/// Prepares a picked photo for upload: centered square, at most 800 px, JPEG.
enum ProfilePhoto {
    static func jpeg(from data: Data, side: CGFloat = 800, quality: CGFloat = 0.82) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let size = image.size
        let crop = min(size.width, size.height)
        guard crop > 0 else { return nil }

        let scale = min(1, side / crop)
        let output = CGSize(width: crop * scale, height: crop * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let rendered = UIGraphicsImageRenderer(size: output, format: format).image { _ in
            image.draw(in: CGRect(
                x: -(size.width - crop) / 2 * scale,
                y: -(size.height - crop) / 2 * scale,
                width: size.width * scale,
                height: size.height * scale))
        }
        return rendered.jpegData(compressionQuality: quality)
    }
}

/// The member's own photo, or their initials until they add one.
struct ProfileAvatar: View {
    let url: String?
    let name: String
    var size: CGFloat = 72

    private var initials: String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }

    var body: some View {
        Group {
            if let url {
                ClubMediaImage(source: url)
            } else {
                Afterglow.surface.overlay {
                    Text(initials)
                        .font(Afterglow.display(size * 0.4))
                        .foregroundStyle(Afterglow.ivory)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay { Circle().strokeBorder(Afterglow.ivory, lineWidth: 2) }
    }
}
