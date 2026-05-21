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
    static let player1YPosition: CGFloat = 180

    /// Vertical offset from the bottom where Player 2 stands.
    static let player2YPosition: CGFloat = 180

    /// Horizontal inset from the screen edge for player placement.
    static let playerXInset: CGFloat = 200

    /// Vertical offset applied to the camera when it focuses on a player.
    /// Negative = camera looks lower, Positive = camera looks higher.
    /// Tune this to frame the player nicely on screen.
    static let cameraPlayerYOffset: CGFloat = 150

    // MARK: - Projectile

    /// Base impulse scalar multiplied by the normalised power value (0…1).
    /// Used only if a SpriteKit physics impulse is needed.
    static let baseImpulseStrength: CGFloat = 240.0

    /// Maximum custom projectile velocity at 100% power.
    /// Used by PhysicsEngine.calculateVelocity().
    /// Playtest tuning value.
    static let maxVelocity: CGFloat = 1200.0

    /// Custom deterministic gravity used by PhysicsEngine trajectory simulation.
    /// Playtest tuning value.
    static let gravity: CGFloat = 980.0

    /// Fixed timestep used by PhysicsEngine prediction for deterministic results.
    /// Smaller value means smoother trajectory prediction.
    /// `1.0 / 120.0` means the prediction simulates 120 steps per second.
    static let fixedTimeStep: CGFloat = 1.0 / 120.0

    /// Maximum number of predicted trajectory points.
    static let trajectorySteps: Int = 240

    /// Ground floor Y level — acts as an invisible floor surface.
    /// Projectiles reaching this level are destroyed (miss).
    /// Set to 20pt below player Y positions (150) to match the prototype's
    /// ground surface concept. Prevents projectiles from going "underground."
    static let groundY: CGFloat = 130.0

    /// Gravity vector applied to the SpriteKit physics world.
    /// This is separate from the custom deterministic PhysicsEngine gravity.
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
    
    /// Default power used when microphone input is unavailable.
    static let defaultThrowPower: Double = 0.5

    /// Minimum throw power used as a fallback so projectile never has zero movement.
    static let minThrowPower: Double = 0.1

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
    
    // MARK: - Hit Box

    /// Default circular hitbox radius for projectile collision checks.
    static let defaultHitBoxRadius: CGFloat = 20.0

    // MARK: - Background / World

    /// When `true`, the game uses 8 parallax layers (Background1…Background8).
    /// When `false`, a single "BackgroundMain" image is used with no parallax shift.
    static let useParallaxBackground: Bool = false

    /// The game world spans this many viewport widths horizontally.
    /// 6 screens gives enough room for high-arc artillery throws.
    static let worldScreenMultiplier: CGFloat = 6.0

    /// Total number of parallax background layers (Background1…Background8).
    static let backgroundLayerCount: Int = 8

    /// Base z-position for the furthest-back layer.
    /// Each successive layer is placed +1 above this.
    static let backgroundBaseZPosition: CGFloat = -20

    /// Parallax speed for the farthest layer (Background1).
    /// The closest layer (Background8) always has factor 1.0.
    /// Intermediate layers are linearly interpolated between these values.
    static let parallaxMinFactor: CGFloat = 0.1

    /// Size multiplier for the farthest background layer.
    /// Distant layers are scaled larger so they don't appear "cropped/zoomed in"
    /// when parallax offsets them. The closest layer is always 1.0×.
    static let parallaxDistantScale: CGFloat = 1.0
}
