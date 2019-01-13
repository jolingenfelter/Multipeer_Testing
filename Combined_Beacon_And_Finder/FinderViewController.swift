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
    }

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var numberOfBeaconsLabel: UILabel!
    
    private lazy var mpcManager: MPCManager = {
        let manager = MPCManager()
        manager.delegate = self
        
        return manager
    }()
    
    let locationManager = CLLocationManager()
    let beaconRegion = CLBeaconRegion(proximityUUID: AppConstants.beaconUUID, major: Constants.major, identifier: Constants.regionID)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        
        view.backgroundColor = .red
        statusLabel.text = "No beacon detected"
        numberOfBeaconsLabel.text = "Detecting 0 beacons"
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
        //        if !beacons.isEmpty {
        //            signalStrengthLabel.text = "\(beacons[0].rssi)"
        //            updateDistance(beacons[0].proximity)
        //        } else {
        //            self.signalStrengthLabel.text = "No beacon detected"
        //            view.backgroundColor = .red
        //        }
        
        if !beacons.isEmpty {
            let sorted = beacons.sorted { $0.rssi > $1.rssi }
            
            let closestBeacon = sorted[0]
            
            statusLabel.text = "Closest beacon is \(closestBeacon.minor): \(closestBeacon.rssi)"
            numberOfBeaconsLabel.text = "Detecting \(beacons.count) beacons"
            
            if closestBeacon.rssi >= -50 {
                mpcManager.startAdvertising()
            } else {
                mpcManager.stop()
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

// MARK: - MPCManagerConnectionHandlingDelegate
extension FinderViewController: MPCManagerConnectionHandlingDelegate {
    func manager(_ manager: MPCManager, didFind device: Device, with browser: MCNearbyServiceBrowser) {
    }
    
    func manager(_ manager: MPCManager, didReceiveInvitiationFrom device: Device) {
        display(alert: "Invitation Received", message: "Would you like to connect to \(device.peerID.displayName)", okHandler: { _ in
            device.connect(manager: manager)
        }, okIsDestructive: false, canCancel: true, cancelHandler: nil)
    }
}
