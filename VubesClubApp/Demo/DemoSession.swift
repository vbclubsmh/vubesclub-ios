import Foundation
import Observation

@MainActor
@Observable
final class DemoSession {
    private(set) var appearance: AppAppearance?
    let api: ClubAPI
    private(set) var membership: ClubMembership?
    private(set) var isRestoring: Bool
    private(set) var restoreError: String?
    private(set) var accountScope = UUID()

    var isSignedIn: Bool { membership?.nextAction == "events" }

    init() {
        api = ClubAPI.configured()
        isRestoring = api.hasSession
        api.onSessionExpired = { [weak self] in self?.reset() }
    }

    func loadAppearance() async {
        do {
            appearance = try await api.publicGet("app/appearance", as: AppAppearance.self)
        } catch {
            // Content stays empty while offline and can be retried when the scene becomes active.
        }
    }

    func restore() async {
        guard api.hasSession else {
            reset()
            return
        }

        let scope = accountScope
        restoreError = nil
        isRestoring = membership == nil

        do {
            let current = try await api.get("auth/session", as: ClubMembership.self)
            guard scope == accountScope else { return }
            membership = current
        } catch {
            guard scope == accountScope else { return }
            restoreError = error.localizedDescription
        }

        isRestoring = false
    }

    func verify(_ challenge: SMSChallenge, code: String) async throws {
        let response = try await api.publicPost(
            "auth/otp-challenges/\(challenge.challengeId)/verify",
            body: ["code": code], as: SMSVerification.self
        )
        try Task.checkCancellation()

        if response.nextAction == "invitationRequired" {
            throw ClubAPIError.invitationRequired
        }

        guard let tokens = response.tokens, let current = response.session else {
            throw ClubAPIError.response
        }

        try api.accept(tokens)
        accountScope = UUID()
        membership = current
        restoreError = nil
    }

    func signOut() {
        api.signOut()
        reset()
    }

    private func reset() {
        membership = nil
        isRestoring = false
        restoreError = nil
        accountScope = UUID()
    }

    private(set) var savedEventIDs: Set<String> = []
    private(set) var bookingIDs: Set<String> = []

    private(set) var connectedTrainerIDs: Set<String> = []
    private(set) var trainerIntroductionIDs: Set<String> = []
    private(set) var eventRatings: [String: Int] = [:]

    var upcomingBookings: [ClubEvent] {
        DemoCatalog.upcoming.filter { bookingIDs.contains($0.id) }
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
