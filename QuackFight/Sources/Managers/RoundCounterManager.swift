//
//  RoundCounterManager.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import Foundation

/// Tracks the number of player-turns elapsed and enforces the 20-turn match cap.
///
/// `TurnHandoffState.didEnter(_:)` calls `incrementTurn()` at the start of each
/// handoff. After the handoff is dismissed, the state checks `isMatchOver` to decide
/// whether to transition to `SkillSelectState` (continue) or `RoundOverState` (end).
///
/// ## Why separate from DamageCycleManager?
/// The damage cycle and the round counter are logically independent:
/// the cycle wraps every 3 turns; the round counter only ever counts up.
/// Keeping them separate makes each testable in isolation without needing
/// to simulate the other's state.
final class RoundCounterManager {

    static let shared = RoundCounterManager()

    // MARK: - State

    /// Total number of player-turns that have been completed this match.
    private(set) var turnsElapsed: Int = 0

    /// The maximum number of player-turns per match.
    let maxTurns: Int = GameConstants.maxRounds

    // MARK: - Init

    private init() {}

    // MARK: - Interface

    /// `true` once `turnsElapsed` has reached `maxTurns` (20).
    /// Used by `TurnHandoffState` to decide if the match should end.
    var isMatchOver: Bool { turnsElapsed >= maxTurns }

    /// Record that one player-turn has been completed.
    /// Posts `.roundCountUpdated(turn:max:)` so the HUD "Turn X/20" label updates.
    func incrementTurn() {
        turnsElapsed += 1
        EventBus.shared.post(.roundCountUpdated(turn: turnsElapsed, max: maxTurns))
    }

    /// Reset to zero. Called by `InitState` at the start of each match.
    func reset() {
        turnsElapsed = 0
    }
}
