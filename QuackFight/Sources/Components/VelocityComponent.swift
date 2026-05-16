//
//  VelocityComponent.swift
//  QuackFight
//
//  Created by Nathan Sudiara on 12/05/26.
//

import GameplayKit
import CoreGraphics

class VelocityComponent: GKComponent {
    var vector: CGVector
    
    init(vector: CGVector = .zero) {
        self.vector = vector
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
