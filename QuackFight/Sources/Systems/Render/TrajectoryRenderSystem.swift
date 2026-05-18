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
        
        // --- Styling (Kriteria 4) ---
        // Membuat tampilannya (warna, ketebalan, transparansi)
        trajectoryNode.strokeColor = .white
        trajectoryNode.lineWidth = 4.0
        trajectoryNode.alpha = 0.6 // Agak transparan agar tidak menutupi karakter
        trajectoryNode.zPosition = 10 // Pastikan garis berada di atas background
        // Make it a dashed/dotted line
        trajectoryNode.strokeTexture = SKTexture(imageNamed: "spark") // Optional
        let pattern: [CGFloat] = [10.0, 10.0]
        // Note: SKShapeNode doesn't support lineDashPattern natively unless using CGPath stroking,
        // Actually it's easier to use CGPath(dashedWithPhase:lengths:) when drawing.
    }
    
    /// Jangan lupa panggil ini sekali saat GameScene baru mulai dimuat (didMove)
    func setup(in scene: SKScene) {
        if trajectoryNode.parent == nil {
            scene.addChild(trajectoryNode)
        }
    }

    func update(deltaTime: TimeInterval) {
        // 1. Kriteria: Clears path outside AimState
        guard GameStateMachine.shared.currentState is AimState
        else {
            trajectoryNode.path = nil
            return
        }
        
        // cari pemain yg lagi jalan
        let activePlayer = GameManager.shared.activePlayer
        
        guard let inputComp = activePlayer.component(ofType: InputStateComponent.self),
              let transformComp = activePlayer.component(ofType: TransformComponent.self) else {
            return
        }
        
        // 2. Kriteria: Reads liveAngle from active player's InputStateComponent
        let liveAngle = inputComp.liveAngle
        let originPosition = transformComp.position
        let facingDirection = activePlayer.facing
        
        // 3. Kriteria: calls PhysicsEngine.predictTrajectory(power: 0.7)
        let predictedPoints = PhysicsEngine.predictTrajectory(
            angle: Double(liveAngle),
            power: 0.7,
            origin: originPosition,
            facing: facingDirection
        )
        
        // 4. Kriteria: draws as SKShapeNode
        let path = CGMutablePath()
        
        if let firstPoint = predictedPoints.first {
            // Taruh pena di titik pertama (tangan pemain)
            path.move(to: firstPoint)
            
            // Tarik garis ke titik-titik selanjutnya
            for point in predictedPoints.dropFirst() {
                path.addLine(to: point)
            }
        }
        
        let dashedPath = path.copy(dashedWithPhase: 0, lengths: [10.0, 10.0])
        trajectoryNode.path = dashedPath
    }
}
