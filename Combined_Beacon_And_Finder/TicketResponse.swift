//
//  TicketResponse.swift
//  Combined_Beacon_And_Finder
//
//  Created by Jo Lingenfelter on 1/14/19.
//  Copyright © 2019 Jo Lingenfelter. All rights reserved.
//

import Foundation

struct TicketResponse: Codable {
    let ticket: Ticket
    var accepted: Bool
    
    init(ticket: Ticket, accepted: Bool) {
        self.ticket = ticket
        self.accepted = accepted
    }
    
    mutating func accept(_ accept: Bool) {
        accepted = accept
    }
}
