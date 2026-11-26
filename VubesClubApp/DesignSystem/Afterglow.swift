import SwiftUI

enum Afterglow {
    static let inset: CGFloat = 22
    static let background = Color(hex: 0x222522)
    static let surface = Color(hex: 0x2d322e)
    static let border = Color(hex: 0x454c44)
    static let accent = Color(hex: 0xdcc6a1)
    static let ivory = Color(hex: 0xf1e9d9)
    static let text = Color(hex: 0xf6f2e9)
    static let muted = Color(hex: 0xc1baab)
    static let green = Color(hex: 0xc4d9ad)

    static func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        .custom("HelveticaNeue-Light", size: size, relativeTo: style)
    }

    static func body(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom("Manrope-Regular", size: size, relativeTo: style)
    }

    static func medium(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom("HelveticaNeue-Medium", size: size, relativeTo: style)
    }

    static func shade(_ color: Color = background) -> LinearGradient {
        LinearGradient(
            stops: [.init(color: color.opacity(0), location: 0),
                    .init(color: color.opacity(0.82), location: 0.75),
                    .init(color: color, location: 1)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

extension Color {
    fileprivate init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 255) / 255,
            green: Double((hex >> 8) & 255) / 255,
            blue: Double(hex & 255) / 255
        )
    }
}

struct ScreenTitle: View {
    let title: String
    let size: CGFloat

    init(_ title: String, size: CGFloat = 49) {
        self.title = title
        self.size = size
    }

    var body: some View {
        Text(L(title))
            .font(Afterglow.display(size))
            .tracking(-1.3)
            .accessibilityAddTraits(.isHeader)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct Overline: View {
    let title: String
    let color: Color

    init(_ title: String, color: Color = Afterglow.muted) {
        self.title = title
        self.color = color
    }

    var body: some View {
        Text(AppLanguage.shared.uppercase(L(title)))
            .font(Afterglow.medium(9.5, relativeTo: .caption2))
            .tracking(1.55)
            .foregroundStyle(color)
    }
}

struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(Afterglow.border)
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}

/// Resolves server media references against the configured API origin.
struct ClubMediaImage: View {
    let source: String
    var fit = false

    var body: some View {
        Group {
            Image(source)
                .resizable()
                .aspectRatio(contentMode: fit ? .fit : .fill)
        }
    }
}

struct ClubPhoto: View {
    let name: String
    var radius: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ClubMediaImage(source: name)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .clipShape(.rect(cornerRadius: radius))
        .accessibilityHidden(true)
    }
}

struct Wordmark: View {
    var width: CGFloat = 90

    var body: some View {
        ClubMediaImage(source: "Wordmark", fit: true)
            .frame(width: width)
            .accessibilityLabel("Vubes Club")
    }
}

struct Avatar: View {
    let image: String
    var size: CGFloat = 24
    var selected = false

    var body: some View {
        ClubMediaImage(source: image)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .strokeBorder(selected ? Afterglow.ivory : Afterglow.background, lineWidth: 2)
            }
            .accessibilityHidden(true)
    }
}
