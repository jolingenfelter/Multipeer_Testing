//
//  TicketView.swift
//  Combined_Beacon_And_Finder
//
//  Created by Jo Lingenfelter on 1/14/19.
//  Copyright © 2019 Jo Lingenfelter. All rights reserved.
//

import UIKit

class TicketView: UIView {
    private enum Constants {
        static let height: CGFloat = 200
        static let width: CGFloat = 350
    }
    
    @IBOutlet weak var beverageNameLabel: UILabel!
    @IBOutlet weak var costLabel: UILabel!
    
    var beverageName: String? {
        didSet {
            if beverageNameLabel != nil {
                beverageNameLabel.text = beverageName
            }
        }
    }
    
    var cost: String? {
        didSet {
            if costLabel != nil {
                costLabel.text = cost
            }
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: Constants.width, height: Constants.height)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
}

private extension TicketView {
    func commonInit() {
        let view = loadFromNib("TicketView")
        view.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(view)
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor)])
        
        beverageNameLabel.text = beverageName
        costLabel.text = cost
    }
}
