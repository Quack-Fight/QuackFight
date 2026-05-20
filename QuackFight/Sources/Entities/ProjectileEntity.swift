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
        
        let spriteComponent = SpriteComponent(imageName: imageName)
        // The source PNGs are 2048×2048; constrain to a gameplay-appropriate size.
        spriteComponent.node.size = CGSize(width: 60, height: 60)
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
