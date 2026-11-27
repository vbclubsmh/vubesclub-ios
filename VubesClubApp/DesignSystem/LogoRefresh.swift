import SwiftUI

/// Aşağı çekip yenileme: V ve C çekildikçe birleşir, yenilenirken monogram nefes alır
/// ve yazı logosu belirir. Sistemin döner göstergesi gizlenir (`VubesClubApp`).
enum LogoRefresh {
    static let space = "logoRefresh"
    static let threshold: CGFloat = 70
    static let minimumDuration: Duration = .milliseconds(1100)
}

private struct PullOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat? = nil

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue() ?? value
    }
}

/// Kaydırılan içeriğin en üstüne konur; çekme miktarını ölçer.
struct LogoRefreshProbe: View {
    var body: some View {
        Color.clear
            .frame(height: 0)
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: PullOffsetKey.self,
                        value: proxy.frame(in: .named(LogoRefresh.space)).minY)
                }
            }
            .accessibilityHidden(true)
    }
}

private struct LogoRefreshModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let action: @MainActor () async -> Void

    @State private var refreshing = false

    func body(content: Content) -> some View {
        // Çekme miktarı yalnızca arka plandaki alt görünümde okunur; böylece kaydırma
        // sırasında `refreshable` sahibi görünüm yeniden çizilmez ve çekme yarıda kesilmez.
        content
            .coordinateSpace(name: LogoRefresh.space)
            .refreshable {
                refreshing = true
                async let work: Void = action()
                try? await Task.sleep(for: reduceMotion ? .milliseconds(400) : LogoRefresh.minimumDuration)
                await work
                refreshing = false
            }
            .backgroundPreferenceValue(PullOffsetKey.self) { raw in
                LogoRefreshLayer(raw: raw, refreshing: refreshing)
            }
    }
}

private struct LogoRefreshLayer: View {
    let raw: CGFloat?
    let refreshing: Bool

    @State private var baseline: CGFloat?
    /// Eşik aşıldığında veya yenilenirken true; bırakınca çizim geri sarmaz, yalnızca solar.
    @State private var engaged = false

    private var pull: CGFloat {
        guard let raw, let baseline else { return 0 }

        return max(0, raw - baseline)
    }

    var body: some View {
        let progress = min(pull / LogoRefresh.threshold, 1)
        let held = engaged || refreshing

        VStack {
            LogoRefreshMark(
                drawn: held ? 1 : progress,
                presence: refreshing ? 1 : held ? min(1, Double(pull) / 34) : Double(min(1, progress * 1.4)),
                armed: held,
                refreshing: refreshing)
                .offset(y: (baseline ?? 0) + max(0, (pull - LogoRefreshMark.height) / 2) + 6)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
        .onChange(of: raw, initial: true) { _, value in
            if baseline == nil, let value { baseline = value }
        }
        .onChange(of: pull) { _, value in
            if value >= LogoRefresh.threshold {
                engaged = true
            } else if value < 1, !refreshing {
                engaged = false
            }
        }
        .onChange(of: refreshing) { _, now in
            if now { engaged = true } else if pull < 1 { engaged = false }
        }
        .sensoryFeedback(.impact(weight: .light, intensity: 0.45), trigger: progress >= 0.5 && !held) { _, new in new }
        .sensoryFeedback(.impact(weight: .medium, intensity: 0.9), trigger: held) { _, new in new }
        .sensoryFeedback(.success, trigger: refreshing) { old, new in old && !new }
    }
}

/// Monogram çekildikçe ince bir çizgiyle kendini çizer, eşikte dolar ve parlar;
/// yenilenirken üzerinden ışık süzülür, altında yazı logosu belirir.
private struct LogoRefreshMark: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let width: CGFloat = 58
    static var monogramHeight: CGFloat { width * 452 / 624 }
    static var height: CGFloat { monogramHeight + 7 + width * 96 / 624 }

    let drawn: CGFloat
    let presence: Double
    let armed: Bool
    let refreshing: Bool

    private static let sweepPeriod = 1.9

    private func smooth(_ value: CGFloat, _ low: CGFloat, _ high: CGFloat) -> CGFloat {
        let t = min(max((value - low) / (high - low), 0), 1)
        return t * t * (3 - 2 * t)
    }

    var body: some View {
        TimelineView(.animation(paused: !refreshing || reduceMotion)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let local = time.truncatingRemainder(dividingBy: Self.sweepPeriod) / Self.sweepPeriod
            let travel = min(local / 0.66, 1)
            let sweep = (1 - cos(Double.pi * travel)) / 2
            let breath = refreshing && !reduceMotion ? (sin(time * 2.7) + 1) / 2 : 0
            let fill = smooth(drawn, 0.7, 1)
            let eased = 1 - (1 - drawn) * (1 - drawn)

            VStack(spacing: 7) {
                ZStack {
                    VCMonogram()
                        .trim(from: 0, to: drawn)
                        .stroke(.white.opacity(1 - 0.55 * fill),
                                style: StrokeStyle(lineWidth: 1.15, lineCap: .round, lineJoin: .round))

                    VCMonogram()
                        .fill(.white.opacity(0.72 * fill))

                    if refreshing && !reduceMotion {
                        LinearGradient(
                            colors: [.white.opacity(0), .white, .white.opacity(0)],
                            startPoint: .leading, endPoint: .trailing)
                            .frame(width: Self.width * 0.55)
                            .offset(x: CGFloat(sweep * 1.7 - 0.85) * Self.width)
                            .mask { VCMonogram().fill(.white) }
                    }
                }
                .frame(width: Self.width, height: Self.monogramHeight)
                .background {
                    Circle()
                        .fill(RadialGradient(
                            colors: [.white.opacity(0.2 * (0.35 * Double(fill) + 0.65 * breath)), .white.opacity(0)],
                            center: .center, startRadius: 0, endRadius: Self.width))
                        .frame(width: Self.width * 2.4, height: Self.width * 2.4)
                }
                .scaleEffect(0.8 + 0.2 * eased)
                .keyframeAnimator(initialValue: CGFloat(1), trigger: armed) { view, scale in
                    view.scaleEffect(scale)
                } keyframes: { _ in
                    KeyframeTrack {
                        CubicKeyframe(1.13, duration: 0.14)
                        SpringKeyframe(1, duration: 0.5, spring: .bouncy)
                    }
                }

                SplashWordmark(visible: refreshing, reduceMotion: reduceMotion)
                    .frame(width: Self.width, height: Self.width * 96 / 624)
            }
            .opacity(presence)
        }
        .accessibilityHidden(true)
    }
}

extension View {
    /// `refreshable` yerine; Vubes Club monogramıyla yenileme göstergesi.
    func logoRefreshable(_ action: @escaping @MainActor () async -> Void) -> some View {
        modifier(LogoRefreshModifier(action: action))
    }
}
