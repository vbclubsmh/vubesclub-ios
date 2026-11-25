enum DemoClub {
    static let deniz = ClubTrainer(
        id: "deniz", name: "Deniz Kaya", specialty: "Trail running & endurance",
        experience: "8 years coaching", location: "Kaş & Istanbul",
        image: "Portrait0", cover: "Likya",
        bio: "Deniz brings runners together on coastal and forest trails. His sessions pair steady pacing with practical trail technique and time to recover.",
        crewName: "Coastal Crew",
        crew: [.init(name: "Ada", image: "Portrait3"), .init(name: "Mert", image: "Portrait2"),
               .init(name: "Can", image: "Portrait4")]
    )

    static let ece = ClubTrainer(
        id: "ece", name: "Ece Arslan", specialty: "Mobility & recovery",
        experience: "6 years coaching", location: "Istanbul",
        image: "Portrait1", cover: "Terrace",
        bio: "Ece coaches small groups through mobility, breathwork and recovery. Her sessions welcome members looking to move more comfortably at their own pace.",
        crewName: "Sunday Studio",
        crew: [.init(name: "Selin", image: "Portrait5"), .init(name: "Ada", image: "Portrait3")]
    )

    static let mert = ClubTrainer(
        id: "mert", name: "Mert Demir", specialty: "Hiking & outdoor conditioning",
        experience: "7 years coaching", location: "Istanbul",
        image: "Portrait2", cover: "Forest",
        bio: "Mert leads forest walks and ridge hikes. He shares route preparation, outdoor skills and conditioning tips throughout the day.",
        crewName: "Forest Circle",
        crew: [.init(name: "Can", image: "Portrait4"), .init(name: "Selin", image: "Portrait5")]
    )

    static let trainers = [deniz, ece, mert]

    static let completedEvents = [
        DemoCatalog.past,
        ClubEvent(
            id: "terrace-recovery", title: "Terrace Recovery", location: "Istanbul", date: "Nov 2",
            sport: .mobility, level: .easy, image: "Terrace", price: 750,
            program: [ProgramDay(sessions: [
                .init(time: "10:00", title: "Mobility practice", details: "Guided movement · 1 hr"),
                .init(time: "11:15", title: "Breathwork & tea", details: "Terrace session · 45 min")
            ])],
            status: .past, trainerID: ece.id, meetingPoint: "Club terrace",
            rating: EventRating(total: 78, count: 16)
        ),
        ClubEvent(
            id: "coastal-trail-morning", title: "Coastal Trail Morning", location: "Kaş", date: "Oct 26",
            sport: .trailRunning, level: .moderate, image: "Likya", price: 1_250,
            program: [ProgramDay(sessions: [
                .init(time: "08:30", title: "Coastal loop", details: "Guided trail run · 90 min"),
                .init(time: "10:30", title: "Recovery & stretch", details: "Cool-down · 30 min")
            ])],
            status: .past, rating: EventRating(total: 114, count: 24)
        )
    ]

    static func trainer(_ id: String) -> ClubTrainer? {
        trainers.first { $0.id == id }
    }

    static func events(for trainer: ClubTrainer, status: EventStatus) -> [ClubEvent] {
        let events = status == .past ? completedEvents : DemoCatalog.upcoming

        return events.filter { $0.trainerID == trainer.id && $0.status == status }
    }
}
