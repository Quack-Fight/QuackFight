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
    var rotation: CGFloat
    
    init(position: CGPoint = .zero, rotation: CGFloat = 0.0) {
        self.position = position
        self.rotation = rotation
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
