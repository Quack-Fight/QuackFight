//
//  CameraSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import Foundation
import CoreGraphics
import SpriteKit

/// System that handles all cinematic camera movements (pan, follow, return) and static views.
///
/// ## SKCameraNode Positioning & Scene Coordinate Space (#85)
/// - The `SKCameraNode` position dictates what is in the center of the screen. 
///   It moves in the scene's coordinate space.
/// - We lerp `cameraNode.position` towards a target position for smooth following.
/// - Why `lerp < 1.0` creates a smooth follow: By moving a fraction (e.g., 0.12) of the 
///   distance to the target each frame, the camera moves faster when far away and slows 
///   down as it gets closer (Zeno's paradox). This creates a proportional decay that 
///   feels natural and cinematic.
///
/// ## GDD Table: Camera Behaviour Rules (#86)
/// | State                 | CameraState enum value | Behaviour description                                |
/// |-----------------------|------------------------|------------------------------------------------------|
/// | TurnHandoffState      | .staticOnPlayer        | Static (pinned to next player)                       |
/// | PreviewPanState       | .previewPan            | Pan from P2 to P1 over 2.5s                          |
/// | AimState              | .staticOnPlayer        | Static (pinned to active player)                     |
/// | PowerState            | .staticOnPlayer        | Static (pinned to active player)                     |
/// | ThrowResolveState     | .followBread           | Follows bread in flight                              |
/// | HealResolveState      | .staticOnPlayer        | Static (pinned to active player)                     |
/// | FixedHitResolveState  | .returnToPlayer        | Cinematic panning / Return                           |
final class CameraSystem {
    static let shared = CameraSystem()
    private init() {}
    
    // MARK: - Feel Constants (#90)
    
    /// Gives a slight lag for cinematic tension when following the projectile.
    private let cameraFollowLerp: CGFloat = 0.12
    /// Slower lerp for a relaxed post-throw feel when returning to the player.
    private let cameraReturnLerp: CGFloat = 0.08
    
    /// The duration of the preview pan at the start of the round (in seconds).
    private let previewPanDuration: TimeInterval = 2.5
    
    // MARK: - State
    
    private var panProgress: TimeInterval = 0.0
    
    // MARK: - Update
    
    func update(deltaTime: TimeInterval) {
        guard let scene = GameManager.shared.scene,
              let cameraEntity = scene.entities.first(where: { $0 is CameraEntity }) as? CameraEntity,
              let cameraComp = cameraEntity.component(ofType: CameraComponent.self) else {
            return
        }
        
        let cameraNode = cameraComp.node
        
        switch cameraComp.state {
        case .staticOnPlayer(let index):
            if let player = GameManager.shared.player(index: index) {
                cameraNode.position = player.position
            }
            
        case .previewPan:
            guard let p1 = GameManager.shared.player(index: 0),
                  let p2 = GameManager.shared.player(index: 1) else { return }
            
            panProgress += deltaTime
            let t = min(CGFloat(panProgress / previewPanDuration), 1.0)
            
            // Lerp from P2 to P1
            cameraNode.position = CGPoint.lerp(from: p2.position, to: p1.position, t: t)
            
            if t >= 1.0 {
                // Prevent multiple event posts
                cameraComp.state = .staticOnPlayer(index: 0)
                panProgress = 0.0
                EventBus.shared.post(.previewPanComplete)
            }
            
        case .followBread:
            // Find active projectile entity
            if let activeBread = ThrowSystem.shared.activeBread {
                let targetPos = activeBread.position
                cameraNode.position = CGPoint.lerp(from: cameraNode.position, to: targetPos, t: cameraFollowLerp)
            }
            
        case .returnToPlayer(let index):
            guard let player = GameManager.shared.player(index: index) else { return }
            
            let targetPos = player.position
            cameraNode.position = CGPoint.lerp(from: cameraNode.position, to: targetPos, t: cameraReturnLerp)
            
            // When close enough, snap and complete
            if cameraNode.position.distance(to: targetPos) < 4.0 {
                cameraNode.position = targetPos
                cameraComp.state = .staticOnPlayer(index: index)
                EventBus.shared.post(.cameraReturnComplete)
            }
        }
    }
}
