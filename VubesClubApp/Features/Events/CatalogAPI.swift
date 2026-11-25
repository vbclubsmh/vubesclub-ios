import Foundation
import Observation

struct CatalogOption: Decodable, Identifiable {
    var id: String { code }
    let code: String
    let label: String
}

struct CatalogFilters: Decodable {
    let sports: [CatalogOption]
    let levels: [CatalogOption]
}

struct CatalogSelection: Equatable {
    var sport: String?
    var level: String?
}

struct CatalogCard: Decodable, Identifiable {
    struct Media: Decodable { let url: String }

    struct Sport: Decodable {
        let code: String
        let label: String
        let fallbackCover: Media?
    }

    struct Point: Decodable {
        let latitude: Double
        let longitude: Double
    }

    struct Rating: Decodable {
        let average: Double?
        let count: Int
    }

    let id: String
    let title: String
    let placeLabel: String
    let startsAt: Date
    let endsAt: Date
    let timeZone: String
    let primarySport: Sport
    let level: String
    let cover: Media?
    let price: BookingAPI.Amount
    let phase: String
    let position: Point?
    let distanceMeters: Int?
    let isSaved: Bool
    let rating: Rating?

    var image: String { cover?.url ?? primarySport.fallbackCover?.url ?? "" }
    var dateLabel: String { BookingAPI.date(startsAt, in: timeZone) }
    var distanceLabel: String? {
        distanceMeters.map { Measurement(value: Double($0), unit: UnitLength.meters)
                .converted(to: .kilometers).value.formatted(.number.precision(.fractionLength(0...2))) + " km" }
    }
}

struct CatalogDetail: Decodable {
    struct Day: Decodable {
        struct Slot: Decodable, Identifiable {
            let id: String
            let startsAt: Date
            let title: String
            let details: String
        }
        let id: String
        let date: String
        let sessions: [Slot]
    }

    struct Meeting: Decodable {
        let label: String
        let directions: String?
    }

    struct Viewer: Decodable {
        struct Rating: Decodable {
            let stars: Int
            let moderation: String
        }
        let primary: String
        let bookingId: String?
        let holdId: String?
        let canViewActivityMap: Bool
        let canRate: Bool
        let myRating: Rating?
    }

    let event: CatalogCard
    let programVersion: String
    let organizer: LiveTrainer
    let days: [Day]
    let additionalSports: [CatalogOption]
    let meetingPoint: Meeting
    let preparation: String?
    let transportNotes: String?
    let accommodation: String?
    let viewer: Viewer
}

@MainActor
@Observable
final class LiveCatalogState {
    var selection = CatalogSelection()
    private(set) var filters: CatalogFilters?
    private(set) var revision = 0

    func loadFilters(_ api: ClubAPI) async throws {
        if filters == nil {
            filters = try await api.get("event-filters", as: CatalogFilters.self)
        }
    }

    func setSaved(_ saved: Bool, eventID: String, api: ClubAPI) async throws {
        try await api.empty(saved ? "PUT" : "DELETE", "me/saved-events/\(eventID)")
        revision += 1
    }

    func levelLabel(_ code: String) -> String {
        filters?.levels.first { $0.code == code }?.label ?? code.capitalized
    }
}

struct CatalogRequest: Equatable {
    let selection: CatalogSelection
    let savedOnly: Bool
    let hasLocation: Bool
    let revision: Int

    func path(after cursor: String?) -> String {
        var route = URLComponents()
        route.path = "events"
        var items = [URLQueryItem(name: "limit", value: "30")]
        if let sport = selection.sport { items.append(URLQueryItem(name: "sport", value: sport)) }
        if let level = selection.level { items.append(URLQueryItem(name: "level", value: level)) }
        if savedOnly { items.append(URLQueryItem(name: "savedOnly", value: "true")) }
        if hasLocation { items.append(URLQueryItem(name: "hasLocation", value: "true")) }
        if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
        route.queryItems = items
        return route.string ?? "events"
    }
}

@MainActor
@Observable
final class CatalogFeed {
    private struct Page: Decodable {
        let items: [CatalogCard]
        let nextCursor: String?
        let total: Int
    }

    private(set) var events: [CatalogCard] = []
    private(set) var cursor: String?
    private(set) var total = 0
    private(set) var loading = true
    private(set) var error: String?
    private var generation = UUID()

    func load(_ api: ClubAPI, request: CatalogRequest, more: Bool = false) async {
        if more && (loading || cursor == nil) { return }
        let token = UUID()
        generation = token
        if !more {
            events = []
            total = 0
            cursor = nil
        }
        loading = true
        error = nil
        defer { if generation == token { loading = false } }
        do {
            let page = try await api.get(request.path(after: cursor), as: Page.self)
            try Task.checkCancellation()
            guard generation == token else { return }
            let previous = Set(events.map(\.id))
            events += page.items.filter { !previous.contains($0.id) }
            cursor = page.nextCursor
            total = page.total
        } catch {
            if !Task.isCancelled && generation == token { self.error = error.localizedDescription }
        }
    }
}
