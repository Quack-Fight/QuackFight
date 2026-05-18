//
//  ProjectileEntity.swift
//  QuackFight
//
//  Created by Nathan Sudiara on 13/05/26.
//

import GameplayKit
import SpriteKit

class ProjectileEntity: GKEntity {
    
    init(imageName: String, position: CGPoint, velocity: CGVector, radius: CGFloat) {
        super.init()
        
        // Issue #38: Attach all 4 components
        // SpriteComponent handles the visual node
        let spriteComponent = SpriteComponent(imageName: imageName)
        
        // Issue #94: Add a visual trail
        let trail = SKEmitterNode()
        trail.particleTexture = SKTexture(imageNamed: "spark") // Will safely fallback to a square if "spark" is missing
        trail.particleBirthRate = 60
        trail.particleLifetime = 0.4
        trail.particlePositionRange = CGVector(dx: 10, dy: 10)
        trail.particleScale = 0.2
        trail.particleScaleSpeed = -0.5
        trail.particleAlpha = 0.8
        trail.particleAlphaSpeed = -2.0
        trail.particleColor = .white
        trail.particleColorBlendFactor = 1.0
        trail.emissionAngleRange = .pi * 2
        trail.particleSpeed = 10
        trail.zPosition = -1 // Render behind the projectile
        
        // We add the trail to the sprite component so it travels with the bread
        // To make particles linger in world space, the `ThrowSystem` or `GameScene` could set `trail.targetNode = scene`.
        trail.name = "trailEmitter"
        spriteComponent.node.addChild(trail)
        
        addComponent(spriteComponent)
        
        // TransformComponent handles position/rotation data
        addComponent(TransformComponent(position: position))
        
        // VelocityComponent handles physics movement data
        addComponent(VelocityComponent(vector: velocity))
        
        // HitboxComponent handles collision rects
        addComponent(HitboxComponent(radius: radius))
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported for ProjectileEntity")
    }
    
}
