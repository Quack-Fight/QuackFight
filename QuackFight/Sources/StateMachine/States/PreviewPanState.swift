//
//  PreviewPanState.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import GameplayKit

// MARK: - Entry / Exit Feedback (#27)
//
// didEnter  → Camera begins panning from Player 2's side → Player 1's side.
//             Background music fades in. Players' idle animations begin.
//             CameraSystem sets its internal state to .previewPan.
// willExit  → Camera pan completes. CameraSystem switches to
//             .staticOnPlayer(index: 0) as it settles on Player 1.

/// Round 1 only — runs the camera pan that reveals both players before the first turn.
///
/// On `didEnter`, tells `CameraSystem` to start the pan. Waits for
/// `.previewPanComplete` (posted by `CameraSystem` when the animation finishes),
/// then transitions to `SkillSelectState` so Player 1 can begin their first turn.
///
/// This state is entered only once per session. `GameStateMachine.isFirstMatch` guards
/// it; rematches skip from `InitState` directly to `SkillSelectState`.
final class PreviewPanState: GKState {

    // MARK: - Tokens

    private var panToken: SubscriptionToken?

    // MARK: - Valid Transitions

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == SkillSelectState.self
    }

    // MARK: - Entry

    override func didEnter(from previousState: GKState?) {
        // Tell CameraSystem to begin the Round 1 pan (Player 2's side → Player 1's side).
        // TODO: CameraSystem.shared.setState(.previewPan)
        // CameraSystem will post .previewPanComplete when the animation finishes.

        panToken = EventBus.shared.subscribe(.previewPanComplete) { [weak self] _ in
            guard self != nil else { return }
            GameStateMachine.shared.enter(SkillSelectState.self)
        }
    }

    // MARK: - Exit

    override func willExit(to nextState: GKState) {
        if let token = panToken {
            EventBus.shared.unsubscribe(token)
        }
        panToken = nil
    }
}
