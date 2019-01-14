//
//  Ticket.swift
//  Combined_Beacon_And_Finder
//
//  Created by Jo Lingenfelter on 1/14/19.
//  Copyright © 2019 Jo Lingenfelter. All rights reserved.
//

import Foundation

struct Ticket: Codable {
    let beverageName: String
    let cost: String
    
    init(beverageName: String, price: String) {
        self.beverageName = beverageName
        self.cost = price
    }
}
