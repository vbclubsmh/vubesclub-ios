import SwiftUI

/// Club: üyenin takip ettiği veya Studio'da bağlandığı PT'lerin etkinlik akışı.
struct ClubScreen: View {
    @Environment(ClubSession.self) private var session
    @Environment(EventCatalog.self) private var catalog

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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
        .refreshable { await catalog.loadFeed(session: session) }
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
        case .locked:
            ContentUnavailableView(
                L("Club opens after your first booking"),
                systemImage: "lock",
                description: Text(L("Trainers, crews and ratings are available to members with a confirmed booking."))
            )
        case .failed:
            ContentUnavailableView {
                Label(L("Club couldn’t be loaded"), systemImage: "wifi.slash")
            } description: {
                Text(L("Check your connection and try again."))
            } actions: {
                Button(L("Try again")) { Task { await catalog.loadFeed(session: session) } }
            }
        case .loaded:
            if catalog.feed.trainers.isEmpty {
                ContentUnavailableView {
                    Label(L("No trainers yet"), systemImage: "person.2")
                } description: {
                    Text(L("Follow a trainer, or ask the club to connect you with one."))
                } actions: {
                    NavigationLink(value: ClubRoute.trainerDirectory) { Text(L("Discover trainers")) }
                }
            } else {
                feed
            }
        }
    }

    private var feed: some View {
        VStack(alignment: .leading, spacing: 20) {
            trainerStrip

            VStack(alignment: .leading, spacing: 10) {
                Overline("For you", color: Afterglow.accent)

                if catalog.feed.forYou.isEmpty {
                    Text(L("No upcoming events from your trainers yet."))
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

    private var trainerStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Overline("Your trainers", color: Afterglow.accent)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(catalog.feed.trainers) { item in
                        NavigationLink(value: ClubRoute.trainer(item.trainer.id)) {
                            VStack(spacing: 6) {
                                Avatar(image: item.trainer.image, size: 52, selected: true, name: item.trainer.name)

                                Text(item.trainer.name.split(separator: " ").first.map(String.init) ?? item.trainer.name)
                                    .font(Afterglow.medium(11, relativeTo: .caption))
                                    .foregroundStyle(Afterglow.muted)
                                    .lineLimit(1)
                            }
                            .frame(minWidth: 56)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(item.trainer.name)
                    }

                    NavigationLink(value: ClubRoute.trainerDirectory) {
                        VStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 17))
                                .foregroundStyle(Afterglow.ivory)
                                .frame(width: 52, height: 52)
                                .overlay { Circle().strokeBorder(Afterglow.border, style: StrokeStyle(lineWidth: 1, dash: [3, 3])) }

                            Text(L("Discover"))
                                .font(Afterglow.medium(11, relativeTo: .caption))
                                .foregroundStyle(Afterglow.muted)
                        }
                        .frame(minWidth: 56)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L("Discover trainers"))
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
