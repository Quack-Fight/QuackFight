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
    private var skillToken: SubscriptionToken?

    // MARK: - Valid Transitions

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == PowerState.self || stateClass == HealResolveState.self || stateClass == FixedHitResolveState.self
    }

    // MARK: - Entry

    override func didEnter(from previousState: GKState?) {
        // Ensure the camera tracks the active player at the start of every turn.
        // This handles all entry paths (ThrowResolve, HealResolve, FixedHitResolve,
        // PreviewPan, InitState) and reads the player's live TransformComponent
        // position, so knockback-displaced players are followed correctly.
        CameraSystem.shared.returnToPlayer(index: GameManager.shared.activePlayerIndex)

        // Reset input, then set phase to .aiming so GyroscopeSystem is allowed to write liveAngle.
        let inputState = GameManager.shared.activePlayer.component(ofType: InputStateComponent.self)
        inputState?.reset()
        inputState?.phase = .aiming

        // Activate gyroscope — reads device tilt and writes liveAngle each CMMotionManager callback.
        GyroscopeSystem.shared.activate()
        EventBus.shared.post(.showInstruction("Tilt to Aim"))

        // Enable tap-to-lock so TapInputSystem posts .aimLocked on touch.
        GameManager.shared.tapContext = .aiming

        // Start the 5-second aim timer (TurnSystem posts .timerTick + .aimLocked on timeout).
        TurnSystem.shared.startAimTimer()

        // Wait for GyroscopeSystem to confirm the angle is locked.
        aimToken = EventBus.shared.subscribe(.aimLockConfirmed) { [weak self] _ in
            guard self != nil else { return }
            GameStateMachine.shared.enter(PowerState.self)
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
        
        EventBus.shared.post(.showSkillSelection) // Ensure skills UI is updated when turn starts
    }

    // MARK: - Exit

    override func willExit(to nextState: GKState) {
        GyroscopeSystem.shared.deactivate()
        TurnSystem.shared.stopTimer()
        GameManager.shared.tapContext = .none

        if let token = aimToken {
            EventBus.shared.unsubscribe(token)
        }
        aimToken = nil
        
        if let token = skillToken {
            EventBus.shared.unsubscribe(token)
        }
        skillToken = nil
    }
}
