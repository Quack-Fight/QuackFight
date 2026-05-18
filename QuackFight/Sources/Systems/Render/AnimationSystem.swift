//
//  AnimationSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

//  =========================================================================
//  ANIMATION SYSTEM ARCHITECTURE: CENTRALISED DRAIN
//  =========================================================================
//  - Avoid Conflicts: If multiple systems (e.g., Collision, Damage, Logic)
//    called `node.run()` directly on a SpriteKit node at the same time,
//    animations could easily conflict, glitch, or override each other.
//
//  - The Queue Pattern: Systems must submit their desired `SKAction` to the
//    `AnimationComponent`'s queue instead of executing them directly.
//
//  - Centralised Drain: `AnimationSystem` is the sole authority that reads
//    and drains these queues. This centralized approach ensures that only
//    one system triggers animations, allowing them to run sequentially or
//    group cleanly without race conditions.
//  =========================================================================

import Foundation
import SpriteKit
import GameplayKit

final class AnimationSystem {
    
    static let shared = AnimationSystem()
    private init() {}
    
    func update(entities: [GKEntity], deltaTime: TimeInterval) {
        
        for entity in entities {
            guard let animComp = entity.component(ofType: AnimationComponent.self),
                  let spriteComp = entity.component(ofType: SpriteComponent.self)
            else {
                continue
            }
            
            // lewati yg ga pake animation
            if animComp.animationQueue.isEmpty {
                continue
            }
            
            let node = spriteComp.node
            
            for task in animComp.animationQueue {
                if let key = task.key {
                    // jalan animation yang punya label nama
                    node.run(task.action, withKey: key)
                } else {
                    
                    node.run(task.action)
                }
            }
            
            animComp.animationQueue.removeAll()
            
        }
        
    }
    
    
    
    
}
