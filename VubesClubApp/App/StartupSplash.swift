import SwiftUI

enum StartupPhase: Int, Comparable {
    case splash
    case backdrop
    case brand
    case headline
    case actions
    case complete

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct StartupSplash: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var phase: StartupPhase

    @State private var lettersVisible = false
    @State private var lettersTogether = false
    @State private var showsJoinedMonogram = false
    @State private var showsWordmark = false

    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width * 0.38, 152)
            let separation = geometry.size.width * 0.21
            let revealingWelcome = phase >= .backdrop

            ZStack {
                Color.black
                    .opacity(revealingWelcome ? 0 : 1)

                SplashMonogram(
                    separation: lettersTogether || reduceMotion ? 0 : separation,
                    joined: showsJoinedMonogram || reduceMotion
                )
                .foregroundStyle(.white)
                .frame(width: width, height: width * 452 / 624)
                .overlay(alignment: .bottom) {
                    SplashWordmark(visible: showsWordmark, reduceMotion: reduceMotion)
                        .frame(width: width, height: width * 96 / 624)
                        .offset(y: width * 157 / 624)
                }
                .opacity(revealingWelcome ? 0 : (lettersVisible || reduceMotion ? 1 : 0))
                .scaleEffect(revealingWelcome && !reduceMotion ? 0.9 : 1)
                .offset(y: revealingWelcome && !reduceMotion ? -20 : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Vubes Club")
        .accessibilityAddTraits(.isImage)
        .sensoryFeedback(ClubHaptics.welcome, trigger: phase) { previous, current in
            previous == .splash && current == .backdrop
        }
        .task { await play() }
    }

    private func play() async {
        do {
            if reduceMotion {
                try await Task.sleep(for: .milliseconds(350))

                withAnimation(.easeOut(duration: 0.25)) {
                    phase = .backdrop
                }

                try await Task.sleep(for: .milliseconds(250))
            } else {
                try await playFullSequence()
            }

            phase = .complete
        } catch {
            // Removing the root view cancels the startup sequence.
        }
    }

    private func playFullSequence() async throws {
        withAnimation(.easeOut(duration: 0.32)) {
            lettersVisible = true
        }

        try await Task.sleep(for: .milliseconds(300))

        withAnimation(.timingCurve(0.45, 0.03, 0.23, 1, duration: 2.35)) {
            lettersTogether = true
        }

        try await Task.sleep(for: .milliseconds(2370))
        showsJoinedMonogram = true

        try await Task.sleep(for: .milliseconds(200))
        showsWordmark = true

        try await Task.sleep(for: .seconds(SplashWordmark.revealDuration))
        try await Task.sleep(for: .milliseconds(600))

        withAnimation(.easeInOut(duration: 1.15)) {
            phase = .backdrop
        }

        try await Task.sleep(for: .milliseconds(360))

        withAnimation(.easeOut(duration: 0.85)) {
            phase = .brand
        }

        try await Task.sleep(for: .milliseconds(280))

        withAnimation(.easeOut(duration: 0.75)) {
            phase = .headline
        }

        try await Task.sleep(for: .milliseconds(340))

        withAnimation(.easeOut(duration: 0.65)) {
            phase = .actions
        }

        try await Task.sleep(for: .milliseconds(650))
    }
}

struct SplashWordmark: View {
    private static let wordDuration = 1.1
    private static let clubDelay = 0.48

    static var revealDuration: Double { wordDuration + clubDelay }

    let visible: Bool
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            word(0..<5, delay: 0)
            word(5..<9, delay: Self.clubDelay)
        }
        .accessibilityHidden(true)
    }

    private func word(_ glyphs: Range<Int>, delay: Double) -> some View {
        let isRevealed = visible || reduceMotion

        return ZStack {
            // Each asset retains its position in the original wordmark.
            ForEach(glyphs) { index in
                Image("SplashGlyph\(index)")
                    .resizable()
                    .scaledToFit()
            }
        }
        .compositingGroup()
        .blur(radius: isRevealed ? 0 : 3.5)
        .opacity(isRevealed ? 1 : 0)
        .offset(y: isRevealed ? 0 : 2)
        .animation(
            reduceMotion ? nil : .timingCurve(0.34, 0.08, 0.22, 1, duration: Self.wordDuration).delay(delay),
            value: visible
        )
    }
}

struct SplashMonogram: View {
    let separation: CGFloat
    let joined: Bool

    var body: some View {
        ZStack {
            if joined {
                VCMonogram()
            } else {
                VCMonogram(piece: .v)
                    .offset(x: -separation)

                VCMonogram(piece: .c)
                    .offset(x: separation)
            }
        }
    }
}

private struct VCMonogram: Shape {
    enum Piece {
        case joined
        case v
        case c
    }

    var piece = Piece.joined

    // Original outline and view box from the landing page’s vc-monogram.svg.
    private let upperJoin = CGPoint(x: 665.86751, y: 415.34819)
    private let lowerJoin = CGPoint(x: 658.86435, y: 530.42706)

    func path(in rect: CGRect) -> Path {
        let path = Path { path in
            if piece == .c {
                path.move(to: upperJoin)
            } else {
                path.addLines([
                    CGPoint(x: 420, y: 304.43337),
                    CGPoint(x: 453.31230, y: 290.04851),
                    CGPoint(x: 591.10410, y: 602.72990),
                    upperJoin
                ])
            }

            if piece == .v {
                path.addLine(to: lowerJoin)
            } else {
                traceC(in: &path)
            }

            if piece != .c {
                path.addLine(to: CGPoint(x: 592.61830, y: 695.09583))
            }

            path.closeSubpath()
        }

        return path.applying(CGAffineTransform(
            a: rect.width / 624, b: 0, c: 0, d: rect.height / 452,
            tx: rect.minX - 408 * rect.width / 624,
            ty: rect.minY - 252 * rect.height / 452
        ))
    }

    private func traceC(in path: inout Path) {
        path.addCurve(to: CGPoint(x: 856.84543, y: 263.92863),
                      control1: CGPoint(x: 710.72555, y: 305.19046),
                      control2: CGPoint(x: 765.99369, y: 263.92863))
        path.addCurve(to: CGPoint(x: 1017.35016, y: 329.79614),
                      control1: CGPoint(x: 921.19874, y: 263.92863),
                      control2: CGPoint(x: 974.57413, y: 285.88447))
        path.addLine(to: CGPoint(x: 991.60883, y: 355.53747))
        path.addCurve(to: CGPoint(x: 856.84543, y: 300.26933),
                      control1: CGPoint(x: 952.99685, y: 316.54693),
                      control2: CGPoint(x: 909.84227, y: 300.26933))
        path.addCurve(to: CGPoint(x: 699.74763, y: 428.97595),
                      control1: CGPoint(x: 781.13565, y: 300.26933),
                      control2: CGPoint(x: 736.08833, y: 335.47437))
        path.addCurve(to: CGPoint(x: 804.98423, y: 635.66365),
                      control1: CGPoint(x: 662.64984, y: 516.79930),
                      control2: CGPoint(x: 709.96845, y: 608.40813))
        path.addCurve(to: CGPoint(x: 996.52997, y: 586.45229),
                      control1: CGPoint(x: 869.71609, y: 656.48384),
                      control2: CGPoint(x: 940.88328, y: 634.14945))
        path.addLine(to: CGPoint(x: 1020, y: 613.70781))
        path.addCurve(to: CGPoint(x: 795.14196, y: 670.49015),
                      control1: CGPoint(x: 956.40379, y: 668.59740),
                      control2: CGPoint(x: 868.95899, y: 694.71728))
        path.addCurve(to: lowerJoin,
                      control1: CGPoint(x: 719.05363, y: 649.66996),
                      control2: CGPoint(x: 670.22082, y: 595.91602))
    }
}
