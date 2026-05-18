//
//  SpriteComponent.swift
//  QuackFight
//
//  Created by Justin Chow on 08/05/26.
//

import Foundation
import GameplayKit
import SpriteKit

class SpriteComponent: GKComponent {
    let node: SKSpriteNode
    
    init(imageName: String) {
        self.node = SKSpriteNode(imageNamed: imageName)
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}   
