//
//  SimpleAnimations.swift
//  MacLock
//
//  Created by Gero Embser on 17.07.18.
//  Copyright © 2018 Gero Embser. All rights reserved.
//

import Foundation
import Cocoa

extension NSView {
    // Using SpringWithDamping
    func shake(duration: TimeInterval = 0.2) {
        let springAnimation = CASpringAnimation(keyPath: "position")

        springAnimation.duration = duration
        springAnimation.damping = 0.4
        springAnimation.initialVelocity = 1.0

        guard let pos = self.layer?.position else {
            return
        }

        springAnimation.fromValue = CGPoint(x: pos.x-2, y: pos.y)
        springAnimation.toValue = pos

        self.layer?.add(springAnimation, forKey: "position")
    }
    
    func shake2() {
        let animation = CAKeyframeAnimation(keyPath: "transform")
        let wobbleAngle: CGFloat = 0.06
        
        let valLeft = NSValue(caTransform3D: CATransform3DMakeRotation(wobbleAngle, 0.0, 0.0, 1.0))
        let valRight = NSValue(caTransform3D: CATransform3DMakeRotation(-wobbleAngle, 0.0, 0.0, 1.0))
        
        animation.values = [valLeft, valRight]
        
        animation.autoreverses = true;
        animation.duration = 0.125;
        animation.repeatCount = 1;
        
        self.layer?.add(animation, forKey: "")
    }
}
