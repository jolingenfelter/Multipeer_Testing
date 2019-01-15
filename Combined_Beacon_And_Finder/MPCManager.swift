//
//  Scanner.swift
//  MultipeerExample
//
//  Created by Ben Gottlieb on 8/18/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation
import MultipeerConnectivity

enum NotificationConstants {
    static let didFindPeer = "DidFindPeer"
    static let didLosePeer = "DidLosePeer"
    static let sessionDidChangeState = "SessionDidChangeState"
    static let connectionEstablished = "ConnectionEstablished"
    static let didReceiveTicket = "DidReceiveTicket"
    static let didReceiveTicketResponse = "DidReceiveTicketResponse"
    static let didReceiveConnectionResponse = "DidReceiveConnectionResponse"
}

enum UserInfoKeys {
    static let browser = "browser"
    static let peer = "peer"
    static let session = "session"
    static let sessionState = "sessionState"
    static let ticket = "ticket"
    static let ticketResponse = "ticketResponse"
    static let connectionResponse = "connectionResponse"
}

class MPCManager: NSObject {
	private var advertiser: MCNearbyServiceAdvertiser
	private var browser: MCNearbyServiceBrowser
    
    private let serviceType = "MPC-Testing"
    private let localPeerID = MCPeerID(displayName: UIDevice.current.name)
    
    private var mostRecentPeer: MCPeerID?
    
    private lazy var session: MCSession = {
        let session = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .none)
        session.delegate = self
        
        return session
    }()
    
    var connectionCount: Int {
        return session.connectedPeers.count
    }
    
    static let shared = MPCManager()
    
    override init() {
        advertiser = MCNearbyServiceAdvertiser(peer: localPeerID, discoveryInfo: nil, serviceType: serviceType)
        browser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: serviceType)
        
        super.init()
        
        advertiser.delegate = self
        browser.delegate = self
    }

	func startAdvertising() {
		self.advertiser.startAdvertisingPeer()
	}
    
    func startBrowsing() {
        self.browser.startBrowsingForPeers()
    }
    
    func stopAdvertising() {
        self.advertiser.stopAdvertisingPeer()
        session.disconnect()
    }
    
    func stopBrowsing() {
        self.browser.stopBrowsingForPeers()
        session.disconnect()
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MPCManager: MCNearbyServiceAdvertiserDelegate {
	func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, self.session)
	}
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MPCManager: MCNearbyServiceBrowserDelegate {
	func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        if session.connectedPeers.isEmpty && mostRecentPeer != peerID {
            let userInfo = [UserInfoKeys.browser: browser, UserInfoKeys.peer: peerID, UserInfoKeys.session: session]
            
            NotificationCenter.default.post(name: Notification.Name(NotificationConstants.didFindPeer), object: nil, userInfo: userInfo)
        }
	}
	
	func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        let userInfo = [UserInfoKeys.session: session]
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationConstants.didLosePeer), object: nil, userInfo: userInfo)
    }
}

// MARK: - MCSessionDelegate
extension MPCManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let userInfo = [UserInfoKeys.sessionState: state]
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationConstants.sessionDidChangeState), object: nil, userInfo: userInfo)
        
        if state == .connected {
            mostRecentPeer = peerID
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let decoder = JSONDecoder()
        
        if let ticket = try? decoder.decode(Ticket.self, from: data) {
            let userInfo = [UserInfoKeys.ticket: ticket]
            NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationConstants.didReceiveTicket), object: nil, userInfo: userInfo)
        } else if let ticketResponse = try? decoder.decode(TicketResponse.self, from: data) {
            let userInfo = [UserInfoKeys.ticketResponse: ticketResponse]
            NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationConstants.didReceiveTicketResponse), object: nil, userInfo: userInfo)
        } else if let connectionResponse = try? decoder.decode(ConnectionResponse.self, from: data) {
            let userInfo = [UserInfoKeys.connectionResponse: connectionResponse]
            NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationConstants.didReceiveConnectionResponse), object: nil, userInfo: userInfo)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        session.disconnect()
    }
}

extension MPCManager {
    func sendTicket(_ ticket: Ticket, completion: ((Error?) -> Void)?) {
        guard !session.connectedPeers.isEmpty else { return }
        
        do {
            let encoded = try JSONEncoder().encode(ticket)
            try session.send(encoded, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            completion?(error)
        }
        
        completion?(nil)
    }
    
    func sendTicketResponse(_ response: TicketResponse, completion: ((Error?) -> Void)?) {
        guard !session.connectedPeers.isEmpty else { return }
        
        do {
            let encoded = try JSONEncoder().encode(response)
            try session.send(encoded, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            completion?(error)
        }
        
        completion?(nil)
    }
    
    func sendConnectionResponse(_ response: ConnectionResponse, completion: ((Error?) -> Void)?) {
        guard !session.connectedPeers.isEmpty else { return }
        
        do {
            let encoded = try JSONEncoder().encode(response)
            try session.send(encoded, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            completion?(error)
        }
        
        completion?(nil)
    }
}


