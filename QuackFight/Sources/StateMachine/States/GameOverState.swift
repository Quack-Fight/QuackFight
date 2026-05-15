//
//  GameOverState.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import GameplayKit

// MARK: - Entry / Exit Feedback (#27)
//
// didEnter  → Game-over screen slides in (winner portrait, "WINNER!" or "DRAW").
//             Victory fanfare or draw jingle plays.
//             "Rematch" and "Main Menu" buttons appear.
// willExit  → Screen fades out before InitState resets everything.

/// Terminal state of the match. Presents the game-over result and waits for
/// the player to rematch or return to the main menu.
///
/// ## Two paths into this state
///
/// 1. **KO** (`ThrowResolveState` or `FixedHitResolveState`):
///    `WinCheckSystem` already posted `.gameOver(outcome:)` to notify UISystem.
///    `GameManager.lastOutcome` was set by the routing state before entering here.
///    This state must NOT re-post `.gameOver` — UISystem has already received it.
///
/// 2. **Round cap** (`RoundOverState`):
///    `WinCheckSystem` never posted `.gameOver` (no player died).
///    `GameManager.lastOutcome` was set by `TurnHandoffState.determineRoundCapOutcome()`.
///    This state MUST post `.gameOver` so UISystem receives the outcome and renders
///    the correct win/draw screen.
///
/// ## Rematch flow
/// When the player taps "Rematch", `GameScene` (or `UISystem`) calls:
/// `GameStateMachine.shared.enter(InitState.self)`.
/// That resets everything and starts a fresh match.
final class GameOverState: GKState {

    // MARK: - Valid Transitions

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == InitState.self
    }

    // MARK: - Entry

    override func didEnter(from previousState: GKState?) {
        // Round-cap path: WinCheckSystem never posted .gameOver, so post it now
        // so UISystem receives the outcome and renders the correct screen.
        if previousState is RoundOverState {
            EventBus.shared.post(.gameOver(outcome: GameManager.shared.lastOutcome))
        }
        // KO path: .gameOver was already posted by WinCheckSystem and received
        // by UISystem. No second post needed.

        // TODO: UISystem subscribes to .gameOver and presents GameOverScene.
        // When the rematch button is tapped, the presenter calls:
        // GameStateMachine.shared.enter(InitState.self)
    }
}
