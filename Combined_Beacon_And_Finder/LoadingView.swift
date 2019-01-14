//
//  LoadingView.swift
//  Combined_Beacon_And_Finder
//
//  Created by Jo Lingenfelter on 1/14/19.
//  Copyright © 2019 Jo Lingenfelter. All rights reserved.
//

import UIKit

class LoadingView: UIView {
    private enum Constants {
        static let showAlphaValue: CGFloat = 0.5
        static let hideAlphaValue: CGFloat = 0.0
        static let animationDuration: TimeInterval = 0.20
    }
    
    private var activityIndicator = UIActivityIndicatorView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.black
        alpha = Constants.showAlphaValue
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor)])
    }
    
    convenience init(with view: UIView) {
        self.init(frame: view.bounds)
        
        view.addSubview(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @discardableResult
    static func show(in view: UIView?, animated: Bool = true) -> LoadingView? {
        guard let view = view, !isShowing(in: view) else { return nil }
        
        let loadingView = LoadingView(with: view)
        loadingView.show(animated: animated)
    
        return loadingView
    }
    
    static func hide(for view: UIView?, animated: Bool = true) {
        guard let view = view else {
            return
        }
        
        let loadingViews = view.subviews.compactMap { $0 as? LoadingView }
        
        loadingViews.forEach { view in
            view.hide(animated: true, completion: { view.removeFromSuperview() })
        }
    }
}

private extension LoadingView {
    static func isShowing(in view: UIView) -> Bool {
        return !view.subviews.filter { $0.isKind(of: LoadingView.self) }.isEmpty
    }
    
    func hide(animated: Bool, completion: (() -> Void)?) {
        activityIndicator.stopAnimating()
        
        if animated {
            UIView.animate(withDuration: Constants.animationDuration, animations: {
                self.alpha = Constants.hideAlphaValue
            }) { isFinished in
                if isFinished {
                    completion?()
                }
            }
        } else {
            alpha = Constants.hideAlphaValue
            completion?()
        }
    }
    
    func show(animated: Bool) {
        activityIndicator.startAnimating()
        
        if animated {
            alpha = Constants.hideAlphaValue
            UIView.animate(withDuration: Constants.animationDuration, animations: {
                self.alpha = Constants.showAlphaValue
            })
        } else {
            alpha = Constants.showAlphaValue
        }
    }
}
