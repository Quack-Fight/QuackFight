//
//  ProjectileEntity.swift
//  QuackFight
//
//  Created by Nathan Sudiara on 13/05/26.
//

import SpriteKit
import GameplayKit
import Foundation

/* =========================================================================
 PROJECTILE (BREAD) ENTITY
 =========================================================================
 LIFETIME CONTRACT:
 - Lifetime is exactly one throw. It is spawned when the power phase ends
   and despawned immediately upon hit (colliding with enemy) or miss
   (going out of bounds/hitting the ground).
 - Owned exclusively by ThrowSystem. No other system should spawn this.
 ========================================================================= */

class ProjectileEntity: GKEntity {
    
    //Component needed: Transform, Velocity, Hitbox, Sprite
    init(startPosition: CGPoint, initialVelocity: CGVector, radius: CGFloat, imageName: String) {
        super.init()
        
        /// Needed to store the current (X, Y) world position, so the physics system knows where it is.
        let transform = TransformComponent(position: startPosition)
        self.addComponent(transform)
        
        /// Needed to store the horizontal/vertical speed (dx, dy) to calculate the parabolic trajectory each frame.
        let velocity = VelocityComponent(vector: initialVelocity)
        self.addComponent(velocity)
        
        /// Needed to define the circular radius used by the HitDetectionSystem to check for overlapping.
        let hitbox = HitboxComponent(radius: radius)
        self.addComponent(hitbox)
        
        /// Needed to hold the visual texture (SKSpriteNode) and handle visual rotation along the velocity tangent.
        let sprite = SpriteComponent(imageName: imageName)
        self.addComponent(sprite)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
