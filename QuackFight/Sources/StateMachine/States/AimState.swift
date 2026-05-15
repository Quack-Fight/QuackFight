//
//  AimState.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import GameplayKit

// MARK: - Entry / Exit Feedback (#27)
//
// didEnter  → Trajectory arc overlaid on screen (TrajectoryRenderSystem activates).
//             5-second countdown timer appears in the HUD.
//             Gyroscope activates; tilting the device moves the arc in real time.
//             If damageMultiplier is active, a "2x" badge appears near the arc.
// willExit  → Trajectory arc is hidden.
//             Gyroscope deactivates; no more angle updates.
//             Timer stops (no tick events after exit).

/// Gyroscope aiming phase: the active player tilts the device to set the throw angle.
///
/// `GyroscopeSystem` continuously writes to `InputStateComponent.aimAngle`.
/// `TapInputSystem` or `TurnSystem` posts `.aimLocked` when the player taps or
/// the 5-second timer expires. `GyroscopeSystem` responds by locking the angle
/// and posting `.aimLockConfirmed`. This state listens for `.aimLockConfirmed`
/// to transition to `PowerState`.
///
/// ## Gyroscope UX contract
/// - Device flat → ~5° (minimum arc).
/// - Device ~45° tilt → ~45° arc.
/// - Device high tilt → up to 85° (maximum arc).
/// - If no valid motion data received: fallback to `GameConstants.defaultAimAngle`.
final class AimState: GKState {

    // MARK: - Tokens

    private var aimToken: SubscriptionToken?

    // MARK: - Valid Transitions

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == PowerState.self
    }

    // MARK: - Entry

    override func didEnter(from previousState: GKState?) {
        // Reset the active player's input so a fresh aim begins.
        GameManager.shared.activePlayer
            .component(ofType: InputStateComponent.self)?.reset()

        // Activate gyroscope input (writes liveAngle each CMMotionManager update).
        // TODO: GyroscopeSystem.shared.activate()

        // Start the 5-second aim timer (TurnSystem posts .timerTick + .aimLocked on timeout).
        // TODO: TurnSystem.shared.startAimTimer()

        // Wait for GyroscopeSystem to confirm the angle is locked.
        aimToken = EventBus.shared.subscribe(.aimLockConfirmed) { [weak self] _ in
            guard let self else { return }
            GameStateMachine.shared.enter(PowerState.self)
        }
    }

    // MARK: - Exit

    override func willExit(to nextState: GKState) {
        // Stop gyroscope and timer before leaving.
        // TODO: GyroscopeSystem.shared.deactivate()
        // TODO: TurnSystem.shared.stopTimer()

        if let token = aimToken {
            EventBus.shared.unsubscribe(token)
        }
        aimToken = nil
    }
}
