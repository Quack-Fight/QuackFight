//
//  HealResolveState.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import GameplayKit

// MARK: - Entry / Exit Feedback (#27)
//
// didEnter  → Active player's HP bar flashes green (0.2 s on the fill node).
//             Heal SFX plays.
//             HP bar animates upward to reflect the new value.
//             The used Heal skill icon is greyed out in the HUD.
// willExit  → HP bar settles at the new value. No further visual changes.

/// Applies the Heal skill: restores HP to the active player without throwing.
///
/// `HealSystem.shared.applyHeal()` reads `DamageCycleManager.currentDamage`,
/// heals the active player, calls `SkillComponent.consumeActive()` to permanently
/// remove the skill, and then posts `.healApplied(amount:to:)`, `.hpChanged(playerIndex:hp:)`,
/// and `.turnEnded` in sequence.
///
/// This state listens for `.healApplied` and immediately transitions to
/// `TurnHandoffState`. There is no KO path — healing can never kill the opponent.
final class HealResolveState: GKState {

    // MARK: - Tokens

    private var healToken: SubscriptionToken?

    // MARK: - Valid Transitions

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == TurnHandoffState.self
    }

    // MARK: - Entry

    override func didEnter(from previousState: GKState?) {
        // Subscribe before applying the heal to guarantee no event is missed.
        healToken = EventBus.shared.subscribe(.healApplied) { [weak self] _ in
            guard let self else { return }
            GameStateMachine.shared.enter(TurnHandoffState.self)
        }

        HealSystem.shared.applyHeal()
    }

    // MARK: - Exit

    override func willExit(to nextState: GKState) {
        if let token = healToken {
            EventBus.shared.unsubscribe(token)
        }
        healToken = nil
    }
}
