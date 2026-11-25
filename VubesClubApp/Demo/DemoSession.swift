import Foundation
import Observation

@MainActor
@Observable
final class DemoSession {
    private(set) var isSignedIn = false
    private(set) var accountScope = UUID()

    private(set) var savedEventIDs: Set<String> = []
    private(set) var bookingIDs: Set<String> = []
    private(set) var connectedTrainerIDs: Set<String> = []
    private(set) var trainerIntroductionIDs: Set<String> = []
    private(set) var eventRatings: [String: Int] = [:]

    var upcomingBookings: [ClubEvent] {
        DemoCatalog.upcoming.filter { bookingIDs.contains($0.id) }
    }

    func signIn() {
        isSignedIn = true
        accountScope = UUID()
    }

    func signOut() {
        isSignedIn = false
        accountScope = UUID()
    }

    func toggleSaved(eventID: String) {
        if savedEventIDs.contains(eventID) {
            savedEventIDs.remove(eventID)
        } else {
            savedEventIDs.insert(eventID)
        }
    }

    func toggleTrainerConnection(_ trainer: ClubTrainer) {
        guard isSignedIn else { return }

        if connectedTrainerIDs.contains(trainer.id) {
            connectedTrainerIDs.remove(trainer.id)
        } else {
            connectedTrainerIDs.insert(trainer.id)
        }
    }

    func requestTrainerIntroduction(_ trainer: ClubTrainer) {
        guard isSignedIn else { return }

        trainerIntroductionIDs.insert(trainer.id)
    }

    func rating(for event: ClubEvent) -> EventRating? {
        guard event.status == .past else { return nil }

        return event.rating?.including(eventRatings[event.id])
    }

    func canRate(_ event: ClubEvent) -> Bool {
        isSignedIn && event.status == .past && event.id == DemoCatalog.past.id
    }

    func rate(_ event: ClubEvent, stars: Int) {
        guard canRate(event), (1...5).contains(stars) else { return }

        eventRatings[event.id] = stars
    }

    func confirmBooking(for event: ClubEvent) -> Bool {
        guard isSignedIn, event.status == .upcoming else { return false }

        bookingIDs.insert(event.id)
        return true
    }
}

struct EventFilter: Equatable {
    var sport: Sport?
    var level: EventLevel?

    func matches(_ event: ClubEvent) -> Bool {
        (sport == nil || sport == event.sport) && (level == nil || level == event.level)
    }
}

struct DemoOTPChallenge: Hashable, Identifiable {
    let id = UUID()
    let codeLength = 4
    let resendAt = Date.now.addingTimeInterval(30)
}
