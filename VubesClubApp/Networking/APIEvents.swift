import Foundation

/// Wire contracts of the catalog and club endpoints (`Contracts/mobile.openapi.json`).

struct APISport: Decodable {
    let code: String
    let label: String
    let fallbackCover: MediaReference?
}

struct APIMoney: Decodable {
    let amountMinor: Int
    let currency: String
}

struct APIPoint: Decodable {
    let latitude: Double
    let longitude: Double
}

struct APIRatingSummary: Decodable {
    let average: Double?
    let count: Int
}

struct APIEventCard: Decodable {
    let id: UUID
    let title: String
    let placeLabel: String
    let startsAt: Date
    let endsAt: Date
    let timeZone: String
    let primarySport: APISport
    let level: String
    let cover: MediaReference?
    let distanceMeters: Int?
    let price: APIMoney
    let phase: String
    let position: APIPoint?
    let isSaved: Bool
    let rating: APIRatingSummary?
    let featured: Bool?
}

struct APIEventPage: Decodable {
    let items: [APIEventCard]
    let nextCursor: String?
}

struct APIProgramSession: Decodable {
    let id: UUID
    let startsAt: Date
    let endsAt: Date?
    let title: String
    let details: String
}

struct APIProgramDay: Decodable {
    let id: UUID
    let date: String
    let sessions: [APIProgramSession]
}

struct APIMeetingPoint: Decodable {
    let label: String
    let directions: String?
    let position: APIPoint?
}

struct APITrainerCard: Decodable {
    let id: UUID
    let displayName: String
    let specialty: String
    let experienceText: String
    let locationLabel: String
    let bio: String
    let avatar: MediaReference?
    let cover: MediaReference?
    let isFollowed: Bool
    let introductionState: String
}

struct APIEventDetail: Decodable {
    let event: APIEventCard
    let organizer: APITrainerCard
    let days: [APIProgramDay]
    let preparation: String?
    let meetingPoint: APIMeetingPoint
    let transportNotes: String?
    let accommodation: String?
    let gallery: [MediaReference]?
}

struct APIPerson: Decodable {
    let displayName: String
    let avatar: MediaReference?
}

struct APICrew: Decodable {
    let name: String
    let members: [APIPerson]
}

struct APITrainerDetail: Decodable {
    let trainer: APITrainerCard
    let crew: APICrew?
    let upcoming: [APIEventCard]
    let ratedExperiences: [APIEventCard]
}

struct APITrainerPage: Decodable {
    let items: [APITrainerCard]
    let nextCursor: String?
}

struct APITrainerRef: Decodable {
    let id: UUID
    let displayName: String
    let avatar: MediaReference?
}

struct APIFeedTrainer: Decodable {
    let trainer: APITrainerCard
    /// `following`, `linked` veya `both`.
    let source: String
}

struct APIFeedEvent: Decodable {
    let event: APIEventCard
    let organizer: APITrainerRef
}

struct APIClubFeed: Decodable {
    let trainers: [APIFeedTrainer]
    let forYou: [APIFeedEvent]
    let ratedExperiences: [APIFeedEvent]
}
