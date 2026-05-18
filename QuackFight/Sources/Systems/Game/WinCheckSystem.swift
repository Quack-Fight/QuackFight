//
//  WinCheckSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import GameplayKit

// MARK: - Win Condition Paths (#78)
//
// Three outcomes can end a match, evaluated in this priority order:
//
// 1. KO (knockout) — highest priority
//    Trigger:   .damageApplied event (posted by DamageSystem or FixedHitSystem)
//    Condition: either player's HealthComponent.isDead == true (hp ≤ 0)
//    Outcome:   .gameOver(.knockout(winner:)) — winner is the surviving player index
//    Priority:  Player 1 death is tested before Player 2; if both reach 0 simultaneously
//               the KO is attributed to Player 1's loss (defined priority, not a game rule).
//
// 2. Round-cap win
//    Trigger:   .turnEnded event (posted after a damage, heal, or fixed-hit resolves)
//    Condition: RoundCounterManager.isMatchOver == true AND p1.hp ≠ p2.hp
//    Outcome:   .gameOver(.roundCapWin(winner:)) — winner is the index with more HP
//
// 3. Draw — lowest priority
//    Trigger:   .turnEnded event (same check as round-cap win)
//    Condition: RoundCounterManager.isMatchOver == true AND p1.hp == p2.hp
//    Outcome:   .gameOver(.draw)
//
// KO always takes precedence: a hit that drops HP to 0 causes .damageApplied to fire
// first, and this system posts .knockout before .turnEnded can trigger a round-cap check.
// The `resolved` flag inside ThrowResolveState and FixedHitResolveState then silences
// the subsequent .turnEnded handler, so the game-over routing fires exactly once.

/// Detects KO and round-cap win conditions and posts `.gameOver` to the EventBus.
///
/// This system never calls `GameStateMachine.enter()` directly; it posts `.gameOver`
/// and lets the active resolve state (ThrowResolveState / FixedHitResolveState) handle
/// the transition — each class keeps its single responsibility.
///
/// ## Subscription lifecycle
/// `setupSubscriptions()` is called by `InitState` at the start of every match,
/// after `EventBus.clearAllSubscriptions()` has removed the previous match's handlers.
final class WinCheckSystem {

    static let shared = WinCheckSystem()

    private init() {}

    // MARK: - Setup

    /// Register EventBus handlers. Called by `InitState` at the start of every match.
    func setupSubscriptions() {
        // KO check: evaluates HP after every damage event.
        EventBus.shared.subscribe(.damageApplied) { [weak self] _ in
            guard let self else { return }
            self.checkKO()
        }

        // Round-cap check: evaluates HP after a full turn resolves.
        // isMatchOver is only true once RoundCounterManager reaches maxTurns (20),
        // which TurnHandoffState increments; this guard is a no-op on earlier turns.
        EventBus.shared.subscribe(.turnEnded) { [weak self] _ in
            guard let self else { return }
            self.checkRoundCap()
        }
    }

    // MARK: - KO Check

    /// If either player has reached 0 HP, post `.gameOver(.knockout(winner:))`.
    /// Player 1 is tested first to provide a defined evaluation order.
    private func checkKO() {
        let p1 = GameManager.shared.player(index: 0)
        let p2 = GameManager.shared.player(index: 1)

        let p1Dead = p1.component(ofType: HealthComponent.self)?.isDead ?? false
        let p2Dead = p2.component(ofType: HealthComponent.self)?.isDead ?? false

        if p1Dead {
            EventBus.shared.post(.gameOver(outcome: .knockout(winner: 1)))
        } else if p2Dead {
            EventBus.shared.post(.gameOver(outcome: .knockout(winner: 0)))
        }
    }

    // MARK: - Round-Cap Check

    /// If the 20-turn cap is reached, compare HP and post the appropriate `.gameOver`.
    private func checkRoundCap() {
        guard RoundCounterManager.shared.isMatchOver else { return }

        let p1HP = GameManager.shared.player(index: 0)
            .component(ofType: HealthComponent.self)?.hp ?? 0
        let p2HP = GameManager.shared.player(index: 1)
            .component(ofType: HealthComponent.self)?.hp ?? 0

        if p1HP > p2HP {
            EventBus.shared.post(.gameOver(outcome: .roundCapWin(winner: 0)))
        } else if p2HP > p1HP {
            EventBus.shared.post(.gameOver(outcome: .roundCapWin(winner: 1)))
        } else {
            EventBus.shared.post(.gameOver(outcome: .draw))
        }
    }
}
