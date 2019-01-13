//
//  Array+Utilities.swift
//  iBeaconTest
//
//  Created by Jo Lingenfelter on 1/9/19.
//  Copyright © 2019 Jo Lingenfelter. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
    mutating func removeElement(_ element: Element) {
        guard let index = self.index(of: element) else {
            return
        }
        
        remove(at: index)
    }
}
