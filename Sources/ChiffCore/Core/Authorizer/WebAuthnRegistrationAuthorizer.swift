//
//  AddSiteAuthorizer.swift
//  chiff
//
//  Copyright: see LICENSE.md
//

import LocalAuthentication
import PromiseKit

public class WebAuthnRegistrationAuthorizer: Authorizer {
    public var session: BrowserSession
    public let type = ChiffMessageType.webauthnCreate
    public let browserTab: Int
    let siteName: String
    let siteURL: String
    let siteId: String
    let relyingPartyId: String
    let algorithms: [WebAuthnAlgorithm]
    let username: String
    let clientDataHash: String?
    let extensions: WebAuthnExtensions?

    public let requestText = "requests.add_account".localized.capitalizedFirstLetter
    public let successText = "requests.account_added".localized.capitalizedFirstLetter
    public var authenticationReason: String {
        return  String(format: "requests.add_site".localized, siteName)
    }

    public required init(request: ChiffRequest, session: BrowserSession) throws {
        self.session = session
        guard let browserTab = request.browserTab,
              let siteName = request.siteName,
              let siteURL = request.siteURL,
              let siteId = request.siteID,
              let username = request.username,
              let relyingPartyId = request.relyingPartyId,
              let algorithms = request.algorithms else {
            throw AuthorizationError.missingData
        }
        self.browserTab = browserTab
        self.siteName = siteName
        self.siteURL = siteURL
        self.siteId = siteId
        self.username = username
        self.relyingPartyId = relyingPartyId
        self.algorithms = algorithms
        self.clientDataHash = request.challenge
        self.extensions = request.webAuthnExtensions
        Logger.shared.analytics(.webAuthnCreateRequestOpened)
    }

    public func authorize(startLoading: ((String?) -> Void)?) -> Promise<Account?> {
        var success = false
        return firstly {
            LocalAuthenticationManager.shared.authenticate(reason: self.authenticationReason, withMainContext: false)
        }.map { context in
            let site = Site(name: self.siteName, id: self.siteId, url: self.siteURL, ppd: nil)
            var account = try UserAccount(username: self.username,
                                          sites: [site],
                                          password: nil,
                                          rpId: self.relyingPartyId,
                                          algorithms: self.algorithms,
                                          notes: nil,
                                          askToChange: false,
                                          context: context)
            var signature: String?
            var counter: Int?
            if let clientDataHash = self.clientDataHash {
                (signature, counter) = try account.webAuthnAttestation(clientData: clientDataHash, extensions: self.extensions)
            }
            try self.session.sendWebAuthnResponse(account: account, browserTab: self.browserTab, type: self.type, context: context, signature: signature, counter: counter)
            NotificationCenter.default.postMain(name: .accountsLoaded, object: nil)
            success = true
            return nil
        }.ensure {
            Logger.shared.analytics(.webAuthnCreateRequestAuthorized, properties: [.value: success])
        }
    }

}
