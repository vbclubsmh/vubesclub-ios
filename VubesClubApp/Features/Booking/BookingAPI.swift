import Foundation

enum BookingAPI {
    struct Amount: Decodable {
        let amountMinor: Int64
        let currency: String

        var display: String {
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "tr_TR")
            formatter.numberStyle = .currency
            formatter.currencyCode = currency

            let decimal = Decimal(amountMinor) / pow(10 as Decimal, formatter.maximumFractionDigits)
            let number = NSDecimalNumber(decimal: decimal)
            return formatter.string(from: number) ?? "\(number.stringValue) \(currency)"
        }
    }

    struct Media: Decodable {
        let url: URL
    }

    struct Terms: Decodable {
        let version: String
        let url: URL
    }

    struct Summary: Decodable {
        let title: String
        let placeLabel: String
        let cover: Media?
        let startsAt: Date
        let endsAt: Date
        let timeZone: String
        let programDays: Int
        let participantCount: Int
        let accommodationIncluded: Bool
        let total: Amount
        let terms: Terms
    }

    enum HoldState: String, Decodable {
        case reserved, paymentPending, verificationPending, confirmed, expired
        case paymentFailed, refundPending, refunded

        var awaitsPayment: Bool {
            self == .paymentPending || self == .verificationPending
        }
    }

    struct Hold: Decodable {
        let id: String
        let state: HoldState
        let expiresAt: Date
        let verificationEndsAt: Date?
        let bookingId: String?
        let checkout: Summary
    }

    struct CreateHold: Encodable {
        let eventId: String
        let programVersion: String
    }

    struct StartPayment: Encodable {
        let acceptedTermsVersion: String
        let termsAccepted: Bool
    }

    struct Payment: Decodable {
        struct Action: Decodable {
            let type: String
            let url: URL
        }

        let nextAction: Action?
    }

    struct Card: Identifiable, Decodable {
        let id: String
        let title: String
        let placeLabel: String
        let startsAt: Date
        let timeZone: String
        let cover: Media?
    }

    struct Detail: Decodable {
        let event: Card
    }

    struct Participant: Decodable {
        let displayName: String
        let avatar: Media?
    }

    struct Entry: Identifiable, Decodable {
        let id: String
        let event: Card
        let status: String
        let attendance: String
        let canShowPass: Bool
        let visibleParticipantPreview: [Participant]
    }

    struct Page: Decodable {
        let items: [Entry]
        let nextCursor: String?
    }

    @MainActor
    static func bookings(_ bucket: String, api: ClubAPI) async throws -> [Entry] {
        var result = [Entry]()
        var cursor: String?
        repeat {
            var route = URLComponents()
            route.path = "me/bookings"
            route.queryItems = [URLQueryItem(name: "bucket", value: bucket)]
            if let cursor { route.queryItems?.append(URLQueryItem(name: "cursor", value: cursor)) }
            guard let path = route.string else { throw ClubAPIError.configuration }
            let page = try await api.get(path, as: Page.self)
            result.append(contentsOf: page.items)
            cursor = page.nextCursor
        } while cursor != nil
        return result
    }

    struct Pass: Decodable {
        struct MeetingPoint: Decodable {
            let label: String
        }

        let bookingId: String
        let eventId: String
        let title: String
        let startsAt: Date
        let timeZone: String
        let meetingPoint: MeetingPoint
        let qrPayload: String
        let validUntil: Date
    }

    static func date(_ value: Date, in timeZone: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.timeZone = TimeZone(identifier: timeZone) ?? TimeZone(secondsFromGMT: 0)
        formatter.setLocalizedDateFormatFromTemplate("d MMM yyyy HHmm")
        return formatter.string(from: value)
    }
}
