import SwiftUI

/// Club: üyenin takip ettiği veya Studio'da bağlandığı PT'lerin etkinlik akışı.
struct ClubScreen: View {
    @Environment(ClubSession.self) private var session
    @Environment(EventCatalog.self) private var catalog

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                LogoRefreshProbe()

                VStack(alignment: .leading, spacing: 7) {
                    Overline("The people behind the sessions", color: Afterglow.accent)
                    ScreenTitle("Club")

                    Text(L("Your trainers’ next sessions, in one place."))
                        .font(Afterglow.body(13))
                        .foregroundStyle(Afterglow.muted)
                }

                content
            }
            .padding(.horizontal, Afterglow.inset)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .logoRefreshable { await catalog.loadFeed(session: session) }
        .task { await catalog.loadFeed(session: session) }
        .background(Afterglow.background.ignoresSafeArea())
    }

    @ViewBuilder
    private var content: some View {
        switch catalog.feedPhase {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 240)
                .accessibilityLabel(L("Loading Club"))
        case .failed:
            ContentUnavailableView {
                Label(L("Club couldn’t be loaded"), systemImage: "wifi.slash")
            } description: {
                Text(L("Check your connection and try again."))
            } actions: {
                Button(L("Try again")) { Task { await catalog.loadFeed(session: session) } }
            }
        case .loaded, .locked:
            feed
        }
    }

    private var feed: some View {
        VStack(alignment: .leading, spacing: 20) {
            allTrainers

            VStack(alignment: .leading, spacing: 10) {
                Overline(catalog.feed.trainers.isEmpty ? "Coming up" : "For you", color: Afterglow.accent)

                if catalog.feed.forYou.isEmpty {
                    Text(L("No upcoming events yet."))
                        .font(Afterglow.body(13))
                        .foregroundStyle(Afterglow.muted)
                }

                ForEach(catalog.feed.forYou) { item in
                    FeedEventCard(item: item)
                }
            }

            if !catalog.feed.rated.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Hairline()
                    ScreenTitle("Rated experiences", size: 26)

                    ForEach(catalog.feed.rated) { item in
                        EventListRow(event: item.event)
                    }
                }
            }
        }
    }

    /// Takip edilen veya Studio'da bağlanan PT'ler başta.
    private var sortedTrainers: [ClubTrainer] {
        let mine = Set(catalog.feed.trainers.map(\.trainer.id)).union(session.connectedTrainerIDs)
        return catalog.directory.sorted { (mine.contains($0.id) ? 0 : 1) < (mine.contains($1.id) ? 0 : 1) }
    }

    private func isMine(_ trainer: ClubTrainer) -> Bool {
        session.connectedTrainerIDs.contains(trainer.id) || catalog.feed.trainers.contains { $0.trainer.id == trainer.id }
    }

    private var allTrainers: some View {
        VStack(alignment: .leading, spacing: 10) {
            Overline("All trainers", color: Afterglow.accent)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(sortedTrainers) { trainer in
                        NavigationLink(value: ClubRoute.trainer(trainer.id)) {
                            VStack(spacing: 6) {
                                Avatar(image: trainer.image, size: 52,
                                       selected: isMine(trainer), name: trainer.name)

                                Text(trainer.name.split(separator: " ").first.map(String.init) ?? trainer.name)
                                    .font(Afterglow.medium(11, relativeTo: .caption))
                                    .foregroundStyle(Afterglow.text)
                                    .lineLimit(1)

                                Text(L(trainer.specialty))
                                    .font(Afterglow.body(10, relativeTo: .caption2))
                                    .foregroundStyle(Afterglow.muted)
                                    .lineLimit(1)
                            }
                            .frame(width: 96)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(trainer.name), \(L(trainer.specialty))")
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}

/// Akıştaki etkinlik: kapak, ad, tarih ve organizatör etiketi.
struct FeedEventCard: View {
    let item: FeedEvent

    var body: some View {
        let event = item.event

        NavigationLink(value: ClubRoute.details(event.id)) {
            VStack(alignment: .leading, spacing: 0) {
                ClubPhoto(name: event.image)
                    .frame(height: 124)

                VStack(alignment: .leading, spacing: 7) {
                    Text(L(event.title))
                        .font(Afterglow.medium(16))
                        .foregroundStyle(Afterglow.text)

                    HStack(spacing: 8) {
                        Text("\(event.displayDate) · \(L(event.location))")
                            .font(Afterglow.body(11.5, relativeTo: .caption))
                            .foregroundStyle(Afterglow.muted)
                            .lineLimit(1)

                        Spacer(minLength: 4)

                        HStack(spacing: 5) {
                            Avatar(image: item.organizerImage, size: 18, name: item.organizer)
                            Text(item.organizer.split(separator: " ").first.map(String.init) ?? item.organizer)
                                .font(Afterglow.medium(11, relativeTo: .caption))
                                .foregroundStyle(Afterglow.ivory)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(12)
            }
            .background(Afterglow.surface, in: .rect(cornerRadius: 14))
            .clipShape(.rect(cornerRadius: 14))
            .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(Afterglow.border.opacity(0.8)) }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
