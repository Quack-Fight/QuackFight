//
//  CameraEntity.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import GameplayKit
import SpriteKit

class CameraEntity: GKEntity {

    /// The SKCameraNode that is registered as `scene.camera`.
    /// Exposed so GameScene.setupUI can attach HUD nodes to it.
    let cameraNode: SKCameraNode

    init(scene: GameScene) {
        // CameraComponent owns the SKCameraNode; we expose it via `cameraNode`
        // so both CameraSystem (which reads cameraComp.node to move the camera)
        // and GameScene.setupUI (which adds HUD children to it) use the same node.
        let cameraComp = CameraComponent(state: .staticOnPlayer(index: 0))
        self.cameraNode = cameraComp.node
        super.init()

        addComponent(cameraComp)

        // Place the camera at Player 1's starting position so the first frame
        // doesn't show a black viewport while CameraSystem runs its first update.
        cameraNode.position = CGPoint(x: scene.size.width * 0.5, y: GameConstants.player1YPosition)

        scene.addChild(cameraNode)
        scene.camera = cameraNode

        scene.registerEntity(self)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported for CameraEntity")
    }
}
