//
//  BeaconViewController.swift
//  Combined_Beacon_And_Finder
//
//  Created by Jo Lingenfelter on 1/9/19.
//  Copyright © 2019 Jo Lingenfelter. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation
import MultipeerConnectivity

class BeaconViewController: UIViewController {
    @IBOutlet weak var statusLabel: UILabel!
    
    private lazy var beaconRegion1: CLBeaconRegion = {
        let proximityUUID = AppConstants.beaconUUID
        let major: CLBeaconMajorValue = 100
        let minor: CLBeaconMinorValue = 1
        let beaconID = "com.example.beacon"
        
        return CLBeaconRegion(proximityUUID: proximityUUID,
                              major: major, minor: minor, identifier: beaconID)
    }()
    
    private lazy var beaconRegion2: CLBeaconRegion = {
        let proximityUUID = AppConstants.beaconUUID
        let major: CLBeaconMajorValue = 100
        let minor: CLBeaconMinorValue = 2
        let beaconID = "com.example.beacon"
        
        return CLBeaconRegion(proximityUUID: proximityUUID,
                              major: major, minor: minor, identifier: beaconID)
    }()
    
    private lazy var beaconRegion3: CLBeaconRegion = {
        let proximityUUID = AppConstants.beaconUUID
        let major: CLBeaconMajorValue = 100
        let minor: CLBeaconMinorValue = 3
        let beaconID = "com.example.beacon"
        
        return CLBeaconRegion(proximityUUID: proximityUUID,
                              major: major, minor: minor, identifier: beaconID)
    }()
    
    private var peripheralManager: CBPeripheralManager!
    private var peripheralData: NSMutableDictionary!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        peripheralData = beaconRegion1.peripheralData(withMeasuredPower: nil)
        
        MPCManager.shared.startAdvertising()
    }
    
    @IBAction func segmentedControlValueChange(_ sender: Any) {
        guard let segmentedControl = sender as? UISegmentedControl else { return }
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            changeBeaconRegion(beaconRegion1, backgroundColor: .yellow)
        case 1:
            changeBeaconRegion(beaconRegion2, backgroundColor: .orange)
        case 2:
            changeBeaconRegion(beaconRegion3, backgroundColor: .purple)
        default:
            return
        }
    }
}

private extension BeaconViewController {
    func changeBeaconRegion(_ beaconRegion: CLBeaconRegion, backgroundColor: UIColor) {
        peripheralManager?.stopAdvertising()
        
        peripheralData = beaconRegion.peripheralData(withMeasuredPower: nil)
        
        peripheralManager?.startAdvertising(((peripheralData) as! [String : Any]))
        
        UIView.animate(withDuration: 0.35) {
            self.view.backgroundColor = backgroundColor
        }
    }
}

// MARK: - CBPeripheralManagerDelegate
extension BeaconViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            peripheral.startAdvertising(((peripheralData) as! [String : Any]))
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            statusLabel.text = "Error starting peripheral advertisment: \(error)"
        } else {
            statusLabel.text = "Peripheral Advertising has commenced!"
        }
    }
}
