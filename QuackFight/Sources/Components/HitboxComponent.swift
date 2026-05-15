//
//  HitboxComponent.swift
//  QuackFight
//
//  Created by Nathan Sudiara on 13/05/26.
//

import GameplayKit
import CoreGraphics

class HitboxComponent: GKComponent {
    var radius: CGFloat
    
    init(radius: CGFloat) {
        self.radius = radius
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
