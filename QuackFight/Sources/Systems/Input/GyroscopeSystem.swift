//
//  GyroscopeSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

/*
 Gyroscope Aiming UX Contract

 - Active only during AimState and only writes to liveAngle when InputStateComponent.phase == .aiming.
 - Flat / near-flat device maps to the minimum arc (~5°).
 - Around 45° device tilt maps to the mid arc (~45°).
 - High upward tilt maps toward the maximum arc (~85°).
 - Final angle must always be clamped to GameConstants.minAimAngle...GameConstants.maxAimAngle.
 - Tap during AimState or 5s timeout posts/handles GameEvent.aimLocked.
 - On lock, lockedAngle uses the current liveAngle.
 - Fallback to GameConstants.defaultAimAngle (~45°) is used only if liveAngle was never written because no valid motion data was received.
 - After locking, the gyroscope deactivates.
 - GyroscopeSystem does not change game state or update UI directly; AimState/GameStateMachine handles transition to PowerState, and render/UI systems handle feedback.
 */


import Foundation



