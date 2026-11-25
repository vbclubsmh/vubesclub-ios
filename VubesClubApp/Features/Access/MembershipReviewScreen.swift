import SwiftUI

struct MembershipReviewScreen: View {
    @Environment(DemoSession.self) private var session
    @Environment(\.scenePhase) private var scenePhase
    @State private var checking = false

    private var title: String {
        switch session.membership?.nextAction {
        case "restricted": "Your membership is restricted"
        case "applicationClosed": "Your application is closed"
        default: "Your membership is under review"
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {

                        Spacer()
                        Wordmark(width: 52)
                    }

                    Spacer(minLength: 52)

                    Rectangle()
                        .fill(Afterglow.ivory.opacity(0.58))
                        .frame(width: 32, height: 1)
                        .accessibilityHidden(true)

                    Overline("Membership review", color: Afterglow.ivory)

                    ScreenTitle(title, size: 48)
                        .lineSpacing(-2)
                        .foregroundStyle(Afterglow.text)

                    Text(session.membership?.nextAction == "review"
                         ? "The Club will review your membership before granting access."
                         : "Contact the Club for more information about your membership.")
                        .font(Afterglow.body(14))
                        .foregroundStyle(Afterglow.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, Afterglow.inset)
                .padding(.vertical, 22)
                .frame(minHeight: geometry.size.height, alignment: .topLeading)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 12) {
                if let error = session.restoreError { Text(error).font(Afterglow.body(12)) }
                PrimaryAction(title: "Check membership status") { checking = true }
                    .disabled(checking)
                Button("Sign out") { session.signOut() }
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.bottom, 11)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { checking = true }
        }
        .task(id: checking) {
            if checking {
                await session.restore()
                checking = false
            }
        }
        .background {
            ClubPhoto(name: session.appearance?.reviewCover?.url ?? session.appearance?.welcomeCover.url ?? "")
                .overlay {
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.48), location: 0),
                            .init(color: .clear, location: 0.33),
                            .init(color: Afterglow.background.opacity(0.85), location: 0.66),
                            .init(color: Afterglow.background, location: 0.94)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea()
        }
    }
}
