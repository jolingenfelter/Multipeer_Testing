//
//  Scanner.swift
//  MultipeerExample
//
//  Created by Ben Gottlieb on 8/18/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class MPCManager: NSObject {
    private enum Constants {
        static let timeoutDuration: TimeInterval = 10
    }
    
	private var advertiser: MCNearbyServiceAdvertiser!
	private var browser: MCNearbyServiceBrowser!
    
    private let serviceType = "MPC-Testing"
    private let localPeerID = MCPeerID(displayName: UIDevice.current.name)
    
    private lazy var session: MCSession = {
        let session = MCSession(peer: localPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        
        return session
    }()
    
    static let shared = MPCManager()

	func startAdvertising() {
		self.advertiser.startAdvertisingPeer()
	}
    
    func startBrowsing() {
        self.browser.startBrowsingForPeers()
    }
    
    func stopAdvertising() {
        self.advertiser.stopAdvertisingPeer()
    }
    
    func stopBrowsing() {
        self.browser.stopBrowsingForPeers()
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
        if session.connectedPeers.isEmpty {
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: Constants.timeoutDuration)
        }
	}
	
	func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}

// MARK: - MCSessionDelegate
extension MPCManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        session.disconnect()
    }
}


