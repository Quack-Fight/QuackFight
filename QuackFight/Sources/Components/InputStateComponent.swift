//
//  InputStateComponent.swift
//  QuackFight
//
//  Created by Nathan Sudiara on 14/05/26.
//

import GameplayKit

/// Pure-data component holding the raw input state gathered during a player's turn.
///
/// - `aimAngle` is written by `GyroscopeSystem` during `AimState`.
/// - `power` is written by `VoiceInputSystem` during `PowerState`.
/// - `isLocked` is set to `true` when the player taps to lock the current value early.
///
/// Call `reset()` at the start of every turn to restore defaults.
///
class InputStateComponent: GKComponent {

    /// Current aiming angle in radians. Updated by `GyroscopeSystem`.
    var aimAngle: Double = GameConstants.defaultAimAngle

    /// Normalised throw power (0.0 … 1.0). Updated by `VoiceInputSystem`.
    var power: Double = 0.0

    /// Whether the player has tapped to lock the current input value.
    var isLocked: Bool = false

    // MARK: - Init

    override init() {
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported for InputStateComponent")
    }

    // MARK: - Reset

    /// Fully restore all input fields to their default values.
    /// Called at the beginning of each new turn.
    func reset() {
        aimAngle = GameConstants.defaultAimAngle
        power = 0.0
        isLocked = false
    }
}
