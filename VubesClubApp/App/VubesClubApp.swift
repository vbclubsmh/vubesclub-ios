import SwiftUI

@main
struct VubesClubApp: App {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var session = ClubSession()
    @State private var startupPhase = StartupPhase.splash

    init() {
        // Yenileme göstergesini logo üstlenir; sistemin döner göstergesi görünmez.
        UIRefreshControl.appearance().tintColor = .clear
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if session.applicationSubmitted {
                    ApplicationSubmittedScreen()
                        .transition(.opacity)
                } else if session.isSignedIn {
                    ClubTabs()
                        .id(session.accountScope)
                        .transition(.opacity)
                } else {
                    AccessFlow(startupPhase: startupPhase)
                        .transition(.opacity)
                }
            }
            .background(Afterglow.background.ignoresSafeArea())
            .animation(.easeInOut(duration: reduceMotion ? 0.16 : 0.34), value: session.isSignedIn)
            .animation(.easeInOut(duration: reduceMotion ? 0.16 : 0.34), value: session.applicationSubmitted)
            .allowsHitTesting(startupPhase == .complete)
            .accessibilityHidden(startupPhase != .complete)
            .overlay {
                if startupPhase != .complete {
                    StartupSplash(phase: $startupPhase)
                }
            }
            .environment(session)
            .task { await session.restore() }
            .preferredColorScheme(.dark)
            .tint(Afterglow.ivory)
        }
    }
}
