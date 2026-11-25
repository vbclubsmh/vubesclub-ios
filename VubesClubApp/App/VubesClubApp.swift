import SwiftUI

@main
struct VubesClubApp: App {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @State private var session = DemoSession()
    @State private var startupPhase = StartupPhase.splash

    var body: some Scene {
        WindowGroup {
            ZStack {
                if session.isRestoring {
                    ProgressView().accessibilityLabel("Checking your membership")
                } else if let error = session.restoreError, session.membership == nil {
                    ContentUnavailableView {
                        Label("Session unavailable", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Try again") { Task { await session.restore() } }
                        Button("Sign out") { session.signOut() }
                    }
                } else if session.isSignedIn {
                    ClubTabs()
                        .id(session.accountScope)
                        .transition(.opacity)
                } else if session.membership != nil {
                    MembershipReviewScreen()
                } else {
                    AccessFlow(startupPhase: startupPhase)
                        .transition(.opacity)
                }
            }
            .background(Afterglow.background.ignoresSafeArea())
            .animation(.easeInOut(duration: reduceMotion ? 0.16 : 0.34), value: session.isSignedIn)
            .allowsHitTesting(startupPhase == .complete)
            .accessibilityHidden(startupPhase != .complete)
            .overlay {
                if startupPhase != .complete {
                    StartupSplash(phase: $startupPhase)
                }
            }
            .task {
                await session.loadAppearance()
                if session.isRestoring { await session.restore() }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active && session.appearance == nil {
                    Task { await session.loadAppearance() }
                }
            }
            .environment(session)
            .preferredColorScheme(.dark)
            .tint(Afterglow.ivory)
        }
    }
}
