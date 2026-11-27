import Foundation
import Observation

/// Üyenin sunucudaki katılımları ve QR kartları.
struct MyBooking: Identifiable {
    var id: String { bookingID }

    let bookingID: String
    let event: ClubEvent
    let attendance: String
    let canShowPass: Bool
    let participants: [(name: String, image: String)]
}

@MainActor
@Observable
final class BookingCenter {
    enum Phase { case idle, loading, loaded, failed }

    enum JoinFailure: Error { case unavailable, notConfirmed }

    private(set) var phase = Phase.idle
    private(set) var upcoming: [MyBooking] = []
    private(set) var inProgress: [MyBooking] = []
    private(set) var past: [MyBooking] = []

    private var passes: [String: String] = [:]
    private let api: ClubAPI

    init(api: ClubAPI = .shared) {
        self.api = api
    }

    func booking(forEvent id: String) -> MyBooking? {
        (upcoming + inProgress + past).first { $0.event.id == id }
    }

    func load(session: ClubSession) async {
        guard phase != .loading else { return }

        phase = .loading
        do {
            upcoming = try await bucket("upcoming")
            inProgress = try await bucket("inProgress")
            past = try await bucket("past")
            session.adoptBookings(Set((upcoming + inProgress).map(\.event.id)))
            phase = .loaded
        } catch is CancellationError {
            phase = .idle
        } catch {
            phase = .failed
        }
    }

    private func bucket(_ name: String) async throws -> [MyBooking] {
        var rows: [APIBookingRow] = []
        var cursor: String?
        repeat {
            var path = "me/bookings?bucket=\(name)&limit=50"
            if let cursor, let encoded = cursor.addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
                path += "&cursor=" + encoded
            }
            let page = try await api.get(path, as: APIBookingPage.self)
            rows += page.items
            cursor = page.nextCursor
        } while cursor != nil && rows.count < 200

        return rows.filter { $0.status == "confirmed" }.map { row in
            MyBooking(
                bookingID: row.id.uuidString.lowercased(),
                event: ClubEvent(card: row.event),
                attendance: row.attendance,
                canShowPass: row.canShowPass,
                participants: row.visibleParticipantPreview.map { ($0.displayName, $0.avatar?.url ?? "") })
        }
    }

    /// QR kartının içeriği; sunucudan alınır ve oturum boyunca saklanır.
    func passPayload(bookingID: String) async -> String? {
        if let cached = passes[bookingID] { return cached }
        guard let pass = try? await api.get("me/bookings/\(bookingID)/pass", as: APIPass.self) else { return nil }

        passes[bookingID] = pass.qrPayload
        return pass.qrPayload
    }

    /// Katılımı oluşturur: yer ayırma → (ödeme adımı) → kesinleşme. Ödeme sağlayıcısı henüz bağlı değil;
    /// sunucu ödemesiz kesinleştirir.
    func join(_ event: ClubEvent, catalog: EventCatalog, session: ClubSession) async throws -> MyBooking {
        if event.programVersion == nil { await catalog.loadDetail(id: event.id) }
        guard let version = catalog.event(event.id)?.programVersion else { throw JoinFailure.unavailable }

        let key = UUID().uuidString
        let hold = try await api.send(
            "POST", "booking-holds", body: APICreateHold(eventId: event.id, programVersion: version),
            as: APIHold.self, headers: ["Idempotency-Key": "hold-" + key])

        if hold.bookingId == nil {
            _ = try await api.send(
                "POST", "booking-holds/\(hold.id.uuidString.lowercased())/payments",
                body: APIStartPayment(acceptedTermsVersion: hold.checkout.terms.version, termsAccepted: true),
                as: APIPaymentState.self, headers: ["Idempotency-Key": "pay-" + key])
        }

        for _ in 0..<8 {
            let current = try await api.get("booking-holds/\(hold.id.uuidString.lowercased())", as: APIHold.self)
            if current.bookingId != nil { break }
            if ["expired", "paymentFailed", "refunded", "refundPending"].contains(current.state) { throw JoinFailure.notConfirmed }
            try await Task.sleep(for: .milliseconds(600))
        }

        await load(session: session)
        guard let booking = booking(forEvent: event.id) else { throw JoinFailure.notConfirmed }

        return booking
    }
}
