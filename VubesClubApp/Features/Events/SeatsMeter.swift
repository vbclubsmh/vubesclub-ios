import SwiftUI

/// Kontenjan göstergesi: doluluk çubuğu ve kalan yer. Değerler sunucudan canlı gelir.
struct SeatsMeter: View {
    let seats: EventSeats

    private var tint: Color {
        seats.isFull ? Afterglow.muted : seats.isLow ? Afterglow.accent : Afterglow.ivory
    }

    private var status: String {
        if seats.isFull { return L("Fully booked") }
        if seats.isLow { return L("Last %d spots", seats.remaining) }
        return L("%d spots left", seats.remaining)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline) {
                Overline("Capacity", color: Afterglow.accent)

                Spacer(minLength: 8)

                Text(status)
                    .font(Afterglow.medium(12.5, relativeTo: .caption))
                    .foregroundStyle(tint)
                    .contentTransition(.numericText())
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Afterglow.border.opacity(0.55))

                    Capsule()
                        .fill(tint)
                        .frame(width: max(6, proxy.size.width * seats.fraction))
                }
            }
            .frame(height: 5)

            Text(L("%d of %d spots taken", seats.taken, seats.capacity))
                .font(Afterglow.body(11.5, relativeTo: .caption))
                .foregroundStyle(Afterglow.muted)
        }
        .padding(14)
        .background(Afterglow.surface, in: .rect(cornerRadius: 14))
        .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(Afterglow.border.opacity(0.7)) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(L("Capacity")): \(L("%d of %d spots taken", seats.taken, seats.capacity)), \(status)")
        .animation(.easeOut(duration: 0.4), value: seats)
    }
}
