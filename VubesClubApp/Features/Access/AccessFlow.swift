import SwiftUI

struct AccessFlow: View {
    enum Route: Hashable {
        case signIn(invited: Bool)
    }

    let startupPhase: StartupPhase

    var body: some View {
        NavigationStack {
            WelcomeScreen(startupPhase: startupPhase)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .signIn(let invited):
                        SignInScreen(invited: invited)
                            .toolbar(.hidden, for: .navigationBar)
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
        }
        .foregroundStyle(Afterglow.text)
    }
}

struct AccessLayout<Content: View, Action: View>: View {
    @Environment(DemoSession.self) private var session
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content
    @ViewBuilder var action: Action

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ClubPhoto(name: session.appearance?.welcomeCover.url ?? "")
                    .frame(height: 163)
                    .overlay(alignment: .bottom) {
                        Afterglow.shade().frame(height: 100)
                    }
                    .overlay(alignment: .top) {
                        Wordmark(width: 58).padding(.top, 59)
                    }
                    .overlay(alignment: .topLeading) {
                        BackControl()
                            .padding(.leading, 19)
                            .padding(.top, 45)
                    }

                VStack(alignment: .leading, spacing: 0) {
                    Hairline()

                    ScreenTitle(title, size: 47)
                        .padding(.top, 16)

                    Text(subtitle)
                        .font(Afterglow.body(13))
                        .foregroundStyle(Afterglow.muted)
                        .padding(.top, 7)

                    content
                        .padding(.top, 22)
                }
                .padding(.horizontal, Afterglow.inset)
            }
            .padding(.bottom, 10)
        }
        .scrollDismissesKeyboard(.interactively)
        .ignoresSafeArea(.container, edges: .top)
        .background(Afterglow.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            action
                .padding(.horizontal, Afterglow.inset)
                .padding(.bottom, 12)
                .background(Afterglow.background)
        }
    }
}
