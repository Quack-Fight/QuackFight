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
