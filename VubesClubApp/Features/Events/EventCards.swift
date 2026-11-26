import SwiftUI

struct EventCover: View {
    let event: ClubEvent
    let height: CGFloat
    var confirmed = false
    var compactTitle = false

    var body: some View {
        NavigationLink(value: ClubRoute.details(event.id)) {
            ClubPhoto(name: event.image)
                .frame(height: height)
                .overlay(alignment: .bottom) {
                    Afterglow.shade().frame(height: height * 0.67)
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 10) {
                        Overline(
                            "\(L(confirmed ? event.date : event.sport.rawValue))  /  \(L(event.location))",
                            color: Afterglow.ivory
                        )

                        Text(L(confirmed && event.id == DemoCatalog.camp.id
                             ? "Likya Trail & Mobility"
                             : event.title))
                            .font(Afterglow.display(compactTitle ? 28 : 31))
                            .tracking(-0.55)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(16)
                }
                .clipShape(.rect(cornerRadius: 13))
                .foregroundStyle(Afterglow.text)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L(event.title))
        .overlay(alignment: .topLeading) {
            if confirmed {
                Pill(title: "Confirmed", icon: "checkmark", selected: true).padding(11)
            }
        }
        .overlay(alignment: .topTrailing) {
            if !confirmed {
                SaveControl(eventID: event.id).padding(6)
            }
        }
    }
}

struct EventListRow: View {
    @Environment(ClubSession.self) private var session

    let event: ClubEvent

    var body: some View {
        NavigationLink(value: ClubRoute.details(event.id)) {
            HStack(spacing: 15) {
                ClubPhoto(name: event.image, radius: 9)
                    .frame(width: 82, height: 82)

                VStack(alignment: .leading, spacing: 6) {
                    Overline(event.sport.rawValue, color: Afterglow.accent)

                    Text(L(event.title))
                        .font(Afterglow.medium(16))

                    Text("\(L(event.date)) · \(L(event.location))")
                        .font(Afterglow.body(11.3, relativeTo: .caption))
                        .foregroundStyle(Afterglow.muted)

                    let details = [L(event.level.rawValue), event.distance, event.status == .upcoming ? event.priceLabel : nil]
                    Text(details.compactMap { $0 }.joined(separator: " · "))
                        .font(Afterglow.medium(11, relativeTo: .caption))
                        .foregroundStyle(Afterglow.ivory)

                    if let rating = session.rating(for: event) {
                        RatingSummary(rating: rating)
                    }
                }

                Spacer(minLength: 3)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Afterglow.accent)
                    .accessibilityHidden(true)
            }
            .padding(10)
            .background(Afterglow.surface, in: .rect(cornerRadius: 14))
            .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(Afterglow.border.opacity(0.7)) }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
