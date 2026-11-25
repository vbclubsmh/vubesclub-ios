import SwiftUI

struct LiveMyEventsScreen: View {
    let api: ClubAPI
    let isSelected: Bool

    @State private var showingPast = false
    @State private var selectedPass: BookingAPI.Entry?
    @State private var bookings: [BookingAPI.Entry] = []
    @State private var live: [BookingAPI.Entry] = []
    @State private var failure: String?
    @State private var loaded = false

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

                if let failure {
                    Text(failure)
                    Button("Yeniden dene") { Task { await load() } }
                } else if !loaded {
                    ProgressView("Katılımlar yükleniyor…")
                } else {
                    if bookings.isEmpty {
                        Text(showingPast ? "No past events yet." : "Your upcoming bookings will appear here.")
                            .font(Afterglow.body(13))
                            .foregroundStyle(Afterglow.muted)
                    }
                    ForEach(bookings) { row in entry(row) }

                    if !showingPast && !live.isEmpty {
                        ScreenTitle("Happening now", size: 28)
                        ForEach(live) { row in entry(row) }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Afterglow.inset)
            .padding(.top, 5)
            .padding(.bottom, 18)
        }
        .scrollIndicators(.hidden)
        .background(Afterglow.background.ignoresSafeArea())
        .refreshable { await load() }
        .task(id: "\(isSelected)-\(showingPast)") {
            guard isSelected else { return }
            await load()
        }
        .sheet(item: $selectedPass) { row in
            ScrollView {
                LivePassContent(api: api, bookingID: row.id)
                PrimaryAction(title: "Done", icon: "checkmark") { selectedPass = nil }
                    .padding(.horizontal, Afterglow.inset)
            }
            .presentationDetents([.medium, .large])
            .presentationBackground(Afterglow.background)
        }
    }

    private func entry(_ row: BookingAPI.Entry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            NavigationLink(value: ClubRoute.liveBookedDetails(eventId: row.event.id, bookingId: row.id)) {
                VStack(alignment: .leading, spacing: 10) {
                    if let media = row.event.cover { BookingCover(url: media.url) }
                    Overline(row.event.placeLabel)
                    ScreenTitle(row.event.title, size: 28)
                    MetadataLabel(title: BookingAPI.date(row.event.startsAt, in: row.event.timeZone), icon: "calendar")
                    if !row.visibleParticipantPreview.isEmpty {
                        HStack(spacing: -6) {
                            ForEach(Array(row.visibleParticipantPreview.enumerated()), id: \.offset) { _, member in
                                if let url = member.avatar?.url {
                                    Avatar(image: url.absoluteString, size: 26)
                                        .accessibilityLabel(member.displayName)
                                } else {
                                    Text(String(member.displayName.prefix(1)))
                                        .frame(width: 26, height: 26)
                                        .background(Afterglow.border, in: Circle())
                                        .accessibilityLabel(member.displayName)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if row.canShowPass {
                Button { selectedPass = row } label: {
                    Label("View event pass", systemImage: "ticket")
                        .font(Afterglow.medium(14))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Afterglow.surface, in: .rect(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func load() async {
        let past = showingPast
        loaded = false
        failure = nil
        do {
            async let list = BookingAPI.bookings(past ? "past" : "upcoming", api: api)
            let active = past ? [] : try await BookingAPI.bookings("inProgress", api: api)
            let result = try await list
            try Task.checkCancellation()
            guard isSelected, showingPast == past else { return }
            bookings = result
            live = active
            loaded = true
        } catch {
            if !Task.isCancelled && isSelected && showingPast == past { failure = error.localizedDescription }
        }
    }
}
