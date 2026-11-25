import SwiftUI

struct MyEventsScreen: View {
    @Environment(DemoSession.self) private var session

    @State private var showingPast = false
    @State private var selectedPass: ClubEvent?

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
                    EventListRow(event: DemoCatalog.past)
                } else {
                    if session.upcomingBookings.isEmpty {
                        Text("Your confirmed bookings will appear here.")
                            .font(Afterglow.body(13))
                            .foregroundStyle(Afterglow.muted)
                    }

                    ForEach(session.upcomingBookings) { event in
                        VStack(spacing: 5) {
                            EventCover(event: event, height: 230, confirmed: true, compactTitle: true)
                            passButton(event)
                        }
                    }

                    ScreenTitle("Happening now", size: 28)
                    LiveEventCard(event: DemoCatalog.live)
                }
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.top, 5)
            .padding(.bottom, 18)
        }
        .scrollIndicators(.hidden)
        .background(Afterglow.background.ignoresSafeArea())
        .sheet(item: $selectedPass) { event in
            VStack(alignment: .leading, spacing: 18) {
                ScreenTitle("Event pass", size: 35)
                EventPass(event: event)
                PrimaryAction(title: "Done", icon: "checkmark") { selectedPass = nil }
            }
            .padding(22)
            .screenMotion(.sheet)
            .presentationDetents([.medium])
            .presentationBackground(Afterglow.background)
        }
    }

    private func passButton(_ event: ClubEvent) -> some View {
        Button {
            selectedPass = event
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "ticket")
                Text("View event pass").font(Afterglow.medium(13.4))
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
    let event: ClubEvent

    var body: some View {
        NavigationLink(value: ClubRoute.details(event.id)) {
            HStack(spacing: 14) {
                ClubPhoto(name: event.image, radius: 8)
                    .frame(width: 100, height: 129)

                VStack(alignment: .leading, spacing: 10) {
                    Label("In progress", systemImage: "circle.fill")
                        .font(Afterglow.medium(9.5, relativeTo: .caption))
                        .foregroundStyle(Afterglow.green)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(Afterglow.green.opacity(0.12), in: Capsule())

                    Text(event.title)
                        .font(Afterglow.display(22, relativeTo: .title2))
                        .tracking(-0.35)

                    HStack(spacing: 8) {
                        HStack(spacing: -6) {
                            ForEach(DemoCatalog.participants.prefix(3)) { participant in
                                Avatar(image: participant.image, size: 24)
                            }
                        }

                        Text("Open event").font(Afterglow.medium(11.5))
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
        .accessibilityLabel("Open \(event.title), in progress")
    }
}
