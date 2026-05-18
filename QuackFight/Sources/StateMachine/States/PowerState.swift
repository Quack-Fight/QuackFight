//
//  PowerState.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import GameplayKit

// MARK: - Entry / Exit Feedback (#27)
//
// didEnter  → Power bar slides in at the bottom of the screen.
//             Microphone activates; speaking loudly fills the bar in real time.
//             5-second countdown timer resets and begins ticking.
//             Gyroscope is no longer active; aim arc is locked (frozen).
// willExit  → Power bar locks in place, showing the final value.
//             Microphone deactivates; no more amplitude updates.
//             Timer stops.

/// Microphone power capture phase: the active player shouts to set throw power.
///
/// `VoiceInputSystem` continuously writes to `InputStateComponent.power` and
/// posts `.amplitudeUpdated(_:)` so the HUD power bar stays in sync.
/// `TapInputSystem` or `TurnSystem` posts `.powerLocked` when the player taps
/// or the 5-second timer expires. `VoiceInputSystem` responds by locking the
/// power value and posting `.powerLockConfirmed`. This state listens for
/// `.powerLockConfirmed` to transition to `ThrowResolveState`.
final class PowerState: GKState {

    // MARK: - Tokens

    private var powerToken: SubscriptionToken?

    // MARK: - Valid Transitions

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == ThrowResolveState.self
    }

    // MARK: - Entry

    override func didEnter(from previousState: GKState?) {
        // Activate microphone input (writes livePower and posts .amplitudeUpdated).
        // TODO: VoiceInputSystem.shared.activate()

        // Start the 5-second power timer (TurnSystem posts .timerTick + .powerLocked on timeout).
        TurnSystem.shared.startPowerTimer()

        // Wait for VoiceInputSystem to confirm the power value is locked.
        powerToken = EventBus.shared.subscribe(.powerLockConfirmed) { [weak self] _ in
            guard self != nil else { return }
            GameStateMachine.shared.enter(ThrowResolveState.self)
        }
    }

    // MARK: - Exit

    override func willExit(to nextState: GKState) {
        // Stop microphone and timer before leaving.
        // TODO: VoiceInputSystem.shared.deactivate()
        TurnSystem.shared.stopTimer()

        if let token = powerToken {
            EventBus.shared.unsubscribe(token)
        }
        powerToken = nil
    }
}
