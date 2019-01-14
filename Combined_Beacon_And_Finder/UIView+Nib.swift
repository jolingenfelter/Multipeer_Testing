//
//  UIView+Nib.swift
//  Rivvir-iPad
//
//  Created by Jo Lingenfelter on 12/5/18.
//  Copyright © 2018 Jo Lingenfelter. All rights reserved.
//

import UIKit

extension UIView {
    func loadFromNib(_ nibName: String) -> UIView {
        let bundle = Bundle(for: type(of: self))
        let  nib = UINib(nibName: nibName, bundle: bundle)
    
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            fatalError("Failed to load view: \(self) from nib")
        }

        return view
    }
}
