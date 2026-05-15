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

final class TrajectoryRenderSystem {
    private let previewPower: Double = 0.7
}
