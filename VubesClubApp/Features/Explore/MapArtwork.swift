import SwiftUI

struct MapArtwork: View {
    let image: String

    var body: some View {
        ClubPhoto(name: image)
            .overlay(alignment: .top) {
                LinearGradient(colors: [.black.opacity(0.48), .clear],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 180)
            }
            .overlay(alignment: .bottom) {
                Afterglow.shade().frame(height: 210)
            }
            .ignoresSafeArea()
    }
}

struct MapPin: View {
    let symbol: String
    let selected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(pinColor)
                .frame(width: 10, height: 10)
                .rotationEffect(.degrees(45))
                .offset(y: 14)

            Circle()
                .fill(pinColor)
                .overlay {
                    Circle().strokeBorder(selected ? .clear : Afterglow.muted.opacity(0.6))
                }
                .frame(width: 32, height: 32)

            Image(systemName: symbol)
                .font(.system(size: 15))
                .foregroundStyle(selected ? Afterglow.background : Afterglow.text)
        }
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }

    private var pinColor: Color {
        selected ? Afterglow.ivory : Afterglow.surface
    }
}

extension MapPosition {
    func point(in size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width / 374, y: (y - 52) * size.height / 716)
    }
}
