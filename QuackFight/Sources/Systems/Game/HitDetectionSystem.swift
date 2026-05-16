//
//  HitDetectionSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import GameplayKit

/// # HitDetectionSystem
///
/// Runs after `PhysicsSystem` to determine if the projectile has hit the opponent.
class HitDetectionSystem {
    
    static let shared = HitDetectionSystem()
    
    private init() {}
    
    func update(deltaTime seconds: TimeInterval) {
        guard ThrowSystem.shared.isInFlight,
              let bread = ThrowSystem.shared.activeBread,
              let breadTransform = bread.component(ofType: TransformComponent.self) else {
            return
        }
        
        let opponent = GameManager.shared.opponentPlayer
        let breadPos = breadTransform.position
        
        // Opponent's hitbox center (since PlayerEntity doesn't have a TransformComponent yet,
        // we use their throwOrigin or base placement).
        // Ideally, PlayerEntity will have a proper TransformComponent and HitboxComponent.
        let targetPos = opponent.throwOrigin
        
        let dx = breadPos.x - targetPos.x
        let dy = breadPos.y - targetPos.y
        let distance = hypot(dx, dy)
        
        // Check collision distance
        let breadRadius = bread.component(ofType: HitboxComponent.self)?.radius ?? GameConstants.defaultHitBoxRadius
        // Assuming player has a roughly equal or larger radius. We will use a combined hit distance.
        let hitDistance = breadRadius + GameConstants.defaultHitBoxRadius
        
        if distance <= hitDistance {
            ThrowSystem.shared.isInFlight = false
            EventBus.shared.post(.throwResolved(hit: true))
        }
    }
}
