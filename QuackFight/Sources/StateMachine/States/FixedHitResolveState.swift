//
//  FixedHitResolveState.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import GameplayKit

// MARK: - Entry / Exit Feedback (#27)
//
// didEnter  → Cinematic zoom on the opponent (CameraSystem zooms to
//             GameConstants.cinematicZoomScale over ~0.3 s).
//             Fixed Hit SFX plays.
//             Damage text floats above the opponent.
//             Opponent's HP bar flashes red (0.2 s on the fill node).
//             Camera shake (GameConstants.cameraShakeIntensity / cameraShakeDuration).
//             The used Fixed Hit skill icon is greyed out in the HUD.
// willExit  → Camera zoom eases back to normal. HP bar settles at new value.

/// Applies the Fixed Hit skill: guaranteed damage to the opponent without throwing.
///
/// `FixedHitSystem.shared.applyFixedHit()` reads `DamageCycleManager.currentDamage`,
/// damages the opponent, calls `SkillComponent.consumeActive()`, and posts
/// `.damageApplied(amount:to:)`, `.hpChanged(playerIndex:hp:)`, and `.turnEnded`.
/// `WinCheckSystem` also receives `.damageApplied` and will post `.gameOver` first
/// if the opponent's HP reached 0.
///
/// ## Routing
/// - **KO** (`.gameOver` from `WinCheckSystem`)  → `GameOverState`.
/// - **No KO** (`.turnEnded` from `FixedHitSystem`) → `TurnHandoffState`.
///
/// A `resolved` flag prevents double-routing when both events fire in the same
/// synchronous EventBus dispatch chain (`.gameOver` fires before `.turnEnded`).
final class FixedHitResolveState: GKState {

    // MARK: - Tokens

    private var turnEndedToken: SubscriptionToken?
    private var gameOverToken: SubscriptionToken?

    private var resolved = false

    // MARK: - Valid Transitions

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == TurnHandoffState.self || stateClass == GameOverState.self
    }

    // MARK: - Entry

    override func didEnter(from previousState: GKState?) {
        resolved = false

        // Subscribe BEFORE applying the hit to guarantee no event is missed.

        // No KO path: FixedHitSystem posts .turnEnded after damage is applied.
        turnEndedToken = EventBus.shared.subscribe(.turnEnded) { [weak self] _ in
            guard let self, !self.resolved else { return }
            self.resolved = true
            GameStateMachine.shared.enter(TurnHandoffState.self)
        }

        // KO path: WinCheckSystem posts .gameOver if opponent HP reaches 0.
        // Fires before .turnEnded in the synchronous dispatch chain.
        gameOverToken = EventBus.shared.subscribe(.gameOver) { [weak self] event in
            guard let self,
                  !self.resolved,
                  case .gameOver(let outcome) = event
            else { return }
            self.resolved = true
            GameManager.shared.lastOutcome = outcome
            GameStateMachine.shared.enter(GameOverState.self)
        }

        FixedHitSystem.shared.applyFixedHit()
    }

    // MARK: - Exit

    override func willExit(to nextState: GKState) {
        [turnEndedToken, gameOverToken]
            .compactMap { $0 }
            .forEach { EventBus.shared.unsubscribe($0) }
        turnEndedToken = nil
        gameOverToken = nil
    }
}
