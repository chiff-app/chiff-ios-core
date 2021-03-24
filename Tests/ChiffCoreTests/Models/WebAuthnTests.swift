//
//  WebAuthnTests.swift
//  chiffTests
//
//  Copyright: see LICENSE.md
//

import Foundation


import XCTest
import LocalAuthentication
import CryptoKit
import PromiseKit

@testable import ChiffCore

class WebAuthnTests: XCTestCase {

    override static func setUp() {
        super.setUp()

        var finished = false
        if !LocalAuthenticationManager.shared.isAuthenticated {
            LocalAuthenticationManager.shared.authenticate(reason: "Testing", withMainContext: true).done { result in
                finished = true
            }.catch { error in
                fatalError("Failed to get context: \(error.localizedDescription)")
            }
        } else {
            finished = true
        }

        while !finished {
            RunLoop.current.run(mode: .default, before: Date.distantFuture)
        }
    }

    override func setUp() {
        super.setUp()
        Keychain.shared = MockKeychain()
        TestHelper.createSeed()
    }

    override func tearDown() {
        super.tearDown()
        TestHelper.deleteLocalData()
    }

    // MARK: - Unit tests

    @available(iOS 14.0, *)
    func test() {
        let pubKey = "pQECAyYgASFYIBglJ1I0mYojBugIJ3g5gBAcMZnhneY99t-K2NwLvceNIlggD9Z3ufKHPpBKtphU_WCwmTbGxjQ_sFTvMPBKuVCO6Os"
        let signature = "MEYCIQDUzbfvSFkmLNpVnYjIrUNrCDhx1Ei-IPiBE9S_Cd9sVQIhAMCY-GuxzwNirKVhNiyEbPOx6tuBowDPvAMHPlu2LYCQ"
//        let authData = " SZYN5YgOjGh0NBcPZHZgW4_krrmihjLHmVzzuoMdl2PFAAAAAXMHIS7G25hezYBV9kofEAcAICuNEbvooa1amnzeZy3mWd_8zO5mOAzQ82iC5rmS3OQ6pQECAyYgASFYIBglJ1I0mYojBugIJ3g5gBAcMZnhneY99t-K2NwLvceNIlggD9Z3ufKHPpBKtphU_WCwmTbGxjQ_sFTvMPBKuVCO6Oug"
//        let clientDataHash = "v6eJABD95IrTTm57dfkr6NOv8r6-YQBBIS7A28IlA-I"
        let challenge = " SZYN5YgOjGh0NBcPZHZgW4_krrmihjLHmVzzuoMdl2PFAAAAAXMHIS7G25hezYBV9kofEAcAICuNEbvooa1amnzeZy3mWd_8zO5mOAzQ82iC5rmS3OQ6pQECAyYgASFYIBglJ1I0mYojBugIJ3g5gBAcMZnhneY99t-K2NwLvceNIlggD9Z3ufKHPpBKtphU_WCwmTbGxjQ_sFTvMPBKuVCO6Ougv6eJABD95IrTTm57dfkr6NOv8r6-YQBBIS7A28IlA-I"
        do {
            let sig = try P256.Signing.ECDSASignature(derRepresentation: signature.fromBase64!)
            let pk = try P256.Signing.PublicKey(derRepresentation: pubKey.fromBase64!)
            XCTAssertTrue(pk.isValidSignature(sig, for: challenge.fromBase64!))
        } catch {
            XCTFail("Error: \(error)")
        }
    }

//    func testECDSA256Attestation() {
//        do {
//            var webAuthn = try JSONDecoder().decode(WebAuthn.self, from: "{ \"id\": \"webauthn.test\", \"algorithm\": \(WebAuthnAlgorithm.ECDSA256.rawValue), \"counter\": 0, \"salt\": \"WrP22qkpZcs=\" }".data)
//            try saveWebAuthn(id: TestHelper.accountId, webAuthn: webAuthn, context: nil)
//            let (_, counter, attestation) = try webAuthn.signAttestation(accountId: TestHelper.accountId)
//            XCTAssertEqual("sGUwV9kJFHXx7A8hO9-OjXlhoKsvdD_6fF7CP1kGgVhFAAAAAXMHIS7G25hezYBV9kofEAcAINO2i5LWVLOMAmEorwqN2M06XAilGLF3Ys9E60EKoU4-pQECAyYgASFYIH6vGKQAhbez8_XqqxrX2bc8nf1VhyOgh8gC20MP6GAqIlgguoXgpatbBal9eT-QypZaOYxkLOIdSqt23Qmeb_W8E8c", attestation.base64)
//            XCTAssertTrue(counter == 1)
//        } catch {
//            XCTFail("An error was thrown: \(error)")
//        }
//    }
//
//    func testECDSA384Attestation() {
//        do {
//            var webAuthn = try JSONDecoder().decode(WebAuthn.self, from: "{ \"id\": \"webauthn.test\", \"algorithm\": \(WebAuthnAlgorithm.ECDSA384.rawValue), \"counter\": 0, \"salt\": \"WrP22qkpZcs=\" }".data)
//            try saveWebAuthn(id: TestHelper.accountId, webAuthn: webAuthn, context: nil)
//            let (_, counter, attestation) = try webAuthn.signAttestation(accountId: TestHelper.accountId)
//            XCTAssertEqual("sGUwV9kJFHXx7A8hO9-OjXlhoKsvdD_6fF7CP1kGgVhFAAAAAXMHIS7G25hezYBV9kofEAcAINO2i5LWVLOMAmEorwqN2M06XAilGLF3Ys9E60EKoU4-pQECAzgiIAIhWDBCw0nMAW2Ekyp6W0X-IpgE83Txhc0MWGs9chZor9T91ySseRUCE2C-o9ebu3m26d4iWDD1ibrUqVqrFD8jhqdSltl74PNBMkjdbAzt2s8UvC--y_Zv9F35y51-tL8icihrFro", attestation.base64)
//            XCTAssertTrue(counter == 1)
//        } catch {
//            XCTFail("An error was thrown: \(error)")
//        }
//    }
//
//    func testECDSA512Attestation() {
//        do {
//            var webAuthn = try JSONDecoder().decode(WebAuthn.self, from: "{ \"id\": \"webauthn.test\", \"algorithm\": \(WebAuthnAlgorithm.ECDSA512.rawValue), \"counter\": 0, \"salt\": \"WrP22qkpZcs=\" }".data)
//            try saveWebAuthn(id: TestHelper.accountId, webAuthn: webAuthn, context: nil)
//            let (_, counter, attestation) = try webAuthn.signAttestation(accountId: TestHelper.accountId)
//            XCTAssertEqual("sGUwV9kJFHXx7A8hO9-OjXlhoKsvdD_6fF7CP1kGgVhFAAAAAXMHIS7G25hezYBV9kofEAcAINO2i5LWVLOMAmEorwqN2M06XAilGLF3Ys9E60EKoU4-pQECAzgjIAMhWEIAOtXkQ-5PbqQ9YP9bR9DNsXdr9xE3XkZVp4wpwLePrp-eTu26Wie5HXzSU_zUvlDBxzL5_XhDne1CLh2aQC8ns3wiWEIAoOjRRF-___Nxu13_gopK-m1OqTvH1w_yz9ob01mo5Krsm8RLjU6FEql-LD0Pk6nt6tZpTXTAlcJ0zvj3WfZXjeQ", attestation.base64)
//            XCTAssertTrue(counter == 1)
//        } catch {
//            XCTFail("An error was thrown: \(error)")
//        }
//    }
//
//    func testEdDSAAttestation() {
//        do {
//            var webAuthn = try JSONDecoder().decode(WebAuthn.self, from: "{ \"id\": \"webauthn.test\", \"algorithm\": \(WebAuthnAlgorithm.edDSA.rawValue), \"counter\": 0, \"salt\": \"WrP22qkpZcs=\" }".data)
//            try saveWebAuthn(id: TestHelper.accountId, webAuthn: webAuthn, context: nil)
//            let (_, counter, attestation) = try webAuthn.signAttestation(accountId: TestHelper.accountId)
//            XCTAssertEqual("sGUwV9kJFHXx7A8hO9-OjXlhoKsvdD_6fF7CP1kGgVhFAAAAAXMHIS7G25hezYBV9kofEAcAINO2i5LWVLOMAmEorwqN2M06XAilGLF3Ys9E60EKoU4-pAEBAycgBiFYIORi7zJlbhsgGhTrC2awZK2wY0alldE5hlmEhaRP435N", attestation.base64)
//            XCTAssertTrue(counter == 1)
//        } catch {
//            XCTFail("An error was thrown: \(error)")
//        }
//    }

    private func saveWebAuthn(id: String, webAuthn: WebAuthn, context: LAContext?) throws {
        let keyPair = try webAuthn.generateKeyPair(accountId: id, context: context)
        switch webAuthn.algorithm {
        case .edDSA:
            try Keychain.shared.save(id: id, service: .account(attribute: .webauthn), secretData: keyPair.privKey, objectData: keyPair.pubKey)
        case .ECDSA256:
            guard #available(iOS 13.0, *) else {
                throw WebAuthnError.notSupported
            }
            let privKey = try P256.Signing.PrivateKey(rawRepresentation: keyPair.privKey)
            try Keychain.shared.saveKey(id: id, key: privKey)
        case .ECDSA384:
            guard #available(iOS 13.0, *) else {
                throw WebAuthnError.notSupported
            }
            let privKey = try P384.Signing.PrivateKey(rawRepresentation: keyPair.privKey)
            try Keychain.shared.saveKey(id: id, key: privKey)
        case .ECDSA512:
            guard #available(iOS 13.0, *) else {
                throw WebAuthnError.notSupported
            }
            let privKey = try P521.Signing.PrivateKey(rawRepresentation: keyPair.privKey)
            try Keychain.shared.saveKey(id: id, key: privKey)
        }
    }

}
