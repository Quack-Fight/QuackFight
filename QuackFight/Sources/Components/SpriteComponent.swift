//
//  SpriteComponent.swift
//  QuackFight
//
//  Created by Justin Chow on 08/05/26.
//

import GameplayKit
import SpriteKit

class SpriteComponent: GKComponent {
    var node: SKSpriteNode?
    
    override init() {
        super.init()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
