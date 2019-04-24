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
    
    private var ticket: Ticket?
    
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        MPCManager.shared.stopBrowsing()
    }
}

private extension FinderViewController {
    func startMonitoring() {
        locationManager.startRangingBeacons(in: beaconRegion)
    }
    
    func stopMonitoring() {
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
        
        switch state {
        case .connected:
            OperationQueue.main.addOperation {
                LoadingView.hide(for: self.navigationController?.view)
                
                MPCManager.shared.sendConnectionResponse(ConnectionResponse(accepted: true), completion: { [weak self] error in
                    guard let error = error else { return }
                    
                    self?.display(alert: error)
                })
            }
        case .notConnected:
            OperationQueue.main.addOperation {
                self.removeTicketView()
            }
            
            stopMonitoring()
            
            DispatchQueue.global().asyncAfter(deadline: .now() + 60.00) {
                self.startMonitoring()
            }
            
        case .connecting:
            break
        }
    }
    
    @objc
    func handleDidReceiveTicket(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let ticket = userInfo[UserInfoKeys.ticket] as? Ticket else {
            return
        }
        
        self.ticket = ticket
        
        DispatchQueue.main.async {
            let ticketView = TicketView()
            ticketView.beverageName = ticket.beverageName
            ticketView.cost = ticket.cost
            ticketView.translatesAutoresizingMaskIntoConstraints = false
            ticketView.alpha = 0.0
            ticketView.isUserInteractionEnabled = true
            
            self.view.addSubview(ticketView)
            
            NSLayoutConstraint.activate([
                ticketView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 120),
                ticketView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)])
            
            UIView.animate(withDuration: Constants.ticketAppearAnimationDuration) {
                ticketView.alpha = 1.0
            }
            
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handleTicketSwipe(_:)))
            ticketView.addGestureRecognizer(panGesture)
        }
    }
    
    @objc
    func handleTicketSwipe(_ gesture: UIGestureRecognizer) {
        guard let pan = gesture as? UIPanGestureRecognizer, let view = pan.view else { return }
        
        if pan.verticalDirection(view) == .up {
            guard let ticket = ticket else { return }
            
            let response = TicketResponse(ticket: ticket, accepted: true)
            MPCManager.shared.sendTicketResponse(response) { [weak self] error in
                self?.display(alert: error)
                self?.removeTicketView()
                
                MPCManager.shared.stopBrowsing()
            }
        }
    }
    
    func removeTicketView() {
        for subview in view.subviews {
            if subview.isKind(of: TicketView.self) {
                UIView.animate(withDuration: Constants.ticketAppearAnimationDuration) {
                    subview.removeFromSuperview()
                }
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
                
                removeTicketView()
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
            
            MPCManager.shared.stopBrowsing()
            
            removeTicketView()
        }
    }
}
