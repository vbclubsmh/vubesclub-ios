import SwiftUI

struct LiveDetailsScreen: View {
    let api: ClubAPI
    let eventID: String
    var bookingID: String?

    @Environment(LiveCatalogState.self) private var catalog
    @State private var detail: CatalogDetail?
    @State private var error: String?
    @State private var ratingError: String?
    @State private var submitting = false
    @State private var generation = UUID()
    @State private var showsPreparation = false
    @ScaledMetric(relativeTo: .largeTitle) private var heroHeight = 283.0

    var body: some View {
        Group {
            if let detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        hero(detail.event)
                        VStack(alignment: .leading, spacing: 19) {
                            HStack {
                                MetadataLabel(title: detail.event.dateLabel, icon: "calendar")
                                Spacer()
                                MetadataLabel(title: catalog.levelLabel(detail.event.level), icon: "mountain.2")
                            }
                            if !detail.additionalSports.isEmpty {
                                MetadataLabel(title: detail.additionalSports.map(\.label).joined(separator: " · "), icon: "figure.run")
                            }
                            Hairline()
                            if detail.viewer.canViewActivityMap {
                                NavigationLink(value: ClubRoute.activityMap(eventID)) {
                                    Label("Open activity map", systemImage: "map")
                                        .frame(maxWidth: .infinity, minHeight: 48)
                                        .background(Afterglow.surface, in: .rect(cornerRadius: 12))
                                }
                            }
                            ItineraryView(days: program(detail)).id(detail.programVersion)
                            LiveTrainerCard(api: api, trainer: detail.organizer)
                            ratings(detail)
                            Hairline()
                            DisclosureGroup("Preparation & meeting point", isExpanded: $showsPreparation) {
                                VStack(alignment: .leading, spacing: 9) {
                                    if let preparation = detail.preparation { Text(preparation) }
                                    Text("Meeting point: \(detail.meetingPoint.label)")
                                    if let directions = detail.meetingPoint.directions { Text(directions) }
                                    if let transport = detail.transportNotes { Text(transport) }
                                    if let stay = detail.accommodation { Text(stay) }
                                }
                                .font(Afterglow.body(12))
                                .foregroundStyle(Afterglow.muted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 8)
                            }
                            if let error {
                                Text(error).font(.footnote)
                                Button("Retry") { Task { await load() } }
                            }
                        }
                        .padding(.horizontal, Afterglow.inset)
                        .padding(.vertical, 15)
                    }
                }
                .scrollIndicators(.hidden)
                .refreshable { await load() }
                .ignoresSafeArea(.container, edges: .top)
                .safeAreaInset(edge: .bottom) { bookingBar(detail) }
            } else {
                VStack(spacing: 16) {
                    HStack { BackControl(); Spacer() }
                    Spacer()
                    if let error {
                        Text(error)
                        Button("Retry") { Task { await load() } }
                    } else {
                        ProgressView()
                    }
                    Spacer()
                }
                .padding()
            }
        }
        .background(Afterglow.background.ignoresSafeArea())
        .task(id: catalog.revision) { await load() }
    }

    private func hero(_ event: CatalogCard) -> some View {
        ClubPhoto(name: event.image)
            .frame(height: heroHeight)
            .overlay(alignment: .bottom) { Afterglow.shade().frame(height: heroHeight * 0.64) }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 8) {
                    Overline("\(event.primarySport.label) / \(event.placeLabel)", color: Afterglow.ivory)
                    ScreenTitle(event.title, size: 36)
                }
                .padding(.horizontal, Afterglow.inset)
                .padding(.bottom, 8)
            }
            .overlay(alignment: .top) {
                HStack {
                    BackControl()
                    Spacer()
                    CatalogSaveControl(api: api, event: event)
                }
                .padding(.horizontal, 19)
                .padding(.top, 46)
            }
    }

    private func program(_ detail: CatalogDetail) -> [ProgramDay] {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: detail.event.timeZone) ?? .gmt
        formatter.dateFormat = "HH:mm"
        return detail.days.map { day in
            ProgramDay(sessions: day.sessions.map {
                ProgramSession(time: formatter.string(from: $0.startsAt), title: $0.title, details: $0.details, serverID: $0.id)
            })
        }
    }

    @ViewBuilder
    private func ratings(_ detail: CatalogDetail) -> some View {
        if detail.event.phase == "past" {
            VStack(alignment: .leading, spacing: 11) {
                ScreenTitle("Member ratings", size: 27)
                if let summary = detail.event.rating, let average = summary.average {
                    Label("\(average.formatted(.number.precision(.fractionLength(1)))) · \(summary.count) ratings",
                          systemImage: "star.fill")
                } else {
                    Text("No published ratings yet").font(.footnote)
                }

                if detail.viewer.canRate {
                    Text("Your rating").font(Afterglow.medium(12))
                    HStack {
                        ForEach(1...5, id: \.self) { stars in
                            Button {
                                Task { await rate(stars) }
                            } label: {
                                Image(systemName: stars <= (detail.viewer.myRating?.stars ?? 0) ? "star.fill" : "star")
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                            .accessibilityLabel("Rate \(stars) out of 5")
                        }
                    }
                    .disabled(submitting)
                    if let mine = detail.viewer.myRating, mine.moderation == "pending" {
                        Text("Your rating is awaiting review.").font(.footnote)
                    }
                    if let ratingError { Text(ratingError).font(.footnote) }
                }
            }
            .padding(15).frame(maxWidth: .infinity, alignment: .leading)
            .background(Afterglow.surface, in: .rect(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private func bookingBar(_ detail: CatalogDetail) -> some View {
        if let route = primaryRoute(detail) {
            NavigationLink(value: route) {
                Text(detail.viewer.primary == "viewPass" ? "View event pass" :
                        (detail.viewer.primary == "resumeCheckout" ? "Resume checkout" : "Join event"))
                    .font(Afterglow.medium(14))
                    .foregroundStyle(Afterglow.background)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Afterglow.ivory, in: .rect(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Afterglow.inset)
            .padding(.bottom, 5)
            .background(Afterglow.background)
        }
    }

    private func primaryRoute(_ detail: CatalogDetail) -> ClubRoute? {
        switch detail.viewer.primary {
        case "viewPass":
            detail.viewer.bookingId.map { .liveConfirmation(bookingId: $0) }
        case "join", "resumeCheckout":
            .liveCheckout(eventId: detail.event.id, programVersion: detail.programVersion, holdId: detail.viewer.holdId)
        default:
            nil
        }
    }

    private func load() async {
        let token = UUID()
        generation = token
        do {
            let query = bookingID.map { "?bookingId=\($0)" } ?? ""
            let item = try await api.get("events/\(eventID)" + query, as: CatalogDetail.self)
            try Task.checkCancellation()
            if generation == token {
                detail = item
                error = nil
            }
        } catch {
            if !Task.isCancelled && generation == token { self.error = error.localizedDescription }
        }
    }

    private func rate(_ stars: Int) async {
        guard !submitting else { return }
        submitting = true
        ratingError = nil
        defer { submitting = false }
        do {
            try await api.sendEmpty("PUT", "events/\(eventID)/me/rating", body: ["stars": stars])
            await load()
        } catch { ratingError = error.localizedDescription }
    }
}
