//
//  TrajectoryRenderSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//


import Foundation
import SpriteKit
import GameplayKit

/*
 Trajectory Preview Feedback Contract

 - Visible only during AimState.
 - Uses fixed 70% power for a consistent, readable preview arc.
 - Redraws every frame while aiming so gyro movement feels responsive.
 - Uses liveAngle from the active player's InputStateComponent.
 - Uses PhysicsEngine.predictTrajectory(...) to match real projectile physics.
 - Clears immediately on aim lock or when exiting AimState.
 - No gameplay logic or state transition belongs in this system.
 */

//  =========================================================================
//  TRAJECTORY ARC FEEDBACK CONTRACT
//  =========================================================================
//  - Update Rate: The arc redraws every single frame (running at 60fps).
//    This ensures that real-time gyroscope adjustments feel incredibly
//    responsive, fluid, and tightly coupled with device movement.
//
//  - Lock-Clear Timing: The trajectory path is cleared instantly upon aim
//    lock or when exiting `AimState`. There is intentionally NO fade-out
//    animation to provide a snappy, crisp confirmation feel to the player.
//
//  - Visual Weight: The arc is rendered with a white, semi-transparent style
//    (alpha blending). This ensures high readability across various map
//    backgrounds while avoiding obscuring crucial background elements or targets.
//  =========================================================================

final class TrajectoryRenderSystem {
    
    static let shared = TrajectoryRenderSystem()
    
    private let trajectoryNode: SKShapeNode
    
    private init() {
        trajectoryNode = SKShapeNode()
        
        // Clean white dashed line styling.
        // No strokeTexture — SpriteKit draws a solid-color stroke natively,
        // which combined with the dashed path produces a crisp "── ── ──" look.
        trajectoryNode.strokeColor = .white
        trajectoryNode.lineWidth = 4.0
        trajectoryNode.alpha = 0.6
        trajectoryNode.zPosition = 10
    }
    
    /// Jangan lupa panggil ini sekali saat GameScene baru mulai dimuat (didMove)
    func setup(in scene: SKScene) {
        if trajectoryNode.parent == nil {
            scene.addChild(trajectoryNode)
        }
    }

    /// Length of the straight aim indicator line in points.
    private let aimLineLength: CGFloat = 200

    /// Hand shoulder offset from body center (matches PlayerEntity.setupHand).
    private let handOffsetGoose = CGPoint(x: 20, y: 15)
    private let handOffsetDuck  = CGPoint(x: -20, y: 15)

    /// Hand sprite width used to find the tip position (matches PlayerEntity).
    private let handWidth: CGFloat = 90

    func update(deltaTime: TimeInterval) {
        let isAiming = GameStateMachine.shared.currentState is AimState
        let activePlayer = GameManager.shared.activePlayer

        // 1. Clear path and reset hand outside AimState
        guard isAiming else {
            trajectoryNode.path = nil
            activePlayer.setHandAngle(nil)
            return
        }
        
        guard let inputComp = activePlayer.component(ofType: InputStateComponent.self),
              let transformComp = activePlayer.component(ofType: TransformComponent.self) else {
            return
        }
        
        // 2. Read aim angle and player data
        let liveAngle = inputComp.liveAngle
        let playerPos = transformComp.position
        let facing = activePlayer.facing  // +1 for Goose, -1 for Duck

        // 3. Rotate the player's hand to match the aim angle
        activePlayer.setHandAngle(liveAngle - 0.27)
        
        // 4. Calculate the aim direction vector
        //    Goose (facing +1): aims right → (cos(angle), sin(angle))
        //    Duck  (facing -1): aims left  → (-cos(angle), sin(angle))
        let dirX = facing * CGFloat(cos(liveAngle))
        let dirY = CGFloat(sin(liveAngle))

        // 5. Find the hand tip position in world space
        //    handTip = playerPos + shoulderOffset + handWidth * aimDirection
        let shoulderOffset = (facing > 0) ? handOffsetGoose : handOffsetDuck
        let shoulderX = playerPos.x + shoulderOffset.x
        let shoulderY = playerPos.y + shoulderOffset.y
        let tipX = shoulderX + handWidth * dirX
        let tipY = shoulderY + handWidth * dirY

        // 6. Draw a straight dashed line from hand tip extending in the aim direction
        let endX = tipX + aimLineLength * dirX
        let endY = tipY + aimLineLength * dirY

        let path = CGMutablePath()
        path.move(to: CGPoint(x: tipX, y: tipY))
        path.addLine(to: CGPoint(x: endX, y: endY))

        let dashedPath = path.copy(dashingWithPhase: 0, lengths: [10.0, 10.0])
        trajectoryNode.path = dashedPath
    }
}
