import Foundation

/// Katılım, ödeme ve saha giriş uçlarının sözleşmeleri (`Contracts/mobile.openapi.json`).

struct APITerms: Decodable {
    let version: String
    let url: String
}

struct APICheckout: Decodable {
    let eventId: UUID
    let title: String
    let terms: APITerms
}

struct APIHold: Decodable {
    let id: UUID
    let state: String
    let bookingId: UUID?
    let paymentId: UUID?
    let checkout: APICheckout
}

struct APIPaymentState: Decodable {
    let paymentId: UUID
    let status: String
}

struct APIPass: Decodable {
    let bookingId: UUID
    let eventId: UUID
    let title: String
    let startsAt: Date
    let timeZone: String
    let qrPayload: String
    let validUntil: Date
}

struct APIBookingRow: Decodable {
    let id: UUID
    let event: APIEventCard
    let status: String
    let attendance: String
    let canShowPass: Bool
    let visibleParticipantPreview: [APIPerson]
}

struct APIBookingPage: Decodable {
    let items: [APIBookingRow]
    let nextCursor: String?
}

struct APICreateHold: Encodable {
    let eventId: String
    let programVersion: String
}

struct APIStartPayment: Encodable {
    let acceptedTermsVersion: String
    let termsAccepted: Bool
}

struct APICheckInRequest: Encodable {
    let payload: String
}

struct APICheckInResult: Decodable {
    let bookingId: UUID
    let memberName: String
    let memberAvatar: MediaReference?
    let eventId: UUID
    let eventTitle: String
    /// `checkedIn` veya `alreadyCheckedIn`.
    let outcome: String
    let checkedInAt: Date
}
