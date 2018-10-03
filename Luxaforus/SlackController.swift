//
//  SlackController.swift
//  Luxaforus
//
//  Created by Mike Gouline on 24/7/17.
//  Copyright © 2017 Traversal Space. All rights reserved.
//

import Cocoa
import Alamofire
import SwiftyJSON

private let kBaseUrl = "https://slack.com"
private let kApiUrl = "\(kBaseUrl)/api"

/// Redirect URL for auth calls.
private let kRedirectUrl = "https://traversal.space/luxaforus/slack"

private let kSnoozePeriod = 60 // minutes

class SlackController {
    
    private let persistenceManager: PersistenceManager
    
    private weak var delegate: SlackControllerDelegate? = nil
    
    private var accessToken: String?
    
    private var isSnoozed: Bool? = nil
    
    private var snoozeTimer: Timer?
    
    var isLoggedIn: Bool {
        get {
            return accessToken != nil
        }
    }
    
    init(persistenceManager: PersistenceManager) {
        self.persistenceManager = persistenceManager
    }
    
    /// Attaches state observers when application starts up.
    func attach(delegate theDelegate: SlackControllerDelegate) {
        // Check that a delegate was attached
        if delegate != nil { return }
        
        delegate = theDelegate
        
        // Check current state
        accessToken = persistenceManager.fetchSlackToken()
        delegate?.slackController(stateChanged: isLoggedIn)
        
        // Add open URL handler
        NSAppleEventManager.shared().setEventHandler(self,
                                                     andSelector: #selector(handleAppleEvent(event:replyEvent:)),
                                                     forEventClass: AEEventClass(kInternetEventClass),
                                                     andEventID: AEEventID(kAEGetURL))
    }
    
    /// Detaches state observers when application closes.
    func detach() {
        // Check that a delegate was attached
        if delegate == nil { return }
        
        // Remove open URL handle
        NSAppleEventManager.shared().removeEventHandler(forEventClass: AEEventClass(kInternetEventClass),
                                                        andEventID: AEEventID(kAEGetURL))
        
        clearTimers()
        
        delegate = nil
    }
    
    /// Starts Slack authentication process.
    func addIntegration() {
        openAuthorizeLink()
    }
    
    /// Removes existing Slack integration.
    func removeIntegration() {
        let alert = NSAlert()
        alert.messageText = "Remove Slack integration?"
        alert.informativeText = "Your Do Not Disturb status will no longer be published to your Slack account."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Remove")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
            clearTimers()
            saveOAuthSession(withToken: nil)
        }
    }
    
    /// Updates snoozed state by sending DND request.
    ///
    /// - Parameter isSnoozed: True if snoozed, false otherwise.
    func update(snoozed isSnoozed: Bool) {
        if isLoggedIn && ((self.isSnoozed == nil && isSnoozed) || (self.isSnoozed != nil && self.isSnoozed != isSnoozed)) {
            self.isSnoozed = isSnoozed
            if isSnoozed {
                requestSetSnooze()
                
                // Update snooze state 1 minute before it expires
                let snoozeTimerInterval = TimeInterval((kSnoozePeriod - 1) * 60)
                snoozeTimer = Timer.scheduledTimer(withTimeInterval: snoozeTimerInterval, repeats: false, block: { (t) in
                    NSLog("Slack: renewing snooze")
                    self.isSnoozed = false
                    self.update(snoozed: true)
                })
                NSLog("Slack: timer started %.0f", snoozeTimerInterval)
            } else {
                clearTimers()
                
                requestEndDnd()
            }
        }
    }
    
    // MARK: - URL handling
    
    @objc private func handleAppleEvent(event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        if let stringUrl = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue, let url = URLComponents(string: stringUrl) {
            handle(url: url)
        }
    }
    
    private func handle(url theUrl: URLComponents) {
        if theUrl.host?.caseInsensitiveCompare("slack") == .orderedSame &&
            theUrl.path.caseInsensitiveCompare("/activate") == .orderedSame {
            if let code = theUrl.queryItems?.first(where: { $0.name == "code" })?.value {
                if !isLoggedIn {
                    requestOAuthAccess(withCode: code)
                } else {
                    authFailure(withMessage: "Slack integration already added, currently only one account is supported.")
                }
            } else {
                authFailure(withMessage: "Activation code not found.")
            }
        }
    }
    
    // MARK: - Requests
    
    /// Open authorize link in the browser.
    private func openAuthorizeLink() {
        var urlComponents = URLComponents(string: "\(kBaseUrl)/oauth/authorize")
        urlComponents?.queryItems = [
            URLQueryItem(name: "client_id", value: kSlackClientId),
            URLQueryItem(name: "scope", value: "dnd:write"),
            URLQueryItem(name: "redirect_uri", value: kRedirectUrl)
        ]

        if let url = urlComponents?.url {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Requests 'oauth.access' profile.
    ///
    /// - Parameter code: Activation code passed from URL.
    private func requestOAuthAccess(withCode code: String) {
        let params = [
            "client_id": kSlackClientId,
            "client_secret": kSlackClientSecret,
            "code": code,
            "redirect_uri": kRedirectUrl
        ]
        _ = Alamofire.request("\(kApiUrl)/oauth.access", method: .post, parameters: params).responseJSON { response in
            let (ok, json) = self.check(response: response)
            if ok, let json = json {
                NSLog("Slack: oauth.access success")
                if let accessToken = json["access_token"].string {
                    self.saveOAuthSession(withToken: accessToken)
                    self.authSuccess(withTeam: json["team_name"].string ?? "Unknown")
                } else {
                    self.authFailure(withMessage: "Access token not returned.")
                }
            } else {
                NSLog("Slack: oauth.access failure")
                self.authFailure(withMessage: "OAuth access request failed. Try again later.")
            }
        }
    }
    
    /// Requests 'dnd.setSnooze' to enable snooze mode.
    private func requestSetSnooze() {
        let params = authenticatedParams([
            "num_minutes": String(kSnoozePeriod)
        ])
        _ = Alamofire.request("\(kApiUrl)/dnd.setSnooze", method: .post, parameters: params).responseJSON { response in
            let (ok, _) = self.check(response: response)
            NSLog("Slack: dnd.setSnooze \(ok ? "success" : "failure")")
            self.isSnoozed = true
        }
    }
    
    /// Requests 'dnd.endSnooze' to disable snooze mode.
    private func requestEndDnd() {
        let params = authenticatedParams()
        _ = Alamofire.request("\(kApiUrl)/dnd.endSnooze", method: .post, parameters: params).responseJSON { response in
            let (ok, _) = self.check(response: response)
            NSLog("Slack: dnd.endSnooze \(ok ? "success" : "failure")")
            self.isSnoozed = false
        }
    }
    
    /// Creates authenticated parameters.
    ///
    /// - Parameter params: Base parameters.
    /// - Returns: Enriched parameters with authentication token.
    private func authenticatedParams(_ params: Parameters? = nil) -> Parameters {
        var newParams: Parameters = [
            "token": accessToken!
        ]
        params?.forEach({ newParams[$0] = $1 })
        return newParams
    }
    
    /// Checks response for success status.
    ///
    /// - Parameter theResponse: Response returned.
    /// - Returns: OK status and JSON.
    private func check(response theResponse: DataResponse<Any>) -> (Bool, JSON?) {
        switch theResponse.result {
        case .success(let value):
            let json = JSON(value)
            if let error = json["error"].string {
                if error == "invalid_auth" || error == "not_authed" {
                    print("Slack: API error=\(error), removing token")
                    saveOAuthSession(withToken: nil)
                } else {
                    print("Slack: API error=\(error)")
                }
                return (false, json)
            } else {
                return (true, json)
            }
        case .failure(let error):
            print("Slack: request error=%@", error.localizedDescription)
            return (false, nil)
        }
    }
    
    // MARK: - State
    
    /// Saves OAuth session.
    ///
    /// - Parameters:
    ///   - token: Access token.
    private func saveOAuthSession(withToken token: String?) {
        accessToken = token
        persistenceManager.set(slackToken: token)
        delegate?.slackController(stateChanged: isLoggedIn)
    }
    
    /// Clears async events between snooze calls.
    private func clearTimers() {
        snoozeTimer?.invalidate()
        snoozeTimer = nil
        
        NSLog("Slack: timer cleared")
    }
    
    // MARK: - Messages
    
    /// Shows authentication success.
    ///
    /// - Parameter teamName: Slack team name.
    private func authSuccess(withTeam teamName: String) {
        let alert = NSAlert()
        alert.messageText = "Slack integration successfully added!"
        alert.informativeText = "Your Do Not Disturb status will now be published to your '\(teamName)' account."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    /// Shows authentication error.
    ///
    /// - Parameter message: Error message.
    private func authFailure(withMessage message: String) {
        let alert = NSAlert()
        alert.messageText = "Slack authentication failed!"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
}

protocol SlackControllerDelegate: class {
    
    /// Logged in status changed.
    ///
    /// - Parameter loggedIn: True if logged in, false otherwise.
    func slackController(stateChanged loggedIn: Bool)
    
}
