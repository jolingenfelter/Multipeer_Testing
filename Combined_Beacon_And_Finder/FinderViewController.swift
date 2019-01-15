//
//  FinderViewController.swift
//  Combined_Beacon_And_Finder
//
//  Created by Jo Lingenfelter on 1/9/19.
//  Copyright © 2019 Jo Lingenfelter. All rights reserved.
//

import UIKit
import CoreLocation
import MultipeerConnectivity

class FinderViewController: UIViewController {
    private enum Constants {
        static let major: CLBeaconMajorValue = 100
        static let regionID = "com.example.beacon"
        static let timeoutInterval: TimeInterval = 10
        static let ticketAppearAnimationDuration: TimeInterval = 0.35
    }

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var numberOfBeaconsLabel: UILabel!
    
    let locationManager = CLLocationManager()
    let beaconRegion = CLBeaconRegion(proximityUUID: AppConstants.beaconUUID, major: Constants.major, identifier: Constants.regionID)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        
        view.backgroundColor = .red
        statusLabel.text = "No beacon detected"
        numberOfBeaconsLabel.text = "Detecting 0 beacons"
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidFindPeerNofication(_:)), name: Notification.Name(rawValue: NotificationConstants.didFindPeer), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleStateChangeNotification(_:)), name: Notification.Name(NotificationConstants.sessionDidChangeState), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidReceiveTicket(_:)), name: Notification.Name(NotificationConstants.didReceiveTicket), object: nil)
    }
}

private extension FinderViewController {
    func startMonitoring() {
        locationManager.startRangingBeacons(in: beaconRegion)
    }
    
    func stopScanning() {
        locationManager.stopRangingBeacons(in: beaconRegion)
    }
    
    func updateDistance(_ distance: CLProximity) {
        UIView.animate(withDuration: 0.8) {
            switch distance {
            case .unknown:
                self.view.backgroundColor = UIColor.gray
                
            case .far:
                self.view.backgroundColor = UIColor.blue
                
            case .near:
                self.view.backgroundColor = UIColor.orange
                
            case .immediate:
                self.view.backgroundColor = UIColor.green
            }
        }
    }
    
    @objc
    func handleDidFindPeerNofication(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let browser = userInfo[UserInfoKeys.browser] as? MCNearbyServiceBrowser,
            let peer = userInfo[UserInfoKeys.peer] as? MCPeerID,
            let session = userInfo[UserInfoKeys.session] as? MCSession
            else { return }
        
        display(alert: "Peer found", message: "Would you like to connect to \(peer.displayName)", okHandler: { [weak self] _ in
            browser.invitePeer(peer, to: session, withContext: nil, timeout: Constants.timeoutInterval)
            
            OperationQueue.main.addOperation {
                LoadingView.show(in: self?.navigationController?.view)
            }
        }, okIsDestructive: false, canCancel: true, cancelHandler: nil)
    }
    
    @objc
    func handleStateChangeNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let state = userInfo[UserInfoKeys.sessionState] as? MCSessionState else {
                return
        }
        
        if state == .connected {
            OperationQueue.main.addOperation {
                LoadingView.hide(for: self.navigationController?.view)
                
                MPCManager.shared.sendConnectionResponse(ConnectionResponse(accepted: true), completion: { [weak self] error in
                    guard let error = error else { return }
                    
                    self?.display(alert: error)
                })
            }
        }
    }
    
    @objc
    func handleDidReceiveTicket(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let ticket = userInfo[UserInfoKeys.ticket] as? Ticket else {
            return
        }
        
        DispatchQueue.main.async {
            let ticketView = TicketView()
            ticketView.beverageName = ticket.beverageName
            ticketView.cost = ticket.cost
            ticketView.translatesAutoresizingMaskIntoConstraints = false
            ticketView.alpha = 0.0
            
            self.view.addSubview(ticketView)
            
            NSLayoutConstraint.activate([
                ticketView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 80),
                ticketView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)])
            
            let _ = ticketView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive
            
            UIView.animate(withDuration: Constants.ticketAppearAnimationDuration) {
                ticketView.alpha = 1.0
            }
        }
    }
}

// MARK: - CLLocationMangerDelegate
extension FinderViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    startMonitoring()
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if !beacons.isEmpty {
            let sorted = beacons.sorted { $0.rssi > $1.rssi }
            
            let closestBeacon = sorted[0]
            
            statusLabel.text = "Closest beacon is \(closestBeacon.minor): \(closestBeacon.rssi)"
            numberOfBeaconsLabel.text = "Detecting \(beacons.count) beacons"
            
            if closestBeacon.rssi >= -50 {
                MPCManager.shared.startBrowsing()
            } else {
                MPCManager.shared.stopBrowsing()
            }
            
            UIView.animate(withDuration: 0.35) {
                self.view.backgroundColor = closestBeacon.rssi >= -50 ? .green : .red
            }
        } else {
            UIView.animate(withDuration: 0.35) {
                self.view.backgroundColor = .red
                self.statusLabel.text = "No beacon detected"
                self.numberOfBeaconsLabel.text = "Detecting 0 beacons"
            }
        }
    }
}
