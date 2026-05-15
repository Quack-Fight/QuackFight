//
//  SkillSelectState.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import GameplayKit

// MARK: - Entry / Exit Feedback (#27)
//
// didEnter  → Skill selection UI slides up from the bottom of the screen.
//             Active player's available skills are shown as tappable cards.
//             If the player has no skills left, the UI is skipped entirely
//             and the state machine immediately enters AimState.
// willExit  → Skill UI slides out. HUD returns to normal layout.
//             If a skill was selected, its icon is highlighted in the HUD.

/// Presents the skill selection UI and routes to the appropriate resolve state.
///
/// ## Routing logic
/// - **No skills remaining** → skip UI, enter `AimState` immediately.
/// - **.heal selected**              → enter `HealResolveState`.
/// - **.fixedHit selected**          → enter `FixedHitResolveState`.
/// - **.damageMultiplier selected**  → activate on player, then enter `AimState`.
/// - **skipped**                     → enter `AimState`.
///
/// The active player's `SkillComponent.activeSkill` is set here on selection.
/// The appropriate resolve state or `DamageSystem` calls `consumeActive()` later.
final class SkillSelectState: GKState {

    // MARK: - Tokens

    private var skillToken: SubscriptionToken?
    private var skipToken: SubscriptionToken?

    // MARK: - Valid Transitions

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == AimState.self          ||
        stateClass == HealResolveState.self  ||
        stateClass == FixedHitResolveState.self
    }

    // MARK: - Entry

    override func didEnter(from previousState: GKState?) {
        let activePlayer = GameManager.shared.activePlayer
        let skillComp = activePlayer.component(ofType: SkillComponent.self)

        // Ensure any lingering active skill from a prior turn is cleared.
        skillComp?.clearActive()

        // If the player has burned all skills, skip straight to aim phase.
        if skillComp?.availableSkills.isEmpty == true {
            GameStateMachine.shared.enter(AimState.self)
            return
        }

        // Show the skill selection UI (UISystem observes this event).
        EventBus.shared.post(.showSkillSelection)

        // Subscribe for the player's choice.
        skillToken = EventBus.shared.subscribe(.skillSelected) { [weak self] event in
            guard let self, case .skillSelected(let skill) = event else { return }
            self.handleSkillSelected(skill)
        }

        skipToken = EventBus.shared.subscribe(.skillSkipped) { [weak self] _ in
            guard let self else { return }
            GameStateMachine.shared.enter(AimState.self)
        }
    }

    // MARK: - Exit

    override func willExit(to nextState: GKState) {
        [skillToken, skipToken].compactMap { $0 }.forEach { EventBus.shared.unsubscribe($0) }
        skillToken = nil
        skipToken = nil
    }

    // MARK: - Routing

    private func handleSkillSelected(_ skill: SkillType) {
        let activePlayer = GameManager.shared.activePlayer
        activePlayer.component(ofType: SkillComponent.self)?.activate(skill)

        // Notify UISystem so the skill icon can be highlighted in the HUD.
        EventBus.shared.post(.skillUsed(playerIndex: activePlayer.playerIndex, skill: skill))

        switch skill {
        case .heal:
            GameStateMachine.shared.enter(HealResolveState.self)
        case .fixedHit:
            GameStateMachine.shared.enter(FixedHitResolveState.self)
        case .damageMultiplier:
            // Multiplier is applied during the throw; route to normal aim phase.
            GameStateMachine.shared.enter(AimState.self)
        }
    }
}
