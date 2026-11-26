import SwiftUI

struct ItineraryView: View {
    @ScaledMetric(relativeTo: .body) private var timeWidth = 51.0

    let days: [ProgramDay]

    @State private var selectedDay = 0

    var body: some View {
        if !days.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    ScreenTitle("Itinerary", size: 30)
                    Spacer()
                    Overline(L("%d sessions", days[selectedDay].sessions.count), color: Afterglow.accent)
                }

                HStack(spacing: 7) {
                    ForEach(days.indices, id: \.self) { index in
                        Button {
                            selectedDay = index
                        } label: {
                            Pill(title: L("Day %d", index + 1), selected: index == selectedDay)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .sensoryFeedback(ClubHaptics.selection, trigger: selectedDay)

                Hairline().padding(.top, 3)

                let sessions = days[selectedDay].sessions

                VStack(spacing: 0) {
                    ForEach(sessions) { session in
                        timelineRow(session, connectsToNext: session.id != sessions.last?.id)
                    }
                }
                .padding(13)
                .background(Afterglow.surface, in: .rect(cornerRadius: 16))
                .overlay { RoundedRectangle(cornerRadius: 16).strokeBorder(Afterglow.border) }
            }
        }
    }

    private func timelineRow(_ session: ProgramSession, connectsToNext: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(session.time)
                .font(Afterglow.medium(12))
                .monospacedDigit()
                .foregroundStyle(Afterglow.ivory)
                .frame(width: timeWidth)
                .padding(.vertical, 5)
                .background(Afterglow.background, in: .rect(cornerRadius: 6))

            Circle()
                .fill(Afterglow.accent)
                .frame(width: 8, height: 8)
                .padding(.top, 8)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(L(session.title)).font(Afterglow.medium(14))

                Text(L(session.details))
                    .font(Afterglow.body(11.2, relativeTo: .caption))
                    .foregroundStyle(Afterglow.muted)
            }

            Spacer(minLength: 0)
        }
        .frame(minHeight: 57, alignment: .top)
        .fixedSize(horizontal: false, vertical: true)
        .background(alignment: .topLeading) {
            if connectsToNext {
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Afterglow.accent.opacity(0.4))
                        .frame(width: 1, height: geometry.size.height)
                        .offset(x: timeWidth + 13.5, y: 12)
                }
                .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
