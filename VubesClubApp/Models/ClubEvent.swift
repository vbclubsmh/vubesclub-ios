import CoreLocation
import Foundation

enum Sport: String, CaseIterable {
    case trailRunning = "Trail running"
    case running = "Running"
    case mobility = "Mobility"
    case hiking = "Hiking"
    case walking = "Walking"
    case cycling = "Cycling"

    /// Sunucudaki spor kodundan (`trailRunning`, `running` …) çözülür; bilinmeyen kod koşuya düşer.
    init(code: String) {
        switch code {
        case "trailRunning": self = .trailRunning
        case "mobility": self = .mobility
        case "hiking": self = .hiking
        case "walking": self = .walking
        case "cycling": self = .cycling
        default: self = .running
        }
    }

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

    /// Kapaktan sonra gelen mekân görselleri (detay ekranında kaydırılır).
    var gallery: [String] = []

    /// Studio'da "öne çıkar" işaretli etkinlikler listede en üstte durur.
    var featured = false

    /// Kontenjan; yalnız detaydan gelir ve sunucuda canlıdır.
    var seats: EventSeats?

    /// Katılım isteği için sunucudaki program sürümü (yalnız detaydan gelir).
    var programVersion: String?

    /// Sunucudan gelen etkinliklerde gerçek zamanlar; yerel örneklerde boş.
    var startsAt: Date?
    var endsAt: Date?
    var timeZoneID: String?

    /// Seçili dilde tarih: sunucu etkinliklerinde zamandan üretilir, örneklerde `date` metni çevrilir.
    @MainActor
    var displayDate: String {
        guard let startsAt, let endsAt else { return L(date) }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZoneID.flatMap(TimeZone.init(identifier:)) ?? .current
        let locale = AppLanguage.shared.locale
        let day = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
            .day().month(.abbreviated)

        if calendar.isDate(startsAt, inSameDayAs: endsAt) { return startsAt.formatted(day) }
        let first = calendar.dateComponents([.year, .month], from: startsAt)
        let last = calendar.dateComponents([.year, .month], from: endsAt)
        if first == last {
            let month = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone)
                .month(.abbreviated)
            return "\(calendar.component(.day, from: startsAt))–\(calendar.component(.day, from: endsAt)) \(startsAt.formatted(month))"
        }
        return "\(startsAt.formatted(day)) – \(endsAt.formatted(day))"
    }

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

/// Etkinliğin kontenjanı: toplam, dolu (kesin katılım ve geçerli yer ayırma) ve kalan.
struct EventSeats: Equatable {
    let capacity: Int
    let taken: Int
    let remaining: Int

    var isFull: Bool { remaining == 0 }
    var isLow: Bool { !isFull && (remaining <= 5 || Double(remaining) / Double(max(capacity, 1)) <= 0.2) }
    var fraction: Double { min(1, Double(taken) / Double(max(capacity, 1))) }
}
