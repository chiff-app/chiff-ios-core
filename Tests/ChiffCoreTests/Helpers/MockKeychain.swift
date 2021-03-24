//
//  File.swift
//  
//
//  Created by Bas Doorn on 24/03/2021.
//

import Foundation
import LocalAuthentication
import PromiseKit
@testable import ChiffCore

class MockKeychain: KeychainProtocol {

    var data = [String: (Data?,Data?)]()
    var keys  = [String: SecKeyConvertible]()

    func save(id identifier: String, service: KeychainService, secretData: Data?, objectData: Data?, label: String?) throws {
        data["\(service.service)-\(identifier)"] = (secretData, objectData)
    }

    func get(id identifier: String, service: KeychainService, context: LAContext?) throws -> Data? {
        return data["\(service.service)-\(identifier)"]?.0
    }

    func get(id identifier: String, service: KeychainService, reason: String, with context: LAContext?, authenticationType type: AuthenticationType) -> Promise<Data?> {
        do {
            return .value(try self.get(id: identifier, service: service, context: nil))
        } catch {
            return Promise(error: error)
        }
    }

    func attributes(id identifier: String, service: KeychainService, context: LAContext?) throws -> Data? {
        return data["\(service.service)-\(identifier)"]?.1
    }

    func all(service: KeychainService, context: LAContext?, label: String?) throws -> [[String : Any]]? {
        return data.filter({ $0.key.hasPrefix(service.service) }).map { [kSecAttrGeneric as String: $0.value.1 as Any] }
    }

    func update(id identifier: String, service: KeychainService, secretData: Data?, objectData: Data?, context: LAContext?) throws {
        if let (secret, object) = data["\(service.service)-\(identifier)"] {
            data["\(service.service)-\(identifier)"] = (secretData ?? secret, objectData ?? object)
        } else {
            data["\(service.service)-\(identifier)"] = (secretData, objectData)
        }
    }

    func has(id identifier: String, service: KeychainService, context: LAContext?) -> Bool {
        return data["\(service.service)-\(identifier)"] != nil
    }

    func delete(id identifier: String, service: KeychainService) throws {
        data.removeValue(forKey: "\(service.service)-\(identifier)")
    }

    func deleteAll(service: KeychainService, label: String?) {
        data.removeAll()
    }

    func saveKey<T>(id identifier: String, key: T) throws where T : SecKeyConvertible {
        keys[identifier] = key
    }

    func getKey<T>(id identifier: String, context: LAContext?) throws -> T? where T : SecKeyConvertible {
        return keys[identifier] as? T
    }

    func deleteKey(id identifier: String) throws {
        keys.removeValue(forKey: identifier)
    }

    func deleteAllKeys() {
        keys.removeAll()
    }


}
