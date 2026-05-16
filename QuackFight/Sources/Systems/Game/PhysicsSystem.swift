//
//  PhysicsSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import GameplayKit

/// # PhysicsSystem
///
/// **Update Order constraint (#60):**
/// According to Architecture 3.4, `PhysicsSystem` MUST run before `HitDetectionSystem`.
/// This ensures that the projectile's position is updated correctly for the current frame
/// *before* we check if it collides with an opponent.
///
/// - `update(deltaTime:)` applies gravity and updates position for the active projectile.
/// - If the projectile falls below `GameConstants.groundY`, it resolves as a miss.
class PhysicsSystem: GKComponentSystem<GKComponent> {
    
    // We only need a shared instance for custom ECS looping if we don't use GKComponentSystem array.
    static let shared = PhysicsSystem()
    
    override init() {
        // Technically GKComponentSystem needs a specific component class.
        // We'll manage iteration manually via ThrowSystem.shared.activeBread.
        super.init(componentClass: TransformComponent.self)
    }
    
    // Manual update hook since we only have 1 active projectile at a time.
    override func update(deltaTime seconds: TimeInterval) {
        guard ThrowSystem.shared.isInFlight,
              let bread = ThrowSystem.shared.activeBread,
              let transform = bread.component(ofType: TransformComponent.self),
              let velocityComp = bread.component(ofType: VelocityComponent.self) else {
            return
        }
        
        let dt = CGFloat(seconds)
        
        // 1. Apply gravity to vertical velocity
        velocityComp.vector.dy -= GameConstants.gravity * dt
        
        // 2. Advance position by velocity
        transform.position.x += velocityComp.vector.dx * dt
        transform.position.y += velocityComp.vector.dy * dt
        
        // Synchronize visual node
        if let sprite = bread.component(ofType: SpriteComponent.self) {
            sprite.node.position = transform.position
        }
        
        // 3. Out-of-bounds detection
        let sceneWidth = GameManager.shared.scene?.size.width ?? 2000
        if transform.position.y < GameConstants.groundY ||
           transform.position.x < -100 ||
           transform.position.x > sceneWidth + 100 {
            
            ThrowSystem.shared.isInFlight = false
            EventBus.shared.post(.throwResolved(hit: false))
        }
    }
}
