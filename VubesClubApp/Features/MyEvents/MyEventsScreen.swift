import SwiftUI

struct MyEventsScreen: View {
    @Environment(ClubSession.self) private var session
    @Environment(BookingCenter.self) private var bookings

    @State private var showingPast = false
    @State private var selectedPass: MyBooking?
    @State private var passPayload: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                ScreenTitle("My Events")

                HStack(spacing: 7) {
                    Button { showingPast = false } label: {
                        Pill(title: "Upcoming", selected: !showingPast)
                    }

                    Button { showingPast = true } label: {
                        Pill(title: "Past", selected: showingPast)
                    }
                }
                .buttonStyle(.plain)

                if showingPast {
                    if bookings.past.isEmpty {
                        Text(L("Events you’ve attended will appear here."))
                            .font(Afterglow.body(13))
                            .foregroundStyle(Afterglow.muted)
                    }

                    ForEach(bookings.past) { booking in
                        EventListRow(event: booking.event)
                    }
                } else {
                    let isEmpty = bookings.upcoming.isEmpty && bookings.inProgress.isEmpty

                    if isEmpty && bookings.phase == .failed {
                        ContentUnavailableView {
                            Label(L("Bookings couldn’t be loaded"), systemImage: "wifi.slash")
                        } actions: {
                            Button(L("Try again")) { Task { await bookings.load(session: session) } }
                        }
                    } else if isEmpty && bookings.phase != .loaded {
                        ProgressView().frame(maxWidth: .infinity, minHeight: 120)
                    } else {
                        if bookings.upcoming.isEmpty && bookings.inProgress.isEmpty {
                            Text(L("Your confirmed bookings will appear here."))
                                .font(Afterglow.body(13))
                                .foregroundStyle(Afterglow.muted)
                        }

                        ForEach(bookings.upcoming) { booking in
                            VStack(spacing: 5) {
                                EventCover(event: booking.event, height: 230, confirmed: true, compactTitle: true)
                                passButton(booking)
                            }
                        }

                        if !bookings.inProgress.isEmpty {
                            ScreenTitle("Happening now", size: 28)

                            ForEach(bookings.inProgress) { booking in
                                LiveEventCard(booking: booking)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.top, 5)
            .padding(.bottom, 18)
        }
        .scrollIndicators(.hidden)
        .background(Afterglow.background.ignoresSafeArea())
        .refreshable { await bookings.load(session: session) }
        .task { await bookings.load(session: session) }
        .sheet(item: $selectedPass, onDismiss: { passPayload = nil }) { booking in
            VStack(alignment: .leading, spacing: 18) {
                ScreenTitle("Event pass", size: 35)
                LargePassQR(payload: passPayload, size: 210)
                EventPass(event: booking.event, payload: passPayload)
                PrimaryAction(title: "Done", icon: "checkmark") { selectedPass = nil }
            }
            .padding(22)
            .screenMotion(.sheet)
            .presentationDetents([.large])
            .presentationBackground(Afterglow.background)
            .task { passPayload = await bookings.passPayload(bookingID: booking.bookingID) }
        }
    }

    private func passButton(_ booking: MyBooking) -> some View {
        Button {
            selectedPass = booking
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "ticket")
                Text(L("View event pass")).font(Afterglow.medium(13.4))
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 11))
            }
            .padding(.horizontal, 15)
            .frame(minHeight: 56)
            .background(Afterglow.surface, in: .rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

private struct LiveEventCard: View {
    let booking: MyBooking

    private var event: ClubEvent { booking.event }

    var body: some View {
        NavigationLink(value: ClubRoute.details(event.id)) {
            HStack(spacing: 14) {
                ClubPhoto(name: event.image, radius: 8)
                    .frame(width: 100, height: 129)

                VStack(alignment: .leading, spacing: 10) {
                    Label(L("In progress"), systemImage: "circle.fill")
                        .font(Afterglow.medium(9.5, relativeTo: .caption))
                        .foregroundStyle(Afterglow.green)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(Afterglow.green.opacity(0.12), in: Capsule())

                    Text(L(event.title))
                        .font(Afterglow.display(22, relativeTo: .title2))
                        .tracking(-0.35)

                    HStack(spacing: 8) {
                        HStack(spacing: -6) {
                            ForEach(Array(booking.participants.enumerated()), id: \.offset) { _, participant in
                                Avatar(image: participant.image, size: 24, name: participant.name)
                            }
                        }

                        Text(L("Open event")).font(Afterglow.medium(11.5))
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right").font(.system(size: 12))
                    }
                }
            }
            .padding(9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Afterglow.surface, in: .rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L("Open %@, in progress", L(event.title)))
    }
}
