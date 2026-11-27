import CoreLocation
import Foundation
import Observation

// MARK: Mapping (API → screen models)

extension ClubEvent {
    /// Kapak yoksa sporun varsayılan görseli, o da yoksa uygulama içi bir görsel.
    init(card: APIEventCard, trainerID: String = "") {
        let status: EventStatus = switch card.phase {
        case "inProgress": .inProgress
        case "past": .past
        default: .upcoming
        }
        let distance = card.distanceMeters.map { meters in
            meters >= 1000
                ? "\((Double(meters) / 1000).formatted(.number.precision(.fractionLength(0...1)))) km"
                : "\(meters) m"
        }

        self.init(
            id: card.id.uuidString.lowercased(),
            title: card.title,
            location: card.placeLabel,
            date: "",
            sport: Sport(code: card.primarySport.code),
            level: EventLevel(code: card.level),
            image: card.cover?.url ?? card.primarySport.fallbackCover?.url ?? "Forest",
            price: card.price.amountMinor / 100,
            program: [],
            status: status,
            trainerID: trainerID,
            meetingCoordinate: card.position.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) },
            distance: distance,
            meetingPoint: card.placeLabel,
            preparation: "",
            rating: card.rating.flatMap { summary in
                summary.average.map { EventRating(total: Int(($0 * Double(summary.count)).rounded()), count: summary.count) }
            },
            startsAt: card.startsAt,
            endsAt: card.endsAt,
            timeZoneID: card.timeZone)
    }

    /// Program, buluşma noktası ve organizatör ile zenginleştirilmiş sürüm.
    init(detail: APIEventDetail) {
        var base = ClubEvent(card: detail.event, trainerID: detail.organizer.id.uuidString.lowercased())
        let zone = TimeZone(identifier: detail.event.timeZone) ?? .current
        let clock = DateFormatter()
        clock.locale = Locale(identifier: "en_US_POSIX")
        clock.timeZone = zone
        clock.dateFormat = "HH:mm"

        let days = detail.days.map { day in
            ProgramDay(sessions: day.sessions.map {
                ProgramSession(time: clock.string(from: $0.startsAt), title: $0.title, details: $0.details,
                               serverID: $0.id.uuidString.lowercased())
            })
        }
        let lodging = detail.accommodation.flatMap { $0.isEmpty ? nil : $0 }

        base = ClubEvent(
            id: base.id, title: base.title, location: base.location, date: base.date, sport: base.sport,
            level: base.level, image: base.image, price: base.price, program: days, status: base.status,
            trainerID: base.trainerID, accommodation: lodging, isCamp: lodging != nil,
            meetingCoordinate: detail.meetingPoint.position.map {
                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
            } ?? base.meetingCoordinate,
            distance: base.distance, meetingPoint: detail.meetingPoint.label,
            preparation: [detail.preparation, detail.transportNotes].compactMap { $0 }
                .filter { !$0.isEmpty }.joined(separator: "\n"),
            rating: base.rating, gallery: (detail.gallery ?? []).map(\.url),
            startsAt: base.startsAt, endsAt: base.endsAt, timeZoneID: base.timeZoneID)
        self = base
    }
}

extension EventLevel {
    init(code: String) {
        switch code {
        case "hard": self = .hard
        case "moderate": self = .moderate
        default: self = .easy
        }
    }
}

extension ClubTrainer {
    init(card: APITrainerCard, crew: APICrew? = nil) {
        self.init(
            id: card.id.uuidString.lowercased(),
            name: card.displayName,
            specialty: card.specialty,
            experience: card.experienceText,
            location: card.locationLabel,
            image: card.avatar?.url ?? "",
            cover: card.cover?.url ?? "",
            bio: card.bio,
            crewName: crew?.name ?? "",
            crew: (crew?.members ?? []).map { CrewMember(name: $0.displayName, image: $0.avatar?.url ?? "") })
    }
}

// MARK: Club content

struct FeedTrainer: Identifiable {
    var id: String { trainer.id }

    let trainer: ClubTrainer
    /// `following`, `linked` veya `both`.
    let source: String
}

struct FeedEvent: Identifiable {
    var id: String { event.id }

    let event: ClubEvent
    let organizer: String
    let organizerImage: String
    let organizerID: String
}

struct ClubFeedContent {
    var trainers: [FeedTrainer] = []
    var forYou: [FeedEvent] = []
    var rated: [FeedEvent] = []
}

struct TrainerContent {
    let trainer: ClubTrainer
    let upcoming: [ClubEvent]
    let rated: [ClubEvent]
}

// MARK: Store

/// Sunucudaki etkinlikleri ve Club akışını tutar; ekranlar buradan okur.
@MainActor
@Observable
final class EventCatalog {
    enum Phase { case idle, loading, loaded, failed }
    enum FeedPhase { case idle, loading, loaded, locked, failed }

    private(set) var phase = Phase.idle
    private(set) var all: [ClubEvent] = []
    private(set) var feed = ClubFeedContent()
    private(set) var feedPhase = FeedPhase.idle

    private var detailed: [String: ClubEvent] = [:]
    private var trainers: [String: ClubTrainer] = [:]
    private let api: ClubAPI

    init(api: ClubAPI = .shared) {
        self.api = api
    }

    var upcoming: [ClubEvent] { all.filter { $0.status == .upcoming } }

    func event(_ id: String) -> ClubEvent? {
        detailed[id] ?? all.first { $0.id == id }
    }

    func trainer(_ id: String) -> ClubTrainer? {
        trainers[id]
    }

    // MARK: Events

    func load(session: ClubSession) async {
        guard phase != .loading else { return }

        phase = .loading
        do {
            var cards: [APIEventCard] = []
            var cursor: String?
            repeat {
                var path = "events?limit=100"
                if let cursor, let encoded = cursor.addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
                    path += "&cursor=" + encoded
                }
                let page = try await api.get(path, as: APIEventPage.self)
                cards += page.items
                cursor = page.nextCursor
            } while cursor != nil && cards.count < 500

            all = cards.filter { $0.phase != "cancelled" }
                .sorted { $0.startsAt < $1.startsAt }
                .map { ClubEvent(card: $0) }
            session.adoptSaved(Set(cards.filter(\.isSaved).map { $0.id.uuidString.lowercased() }))
            phase = .loaded
        } catch is CancellationError {
            phase = all.isEmpty ? .idle : .loaded
        } catch {
            phase = .failed
        }
    }

    func loadDetail(id: String) async {
        guard let detail = try? await api.get("events/\(id)", as: APIEventDetail.self) else { return }

        detailed[id] = ClubEvent(detail: detail)
        trainers[detail.organizer.id.uuidString.lowercased()] = ClubTrainer(card: detail.organizer)
    }

    // MARK: Club

    func loadFeed(session: ClubSession) async {
        guard feedPhase != .loading else { return }

        feedPhase = .loading
        do {
            let remote = try await api.get("club/feed", as: APIClubFeed.self)
            for item in remote.trainers { session.markFollowing(item.trainer.id.uuidString.lowercased(), item.trainer.isFollowed) }
            var content = ClubFeedContent()
            content.trainers = remote.trainers.map {
                let trainer = ClubTrainer(card: $0.trainer)
                trainers[trainer.id] = trainer
                return FeedTrainer(trainer: trainer, source: $0.source)
            }
            content.forYou = remote.forYou.map(feedEvent)
            content.rated = remote.ratedExperiences.map(feedEvent)
            feed = content
            feedPhase = .loaded
        } catch let failure as ClubAPIError {
            if case .server(403, _, _) = failure {
                feed = ClubFeedContent()
                feedPhase = .locked
            } else {
                feedPhase = .failed
            }
        } catch is CancellationError {
            feedPhase = .idle
        } catch {
            feedPhase = .failed
        }
    }

    private func feedEvent(_ item: APIFeedEvent) -> FeedEvent {
        let id = item.organizer.id.uuidString.lowercased()
        return FeedEvent(
            event: ClubEvent(card: item.event, trainerID: id),
            organizer: item.organizer.displayName,
            organizerImage: item.organizer.avatar?.url ?? "",
            organizerID: id)
    }

    func trainerContent(id: String, session: ClubSession) async -> TrainerContent? {
        guard let detail = try? await api.get("club/trainers/\(id)", as: APITrainerDetail.self) else { return nil }

        let trainer = ClubTrainer(card: detail.trainer, crew: detail.crew)
        trainers[trainer.id] = trainer
        session.markFollowing(trainer.id, detail.trainer.isFollowed)
        let owner = trainer.id
        return TrainerContent(
            trainer: trainer,
            upcoming: detail.upcoming.map { ClubEvent(card: $0, trainerID: owner) },
            rated: detail.ratedExperiences.map { ClubEvent(card: $0, trainerID: owner) })
    }

    func trainerDirectory() async -> [ClubTrainer]? {
        guard let page = try? await api.get("club/trainers?limit=100", as: APITrainerPage.self) else { return nil }

        return page.items.map {
            let trainer = ClubTrainer(card: $0)
            trainers[trainer.id] = trainer
            return trainer
        }
    }
}
