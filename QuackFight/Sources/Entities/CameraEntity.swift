//
//  CameraEntity.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import GameplayKit
import SpriteKit

class CameraEntity: GKEntity {
    
    let cameraNode: SKCameraNode
    
    init(scene: GameScene) {
        self.cameraNode = SKCameraNode()
        super.init()
        
        // Add to scene and set as the active camera
        scene.addChild(cameraNode)
        scene.camera = cameraNode
        
        // Register entity for updates
        scene.registerEntity(self)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported for CameraEntity")
    }
}
