import SwiftUI

struct RatingSummary: View {
    let rating: EventRating

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .foregroundStyle(Afterglow.accent)
                .accessibilityHidden(true)

            Text(rating.averageLabel)
                .foregroundStyle(Afterglow.ivory)
                .monospacedDigit()

            Text(L("· %d ratings", rating.count))
                .foregroundStyle(Afterglow.muted)
        }
        .font(Afterglow.medium(12, relativeTo: .caption))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L("%@ out of 5, %d ratings", rating.averageLabel, rating.count))
    }
}

struct EventRatingSection: View {
    @Environment(ClubSession.self) private var session

    let event: ClubEvent

    var body: some View {
        if let rating = session.rating(for: event) {
            VStack(alignment: .leading, spacing: 11) {
                ScreenTitle("Member ratings", size: 27)
                RatingSummary(rating: rating)

                if session.canRate(event) {
                    Text(L("Your rating"))
                        .font(Afterglow.medium(12))
                        .foregroundStyle(Afterglow.muted)

                    let selected = session.eventRatings[event.id] ?? 0

                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { stars in
                            Button {
                                session.rate(event, stars: stars)
                            } label: {
                                Image(systemName: stars <= selected ? "star.fill" : "star")
                                    .font(.system(size: 19))
                                    .foregroundStyle(Afterglow.accent)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(L("Rate %d out of 5", stars))
                            .accessibilityAddTraits(stars == selected ? .isSelected : [])
                        }
                    }
                    .sensoryFeedback(ClubHaptics.selection, trigger: selected)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(15)
            .background(Afterglow.surface, in: .rect(cornerRadius: 14))
        }
    }
}
