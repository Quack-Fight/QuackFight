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
    private var skillToken: SubscriptionToken?

    // MARK: - Valid Transitions

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == ThrowResolveState.self || stateClass == HealResolveState.self || stateClass == FixedHitResolveState.self
    }

    // MARK: - Entry

    override func didEnter(from previousState: GKState?) {
        // Set phase to .power so VoiceInputSystem is allowed to write livePower.
        GameManager.shared.activePlayer
            .component(ofType: InputStateComponent.self)?.phase = .power

        // Activate microphone — reads RMS each audio buffer and writes livePower.
        VoiceInputSystem.shared.activate()
        EventBus.shared.post(.showInstruction("Shout!"))

        // Delay tap-to-lock until the instruction overlay has auto-hidden (~1.5s).
        // This prevents the player from accidentally tapping the overlay and skipping
        // straight to ThrowResolveState before they even had a chance to shout.
        // The microphone and timer still run during the delay — only the tap is deferred.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard self != nil else { return }  // state already exited (skill used, etc.)
            GameManager.shared.tapContext = .power
        }

        // Start the 5-second power timer (TurnSystem posts .timerTick + .powerLocked on timeout).
        TurnSystem.shared.startPowerTimer()

        // Wait for VoiceInputSystem to confirm the power value is locked.
        powerToken = EventBus.shared.subscribe(.powerLockConfirmed) { [weak self] _ in
            guard self != nil else { return }
            GameStateMachine.shared.enter(ThrowResolveState.self)
        }
        
        // Listen for skill selection
        skillToken = EventBus.shared.subscribe(.skillSelected) { [weak self] event in
            guard self != nil, case .skillSelected(let skill) = event else { return }
            
            let activePlayer = GameManager.shared.activePlayerIndex
            let player = GameManager.shared.player(index: activePlayer)
            
            if let skillComp = player.component(ofType: SkillComponent.self), skillComp.activate(skill) {
                EventBus.shared.post(.skillUsed(playerIndex: activePlayer, skill: skill))
                EventBus.shared.post(.showSkillSelection) // Update skill buttons UI
                
                if skill == .heal {
                    GameStateMachine.shared.enter(HealResolveState.self)
                } else if skill == .fixedHit {
                    GameStateMachine.shared.enter(FixedHitResolveState.self)
                }
            }
        }
    }

    // MARK: - Exit

    override func willExit(to nextState: GKState) {
        VoiceInputSystem.shared.deactivate()
        TurnSystem.shared.stopTimer()
        GameManager.shared.tapContext = .none

        if let token = powerToken {
            EventBus.shared.unsubscribe(token)
        }
        powerToken = nil
        
        if let token = skillToken {
            EventBus.shared.unsubscribe(token)
        }
        skillToken = nil
    }
}
