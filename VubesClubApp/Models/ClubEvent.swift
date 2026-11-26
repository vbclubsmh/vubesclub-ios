import CoreLocation
import Foundation

enum Sport: String, CaseIterable {
    case trailRunning = "Trail running"
    case running = "Running"
    case mobility = "Mobility"
    case hiking = "Hiking"
    case walking = "Walking"
    case cycling = "Cycling"

    var symbol: String {
        switch self {
        case .trailRunning, .running: "figure.run"
        case .mobility: "figure.mind.and.body"
        case .hiking: "figure.hiking"
        case .walking: "figure.walk"
        case .cycling: "bicycle"
        }
    }
}

enum EventCategory: CaseIterable {
    case all, sports, camp

    var title: String {
        switch self {
        case .all: "All"
        case .sports: "Sports"
        case .camp: "Camp"
        }
    }

    func matches(_ event: ClubEvent) -> Bool {
        switch self {
        case .all: true
        case .sports: !event.isCamp
        case .camp: event.isCamp
        }
    }
}

enum EventLevel: String, CaseIterable {
    case easy = "Easy"
    case moderate = "Moderate"
    case hard = "Hard"
}

enum EventStatus {
    case upcoming
    case inProgress
    case past
}

struct ProgramDay {
    let sessions: [ProgramSession]
}

struct ProgramSession: Identifiable {
    var id: String { serverID ?? time }

    let time: String
    let title: String
    let details: String
    var serverID: String?
}

struct MapPosition {
    let x: Double
    let y: Double
}

struct ClubEvent: Identifiable {
    let id: String
    let title: String
    let location: String
    let date: String
    let sport: Sport
    let level: EventLevel
    let image: String
    let price: Int
    let program: [ProgramDay]
    let status: EventStatus

    var trainerID = "deniz"
    var accommodation: String?
    var isCamp = false
    var meetingCoordinate: CLLocationCoordinate2D?
    var distance: String?
    var meetingPoint = "Kaş Marina"
    var preparation = "Bring trail shoes, water, a light layer and sun protection."

    var rating: EventRating?

    @MainActor
    var priceLabel: String {
        "₺" + price.formatted(.number.locale(AppLanguage.shared.locale))
    }
}

struct Participant: Identifiable {
    let id: String
    let name: String
    let image: String
    let position: MapPosition
}
