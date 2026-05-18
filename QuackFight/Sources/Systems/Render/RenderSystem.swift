//
//  RenderSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

//  =========================================================================
//  RENDER SYSTEM ARCHITECTURE: SINGLE WRITER RULE
//  =========================================================================
//  - Avoid Race Conditions: Allowing multiple systems to directly modify
//    `SKNode.position` creates race conditions, causing visual glitches,
//    stuttering, or flickering on the screen.
//
//  - Single Source of Truth: All positional and rotational math data lives
//    exclusively within `TransformComponent`. Other systems (like Physics)
//    must only modify this component.
//
//  - One-Way Bridge: `RenderSystem` is the strict one-way bridge from ECS
//    data to SpriteKit nodes. It runs at the very end of the frame, safely
//    applying the final `TransformComponent` data to the `SpriteComponent`'s
//    visual node.
//  =========================================================================

import SpriteKit
import GameplayKit

final class RenderSystem {
    
    static let shared = RenderSystem()
    private init() {}
    
    func update(entities: [GKEntity], deltaTime: TimeInterval) {
        for entity in entities {
            guard let spriteComp = entity.component(ofType: SpriteComponent.self),
                  let transformComp = entity.component(ofType: TransformComponent.self) else {
                continue
            }
            
            // 1. Sync Position
            spriteComp.node.position = transformComp.position
            
            // 2. Sync Facing (PlayerEntity specific)
            if let player = entity as? PlayerEntity {
                spriteComp.node.xScale = abs(spriteComp.node.xScale) * player.facing
            }
            
            // 3. Sync Rotation
            // If the entity has velocity (e.g. Bread), point it along its trajectory.
            if let velocityComp = entity.component(ofType: VelocityComponent.self) {
                let dx = velocityComp.vector.dx
                let dy = velocityComp.vector.dy
                if dx != 0 || dy != 0 {
                    spriteComp.node.zRotation = atan2(dy, dx)
                }
            } else {
                // Default transform rotation
                spriteComp.node.zRotation = transformComp.rotation
            }
        }
    }
}
