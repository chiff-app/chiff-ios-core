//
//  WebAuthn.swift
//  chiff
//
//  Copyright: see LICENSE.md
//

import Foundation
import LocalAuthentication
import CryptoKit
import CommonCrypto

enum WebAuthnError: Error {
    case wrongRpId
    case notSupported
    case wrongAlgorithm
}

public enum WebAuthnAlgorithm: Int, Codable, Equatable {
    case edDSA = -8
    case ECDSA256 = -7
    case ECDSA384 = -35
    case ECDSA512 = -36

    var keyLength: Int {
        switch self {
        case .edDSA, .ECDSA256: return 32
        case .ECDSA384: return 48
        case .ECDSA512: return 65
        }
    }
}

public struct WebAuthnExtensions: Codable {
    let hmacSecret: Bool?
    let credentialProtectionPolicy: Int?

    enum CodingKeys: String, CodingKey {
        case hmacSecret = "hs"
        case credentialProtectionPolicy = "cp"
    }
}

/// A WebAuthn for an account.
public struct WebAuthn: Equatable {
    /// This is the RPid (relying party id) in WebAuthn definition.
    let id: String
    let algorithm: WebAuthnAlgorithm
    let salt: Data
    var counter: Int = 0

    static let cryptoContext = "webauthn"
//    static let AAGUID = Data([UInt8](arrayLiteral: 0x73, 0x07, 0x21, 0x2e, 0xc6, 0xdb, 0x98, 0x5e, 0xcd, 0x80, 0x55, 0xf6, 0x4a, 0x1f, 0x10, 0x07))
    static let AAGUID = Data([UInt8](arrayLiteral:     0xd6,
                                     0xd0,
                                     0xbd,
                                     0xc3,
                                     0x62,
                                     0xee,
                                     0xc4,
                                     0xdb,
                                     0xde,
                                     0x8d,
                                     0x7a,
                                     0x65,
                                     0x6e,
                                     0x4a,
                                     0x44,
                                     0x87))

    /// Create a new WebAuthn object.
    /// - Parameters:
    ///   - id: The relying party id (RPid)
    ///   - algorithms: The algorithms should be provided in order of preference.
    /// - Throws: Crypto errors if no accepted algorithm is found.
    init(id: String, algorithms: [WebAuthnAlgorithm]) throws {
        var algorithm: WebAuthnAlgorithm?
        if #available(iOS 13.0, *) {
            algorithm = algorithms.first
        } else if algorithms.contains(.edDSA) {
            algorithm = .edDSA
        }
        guard let acceptedAlgorithm = algorithm else {
            throw WebAuthnError.notSupported
        }
        self.algorithm = acceptedAlgorithm
        self.id = id
        self.salt = try Crypto.shared.generateSeed(length: 8)
    }

    /// Generate a WebAuthn signing keypair.
    /// - Parameters:
    ///   - accountId: The account id.
    ///   - context: Optionally, an authenticated `LAContext` object.
    /// - Throws: Crypto or Keychain errors.
    /// - Returns: The signing keypair.
    func generateKeyPair(accountId: String, context: LAContext?) throws -> KeyPair {
        let siteKey = try Crypto.shared.deriveKey(keyData: try Seed.getWebAuthnSeed(context: context), context: Self.cryptoContext, index: id.sha256Data)
        let key = try Crypto.shared.deriveKey(keyData: siteKey, context: String(accountId.sha256Data.base64.prefix(8)), index: salt)
        var keyPair: KeyPair
        if case .edDSA = algorithm {
            keyPair = try Crypto.shared.createSigningKeyPair(seed: key)
        } else if #available(iOS 13.0, *) {
            keyPair = try Crypto.shared.createECDSASigningKeyPair(seed: key, algorithm: algorithm)
        } else {
            // Should only occur in the unlikely case that someone downgrades iOS version after initializing.
            throw WebAuthnError.notSupported
        }
        return keyPair
    }

    /// Return the public key of the signing keypair.
    /// - Parameter accountId: The account id.
    /// - Throws: Crypto or Keychain errors.
    /// - Returns: The public key.
    func pubKey(accountId: String) throws -> Data {
        switch algorithm {
        case .edDSA:
            guard let pubKey = try Keychain.shared.attributes(id: accountId, service: .account(attribute: .webauthn)) else {
                throw KeychainError.notFound
            }
            return pubKey
        case .ECDSA256:
            guard #available(iOS 13.0, *) else {
                throw WebAuthnError.notSupported
            }
            guard let key: P256.Signing.PrivateKey = try Keychain.shared.getKey(id: accountId, context: nil) else {
                throw KeychainError.notFound
            }
            return key.publicKey.rawRepresentation
        case .ECDSA384:
            guard #available(iOS 13.0, *) else {
                throw WebAuthnError.notSupported
            }
            guard let key: P384.Signing.PrivateKey = try Keychain.shared.getKey(id: accountId, context: nil) else {
                throw KeychainError.notFound
            }
            return key.publicKey.rawRepresentation
        case .ECDSA512:
            guard #available(iOS 13.0, *) else {
                throw WebAuthnError.notSupported
            }
            guard let key: P521.Signing.PrivateKey = try Keychain.shared.getKey(id: accountId, context: nil) else {
                throw KeychainError.notFound
            }
            return key.publicKey.rawRepresentation
        }
    }

    /// Return the base64 encoded public key of the signing keypair.
    /// - Parameter accountId: The account id.
    /// - Throws: Crypto or Keychain errors.
    /// - Returns: The base64 encoded public key.
    func pubKey(accountId: String) throws -> String {
        return try Crypto.shared.convertToBase64(from: pubKey(accountId: accountId))
    }

    /// Save the keypair to the Keychain.
    /// - Parameters:
    ///   - accountId: The account id to use as an identifier.
    ///   - keyPair: The keypair.
    /// - Throws: Crypto or Keychain errors.    
    func save(accountId: String, keyPair: KeyPair) throws {
        switch algorithm {
        case .edDSA: try Keychain.shared.save(id: accountId, service: .account(attribute: .webauthn), secretData: keyPair.privKey, objectData: keyPair.pubKey)
        case .ECDSA256:
            guard #available(iOS 13.0, *) else {
                throw WebAuthnError.notSupported
            }
            let privKey = try P256.Signing.PrivateKey(rawRepresentation: keyPair.privKey)
            try Keychain.shared.saveKey(id: accountId, key: privKey)
        case .ECDSA384:
            guard #available(iOS 13.0, *) else {
                throw WebAuthnError.notSupported
            }
            let privKey = try P384.Signing.PrivateKey(rawRepresentation: keyPair.privKey)
            try Keychain.shared.saveKey(id: accountId, key: privKey)
        case .ECDSA512:
            guard #available(iOS 13.0, *) else {
                throw WebAuthnError.notSupported
            }
            let privKey = try P521.Signing.PrivateKey(rawRepresentation: keyPair.privKey)
            try Keychain.shared.saveKey(id: accountId, key: privKey)
        }
    }

    /// Delete this WebAuthn keypair from the Keychain.
    /// - Parameter accountId: The account id.
    /// - Throws: Keyhain errors.
    func delete(accountId: String) throws {
        switch algorithm {
        case .edDSA: try Keychain.shared.delete(id: accountId, service: .account(attribute: .webauthn))
        default:
            guard #available(iOS 13.0, *) else {
                throw WebAuthnError.notSupported
            }
            try Keychain.shared.deleteKey(id: accountId)
        }
    }

    /// Sign a WebAuthn challenge.
    /// - Parameters:
    ///   - accountId: The account id.
    ///   - challenge: The challenge to be signed.
    ///   - rpId: The relying party id.
    /// - Throws: Keychain, Crypto or WebAuthn errors.
    /// - Returns: A tuple with the signature and the used counter.
    mutating func sign(accountId: String, challenge: String, rpId: String) throws -> (String, Int) {
        guard rpId == id else {
            throw WebAuthnError.wrongRpId
        }
        let challengeData = try Crypto.shared.convertFromBase64(from: challenge)
        let data = try createAuthenticatorData(accountId: nil, extensions: nil) + challengeData
        return (try sign(accountId: accountId, data: data), counter)
    }

    /// Get a self-signed WebAuthn attestation
    /// - Parameters:
    ///   - accountId: The account id.
    /// - Throws: Keychain, Crypto or WebAuthn errors.
    /// - Returns: A triple with the signature, used counter and the attestation data.
    mutating func signAttestation(accountId: String, clientData: String, extensions: WebAuthnExtensions?) throws -> (String, Int, Data) {
        let authData = try createAuthenticatorData(accountId: accountId, extensions: extensions)
        let clientDataHash = try Crypto.shared.convertFromBase64(from: clientData)
        let data = authData + clientDataHash
//        let signature = try sign(accountId: accountId, data: data)
        guard #available(iOS 13.0, *) else {
            throw WebAuthnError.notSupported
        }
        let trezorPrivKey = try P256.Signing.PrivateKey(rawRepresentation: "cSasK_ZE3GGGrYPvH83xKle1z6IAC4rQJ-lW6FTFCos".fromBase64!)
        let signature = try trezorPrivKey.signature(for: data)
        print("Auth data: \(authData.base64)")
        print("Client data hash: \(clientDataHash.base64)")
        print("Sig data: \(data.base64)")
        print("Pub key: \(trezorPrivKey.publicKey.rawRepresentation.base64)")
        print("Signature: \(signature.derRepresentation.base64)")
        return (signature.derRepresentation.base64, counter, data)
    }

    // MARK: - Private functions

    private mutating func createAuthenticatorData(accountId: String?, extensions: WebAuthnExtensions?) throws -> Data {
        counter += 1
        var data = Data()
        data.append(id.sha256Data)
        data.append(0x05) // UP + UV flags
        data.append(UInt8((counter >> 24) & 0xff))
        data.append(UInt8((counter >> 16) & 0xff))
        data.append(UInt8((counter >> 8) & 0xff))
        data.append(UInt8((counter >> 0) & 0xff))
        if let accountId = accountId {
            data[32] |= 1 << 6 // Set attestation flag
            let accountIdData = try Crypto.shared.fromHex(accountId).prefix(16)
            data.append(WebAuthn.AAGUID)
            data.append(UInt8((accountIdData.count >> 8) & 0xff))
            data.append(UInt8(accountIdData.count & 0xff))
            data.append(accountIdData)
            switch algorithm {
            case .edDSA:
                data.append(contentsOf: [UInt8](arrayLiteral: 0xa4, 0x01, 0x01, 0x03, 0x27, 0x20, 0x06, 0x21, 0x58, 0x20))
                data.append(try pubKey(accountId: accountId))
            case .ECDSA256:
                let pubkey: Data = try pubKey(accountId: accountId)
                data.append(contentsOf: [UInt8](arrayLiteral: 0xa5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20))
                data.append(pubkey.prefix(algorithm.keyLength))
                data.append(contentsOf: [0x22, 0x58, 0x20])
                data.append(pubkey.suffix(algorithm.keyLength))
            case .ECDSA384:
                let pubkey: Data = try pubKey(accountId: accountId)
                data.append(contentsOf: [UInt8](arrayLiteral: 0xa5, 0x01, 0x02, 0x03, 0x38, 0x22, 0x20, 0x02, 0x21, 0x58, 0x30))
                data.append(pubkey.prefix(algorithm.keyLength))
                data.append(contentsOf: [UInt8](arrayLiteral: 0x22, 0x58, 0x30))
                data.append(pubkey.suffix(algorithm.keyLength))
            case .ECDSA512:
                let pubkey: Data = try pubKey(accountId: accountId)
                data.append(contentsOf: [UInt8](arrayLiteral: 0xa5, 0x01, 0x02, 0x03, 0x38, 0x23, 0x20, 0x03, 0x21, 0x58, 0x42))
                data.append(pubkey.prefix(algorithm.keyLength + 1)) // We also need the heading zero bytes here
                data.append(contentsOf: [UInt8](arrayLiteral: 0x22, 0x58, 0x42))
                data.append(pubkey.suffix(algorithm.keyLength + 1)) // We also need the heading zero bytes here
            }
        }
        if let extensions = extensions {
            var count = 0
            var extensionData = Data()
            if extensions.credentialProtectionPolicy != nil {
                count += 1
                extensionData.append(contentsOf: [UInt8](arrayLiteral: 0x6b, 0x63, 0x72, 0x65, 0x64, 0x50, 0x72, 0x6F, 0x74, 0x65, 0x63, 0x74, 0x01))
            }
            if let hmac = extensions.hmacSecret, hmac {
                count += 1
                extensionData.append(contentsOf: [UInt8](arrayLiteral: 0x6b, 0x68, 0x6D, 0x61, 0x63, 0x2D, 0x73, 0x65, 0x63, 0x72, 0x65, 0x74, 0xf5))
            }
            if !extensionData.isEmpty {
                data[32] |= 1 << 7 // Set extension flag
                data.append(UInt8(0xa0 + count))
                data.append(extensionData)
            }
        }
        return data
    }

    private func sign(accountId: String, data: Data) throws -> String {
        switch algorithm {
        case .edDSA:
            guard let privKey: Data = try Keychain.shared.get(id: accountId, service: .account(attribute: .webauthn)) else {
                throw KeychainError.notFound
            }
            let signature = try Crypto.shared.signature(message: data, privKey: privKey)
            return signature.base64
        case .ECDSA256:
            guard #available(iOS 13.0, *) else {
                throw WebAuthnError.notSupported
            }
            guard let privKey: P256.Signing.PrivateKey = try Keychain.shared.getKey(id: accountId, context: nil) else {
                throw KeychainError.notFound
            }
            let signature = try privKey.signature(for: data)
            return signature.derRepresentation.base64
        case .ECDSA384:
            guard #available(iOS 13.0, *) else {
                throw WebAuthnError.notSupported
            }
            guard let privKey: P384.Signing.PrivateKey = try Keychain.shared.getKey(id: accountId, context: nil) else {
                throw KeychainError.notFound
            }
            let signature = try privKey.signature(for: data)
            return signature.derRepresentation.base64
        case .ECDSA512:
            guard #available(iOS 13.0, *) else {
                throw WebAuthnError.notSupported
            }
            guard let privKey: P521.Signing.PrivateKey = try Keychain.shared.getKey(id: accountId, context: nil) else {
                throw KeychainError.notFound
            }
            let signature = try privKey.signature(for: data)
            return signature.derRepresentation.base64
        }
    }
//
//    private func generateX509Certificate(key: Data) -> Data {
//        var result = Data()
//
//        let encodingLength: Int = (key.count + 1).encodedOctets().count
//        let OID: [UInt8] = [0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
//            0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00]
//
//        // ASN.1 SEQUENCE
//        result.append(0x30)
//
//        // Overall size, made of OID + bitstring encoding + actual key
//        let size = OID.count + 2 + encodingLength + key.count
//        let encodedSize = size.encodedOctets()
//        result.append(contentsOf: encodedSize)
//        result.append(contentsOf: OID)
//
//        result.append(0x03)
//        result.append(contentsOf: (key.count + 1).encodedOctets())
//        result.append(0x00)
//
//        // Actual key bytes
//
//        result.append(key)
//
//        return result as Data
//    }

}

extension WebAuthn: Codable {

    enum CodingKeys: CodingKey {
        case id
        case algorithm
        case salt
        case counter
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(String.self, forKey: .id)
        self.algorithm = try values.decode(WebAuthnAlgorithm.self, forKey: .algorithm)
        do {
            self.salt = try values.decode(Data.self, forKey: .salt)
        } catch is DecodingError {
            var integer = try values.decode(UInt64.self, forKey: .salt)
            self.salt = withUnsafeBytes(of: &integer) { Data($0) }
        }
        self.counter = try values.decode(Int.self, forKey: .counter)
    }
}

//extension Int {
//    func encodedOctets() -> [UInt8] {
//        // Short form
//        if self < 128 {
//            return [UInt8(self)];
//        }
//
//        // Long form
//        let i = Int(log2(Double(self)) / 8 + 1)
//        var len = self
//        var result: [UInt8] = [UInt8(i + 0x80)]
//
//        for _ in 0..<i {
//            result.insert(UInt8(len & 0xFF), at: 1)
//            len = len >> 8
//        }
//
//        return result
//    }
//}
