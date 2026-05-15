//
//  GameManager.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import Foundation
import GameplayKit

/// Single source of truth for whose turn it is and references to both player entities.
///
/// Systems and states query `GameManager.shared` instead of tracking player state
/// themselves, which prevents the desync bugs that arise when two different objects
/// each independently try to record the active player.
///
/// ## Ownership
/// - `activePlayerIndex` is mutated only by `switchPlayer()`.
/// - `switchPlayer()` is called only by `TurnHandoffState.handoffDismissed` handler.
/// - `registerPlayers(_:_:)` is called once by `GameScene.didMove(to:)`.
final class GameManager {

    static let shared = GameManager()

    // MARK: - State

    /// The two player entities in turn order: index 0 = Player 1, index 1 = Player 2.
    private var players: [PlayerEntity] = []

    /// Index of the player whose turn it currently is (0 or 1).
    private(set) var activePlayerIndex: Int = 0

    /// The outcome of the most recently completed match, used by GameOverState.
    var lastOutcome: GameOutcome = .draw
    
    /// Konteks tap yang sedang aktif.
    /// Dipakai TapInputSystem untuk menentukan event tap yang benar.
    var tapContext: TapContext = .none

    // MARK: - Computed Access

    /// The player entity whose turn it is right now.
    var activePlayer: PlayerEntity {
        assert(!players.isEmpty, "GameManager: registerPlayers(_:_:) must be called before accessing activePlayer.")
        return players[activePlayerIndex]
    }

    /// The player entity who is waiting (not the active player).
    var opponentPlayer: PlayerEntity {
        assert(!players.isEmpty, "GameManager: registerPlayers(_:_:) must be called before accessing opponentPlayer.")
        return players[1 - activePlayerIndex]
    }

    /// The index that will become active after the current turn ends.
    var nextPlayerIndex: Int { 1 - activePlayerIndex }

    // MARK: - Init

    private init() {}

    // MARK: - Registration

    /// Store references to both player entities.
    /// Call exactly once from `GameScene.didMove(to:)` after entities are created.
    func registerPlayers(_ p1: PlayerEntity, _ p2: PlayerEntity) {
        players = [p1, p2]
        activePlayerIndex = 0
    }

    // MARK: - Turn Management

    /// Advance `activePlayerIndex` from 0 → 1 or 1 → 0.
    /// Called by `TurnHandoffState` when the handoff overlay is dismissed.
    func switchPlayer() {
        activePlayerIndex = 1 - activePlayerIndex
    }

    /// Return the player entity for the given index (0 or 1).
    func player(index: Int) -> PlayerEntity {
        assert(index == 0 || index == 1, "GameManager: player index must be 0 or 1.")
        assert(!players.isEmpty, "GameManager: registerPlayers(_:_:) must be called first.")
        return players[index]
    }

}
