import SwiftUI

struct AccessFlow: View {
    enum Route: Hashable {
        case signIn
        case signUp
    }

    let startupPhase: StartupPhase

    init(startupPhase: StartupPhase) {
        self.startupPhase = startupPhase
        // Start listening before the first keyboard appears so later screens know its state.
        _ = KeyboardObserver.shared
    }

    var body: some View {
        NavigationStack {
            WelcomeScreen(startupPhase: startupPhase)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .signIn:
                        SignInScreen()
                            .toolbar(.hidden, for: .navigationBar)
                    case .signUp:
                        SignUpScreen()
                            .toolbar(.hidden, for: .navigationBar)
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
        }
        .foregroundStyle(Afterglow.text)
    }
}

/// Tracks whether the software keyboard is up, animated with the keyboard's own timing.
@MainActor
@Observable
final class KeyboardObserver {
    static let shared = KeyboardObserver()

    private(set) var isVisible = false

    private init() {
        let center = NotificationCenter.default
        center.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] note in
            let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
            MainActor.assumeIsolated { self?.set(true, duration: duration) }
        }
        center.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] note in
            let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
            MainActor.assumeIsolated { self?.set(false, duration: duration) }
        }
    }

    private func set(_ visible: Bool, duration: Double) {
        guard visible != isVisible else { return }
        withAnimation(.easeOut(duration: duration)) { isVisible = visible }
    }
}

/// Shared layout for access screens.
///
/// One keyboard rule for every screen: while the keyboard is up the dusk photo collapses, the back button
/// sits on the title row, and the subtitle is hidden. Nothing is scrolled programmatically, so focusing a
/// field never fights the layout; the scroll view only moves if a field genuinely would not fit.
struct AccessLayout<Content: View, Action: View>: View {
    let title: String
    let subtitle: String
    var onBack: (() -> Void)? = nil
    @ViewBuilder var content: Content
    @ViewBuilder var action: Action

    private var keyboard: KeyboardObserver { .shared }

    private let headerHeight: CGFloat = 163

    var body: some View {
        let compact = keyboard.isVisible

        GeometryReader { geometry in
            let safeTop = geometry.safeAreaInsets.top

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ClubPhoto(name: "Dusk")
                        .frame(height: compact ? 0 : headerHeight)
                        .overlay(alignment: .bottom) {
                            Afterglow.shade().frame(height: 100)
                        }
                        .overlay(alignment: .top) {
                            Wordmark(width: 58).padding(.top, 59)
                        }
                        .clipped()
                        .opacity(compact ? 0 : 1)
                        .frame(height: compact ? safeTop + 2 : headerHeight, alignment: .top)

                    VStack(alignment: .leading, spacing: 0) {
                        Hairline()

                        ScreenTitle(title, size: compact ? 34 : 47)
                            .padding(.top, compact ? 4 : 16)
                            .padding(.leading, compact ? 56 : 0)
                            .frame(minHeight: compact ? 44 : 0, alignment: .leading)

                        if !compact {
                            Text(L(subtitle))
                                .font(Afterglow.body(13))
                                .foregroundStyle(Afterglow.muted)
                                .padding(.top, 7)
                        }

                        content
                            .padding(.top, compact ? 14 : 22)
                    }
                    .padding(.horizontal, Afterglow.inset)
                }
                .padding(.bottom, 10)
            }
            .scrollDismissesKeyboard(.interactively)
            .ignoresSafeArea(.container, edges: .top)
            .overlay(alignment: .topLeading) {
                Group {
                    if let onBack {
                        RoundControl(icon: "chevron.left", title: "Back", action: onBack)
                    } else {
                        BackControl()
                    }
                }
                .padding(.leading, 19)
                .padding(.top, compact ? 4 : 45 - safeTop)
            }
        }
        .background(Afterglow.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            action
                .padding(.horizontal, Afterglow.inset)
                .padding(.bottom, 12)
                .background(Afterglow.background)
        }
    }
}
