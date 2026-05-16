//
//  ThrowResolveState.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import GameplayKit

// MARK: - Entry / Exit Feedback (#27, #61, #66)
//
// Throw Resolution Rules (#61):
// - Hit: Damage is applied to the opponent, and the DamageCycle advances.
// - Miss: No damage is applied, but the DamageCycle still advances. Any active
//         skill (like damageMultiplier) is still permanently consumed.
// - Out of Bounds: The projectile hitting the left, right, or bottom boundaries
//                  is considered a miss.
//
// Feedback Moments (#66):
// didEnter  → Bread projectile spawns at activePlayer.throwOrigin.
//             Camera switches to .followBread mode (tracks the projectile in flight).
//             Throw SFX triggers (AudioManager).
// On hit    → Impact SFX triggers. Camera shakes. Damage text floats above the target.
//             Target flashes red (0.2 s, HP bar fill node).
//             `BreadImpact` particles spawn at the collision point.
//             Camera returns to active player.
// On miss   → Miss SFX triggers.
//             `BreadMiss` crumb puff particles spawn at the landing point.
//             Camera returns to active player.
// willExit  → Projectile node is removed from the scene.

/// Handles the bread projectile's flight and routes on the outcome.
///
/// ## Event flow
///
/// 1. `ThrowSystem.shared.executeThrow()` is called immediately on entry.
///    It spawns the projectile and posts `.throwStarted`, then (asynchronously)
///    posts `.throwResolved(hit:)` when the projectile lands.
///
/// 2. Three outcomes are handled via dedicated subscriptions (a `resolved` flag
///    prevents double-routing when events chain synchronously through EventBus):
///
///    - **Miss** (`.throwResolved(hit: false)`)
///      → `resolved = true` → enter `TurnHandoffState` directly.
///
///    - **Hit + no KO** (`.turnEnded`, posted by `DamageSystem` after applying damage)
///      → `resolved = true` → enter `TurnHandoffState`.
///
///    - **KO** (`.gameOver`, posted by `WinCheckSystem` after detecting 0 HP)
///      → `resolved = true` → store outcome in `GameManager.lastOutcome`
///      → enter `GameOverState`.
///
/// The `.gameOver` handler fires before `.turnEnded` in the KO case because
/// `WinCheckSystem` subscribes to `.damageApplied` which `DamageSystem` posts
/// before `.turnEnded`. The `resolved` flag silences the subsequent `.turnEnded`.
final class ThrowResolveState: GKState {

    // MARK: - Tokens

    private var throwToken: SubscriptionToken?
    private var turnEndedToken: SubscriptionToken?
    private var gameOverToken: SubscriptionToken?

    // Prevents double-routing when .gameOver and .turnEnded both fire in the
    // same EventBus synchronous dispatch chain.
    private var resolved = false

    // MARK: - Valid Transitions

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == TurnHandoffState.self || stateClass == GameOverState.self
    }

    // MARK: - Entry

    override func didEnter(from previousState: GKState?) {
        resolved = false

        // Subscribe BEFORE executing the throw to guarantee no event is missed.

        // Miss path: no damage, route directly to handoff.
        throwToken = EventBus.shared.subscribe(.throwResolved) { [weak self] event in
            guard let self,
                  case .throwResolved(let hit) = event,
                  !hit,
                  !self.resolved
            else { return }
            self.resolved = true
            
            // Consume skill separately on a miss per Issue #67 edge case
            GameManager.shared.activePlayer.component(ofType: SkillComponent.self)?.consumeActive()
            
            GameStateMachine.shared.enter(TurnHandoffState.self)
        }

        // Hit + no KO path: DamageSystem posts .turnEnded after applying damage.
        turnEndedToken = EventBus.shared.subscribe(.turnEnded) { [weak self] _ in
            guard let self, !self.resolved else { return }
            self.resolved = true
            GameStateMachine.shared.enter(TurnHandoffState.self)
        }

        // KO path: WinCheckSystem posts .gameOver after detecting 0 HP.
        // This fires before .turnEnded in the synchronous dispatch chain, so
        // the resolved flag will silence the subsequent .turnEnded.
        gameOverToken = EventBus.shared.subscribe(.gameOver) { [weak self] event in
            guard let self,
                  !self.resolved,
                  case .gameOver(let outcome) = event
            else { return }
            self.resolved = true
            GameManager.shared.lastOutcome = outcome
            GameStateMachine.shared.enter(GameOverState.self)
        }

        if let scene = GameManager.shared.scene {
            ThrowSystem.shared.executeThrow(player: GameManager.shared.activePlayer, scene: scene)
        } else {
            print("Warning: GameManager.shared.scene is nil; cannot execute throw.")
        }
    }

    // MARK: - Exit

    override func willExit(to nextState: GKState) {
        [throwToken, turnEndedToken, gameOverToken]
            .compactMap { $0 }
            .forEach { EventBus.shared.unsubscribe($0) }
        throwToken = nil
        turnEndedToken = nil
        gameOverToken = nil
        
        if let scene = GameManager.shared.scene {
            ThrowSystem.shared.clearBread(scene: scene)
        }
    }
}
