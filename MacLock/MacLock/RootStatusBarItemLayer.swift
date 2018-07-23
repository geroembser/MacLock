//
//  RootStatusBarItemLayer.swift
//  MacLock
//
//  Created by Gero Embser on 22.07.18.
//  Copyright © 2018 Gero Embser. All rights reserved.
//

import Cocoa

class RootStatusBarItemLayer: CALayer {
    private var renderedCount = 0
    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        print("draw....")
    }
    
    override func display() {
        print("display...")
        super.display()
    }
    override func render(in ctx: CGContext) {
        renderedCount += 1
        print("render...")
        
//        if renderedCount > 2 {
//            return
//        }

        super.render(in: ctx)
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        print("layout sublayers...")
    }
}
