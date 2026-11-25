import SwiftUI

struct WelcomeScreen: View {
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let startupPhase: StartupPhase

    var body: some View {
        ZStack {
            ClubPhoto(name: "Dusk")
                .overlay(alignment: .bottom) {
                    GeometryReader { geometry in
                        Afterglow.shade()
                            .frame(height: geometry.size.height * 0.54)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                }
                .overlay(alignment: .top) {
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.14), location: 0),
                            .init(color: .black.opacity(0.14), location: 0.55),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 230)
                }
                .scaleEffect(startupPhase >= .backdrop || reduceMotion ? 1 : 1.07)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Wordmark()
                    .padding(.top, 23)
                    .opacity(isRevealed(at: .brand) ? 1 : 0)
                    .offset(y: isRevealed(at: .brand) || reduceMotion ? 0 : -12)

                Spacer(minLength: 36)

                ViewThatFits(in: .horizontal) {
                    slogan.fixedSize(horizontal: true, vertical: false)
                    slogan
                }
                .padding(.bottom, 52)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Afterglow.ivory.opacity(0.55))
                        .frame(width: 28, height: 1)
                        .scaleEffect(x: isRevealed(at: .headline) || reduceMotion ? 1 : 0.15, y: 1)
                        .offset(y: -22)
                        .accessibilityHidden(true)
                }

                .opacity(isRevealed(at: .headline) ? 1 : 0)
                .offset(y: isRevealed(at: .headline) || reduceMotion ? 0 : 18)

                VStack(spacing: 9) {
                    NavigationLink(value: AccessFlow.Route.signIn(invited: false)) {
                        Text("Sign in")
                            .font(Afterglow.medium(14))
                            .foregroundStyle(Afterglow.background)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Afterglow.ivory, in: .rect(cornerRadius: 8))
                            .overlay(alignment: .trailing) {
                                Image(systemName: "arrow.right")
                                    .foregroundStyle(Afterglow.background)
                                    .padding(.trailing, 17)
                                    .accessibilityHidden(true)
                            }
                    }
                    .buttonStyle(.plain)

                    NavigationLink(value: AccessFlow.Route.signIn(invited: true)) {
                        Text("I have an invitation code")
                            .font(Afterglow.medium(13))
                            .foregroundStyle(Afterglow.ivory)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.plain)
                }
                .opacity(isRevealed(at: .actions) ? 1 : 0)
                .offset(y: isRevealed(at: .actions) || reduceMotion ? 0 : 16)
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.bottom, 11)
        }
    }

    private func isRevealed(at phase: StartupPhase) -> Bool {
        startupPhase >= (reduceMotion ? .backdrop : phase)
    }

    private var slogan: some View {
        Text("More than fitness.")
            .font(Afterglow.display(43))
            .tracking(-1.5)
            .multilineTextAlignment(.center)
    }
}
