//
//  Scanner.swift
//  MultipeerExample
//
//  Created by Ben Gottlieb on 8/18/18.
//  Copyright © 2018 Stand Alone, Inc. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol MPCManagerConnectionHandlingDelegate: class {
    func manager(_ manager: MPCManager, didFind device: Device, with browser: MCNearbyServiceBrowser)
    func manager(_ manager: MPCManager, didReceiveInvitiationFrom device: Device)
}

class MPCManager: NSObject {
	private var advertiser: MCNearbyServiceAdvertiser!
	private var browser: MCNearbyServiceBrowser!
    
    private let serviceType = "MPC-Testing"
    private var devices: [Device] = []
    
    let localPeerID: MCPeerID

	struct Notifications {
		static let deviceDidChangeState = Notification.Name("deviceDidChangeState")
	}
    
    var delegate: MPCManagerConnectionHandlingDelegate?
	
	override init() {
		if let data = UserDefaults.standard.data(forKey: "peerID"), let id = NSKeyedUnarchiver.unarchiveObject(with: data) as? MCPeerID {
			self.localPeerID = id
		} else {
			let peerID = MCPeerID(displayName: UIDevice.current.name)
			let data = NSKeyedArchiver.archivedData(withRootObject: peerID)
			UserDefaults.standard.set(data, forKey: "peerID")
			self.localPeerID = peerID
		}
		
		super.init()
		
		self.advertiser = MCNearbyServiceAdvertiser(peer: localPeerID, discoveryInfo: nil, serviceType: self.serviceType)
		self.advertiser.delegate = self
		
		self.browser = MCNearbyServiceBrowser(peer: localPeerID, serviceType: self.serviceType)
		self.browser.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(enteredBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
	}
	
	func device(for id: MCPeerID) -> Device {
		for device in self.devices {
			if device.peerID == id { return device }
		}
		
		let device = Device(peerID: id)
		
		self.devices.append(device)
		return device
	}

	func startAdvertising() {
		self.advertiser.startAdvertisingPeer()
	}
    
    func startBrowsing() {
        self.browser.startBrowsingForPeers()
    }
    
    func stop() {
        self.advertiser.stopAdvertisingPeer()
        self.browser.stopBrowsingForPeers()
        
        for device in devices {
            device.disconnect()
        }
        
        devices.removeAll()
    }
}

private extension MPCManager {
    @objc func enteredBackground() {
        for device in self.devices {
            device.disconnect()
        }
    }
}

extension MPCManager {
	var connectedDevices: [Device] {
		return self.devices.filter { $0.state == .connected }
	}
}

extension MPCManager: MCNearbyServiceAdvertiserDelegate {
	func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
		let detectedDevice = device(for: peerID)
        invitationHandler(true, detectedDevice.session)
        
		delegate?.manager(self, didReceiveInvitiationFrom: detectedDevice)
	}
}

extension MPCManager: MCNearbyServiceBrowserDelegate {
	func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
		let detectedDevice = device(for: peerID)
		
        delegate?.manager(self, didFind: detectedDevice, with: browser)
	}
	
	func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
		let detectedDevice = device(for: peerID)
		detectedDevice.disconnect()
        
        print("Lost connection")
        
        devices.removeElement(detectedDevice)
	}
}


