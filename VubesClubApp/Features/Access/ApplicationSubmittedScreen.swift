import SwiftUI

struct ApplicationSubmittedScreen: View {
    @Environment(ClubSession.self) private var session
    @State private var appeared = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 22) {
                Spacer()

                ZStack {
                    Circle().stroke(Afterglow.accent, lineWidth: 1).frame(width: 116, height: 116)
                    Circle().fill(Afterglow.accent).frame(width: 82, height: 82)
                    Text("V")
                        .font(Afterglow.display(46))
                        .foregroundStyle(Afterglow.background)
                }

                VStack(spacing: 5) {
                    ScreenTitle("We’ve received your application", size: 37)
                        .multilineTextAlignment(.center)
                    Text(L("We’re reviewing it."))
                        .font(Afterglow.display(31))
                        .italic()
                        .foregroundStyle(Afterglow.accent)
                }

                Text(L("Every application is reviewed by hand. We’ll share the decision when the review is complete."))
                    .font(Afterglow.body(15))
                    .foregroundStyle(Afterglow.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)

                VStack(alignment: .leading, spacing: 17) {
                    statusRow("We’ve received your application", active: true)
                    statusRow("Our team is reviewing it", active: true)
                    statusRow("We’ll share the review decision with you", active: false)
                }
                .padding(.top, 16)

                Spacer()

                PrimaryAction(title: "Back to welcome") {
                    session.dismissApplicationConfirmation()
                }
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            .background(Afterglow.background.ignoresSafeArea())
        }
        .onAppear { appeared = true }
        .sensoryFeedback(.success, trigger: appeared)
    }

    private func statusRow(_ title: String, active: Bool) -> some View {
        HStack(spacing: 14) {
            Circle()
                .stroke(active ? Afterglow.accent : Afterglow.border, lineWidth: 2)
                .frame(width: 15, height: 15)
                .overlay { if active { Circle().fill(Afterglow.accent).frame(width: 6, height: 6) } }
            Text(L(title))
                .font(Afterglow.body(14))
                .foregroundStyle(active ? Afterglow.text : Afterglow.muted)
        }
    }
}
