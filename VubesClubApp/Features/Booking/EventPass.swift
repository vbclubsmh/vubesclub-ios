import SwiftUI

struct EventPass: View {
    let event: ClubEvent

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "qrcode")
                .font(.system(size: 48))
                .foregroundStyle(Afterglow.ivory)
                .frame(width: 80)
                .accessibilityHidden(true)

            Rectangle()
                .fill(Afterglow.border)
                .frame(width: 1)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 7) {
                Overline("Event pass")

                Text(event.title).font(Afterglow.medium(13.3))

                Text([event.date, event.program.first?.sessions.first?.time, event.meetingPoint]
                    .compactMap { $0 }.joined(separator: " · "))
                    .font(Afterglow.body(11, relativeTo: .caption))
                    .foregroundStyle(Afterglow.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 13)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 108)
        .fixedSize(horizontal: false, vertical: true)
        .background(Afterglow.surface, in: .rect(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(Afterglow.border) }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Illustrative pass")
    }
}
