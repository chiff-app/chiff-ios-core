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
    case notSupported
}

@available(iOS 13.0, *) fileprivate typealias PrivateKey = SecureEnclave.P256.Signing.PrivateKey

@available(iOS 14.0, *)
public struct Attestation {

    private static var service: DCAppAttestService {
        return DCAppAttestService.shared
    }

    public static func attestDevice() -> Promise<Void> {
        guard let deviceId = UIDevice.current.identifierForVendor?.uuidString,
              service.isSupported else {
            return .value(())
        }
        return firstly {
            try API.shared.signedRequest(path: "users/\(Seed.publicKey())/devices/\(deviceId)/attestation", method: .get, privKey: Seed.privateKey(), message: ["id": deviceId])
        }.then { (result: JSONObject) -> Promise<(String, [String: Any])> in
            guard let challenge = result["challenge"] as? String else {
                throw CodingError.unexpectedData
            }
            let clientData: [String: Any] = [
                "pubkey": try Seed.publicKey(),
                "challenge": challenge
            ]
            return generateKey().map { ($0, clientData) }
        }.then { (id: String, clientData: [String: Any]) -> Promise<(Data, String, String)> in
            let jsonData = try JSONSerialization.data(withJSONObject: clientData, options: [])
            return service.attestKey(id, clientDataHash: jsonData.sha256).map { ($0, jsonData.base64, id) }
        }.then { (attestation: Data, clientData: String, id: String) -> Promise<Void>  in
            let data: [String: Any] = [
                "clientData": clientData,
                "keyID": id,
                "attestationObject": attestation.base64
            ]
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            return try API.shared.signedRequest(path: "users/\(Seed.publicKey())/devices/\(deviceId)/attestation", method: .post, privKey: Seed.privateKey(), message: ["hash": jsonData.sha256.hexEncodedString(), "id": deviceId], body: jsonData).asVoid()
        }.done {
            print("TODO: Set flag that attestation is complete")
        }.log("Error submitting attestation key").asVoid()
    }

    /// Generate an attestation KeyPair.
    public static func attestWebAuthnKeypair(keypair: SecureEnclave.P256.Signing.PrivateKey) -> Promise<[Data]> {
        // TODO: check if device attestation has been completed
        guard service.isSupported,
              let id = Properties.attestationKeyID,
              let deviceId = UIDevice.current.identifierForVendor?.uuidString else {
            return Promise(error: AttestationError.notSupported)
        }
        return firstly { () -> Promise<JSONObject> in
            try API.shared.signedRequest(path: "users/\(Seed.publicKey())/devices/\(deviceId)/assertion", method: .get, privKey: Seed.privateKey(), message: ["id": deviceId])
        }.then { (result: JSONObject) -> Promise<(Data, String)> in
            guard let challenge = result["challenge"] as? String else {
                throw CodingError.unexpectedData
            }
            let csr = try CertificateSigningRequest(keypair: keypair)
            let clientData: [String: Any] = [
                "pubkey": try Seed.publicKey(),
                "challenge": challenge,
                "csr": csr.data.base64
            ]
            let jsonData = try JSONSerialization.data(withJSONObject: clientData, options: [])
            return service.generateAssertion(id, clientDataHash: jsonData.sha256).map { ($0, jsonData.base64) }
        }.then { (assertion: Data, clientData: String) -> Promise<[String]>  in
            let data: [String: Any] = [
                "clientData": clientData,
                "assertion": assertion.base64
            ]
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            return try API.shared.signedRequest(path: "users/\(Seed.publicKey())/devices/\(deviceId)/assertion", method: .post, privKey: Seed.privateKey(), message: ["hash": jsonData.sha256.hexEncodedString(), "id": deviceId], body: jsonData)
        }.map { certificates in
            return try certificates.map { try Crypto.shared.convertFromBase64(from: $0) }
        }.log("Error submitting attestation key")
    }

    // MARK: - Private methods

    private static func generateKey() -> Promise<String> {
        if let id = Properties.attestationKeyID {
            return .value(id)
        }
        return service.generateKey().get {
            Properties.attestationKeyID = $0
        }
    }

}
#endif
