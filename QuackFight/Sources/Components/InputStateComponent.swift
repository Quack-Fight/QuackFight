//
//  InputStateComponent.swift
//  QuackFight
//
//  Created by Nathan Sudiara on 14/05/26.
//

import GameplayKit

/// Pure-data component holding the input state gathered during a player's turn.
///
/// - `liveAngle` is updated continuously by `GyroscopeSystem` during `AimState`.
/// - `lockedAngle` is set when the player taps or the aim timer expires.
/// - `livePower` is updated continuously by `VoiceInputSystem` during `PowerState`.
/// - `lockedPower` is set when the player taps or the power timer expires.
/// - `phase` determines which input system is allowed to write.
///
/// Call `reset()` at the start of every turn to restore defaults.
class InputStateComponent: GKComponent {

    /// Live aiming angle in radians. Updated every frame by `GyroscopeSystem`.
    var liveAngle: Double = GameConstants.defaultAimAngle

    /// Final aiming angle in radians. Set when `GameEvent.aimLocked` is handled.
    var lockedAngle: Double?

    /// Live throw power from microphone input. Updated by `VoiceInputSystem`.
    var livePower: Double = 0.0

    /// Final throw power. Set when `GameEvent.powerLocked` is handled.
    var lockedPower: Double?

    /// Current input phase. Used to prevent systems from writing at the wrong time.
    var phase: InputPhase = .idle

    /// Whether both aim and power have been locked and the throw can execute.
    var isReadyToThrow: Bool {
        lockedAngle != nil && lockedPower != nil
    }

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
<<<<<<< HEAD
        liveAngle = GameConstants.defaultAimAngle
        lockedAngle = nil
        livePower = 0.0
        lockedPower = nil
        phase = .idle
=======
        aimAngle = GameConstants.defaultAimAngle
        power = 0.0
        isLocked = false
>>>>>>> 6838055 (feat: Implement core ECS foundation and components (#30, #34, #39, #68))
    }
}
