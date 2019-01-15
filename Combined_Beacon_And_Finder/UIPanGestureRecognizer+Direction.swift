//
//  UIPanGestureRecognizer+Direction.swift
//  Combined_Beacon_And_Finder
//
//  Created by Jo Lingenfelter on 1/15/19.
//  Copyright © 2019 Jo Lingenfelter. All rights reserved.
//

import UIKit

extension UIPanGestureRecognizer {
    
    enum GestureDirection {
        case up
        case down
        case left
        case right
    }
    
    /// Get current vertical direction
    ///
    /// - Parameter target: view target
    /// - Returns: current direction
    func verticalDirection(_ target: UIView) -> GestureDirection {
        return self.velocity(in: target).y > 0 ? .down : .up
    }
    
    /// Get current horizontal direction
    ///
    /// - Parameter target: view target
    /// - Returns: current direction
    func horizontalDirection(_ target: UIView) -> GestureDirection {
        return self.velocity(in: target).x > 0 ? .right : .left
    }
    
    /// Get a tuple for current horizontal/vertical direction
    ///
    /// - Parameter target: view target
    /// - Returns: current direction
    func versus(_ target: UIView) -> (horizontal: GestureDirection, vertical: GestureDirection) {
        return (self.horizontalDirection(target), self.verticalDirection(target))
    }
    
}
