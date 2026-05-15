//
//  TransformComponent.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import Foundation
import GameplayKit
import CoreGraphics

class TransformComponent: GKComponent {
    var position: CGPoint
    
    init(position: CGPoint) {
        self.position = position
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
