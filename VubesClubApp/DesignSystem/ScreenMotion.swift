import SwiftUI

enum ScreenMotion {
    case navigation
    case sheet

    fileprivate var travel: CGSize {
        switch self {
        case .navigation: CGSize(width: 10, height: 0)
        case .sheet: CGSize(width: 0, height: 10)
        }
    }

    fileprivate var duration: Double {
        switch self {
        case .navigation: 0.34
        case .sheet: 0.32
        }
    }
}

extension View {
    func screenMotion(_ motion: ScreenMotion) -> some View {
        modifier(ScreenMotionModifier(motion: motion))
    }
}

private struct ScreenMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let motion: ScreenMotion

    @State private var entrance = 0

    func body(content: Content) -> some View {
        let travel = reduceMotion ? .zero : motion.travel
        let duration = reduceMotion ? 0.16 : motion.duration

        return content
            .keyframeAnimator(initialValue: 1.0, trigger: entrance) { view, progress in
                view
                    .opacity(0.86 + 0.14 * progress)
                    .offset(
                        x: travel.width * (1 - progress),
                        y: travel.height * (1 - progress)
                    )
            } keyframes: { _ in
                MoveKeyframe(0.0)
                CubicKeyframe(1.0, duration: duration)
            }
            .task {
                entrance += 1
            }
    }
}
