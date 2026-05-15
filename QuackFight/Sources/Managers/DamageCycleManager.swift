//
//  DamageCycleManager.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import Foundation

// MARK: - Damage Cycle Rules
//
// The damage cycle is the global sequence [10, 10, 15] that repeats indefinitely.
// It determines the base damage (or heal/fixed-hit amount) for every player turn.
//
// UNIT OF ADVANCE — one full round (both players take their turn):
//   Both P1 and P2 use the SAME damage value within a single round.
//   The cycle advances only after P2 (the second player) completes their turn.
//   P1 and P2 always deal equal base damage in the same round.
//
// WHO CALLS advance():
//   `TurnHandoffState.didEnter(_:)` calls `advance()` only when
//   `GameManager.shared.activePlayerIndex == 1` (P2 just finished).
//   No other caller should call advance().
//
// REGARDLESS OF OUTCOME — the cycle still advances after a completed round even if:
//     - One or both players missed (no hit)
//     - A Heal skill was used (no throw)
//     - A Fixed Hit skill was used (no throw)
//   The round was played; the cycle moves on.
//
// DOES NOT ADVANCE mid-round:
//   `throwResolved(hit: false)` alone does NOT advance the cycle.
//   Only the round completion (P2 finishing) triggers the advance.
//
// EXAMPLE SEQUENCE (3 rounds = 6 individual player turns):
//   Round 1 → P1: 10, P2: 10 → advance → position 1
//   Round 2 → P1: 10, P2: 10 → advance → position 2
//   Round 3 → P1: 15, P2: 15 → advance → position 0  (wraps)
//   Round 4 → P1: 10, P2: 10 → advance → position 1
//   (repeats)

/// Tracks the current position in the repeating `[10, 10, 15]` damage cycle.
///
/// Every system that needs to apply or display damage reads `currentDamage` first,
/// then calls `advance()` when the turn is resolved. This ordering guarantees the
/// value used for the turn is the value shown to the player in the HUD.
final class DamageCycleManager {

    static let shared = DamageCycleManager()

    // MARK: - State

    /// The repeating damage sequence. Source of truth: `GameConstants.damageCycle`.
    private let cycle: [Int] = GameConstants.damageCycle

    /// Current index into `cycle`. Always in `0 ..< cycle.count`.
    private(set) var position: Int = 0

    // MARK: - Init

    private init() {}

    // MARK: - Interface

    /// The base damage amount for the current turn.
    /// Systems read this before calling `advance()`.
    var currentDamage: Int { cycle[position] }

    /// Step to the next position in the cycle (wraps at the end).
    /// Posts `.cycleAdvanced(newDamage:)` so the HUD can update the "Next: X" label.
    func advance() {
        position = (position + 1) % cycle.count
        EventBus.shared.post(.cycleAdvanced(newDamage: cycle[position]))
    }

    /// Reset to position 0. Called by `InitState` at the start of each match.
    func reset() {
        position = 0
    }
}
