//
//  Extensions.swift
//  ChiffCore
//
//  Copyright: see LICENSE.md
//

import Foundation
import UserNotifications
import OneTimePassword
import PromiseKit

extension OSStatus {
    /// A human readable message for the OS status.
    var message: String {
        if #available(iOS 13.0, *) {
            return (SecCopyErrorMessageString(self, nil) as String?) ?? String(self)
        } else {
            return String(self)
        }
    }
}

extension NotificationCenter {
    /// Post a notification on the main queue.
    func postMain(_ notification: Notification) {
        DispatchQueue.main.async {
            self.post(notification)
        }
    }

    /// Post a notification on the main queue.
    func postMain(name aName: NSNotification.Name, object anObject: Any?) {
        DispatchQueue.main.async {
            self.post(name: aName, object: anObject)
        }
    }

    /// Post a notification on the main queue.
    func postMain(name aName: NSNotification.Name, object anObject: Any?, userInfo aUserInfo: [AnyHashable: Any]? = nil) {
        DispatchQueue.main.async {
            self.post(name: aName, object: anObject, userInfo: aUserInfo)
        }
    }
}

extension CatchMixin {
    /// Log the error and rethrow the error.
    func log(_ message: String) -> Promise<T> {
        recover { (error) -> Promise<T> in
            Logger.shared.error(message, error: error)
            throw error
        }
    }

    /// Catch any errors and log it.
    func catchLog(_ message: String) {
        `catch` { (error) in
            Logger.shared.error(message, error: error)
        }
    }
}

extension Notification.Name {
    static let passwordChangeConfirmation = Notification.Name("PasswordChangeConfirmation")
    static let sessionStarted = Notification.Name("SessionStarted")
    static let sessionUpdated = Notification.Name("SessionUpdated")
    static let sessionEnded = Notification.Name("SessionEnded")
    static let accountsLoaded = Notification.Name("AccountsLoaded")
    static let authenticated = Notification.Name("Authenticated")
    static let sharedAccountsChanged = Notification.Name("SharedAccountsChanged")
    static let accountUpdated = Notification.Name("AccountUpdated")
    static let notificationSettingsUpdated = Notification.Name("NotificationSettingsUpdated")
    static let backupCompleted = Notification.Name("BackupCompleted")
    static let newsMessage = Notification.Name("NewsMessage")
}

extension Token {
    var currentPasswordSpaced: String? {
        return self.currentPassword?.components(withLength: 3).joined(separator: " ")
    }
}

extension CharacterSet {
    static var base32WithSpaces: CharacterSet {
        return CharacterSet.letters.union(CharacterSet(["0", "1", "2", "3", "4", "5", "6", "7", " "]))
    }

    static var base32: CharacterSet {
        return CharacterSet.lowercaseLetters.union(CharacterSet(["0", "1", "2", "3", "4", "5", "6", "7"]))
    }
}
