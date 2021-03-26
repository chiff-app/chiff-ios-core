//
//  WebAuthn+Attestation.swift
//  ChiffCore
//
//  Copyright: see LICENSE.md
//

#if os(iOS)
import UIKit
import CryptoKit
import DeviceCheck
import PromiseKit
import LocalAuthentication

enum AttestationError: Error {
    case lengthOverflow
}

@available(iOS 13.0, *) fileprivate typealias PrivateKey = SecureEnclave.P256.Signing.PrivateKey

@available(iOS 14.0, *)
public struct Attestation {

    private static let header: [UInt8] = [0x02, 0x01, 0x00, 0x30, 0x6a]
    private static let organizationalUnitName: [UInt8] = [0x31, 0x22, 0x30, 0x20, 0x06, 0x03, 0x55, 0x04, 0x0b, 0x0c, 0x19, 0x41, 0x75, 0x74, 0x68, 0x65, 0x6e, 0x74, 0x69, 0x63, 0x61, 0x74, 0x6f, 0x72, 0x20, 0x41, 0x74, 0x74, 0x65, 0x73, 0x74, 0x61, 0x74, 0x69, 0x6f, 0x6e]
    private static let commonName: [UInt8] = [0x31, 0x22, 0x30, 0x20, 0x06, 0x03, 0x55, 0x04, 0x03, 0x0c, 0x19, 0x43, 0x68, 0x69, 0x66, 0x66, 0x20, 0x46, 0x49, 0x44, 0x4f, 0x20, 0x41, 0x74, 0x74, 0x65, 0x73, 0x74, 0x61, 0x74, 0x69, 0x6f, 0x6e, 0x20, 0x76, 0x31]
    private static let country: [UInt8] = [0x31, 0x0b, 0x30, 0x09, 0x06, 0x03, 0x55, 0x04, 0x06, 0x13, 0x02, 0x4e, 0x4c]
    private static let organizationName: [UInt8] = [0x31, 0x13, 0x30, 0x11, 0x06, 0x03, 0x55, 0x04, 0x0a, 0x0c, 0x0a, 0x43, 0x68, 0x69, 0x66, 0x66, 0x20, 0x42, 0x2e, 0x56, 0x2e]
    private static let extensions: [UInt8] = [0xa0, 0x42, 0x30, 0x40, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x09, 0x0e, 0x31, 0x33, 0x30, 0x31, 0x30, 0x0c, 0x06, 0x03, 0x55, 0x1d, 0x13, 0x01, 0x01, 0xff, 0x04, 0x02, 0x30, 0x00, 0x30, 0x21, 0x06, 0x0b, 0x2b, 0x06, 0x01, 0x04, 0x01, 0x82, 0xe5, 0x1c, 0x01, 0x01, 0x04, 0x04, 0x12, 0x04, 0x10]
    private static let signatureHeader: [UInt8] = [0x30, 0x0a, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x04, 0x03, 0x02]

    private static var service: DCAppAttestService {
        return DCAppAttestService.shared
    }

    /// Generate an attestation KeyPair.
    public static func attestDevice(context: LAContext?) -> Promise<Void> {
        guard !Keychain.shared.has(id: KeyIdentifier.attestation.identifier(for: .attestation), service: .attestation, context: context),
              let id = UIDevice.current.identifierForVendor?.uuidString,
              service.isSupported else {
            return .value(())
        }
        return firstly { () -> Promise<JSONObject> in
            try API.shared.signedRequest(path: "users/\(Seed.publicKey())/devices/\(id)/attestation", method: .get, privKey: Seed.privateKey())
        }.map { result in
            guard let challenge = result["challenge"] as? String else {
                throw CodingError.unexpectedData
            }
            let keypair = try Crypto.shared.createSecureEnclaveECDSASigningKeyPair(context: context)
            let csr = try createSigningRequest(keypair: keypair)
            let clientData: [String: Any] = [
                "challenge": challenge,
                "csr": csr.base64
            ]
            return (clientData, keypair)
        }.then { (clientData: [String: Any], keypair: PrivateKey) in
            generateKey().map { ($0, clientData, keypair) }
        }.then { (id: String, clientData: [String: Any], keypair: PrivateKey) -> Promise<(Data, PrivateKey)> in
            let clientDataHash = try JSONSerialization.data(withJSONObject: clientData, options: []).sha256
            return attestKey(id: id, clientDataHash: clientDataHash).map { attestation in
                var message = clientData
                message["attestation"] = attestation.base64
                message["httpMethod"] = APIMethod.post.rawValue
                message["timestamp"] = Date.now
                let messageData = try JSONSerialization.data(withJSONObject: message, options: [])
                return (messageData, keypair)
            }
        }.then { (message: Data, keypair: PrivateKey) -> Promise<(JSONObject, PrivateKey)>  in
            let signature = try Crypto.shared.signature(message: message, privKey: Seed.privateKey())
            return try API.shared.request(path: "users/\(Seed.publicKey())/devices/\(id)/attestation", method: .post, signature: signature.base64, body: message).map { ($0, keypair) }
        }.done { (result: JSONObject, keypair: PrivateKey) in
            guard let certificate = result["certificate"] as? String,
                  let certificateData = certificate.fromBase64 else {
                throw CodingError.missingData
            }
            try Keychain.shared.save(id: KeyIdentifier.attestation.identifier(for: .attestation), service: .attestation, secretData: keypair.dataRepresentation, objectData: certificateData, label: nil)
        }.log("Error submitting attestation key").asVoid()
    }

    // MARK: - Private methods

    private static func generateKey() -> Promise<String> {
        if let id = Properties.attestationKeyID {
            return .value(id)
        }
        return firstly {
            Promise { service.generateKey(completionHandler: $0.resolve) }
        }.map { id in
            Properties.attestationKeyID = id
            return id
        }
    }

    private static func attestKey(id: String, clientDataHash: Data) -> Promise<Data> {
        return Promise { service.attestKey(id, clientDataHash: clientDataHash, completionHandler: $0.resolve) }
    }

    private static func createSigningRequest(keypair: SecureEnclave.P256.Signing.PrivateKey) throws -> Data {
        var data = Data()
        data.append(contentsOf: header)
        data.append(contentsOf: organizationalUnitName)
        data.append(contentsOf: commonName)
        data.append(contentsOf: country)
        data.append(contentsOf: organizationName)
        data.append(contentsOf: keypair.publicKey.derRepresentation)
        data.append(contentsOf: extensions)
        data.append(WebAuthn.AAGUID)
        try embedInSequence(&data)
        let signature = try keypair.signature(for: data)
        data.append(contentsOf: signatureHeader)
        var signatureData = Data()
        signatureData.append(0x00)
        signatureData.append(signature.derRepresentation)
        try embedInBitstring(&signatureData)
        data.append(signatureData)
        try embedInSequence(&data)
        return data
    }

    private static func embedInBitstring(_ data: inout Data) throws {
        var newData = Data()
        newData.append(0x03)
        try newData.append(getLength(&data))
        newData.append(data)
        data = newData
    }

    private static func embedInSequence(_ data: inout Data) throws {
        var newData = Data()
        newData.append(0x30)
        try newData.append(getLength(&data))
        newData.append(data)
        data = newData
    }

    private static func getLength(_ data: inout Data) throws -> Data {
        let length = data.count
        var lengthData = Data()
        switch length {
        case 0..<128:
            lengthData.append(UInt8(length))
        case 128..<256:
            lengthData.append(UInt8(0x81))
            lengthData.append(UInt8(length & 0xff))
        case 256..<0x8000:
            lengthData.append(UInt8(0x82))
            lengthData.append((UInt8(length >> 8) & 0xff))
            lengthData.append(UInt8(length & 0xff))
        default:
            throw AttestationError.lengthOverflow
        }
        return lengthData
    }

}
#endif
