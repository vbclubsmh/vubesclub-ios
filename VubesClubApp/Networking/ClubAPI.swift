import Foundation

enum ClubAPIError: LocalizedError {
    case configuration, response, authentication, invitationRequired
    case server(status: Int, code: String, message: String)

    var errorDescription: String? {
        switch self {
        case .configuration: "Vubes API adresi geçersiz."
        case .response: "Sunucudan geçerli bir yanıt alınamadı."
        case .authentication: "Oturumunuz sona erdi. Lütfen tekrar giriş yapın."
        case .invitationRequired: "Bu numarayla kayıtlı bir üyelik bulunamadı. Davet kodunuzla başvurabilirsiniz."
        case let .server(_, _, message): message
        }
    }

    /// A message for the user: the server's own text for API errors, a fixed key for transport failures.
    static func message(for error: Error) -> String {
        // Bilinen sunucu kodları, seçili dile çevrilen sabit anahtarlara eşlenir; bilinmeyenler sunucunun metnini gösterir.
        if let failure = error as? ClubAPIError, case let .server(status, code, _) = failure {
            switch code {
            case "OTP_INVALID": return "That code isn’t right. Check it and try again."
            case "OTP_EXPIRED": return "That code has expired. Request a new one."
            case "OTP_LIMIT": return "Too many attempts. Please wait a few minutes and try again."
            case "EMAIL_UNAVAILABLE", "SMS_UNAVAILABLE": return "We couldn’t send your code right now. Try again in a moment."
            case "MEMBER_EXISTS": return "A membership with this phone number or email already exists."
            case "EMAIL_TAKEN": return "That email address is already used by another membership."
            case "PHONE_TAKEN": return "That phone number is already used by another membership."
            case "DEMO_ACCOUNT": return "The demo account’s contact details can’t be changed."
            case "BIRTH_DATE_LOCKED": return "Your birth date can’t be changed. Contact support to correct it."
            case "AVATAR_TOO_LARGE": return "That photo is too large. Choose a smaller one."
            default: break
            }
            if status >= 500 { return "Something went wrong on our side. Try again in a moment." }
        }
        if let failure = error as? ClubAPIError, case .server = failure { return failure.errorDescription ?? "" }
        if let failure = error as? ClubAPIError { return failure.errorDescription ?? "Something went wrong." }
        if let failure = error as? URLError {
            switch failure.code {
            case .notConnectedToInternet, .networkConnectionLost: return "You appear to be offline."
            default: return "Can’t reach the server. Try again in a moment."
            }
        }
        return "Something went wrong. Try again."
    }

    var isUnauthorized: Bool {
        if case .server(401, _, _) = self { return true }
        if case .authentication = self { return true }
        return false
    }
}

private final class NoAPIRedirects: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession, task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}

@MainActor
final class ClubAPI {
    private let baseURL: URL?
    private let network: URLSession
    private let keychain: SessionKeychain
    private var tokens: ClubTokens?
    private var refreshTask: Task<ClubTokens, Error>?
    private var generation = UUID()

    var onSessionExpired: (() -> Void)?
    var hasSession: Bool { tokens != nil }

    static let shared = ClubAPI.configured()

    static func configured() -> ClubAPI {
        let raw = ProcessInfo.processInfo.environment["VUBES_API_BASE_URL"]
            ?? Bundle.main.object(forInfoDictionaryKey: "VubesAPIBaseURL") as? String
            ?? ""
        let address = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return ClubAPI(address: address)
    }

    init(address: String) {
        var root = URLComponents(string: address)
        if let components = root {
            var permitted = components.scheme?.lowercased() == "https"
            #if DEBUG
            permitted = permitted || components.scheme?.lowercased() == "http"
            #endif
            if !permitted || components.host == nil || components.user != nil ||
                components.password != nil || components.query != nil || components.fragment != nil {
                root = nil
            }
        }
        if var valid = root {
            let path = valid.path.split(separator: "/").joined(separator: "/")
            valid.path = path.isEmpty ? "/api/v1" : "/" + path
            baseURL = valid.url
        } else {
            baseURL = nil
        }

        keychain = SessionKeychain(account: baseURL?.absoluteString ?? "invalid-api-address")
        tokens = keychain.read()
        let options = URLSessionConfiguration.ephemeral
        options.httpShouldSetCookies = false
        options.urlCredentialStorage = nil
        options.urlCache = nil
        options.timeoutIntervalForRequest = 20
        network = URLSession(configuration: options, delegate: NoAPIRedirects(), delegateQueue: nil)
    }

    func resourceURL(_ reference: URL) -> URL? {
        guard let baseURL,
              let url = URL(string: reference.relativeString, relativeTo: baseURL)?.absoluteURL,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              components.user == nil, components.password == nil, components.host != nil else {
            return nil
        }

        if url.scheme?.lowercased() == "https" { return url }
        #if DEBUG
        if url.scheme == baseURL.scheme && url.host == baseURL.host && url.port == baseURL.port {
            return url
        }
        #endif
        return nil
    }

    func publicGet<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
        try decode(type, from: await transmit("GET", path: path))
    }

    func get<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
        try decode(type, from: await call("GET", path: path))
    }

    func send<T: Decodable, B: Encodable>(
        _ method: String, _ path: String, body: B, as type: T.Type,
        headers: [String: String] = [:]
    ) async throws -> T {
        try decode(type, from: await call(method, path: path, body: encode(body), headers: headers))
    }

    /// Sends raw bytes (for example a JPEG) and decodes the JSON reply.
    func upload<T: Decodable>(
        _ method: String, _ path: String, data: Data, contentType: String, as type: T.Type
    ) async throws -> T {
        try decode(type, from: await call(method, path: path, body: data, headers: ["Content-Type": contentType]))
    }

    /// A request without a body whose JSON reply is decoded.
    func fetch<T: Decodable>(_ method: String, _ path: String, as type: T.Type) async throws -> T {
        try decode(type, from: await call(method, path: path))
    }

    func empty(_ method: String, _ path: String) async throws {
        _ = try await call(method, path: path)
    }

    func sendEmpty<B: Encodable>(_ method: String, _ path: String, body: B) async throws {
        _ = try await call(method, path: path, body: encode(body))
    }

    func publicPost<B: Encodable, T: Decodable>(_ path: String, body: B, as type: T.Type) async throws -> T {
        try decode(type, from: await transmit("POST", path: path, body: encode(body)))
    }

    func publicPost<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
        try decode(type, from: await transmit("POST", path: path))
    }

    func accept(_ value: ClubTokens) throws {
        try keychain.save(value)
        generation = UUID()
        refreshTask?.cancel()
        refreshTask = nil
        tokens = value
    }

    func signOut() {
        let previous = tokens
        forget()
        guard let previous else { return }
        Task { await revoke(previous) }
    }

    private func forget() {
        generation = UUID()
        refreshTask?.cancel()
        refreshTask = nil
        tokens = nil
        keychain.remove()
    }

    private func revoke(_ value: ClubTokens) async {
        do {
            _ = try await transmit("DELETE", path: "auth/session", bearer: value.accessToken)
        } catch let failure as ClubAPIError where failure.isUnauthorized && value.sessionExpiresAt > .now {
            if let updated = try? await exchange(value.refreshToken) {
                _ = try? await transmit("DELETE", path: "auth/session", bearer: updated.accessToken)
            }
        } catch {
            // Offline sign-out still removes all local credentials.
        }
    }

    private func call(
        _ method: String, path: String, body: Data? = nil, headers: [String: String] = [:]
    ) async throws -> Data {
        let scope = generation
        guard let original = tokens else { throw ClubAPIError.authentication }
        let initial = original.accessExpiresAt > Date.now.addingTimeInterval(15)
            ? original : try await refresh(for: original, scope: scope)
        try check(scope)

        do {
            let result = try await transmit(method, path: path, body: body, headers: headers, bearer: initial.accessToken)
            try check(scope)
            return result
        } catch let failure as ClubAPIError where failure.isUnauthorized {
            try check(scope)
            let retry = try await refresh(for: initial, scope: scope)
            do {
                let result = try await transmit(method, path: path, body: body, headers: headers, bearer: retry.accessToken)
                try check(scope)
                return result
            } catch let failure as ClubAPIError where failure.isUnauthorized {
                if scope == generation { forget(); onSessionExpired?() }
                throw ClubAPIError.authentication
            }
        }
    }

    private func refresh(for expired: ClubTokens, scope: UUID) async throws -> ClubTokens {
        try check(scope)
        guard let current = tokens else { throw ClubAPIError.authentication }
        if current.accessToken != expired.accessToken { return current }
        if let task = refreshTask { return try await task.value }
        let task = Task<ClubTokens, Error> {
            defer { if self.generation == scope { self.refreshTask = nil } }
            do {
                guard current.sessionExpiresAt > .now else { throw ClubAPIError.authentication }
                let updated = try await self.exchange(current.refreshToken)
                try self.check(scope)
                try self.keychain.save(updated)
                self.tokens = updated
                return updated
            } catch let failure as ClubAPIError where failure.isUnauthorized {
                if scope == self.generation {
                    self.forget()
                    self.onSessionExpired?()
                }
                throw ClubAPIError.authentication
            }
        }
        refreshTask = task
        return try await task.value
    }

    private func exchange(_ token: String) async throws -> ClubTokens {
        try await publicPost("auth/session/refresh", body: ["refreshToken": token], as: ClubTokens.self)
    }

    private func check(_ scope: UUID) throws {
        guard scope == generation else { throw CancellationError() }
        try Task.checkCancellation()
    }

    private func transmit(
        _ method: String, path: String, body: Data? = nil, headers: [String: String] = [:], bearer: String? = nil
    ) async throws -> Data {
        guard let baseURL, var url = URLComponents(url: baseURL, resolvingAgainstBaseURL: false),
              let route = URLComponents(string: path), route.scheme == nil, route.host == nil,
              route.fragment == nil, !route.path.split(separator: "/").contains("..") else {
            throw ClubAPIError.configuration
        }
        let relative = route.percentEncodedPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        url.percentEncodedPath += "/" + relative
        url.percentEncodedQuery = route.percentEncodedQuery
        guard let endpoint = url.url else { throw ClubAPIError.configuration }

        var request = URLRequest(url: endpoint)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key) }
        if let bearer { request.setValue("Bearer " + bearer, forHTTPHeaderField: "Authorization") }

        let (data, response) = try await network.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ClubAPIError.response }
        guard (200..<300).contains(http.statusCode) else {
            struct ErrorBody: Decodable { let code: String; let message: String }
            let error = try? JSONDecoder().decode(ErrorBody.self, from: data)
            throw ClubAPIError.server(status: http.statusCode, code: error?.code ?? "HTTP_\(http.statusCode)",
                                      message: error?.message ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode))
        }
        return data
    }

    private func encode<B: Encodable>(_ body: B) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(body)
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let box = try decoder.singleValueContainer()
            let raw = try box.decode(String.self)
            let precise = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
            let standard = Date.ISO8601FormatStyle()
            if let date = try? precise.parse(raw) { return date }
            if let date = try? standard.parse(raw) { return date }
            throw DecodingError.dataCorruptedError(in: box, debugDescription: "Invalid ISO-8601 timestamp")
        }
        return try decoder.decode(type, from: data)
    }
}
