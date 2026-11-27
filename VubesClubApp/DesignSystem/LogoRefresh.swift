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

    private var pull: CGFloat {
        guard let raw, let baseline else { return 0 }

        return max(0, raw - baseline)
    }

    var body: some View {
        VStack {
            LogoRefreshMark(pull: pull, refreshing: refreshing)
                .offset(y: (baseline ?? 0) + max(0, (pull - LogoRefreshMark.height) / 2) + 4)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
        .onChange(of: raw, initial: true) { _, value in
            if baseline == nil, let value { baseline = value }
        }
        .sensoryFeedback(ClubHaptics.selection, trigger: pull >= LogoRefresh.threshold && !refreshing) { _, armed in armed }
    }
}

private struct LogoRefreshMark: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let width: CGFloat = 46
    static var height: CGFloat { width * 452 / 624 + 6 + width * 96 / 624 }

    let pull: CGFloat
    let refreshing: Bool

    @State private var breathing = false

    private var progress: CGFloat { min(pull / LogoRefresh.threshold, 1) }

    var body: some View {
        let together = refreshing || reduceMotion || progress >= 1
        let eased = 1 - (1 - progress) * (1 - progress)

        VStack(spacing: 6) {
            SplashMonogram(separation: together ? 0 : (1 - eased) * 26, joined: together)
                .foregroundStyle(.white)
                .frame(width: Self.width, height: Self.width * 452 / 624)
                .scaleEffect(refreshing && !reduceMotion ? (breathing ? 1.08 : 0.95) : 0.72 + 0.28 * eased)
                .animation(
                    refreshing && !reduceMotion
                        ? .easeInOut(duration: 0.85).repeatForever(autoreverses: true)
                        : .easeOut(duration: 0.18),
                    value: breathing)

            SplashWordmark(visible: refreshing, reduceMotion: reduceMotion)
                .frame(width: Self.width, height: Self.width * 96 / 624)
        }
        .opacity(refreshing ? 1 : Double(progress))
        .onChange(of: refreshing) { _, now in breathing = now }
        .accessibilityHidden(true)
    }
}

extension View {
    /// `refreshable` yerine; Vubes Club monogramıyla yenileme göstergesi.
    func logoRefreshable(_ action: @escaping @MainActor () async -> Void) -> some View {
        modifier(LogoRefreshModifier(action: action))
    }
}
