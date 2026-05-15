//
//  GameConstants.swift
//  QuackFight
//
//  Created by Nathan Sudiara on 12/05/26.
//

import Foundation
import CoreGraphics

/// Central repository for all game-wide constants.
enum GameConstants {

    // MARK: - Player

    /// Maximum hit points each player starts with.
    static let maxHP: Int = 100

    /// Total number of player-turns before the match ends on a round cap.
    static let maxRounds: Int = 20

    /// The repeating damage cycle per player turn. After cycle 3, it repeats.
    static let damageCycle: [Int] = [10, 10, 15]

    // MARK: - Turn Timers

    /// Maximum seconds allowed in the AimingState.
    static let aimingDuration: TimeInterval = 5.0

    /// Maximum seconds allowed in the PowerState.
    static let powerDuration: TimeInterval = 5.0

    // MARK: - Physics Categories (bitmask)

    struct PhysicsCategory {
        static let none:       UInt32 = 0
        static let duck:       UInt32 = 0b0001  // 1
        static let bread:      UInt32 = 0b0010  // 2
        static let ground:     UInt32 = 0b0100  // 4
        static let boundary:   UInt32 = 0b1000  // 8
    }

    // MARK: - Scene Layout

    /// Vertical offset from the bottom where Player 1 stands.
    static let player1YPosition: CGFloat = 250

    /// Vertical offset from the bottom where Player 2 stands.
    static let player2YPosition: CGFloat = 250

    /// Horizontal inset from the screen edge for player placement.
    static let playerXInset: CGFloat = 300

    // MARK: - Projectile

    /// Base impulse scalar multiplied by the normalised power value (0…1).
    static let baseImpulseStrength: CGFloat = 240.0

    /// Gravity vector applied to the physics world.
    static let worldGravity = CGVector(dx: 0, dy: -9.8)

    // MARK: - Gyroscope Aiming

    /// CMMotionManager update interval (60 Hz).
    static let gyroUpdateInterval: TimeInterval = 1.0 / 60.0

    /// Minimum aim angle in degrees.
    static let minAimAngleDegrees: Double = 5.0

    /// Maximum aim angle in degrees.
    static let maxAimAngleDegrees: Double = 85.0

    /// Default aim angle in degrees, used when gyroscope data is unavailable.
    static let defaultAimAngleDegrees: Double = 45.0

    /// Minimum aim angle in radians.
    static let minAimAngle: Double = minAimAngleDegrees * .pi / 180.0

    /// Maximum aim angle in radians.
    static let maxAimAngle: Double = maxAimAngleDegrees * .pi / 180.0

    /// Default aim angle in radians.
    static let defaultAimAngle: Double = defaultAimAngleDegrees * .pi / 180.0

    // MARK: - Microphone Power

    /// Exponential moving average alpha for smoothing mic input (0 = frozen, 1 = raw).
    static let micSmoothingFactor: Double = 0.3

    /// RMS values below this threshold are treated as silence (0 power).
    static let micNoiseFloor: Double = 0.05

    /// RMS values at or above this threshold are treated as max power (1.0).
    static let micCeiling: Double = 0.6

    // MARK: - Visual Effects

    /// Camera shake offset in points.
    static let cameraShakeIntensity: CGFloat = 8.0

    /// Camera shake duration in seconds.
    static let cameraShakeDuration: TimeInterval = 0.4

    /// Font size for the floating damage label.
    static let damageTextFontSize: CGFloat = 28.0

    /// Camera zoom scale during the Fixed Hit cinematic.
    static let cinematicZoomScale: CGFloat = 1.5

    /// Number of particles in a hit burst.
    static let hitParticleCount: Int = 20

    /// Number of particles in a miss dust poof.
    static let missParticleCount: Int = 8
}
