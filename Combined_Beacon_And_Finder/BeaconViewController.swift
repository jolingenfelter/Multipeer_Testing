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
    @IBOutlet weak var connectionCountLabel: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var transactionLabel: UILabel!
    
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidReceiveConnectionResponse(_:)), name: Notification.Name(rawValue: NotificationConstants.didReceiveConnectionResponse), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleTicketResponse(_:)), name: Notification.Name(rawValue: NotificationConstants.didReceiveTicketResponse), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleStateChange(_:)), name: Notification.Name(rawValue: NotificationConstants.sessionDidChangeState), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        MPCManager.shared.startAdvertising()
        
        connectionCountLabel.text = "Currently connected to \(MPCManager.shared.connectionCount) peers"
        
        view.backgroundColor = .red
        
        statusLabel.text = "Not Connected"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        MPCManager.shared.stopAdvertising()
    }
    
    @IBAction func segmentedControlValueChange(_ sender: Any) {
        guard let segmentedControl = sender as? UISegmentedControl else { return }
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            changeBeaconRegion(beaconRegion1)
        case 1:
            changeBeaconRegion(beaconRegion2)
        case 2:
            changeBeaconRegion(beaconRegion3)
        default:
            return
        }
    }
}

private extension BeaconViewController {
    func changeBeaconRegion(_ beaconRegion: CLBeaconRegion) {
        peripheralManager?.stopAdvertising()
        
        peripheralData = beaconRegion.peripheralData(withMeasuredPower: nil)
        
        peripheralManager?.startAdvertising(((peripheralData) as! [String : Any]))
    }
    
    @objc
    func handleDidReceiveConnectionResponse(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let connectionResponse = userInfo[UserInfoKeys.connectionResponse] as? ConnectionResponse,
            connectionResponse.accepted  == true else {
                return
        }
        
        let exampleTicket = Ticket(beverageName: "Example Beer", price: "$5.00")
        
        MPCManager.shared.sendTicket(exampleTicket) { [weak self] error in
            self?.display(alert: error)
        }
    }
    
    @objc
    func handleTicketResponse(_ notification: Notification) {
        OperationQueue.main.addOperation {
            self.transactionLabel.isHidden = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.transactionLabel.isHidden = true
        }
    }
    
    @objc
    func handleStateChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let state = userInfo[UserInfoKeys.sessionState] as? MCSessionState else {
                return
        }
        
        OperationQueue.main.addOperation {
            switch state {
            case .connected:
                self.statusLabel.text = "Connection Established!"
                self.view.backgroundColor = .green
            case .connecting:
                self.statusLabel.text = "Connecting..."
                self.view.backgroundColor = .yellow
            case .notConnected:
                self.statusLabel.text = "Not connected"
                self.view.backgroundColor = .red
            }
            
            self.connectionCountLabel.text = "Counting \(MPCManager.shared.connectionCount) peers"
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
        }
    }
}
