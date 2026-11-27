import Foundation

/// Wire contracts of the Vubes mobile API (`Contracts/mobile.openapi.json`).

struct ClubTokens: Codable {
    let accessToken: String
    let accessExpiresAt: Date
    let refreshToken: String
    let sessionExpiresAt: Date
}

struct ClubMembership: Decodable {
    let membershipState: String
    let nextAction: String
    let sessionExpiresAt: Date?
}

struct SMSChallenge: Decodable, Hashable {
    let challengeId: UUID
    let codeLength: Int
    let expiresAt: Date
    let resendAt: Date
    let channel: String?
}

struct LoginCodeRequest: Encodable {
    let phone: String
}

struct ApplicationCodeRequest: Encodable {
    let phone: String
    let fullName: String
    let email: String
    let university: String
    let jobTitle: String
    let heightCm: Int
    let weightKg: Int
    /// ISO tarih: yyyy-MM-dd
    let birthDate: String
    let workplace: String?
    let instagram: String?
    let linkedIn: String?
    let invitationCode: String?
    let adultDeclared: Bool
}

struct CodeVerification: Encodable {
    let code: String
}

/// The verify endpoint answers with a session, or with only the next action
/// (`applicationReceived` after a new application, `invitationRequired` for an unknown number).
struct CodeVerificationResult: Decodable {
    let session: ClubMembership?
    let tokens: ClubTokens?
    let nextAction: String?
}

struct MediaReference: Decodable, Hashable {
    let url: String
    let altText: String?
}

struct MemberProfile: Decodable {
    let memberId: UUID
    let fullName: String
    let avatar: MediaReference?
    let cover: MediaReference?
    let phoneMasked: String
    let phone: String?
    let email: String?
    let heightCm: Int?
    let weightKg: Int?
    let clothingSize: String?
    /// ISO tarih: yyyy-MM-dd
    let birthDate: String?
    let membershipState: String
    let tier: String
    let trainerRole: Bool
    let fieldStaff: Bool?
}

/// Boş bırakılan alan değişmez; doğum tarihi yalnızca bir kez girilebilir.
struct ProfileUpdate: Encodable {
    var heightCm: Int?
    var weightKg: Int?
    var clothingSize: String?
    var birthDate: String?
}

/// Tam olarak biri dolu olmalı.
struct ContactChangeBody: Encodable {
    var email: String?
    var phone: String?
}
