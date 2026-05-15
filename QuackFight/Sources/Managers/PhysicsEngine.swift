//
//  PhysicsEngine.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import Foundation
import CoreGraphics

// PhysicsEngine = stateless math utility for projectile calculations.
// PhysicsSystem = system that updates BreadEntity position every frame.

/*
 Physics Model Rules

 - Stateless and deterministic: identical inputs must always return identical outputs.
 - Uses custom 2D projectile motion with constant flat gravity.
 - No wind, drag, random force, or environmental modifier.
 - Uses fixed 60 FPS timestep for stable cross-device trajectory prediction.
 - SKPhysicsBody / Box2D are not used for trajectory prediction to avoid device-dependent results.
 - All tunable values come from GameConstants.
 */

enum PhysicsEngine {

    /// Converts aim angle, throw power, and facing direction into the projectile's starting velocity.
    ///
    /// Example:
    /// - Player 1 faces right, so `facing = 1.0`
    /// - Player 2 faces left, so `facing = -1.0`
    /// - Higher `power` means faster projectile speed
    /// - Higher `angle` means the projectile goes more upward
    ///
    /// Formula:
    /// - speed = power × maxVelocity
    /// - dx = facing × speed × cos(angle)
    /// - dy = speed × sin(angle)
    ///
    /// - Parameters:
    ///   - angle: Launch angle in radians. Example: 45° = `.pi / 4`.
    ///   - power: Normalised throw power from 0.0 to 1.0.
    ///   - facing: Horizontal direction. Use `1.0` for right, `-1.0` for left.
    /// - Returns: Initial velocity as `CGVector(dx:dy:)`.
    static func calculateVelocity(
        angle: Double,
        power: Double,
        facing: CGFloat
    ) -> CGVector {
        // Keep power safe so it never goes below 0% or above 100%.
        let clampedPower = max(0.0, min(power, 1.0))

        // Convert normalised power into actual projectile speed.
        // Example: power 0.5 means 50% of GameConstants.maxVelocity.
        let speed = CGFloat(clampedPower) * GameConstants.maxVelocity

        // Horizontal velocity.
        // `facing` flips the projectile direction:
        //  1.0 = move right
        // -1.0 = move left
        let dx = facing * speed * CGFloat(cos(angle))

        // Vertical velocity.
        // sin(angle) decides how much of the speed goes upward.
        let dy = speed * CGFloat(sin(angle))

        return CGVector(dx: dx, dy: dy)
    }
    
    /// Predicts the projectile trajectory using the same deterministic physics model.
    ///
    /// The first returned point is always the origin.
    /// The prediction uses a fixed timestep so the same input always produces the same trajectory.
    ///
    /// - Parameters:
    ///   - angle: Launch angle in radians. Example: 45° = `.pi / 4`.
    ///   - power: Normalised throw power from 0.0 to 1.0.
    ///   - origin: Starting position of the projectile.
    ///   - facing: Horizontal direction. Use `1.0` for right, `-1.0` for left.
    /// - Returns: A list of predicted positions forming a projectile arc.
    static func predictTrajectory(
        angle: Double,
        power: Double,
        origin: CGPoint,
        facing: CGFloat
    ) -> [CGPoint] {
        var points: [CGPoint] = []
        
        // Start from the projectile spawn position.
        var position = origin
        
        // Use calculateVelocity so trajectory prediction and real throw use the same launch math.
        var velocity = calculateVelocity(
            angle: angle,
            power: power,
            facing: facing
        )
        
        // Fixed timestep keeps prediction deterministic and consistent across devices.
        let dt = GameConstants.fixedTimeStep
        
        for _ in 0..<GameConstants.trajectorySteps {
            // The first point must be the origin.
            points.append(position)
            
            // Stop early if the projectile has gone below the ground limit.
            if position.y < GameConstants.groundY {
                break
            }
            
            // Apply gravity to vertical velocity.
            velocity.dy -= GameConstants.gravity * dt
            
            // Move position based on current velocity.
            position.x += velocity.dx * dt
            position.y += velocity.dy * dt
        }
        
        return points
    }
    
    
}
