//
//  RWVideoGestureHandler.swift
//  RWVideoController
//
//  Created by Raditya Kurnianto on 7/19/19.
//  Copyright © 2019 raditya. All rights reserved.
//

import UIKit

@objc protocol RWGestureProtocol {
    @objc func gestureHandlerDidTap() -> Void
}

class RWVideoGestureHandler {
    weak var delegate: RWGestureProtocol?
    
    init(attachTap _view: UIView) {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTap(sender:)))
        gesture.numberOfTapsRequired = 1
        gesture.numberOfTouchesRequired = 1
        _view.addGestureRecognizer(gesture)
    }
    
    @objc func didTap(sender: UITapGestureRecognizer) -> Void {
        delegate?.gestureHandlerDidTap()
//        if controlShow {
//            controlShow = false
//        } else {
//            controlShow = true
//        }
    }
}

//extension RWVideoController {
//    func addTapGesture() -> Void {
//        self.controlLayerView.addGestureRecognizer(tap)
//    }
//
//    @objc func didTap(sender: UITapGestureRecognizer) -> Void {
//        if controlShow {
//            controlShow = false
//        } else {
//            controlShow = true
//        }
//    }
//
//    func showControl() -> Void {
//        self.controlLayerView.alpha = 1.0
//        self.controlShadowView.alpha = 0.5
//        self.controlLayerView.addGestureRecognizer(tap)
//        self.view.removeGestureRecognizer(tap)
//        self.runTimer()
//    }
//
//    @objc func hideControl() -> Void {
//        self.controlLayerView.alpha = 0.0
//        self.controlShadowView.alpha = 0.0
//        self.controlLayerView.removeGestureRecognizer(tap)
//        self.view.addGestureRecognizer(tap)
//    }
//}
