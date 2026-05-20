//
//  InitState.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import GameplayKit

// MARK: - Entry / Exit Feedback (#27)
//
// didEnter  → No visual output; this state runs synchronously before the first
//             frame renders. Systems are re-wired, managers reset, and the machine
//             immediately transitions to the next state within the same call.
// willExit  → Nothing; transition is immediate.

/// Resets the entire match to a clean initial state and branches to the first
/// active gameplay state.
///
/// ## Responsibilities
/// 1. Clear all `EventBus` subscriptions (removes stale handlers from last match).
/// 2. Reset all manager singletons: `DamageCycleManager`, `RoundCounterManager`.
/// 3. Reset both player entities: HP to max, all skills restored, input cleared.
/// 4. Re-wire system subscriptions via each system's `setupSubscriptions()`.
/// 5. Branch:
///    - **First match** → `PreviewPanState` (camera pan from P2 → P1).
///    - **Rematch**     → `SkillSelectState` directly (skip the pan).
///
/// ## Call site
/// - First call: `GameStateMachine.shared.start()` in `GameScene.didMove(to:)`.
/// - Subsequent calls: `GameStateMachine.shared.enter(InitState.self)` triggered
///   by the "Rematch" button in `GameOverState` / UISystem.
final class InitState: GKState {

    // MARK: - Valid Transitions

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == PreviewPanState.self || stateClass == AimState.self
    }

    // MARK: - Entry

    override func didEnter(from previousState: GKState?) {
        // 1. Wipe all EventBus handlers from the previous match.
        EventBus.shared.clearAllSubscriptions()

        // 2. Reset manager singletons.
        DamageCycleManager.shared.reset()
        RoundCounterManager.shared.reset()

        // 3. Reset both player entities (HP, skills, input).
        resetPlayers()

        // 4. Re-wire system subscriptions now that the bus is clean.
        //    Each system exposes setupSubscriptions() for this purpose.
        //    Order doesn't matter here — all handlers are registered before
        //    the first event fires in PreviewPanState / AimState.
        DamageSystem.shared.setupSubscriptions()
        HealSystem.shared.setupSubscriptions()
        FixedHitSystem.shared.setupSubscriptions()
        WinCheckSystem.shared.setupSubscriptions()
        GyroscopeSystem.shared.setupSubscriptions()
        VoiceInputSystem.shared.setupSubscriptions()
        UISystem.shared.setupSubscriptions()
        AudioManager.shared.setupSubscriptions()

        // 5. Branch: first match shows Round 1 camera preview pan; rematches skip it.
        let isFirst = GameStateMachine.shared.isFirstMatch
        if isFirst {
            GameStateMachine.shared.setFirstMatchComplete()
        }
        GameStateMachine.shared.enter(isFirst ? PreviewPanState.self : AimState.self)
    }

    // MARK: - Private Helpers

    private func resetPlayers() {
        for index in 0...1 {
            let player = GameManager.shared.player(index: index)
            // Heal back to full (HealthComponent.heal clamps to maxHP automatically).
            player.component(ofType: HealthComponent.self)?.heal(GameConstants.maxHP)
            // Restore all three skills and clear any lingering active selection.
            player.component(ofType: SkillComponent.self)?.reset()
            // Clear aim angle, power, and isLocked for the fresh turn.
            player.component(ofType: InputStateComponent.self)?.reset()
        }
    }
}
