import Foundation

struct ClubTrainer: Identifiable {
    let id: String
    let name: String
    let specialty: String
    let experience: String
    let location: String
    let image: String
    let cover: String
    let bio: String
    let crewName: String
    let crew: [CrewMember]
}

struct CrewMember: Identifiable {
    var id: String { name }

    let name: String
    let image: String
}

struct EventRating {
    let total: Int
    let count: Int

    func including(_ rating: Int?) -> Self {
        guard let rating else { return self }

        return Self(total: total + rating, count: count + 1)
    }

    var averageLabel: String {
        guard count > 0 else { return "—" }

        return (Double(total) / Double(count))
            .formatted(.number.precision(.fractionLength(1)).locale(Locale(identifier: "en_US")))
    }
}
