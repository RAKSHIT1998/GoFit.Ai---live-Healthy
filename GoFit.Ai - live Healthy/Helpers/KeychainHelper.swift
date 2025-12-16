import Foundation
import Security

final class KeychainHelper {
    static let standard = KeychainHelper()
    private init() {}

    func save(_ data: Data, service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account
        ]
        SecItemDelete(query as CFDictionary)
        let attributes: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account,
            kSecValueData as String   : data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(attributes as CFDictionary, nil)
    }

    func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account,
            kSecReturnData as String  : kCFBooleanTrue as Any,
            kSecMatchLimit as String  : kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrService as String : service,
            kSecAttrAccount as String : account
        ]
        SecItemDelete(query as CFDictionary)
    }

    // Convenience
    func save<T: Codable>(_ item: T, service: String, account: String) {
        do {
            let data = try JSONEncoder().encode(item)
            save(data, service: service, account: account)
        } catch { print("Keychain save error:", error) }
    }

    func read<T: Codable>(_ type: T.Type, service: String, account: String) -> T? {
        guard let data = read(service: service, account: account) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
//
//  KeychainHelper.swift
//  GoFit.Ai - live Healthy
//
//  Created by Rakshit Bargotra on 12/12/25.
//

