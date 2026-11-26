import Foundation
import OSLog
import Security

struct SessionKeychain {
    let account: String

    private static let logger = Logger(subsystem: "com.vubesclub.app", category: "SessionKeychain")

    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.vubesclub.app.session",
            kSecAttrAccount as String: account
        ]
    }

    func read() -> ClubTokens? {
        var request = query
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            Self.logger.error("Keychain read failed (\(status)).")
            return nil
        }
        return try? JSONDecoder().decode(ClubTokens.self, from: data)
    }

    func save(_ tokens: ClubTokens) throws {
        let attributes: [String: Any] = [
            kSecValueData as String: try JSONEncoder().encode(tokens),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let item = query.merging(attributes) { _, new in new }
        var status = SecItemAdd(item as CFDictionary, nil)
        if status == errSecDuplicateItem {
            status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        }
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }

    func remove() {
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            Self.logger.error("Keychain delete failed (\(status)).")
        }
    }
}
