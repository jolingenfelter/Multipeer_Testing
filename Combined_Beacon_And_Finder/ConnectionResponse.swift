//
//  ConnectionResponse.swift
//  Combined_Beacon_And_Finder
//
//  Created by Jo Lingenfelter on 1/14/19.
//  Copyright © 2019 Jo Lingenfelter. All rights reserved.
//

import Foundation

struct ConnectionResponse: Codable {
    var accepted: Bool
    
    init(accepted: Bool) {
        self.accepted = accepted
    }
}