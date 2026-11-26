import Foundation
import Observation

@MainActor
@Observable
final class ClubSession {
    let api: ClubAPI

    private(set) var isSignedIn = false
    private(set) var accountScope = UUID()
    private(set) var applicationSubmitted = false
    private(set) var profile: MemberProfile?

    private(set) var savedEventIDs: Set<String> = []
    private(set) var bookingIDs: Set<String> = []
    private(set) var connectedTrainerIDs: Set<String> = []
    private(set) var trainerIntroductionIDs: Set<String> = []
    private(set) var eventRatings: [String: Int] = [:]

    var upcomingBookings: [ClubEvent] {
        DemoCatalog.upcoming.filter { bookingIDs.contains($0.id) }
    }

    init(api: ClubAPI = .shared) {
        self.api = api
        api.onSessionExpired = { [weak self] in self?.endLocalSession() }
    }

    // MARK: Access

    enum VerificationOutcome {
        case signedIn
        case applicationReceived
        case unknownNumber
        case underReview
    }

    /// Restores a stored session at launch. Only an active membership opens the app.
    func restore() async {
        guard api.hasSession else { return }

        do {
            let membership = try await api.get("auth/session", as: ClubMembership.self)
            if membership.membershipState == "active" {
                await loadProfile()
                isSignedIn = true
                accountScope = UUID()
            } else {
                api.signOut()
            }
        } catch let failure as ClubAPIError where failure.isUnauthorized {
            endLocalSession()
        } catch {
            // Offline at launch keeps the stored credentials; the welcome screen stays available.
        }
    }

    func requestLoginCode(digits: String) async throws -> SMSChallenge {
        try await api.publicPost("auth/otp-challenges", body: LoginCodeRequest(phone: Self.phone(digits)),
                                 as: SMSChallenge.self)
    }

    func requestApplicationCode(_ request: ApplicationCodeRequest) async throws -> SMSChallenge {
        try await api.publicPost("auth/application-otp-challenges", body: request, as: SMSChallenge.self)
    }

    func resendCode(_ challenge: SMSChallenge) async throws -> SMSChallenge {
        try await api.publicPost("auth/otp-challenges/\(challenge.challengeId.uuidString.lowercased())/resend",
                                 as: SMSChallenge.self)
    }

    func verify(_ challenge: SMSChallenge, code: String) async throws -> VerificationOutcome {
        let path = "auth/otp-challenges/\(challenge.challengeId.uuidString.lowercased())/verify"
        let result: CodeVerificationResult
        do {
            result = try await api.publicPost(path, body: CodeVerification(code: code), as: CodeVerificationResult.self)
        } catch ClubAPIError.server(status: 403, _, _) {
            return .underReview
        }

        if let tokens = result.tokens {
            try api.accept(tokens)
            if result.session?.membershipState != "active" {
                api.signOut()
                return .underReview
            }
            await loadProfile()
            isSignedIn = true
            accountScope = UUID()
            return .signedIn
        }
        switch result.nextAction {
        case "applicationReceived": 
            applicationSubmitted = true
            return .applicationReceived
        default:
            return .unknownNumber
        }
    }

    func dismissApplicationConfirmation() {
        applicationSubmitted = false
    }

    func signOut() {
        api.signOut()
        endLocalSession()
    }

    private func endLocalSession() {
        isSignedIn = false
        profile = nil
        savedEventIDs = []
        bookingIDs = []
        connectedTrainerIDs = []
        trainerIntroductionIDs = []
        eventRatings = [:]
        accountScope = UUID()
    }

    private func loadProfile() async {
        profile = try? await api.get("me", as: MemberProfile.self)
    }

    func refreshProfile() async {
        guard isSignedIn else { return }
        await loadProfile()
    }

    /// Uploads a new profile photo (JPEG bytes) and keeps the returned profile.
    func updateAvatar(_ jpeg: Data) async throws {
        profile = try await api.upload("PUT", "me/avatar", data: jpeg, contentType: "image/jpeg", as: MemberProfile.self)
    }

    /// Boy, kilo, beden ve (bir kez) doğum tarihi.
    func updateProfile(_ update: ProfileUpdate) async throws {
        profile = try await api.send("PATCH", "me", body: update, as: MemberProfile.self)
    }

    /// E-posta ya da telefon değişikliği için kod ister; kod yeni e-postaya ya da mevcut e-postaya gider.
    func requestContactChange(_ change: ContactChangeBody) async throws -> SMSChallenge {
        try await api.send("POST", "me/contact-changes", body: change, as: SMSChallenge.self)
    }

    func resendContactChange(_ challenge: SMSChallenge) async throws -> SMSChallenge {
        try await api.fetch("POST", "me/contact-changes/\(challenge.challengeId.uuidString.lowercased())/resend", as: SMSChallenge.self)
    }

    func confirmContactChange(_ challenge: SMSChallenge, code: String) async throws {
        profile = try await api.send(
            "POST", "me/contact-changes/\(challenge.challengeId.uuidString.lowercased())/verify",
            body: CodeVerification(code: code), as: MemberProfile.self)
    }

    func removeAvatar() async throws {
        profile = try await api.fetch("DELETE", "me/avatar", as: MemberProfile.self)
    }

    /// `5551234567` → `+905551234567`.
    static func phone(_ digits: String) -> String { "+90" + digits }

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
