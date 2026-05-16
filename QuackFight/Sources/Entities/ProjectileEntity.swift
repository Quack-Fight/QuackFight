//
//  ProjectileEntity.swift
//  QuackFight
//
//  Created by Nathan Sudiara on 13/05/26.
//

import GameplayKit
import SpriteKit

class ProjectileEntity: GKEntity {
    
    init(texture: SKTexture) {
        super.init()
        
        // Issue #38: Attach all 4 components
        // SpriteComponent handles the visual node
        let spriteComponent = SpriteComponent()
        spriteComponent.node = SKSpriteNode(texture: texture)
        addComponent(spriteComponent)
        
        // TransformComponent handles position/rotation data
        addComponent(TransformComponent())
        
        // VelocityComponent handles physics movement data
        addComponent(VelocityComponent())
        
        // HitboxComponent handles collision rects
        addComponent(HitboxComponent())
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported for ProjectileEntity")
    }
    
    // MARK: - Scene Management
    
    /// Adds the projectile to the scene cleanly
    func addToScene(_ scene: GameScene) {
        if let spriteNode = component(ofType: SpriteComponent.self)?.node {
            scene.addChild(spriteNode)
        }
        scene.registerEntity(self)
    }
    
    /// Removes the projectile from the scene cleanly with no dangling references
    func removeFromScene(_ scene: GameScene) {
        if let spriteNode = component(ofType: SpriteComponent.self)?.node {
            spriteNode.removeFromParent()
        }
        scene.removeEntity(self)
    }
}
