import Foundation

enum DemoCatalog {
    static let camp = ClubEvent(
        id: "likya-camp",
        title: "Likya Trail & Mobility Camp",
        location: "Kaş",
        date: "Nov 22–24",
        sport: .trailRunning,
        level: .moderate,
        image: "Likya",
        price: 4_850,
        program: [
            ProgramDay(sessions: [
                .init(time: "08:30", title: "Meet at Kaş Marina", details: "Check-in · 30 min"),
                .init(time: "09:00", title: "Coastal trail run", details: "Guided group run · 1 hr 30 min"),
                .init(time: "10:30", title: "Mobility session", details: "Stretch & recover · 45 min"),
                .init(time: "11:30", title: "Lunch on the terrace", details: "Group lunch · 1 hr"),
                .init(time: "14:00", title: "Trail technique clinic", details: "Footwork and pacing · 45 min"),
                .init(time: "16:00", title: "Coastal cool-down", details: "Easy walk & guided stretch · 45 min"),
                .init(time: "17:30", title: "Sunset debrief", details: "Terrace tea & tomorrow’s route · 30 min")
            ]),
            ProgramDay(sessions: [
                .init(time: "08:00", title: "Breakfast", details: "At the lodge · 45 min"),
                .init(time: "09:00", title: "Lycian Way trail", details: "Guided run · 2 hr"),
                .init(time: "11:30", title: "Recovery & lunch", details: "Mobility and a shared meal · 1 hr"),
                .init(time: "14:30", title: "Route-reading workshop", details: "Navigation with Deniz · 45 min"),
                .init(time: "16:30", title: "Mobility reset", details: "Guided recovery · 45 min"),
                .init(time: "17:30", title: "Crew wind-down", details: "Tea and trail stories · 30 min")
            ]),
            ProgramDay(sessions: [
                .init(time: "08:30", title: "Sunrise mobility", details: "Terrace session · 45 min"),
                .init(time: "10:00", title: "Coastal walk", details: "Easy group walk · 1 hr"),
                .init(time: "11:30", title: "Lodge check-out", details: "Pack & store bags · 30 min"),
                .init(time: "13:00", title: "Lunch in Kaş", details: "Shared table · 1 hr"),
                .init(time: "15:30", title: "Your next trail", details: "Personal training takeaways · 45 min"),
                .init(time: "17:00", title: "Club send-off", details: "Meet at Kaş Marina · 30 min")
            ])
        ],
        status: .upcoming,
        accommodation: "Two nights at the club’s lodge are included in the full program.",
        isCamp: true
    )

    static let forest = ClubEvent(
        id: "belgrad-run", title: "Belgrad Forest Run", location: "Istanbul", date: "Nov 29",
        sport: .running, level: .easy, image: "Forest", price: 950,
        program: [ProgramDay(sessions: [
            .init(time: "09:00", title: "Meet at the trailhead", details: "Warm-up · 15 min"),
            .init(time: "09:15", title: "Forest loop", details: "Guided group run · 1 hr")
        ])],
        status: .upcoming, meetingCoordinate: .init(latitude: 41.1798, longitude: 28.9896), distance: "6 km",
        meetingPoint: "Belgrad Forest trailhead"
    )

    static let mobility = ClubEvent(
        id: "sunday-mobility", title: "Sunday Mobility", location: "Istanbul", date: "Dec 6",
        sport: .mobility, level: .easy, image: "Terrace", price: 750,
        program: [ProgramDay(sessions: [
            .init(time: "10:00", title: "Terrace mobility", details: "Guided session · 1 hr")
        ])],
        status: .upcoming, trainerID: "ece", meetingCoordinate: .init(latitude: 41.0484, longitude: 29.0267),
        meetingPoint: "Club terrace", preparation: "Bring a mat, water and comfortable layers."
    )

    static let hike = ClubEvent(
        id: "bosphorus-hike", title: "Bosphorus Ridge Hike", location: "Istanbul", date: "Dec 13",
        sport: .hiking, level: .moderate, image: "Forest", price: 1_250,
        program: [ProgramDay(sessions: [
            .init(time: "09:00", title: "Ridge hike", details: "Guided hike · 2 hr")
        ])],
        status: .upcoming, trainerID: "mert", meetingCoordinate: .init(latitude: 41.1068, longitude: 29.0917), distance: "8 km",
        meetingPoint: "Ridge trailhead"
    )

    static let cycling = ClubEvent(
        id: "bosphorus-ride", title: "Bosphorus Sunrise Ride", location: "Istanbul", date: "Dec 14",
        sport: .cycling, level: .moderate, image: "Cycling", price: 1_150,
        program: [ProgramDay(sessions: [
            .init(time: "08:00", title: "Meet by the waterfront", details: "Bike check · 15 min"),
            .init(time: "08:15", title: "Bosphorus ride", details: "Guided group ride · 1 hr 30 min"),
            .init(time: "09:45", title: "Coffee by the water", details: "Group cool-down · 30 min")
        ])],
        status: .upcoming, trainerID: "deniz", meetingCoordinate: .init(latitude: 41.0768, longitude: 29.0440),
        distance: "18 km", meetingPoint: "Bebek waterfront",
        preparation: "Bring a roadworthy bicycle, helmet, lights and water."
    )

    static let waterfrontWalk = ClubEvent(
        id: "marmara-walk", title: "Marmara Waterfront Walk", location: "Istanbul", date: "Dec 20",
        sport: .walking, level: .easy, image: "Dusk", price: 550,
        program: [ProgramDay(sessions: [
            .init(time: "09:30", title: "Meet on the promenade", details: "Group introduction · 15 min"),
            .init(time: "09:45", title: "Walk along the coast", details: "Easy group walk · 1 hr")
        ])],
        status: .upcoming, trainerID: "mert", meetingCoordinate: .init(latitude: 40.9647, longitude: 28.7995),
        distance: "4 km", meetingPoint: "Florya promenade",
        preparation: "Bring comfortable walking shoes, water and a light layer."
    )

    static let live = ClubEvent(
        id: "likya-coastal-run", title: "Likya Coastal Run", location: "Kaş", date: "Today",
        sport: .trailRunning, level: .moderate, image: "Likya", price: 1_250,
        program: [ProgramDay(sessions: [
            .init(time: "09:00", title: "Coastal trail run", details: "Guided group run · 1 hr 30 min"),
            .init(time: "10:30", title: "Recovery", details: "Stretch & recover · 45 min")
        ])],
        status: .inProgress, distance: "6 km"
    )

    static let past = ClubEvent(
        id: "forest-walk", title: "Forest Walk", location: "Istanbul", date: "Nov 8",
        sport: .hiking, level: .easy, image: "Forest", price: 750,
        program: [ProgramDay(sessions: [
            .init(time: "09:00", title: "Forest walk", details: "Group hike · 1 hr")
        ])],
        status: .past, trainerID: "mert", meetingPoint: "Belgrad Forest trailhead",
        rating: EventRating(total: 94, count: 20)
    )

    /// Gürkan Bilgen'in düzenlediği tanıtım etkinliği. Program ve fiyat Gürkan'ın paylaşımına göre güncellenecek.
    static let hasdal = ClubEvent(
        id: "hasdal-run-meet", title: "Hasdal Run & Meet", location: "Kağıthane, Istanbul", date: "Dec 6",
        sport: .running, level: .easy, image: "Hasdal", price: 650,
        program: [ProgramDay(sessions: [
            .init(time: "09:30", title: "Meet at the club", details: "Welcome & warm-up · 30 min"),
            .init(time: "10:00", title: "Group run", details: "Easy-pace run around Hasdal · 1 hr"),
            .init(time: "11:15", title: "Coffee & get-together", details: "Meet the crew · 45 min")
        ])],
        status: .upcoming, trainerID: "gurkan", meetingCoordinate: .init(latitude: 41.1021897, longitude: 28.960769),
        distance: "6 km", meetingPoint: "Yılmaz Ulusoy Atlı Spor Kulübü, Hasdal",
        preparation: "Bring running shoes, water and a light layer. Organized by Gürkan Bilgen."
    )

    static let upcoming = [hasdal, camp, forest, mobility, hike, cycling, waterfrontWalk]

    static let participants = [
        Participant(id: "deniz", name: "Deniz", image: "Portrait0", position: .init(x: 169, y: 225)),
        Participant(id: "ece", name: "Ece", image: "Portrait1", position: .init(x: 224, y: 285)),
        Participant(id: "mert", name: "Mert", image: "Portrait2", position: .init(x: 275, y: 339)),
        Participant(id: "ada", name: "Ada", image: "Portrait3", position: .init(x: 181, y: 419)),
        Participant(id: "can", name: "Can", image: "Portrait4", position: .init(x: 226, y: 475)),
        Participant(id: "selin", name: "Selin", image: "Portrait5", position: .init(x: 272, y: 532))
    ]

    static let route: [MapPosition] = [
        .init(x: 144, y: 193), .init(x: 169, y: 225), .init(x: 188, y: 262),
        .init(x: 224, y: 285), .init(x: 249, y: 314), .init(x: 275, y: 339),
        .init(x: 243, y: 365), .init(x: 213, y: 391), .init(x: 181, y: 419),
        .init(x: 195, y: 448), .init(x: 226, y: 475), .init(x: 231, y: 507),
        .init(x: 272, y: 532), .init(x: 294, y: 582), .init(x: 304, y: 596)
    ]

    static func event(_ id: String) -> ClubEvent? {
        (upcoming + [live] + DemoClub.completedEvents).first { $0.id == id }
    }
}
