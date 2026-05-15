//
//  CameraComponent.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import Foundation
import GameplayKit
import SpriteKit

class CameraComponent: GKComponent {
    let node: SKCameraNode
    var state: CameraState
    
    init(state: CameraState = .staticOnPlayer(index: 0)){
        self.node = SKCameraNode()
        self.state = state
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


