//
//  RoundOverState.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import GameplayKit

// MARK: - Entry / Exit Feedback (#27)
//
// didEnter  → "Round Over" banner slides in.
//             Both players' final HP values are shown side by side.
//             Winner (or "Draw") text is displayed.
//             A brief dramatic pause holds the screen for 1.5 seconds.
// willExit  → Banner fades out. Transition begins to game-over screen.

/// 1.5-second pause after the 20-turn cap is reached, before showing the win screen.
///
/// Uses `update(deltaTime:)` (the GKState game-loop hook) to accumulate elapsed
/// time and transition to `GameOverState` once the delay has passed.
/// `GameManager.lastOutcome` is already set by `TurnHandoffState` before this
/// state is entered.
final class RoundOverState: GKState {

    // MARK: - Constants

    private let displayDuration: TimeInterval = 1.5

    // MARK: - State

    private var elapsed: TimeInterval = 0

    // MARK: - Valid Transitions

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == GameOverState.self
    }

    // MARK: - Entry

    override func didEnter(from previousState: GKState?) {
        elapsed = 0
        // UISystem observes the state machine's current state (or a future
        // .roundOver event) to show the round-summary banner.
        // TODO: EventBus.shared.post(.roundOver) if a dedicated event is added.
    }

    // MARK: - Update

    override func update(deltaTime seconds: TimeInterval) {
        elapsed += seconds
        if elapsed >= displayDuration {
            GameStateMachine.shared.enter(GameOverState.self)
        }
    }
}
