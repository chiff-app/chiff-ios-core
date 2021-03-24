//
//  AddSiteAuthorizer.swift
//  chiff
//
//  Copyright: see LICENSE.md
//

import LocalAuthentication
import PromiseKit

public class TeamAdminLoginAuthorizer: Authorizer {
    public var session: BrowserSession
    public let type = ChiffMessageType.adminLogin
    public let browserTab: Int

    public let requestText = "requests.confirm_login".localized.capitalizedFirstLetter
    public let successText = "requests.login_succesful".localized.capitalizedFirstLetter
    public var authenticationReason: String {
        return String(format: "requests.login_to".localized, "requests.keyn_for_teams".localized)
    }

    public required init(request: ChiffRequest, session: BrowserSession) throws {
        self.session = session
        guard let browserTab = request.browserTab else {
            throw AuthorizationError.missingData
        }
        self.browserTab = browserTab
        Logger.shared.analytics(.adminLoginRequestOpened)
    }

    public func authorize(startLoading: ((String?) -> Void)?) -> Promise<Account?> {
        do {
            let teamSession = try getTeamSession()
            return firstly {
                LocalAuthenticationManager.shared.authenticate(reason: self.authenticationReason, withMainContext: false)
            }.then { context -> Promise<(Data, LAContext?)> in
                startLoading?(nil)
                return teamSession.getTeamSeed().map { ($0, context) }
            }.then { seed, context  in
                self.session.sendTeamSeed(id: teamSession.id, teamId: teamSession.teamId, seed: seed.base64, browserTab: self.browserTab, context: context!, organisationKey: nil).map { nil }
            }.ensure {
                Logger.shared.analytics(.adminLoginRequestAuthorized)
            }.log("Error getting admin seed")
        } catch {
            return Promise(error: error)
        }
    }

    // MARK: - Private methods

    private func getTeamSession() throws -> TeamSession {
        let teamSessions = try TeamSession.all()
        guard !teamSessions.isEmpty else {
            throw AuthorizationError.noTeamSessionFound
        }
        let adminSessions = teamSessions.filter({ $0.isAdmin })
        guard !adminSessions.isEmpty else {
            throw AuthorizationError.notAdmin
        }
        return adminSessions.first!
    }

}
