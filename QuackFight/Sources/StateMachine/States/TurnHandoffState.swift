//
//  TurnHandoffState.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import GameplayKit

// MARK: - Entry / Exit Feedback (#27)
//
// didEnter  → Trajectory arc and power bar are removed from screen.
//             "Player X's Turn" overlay slides in from the top.
//             Both players' HP bars remain visible during the handoff.
//             Round counter in the HUD updates to the new turn number.
//             If damageMultiplier was just used but didn't hit, the skill
//             icon returns to an un-used appearance (skill NOT consumed on miss).
// willExit  → Overlay slides out. The next player's name/colour highlights.

/// Brief overlay between turns showing "Goose's Turn" / "Duck's Turn".
///
/// Auto-dismisses after a short delay (GDD: no tap required).
///
/// ## Responsibilities (in order)
/// 1. **Advance damage cycle** — if Player 2 (index 1) just finished, one full round
///    has completed and `DamageCycleManager.advance()` steps to the next value.
/// 2. **Increment turn counter** — `RoundCounterManager.incrementTurn()` tracks total
///    player-turns and posts `.roundCountUpdated` so the HUD updates.
/// 3. **Show handoff overlay** — posts `.showTurnHandoff(nextPlayerIndex:)` so `UISystem`
///    displays the "Player X's Turn" screen over the arena.
/// 4. **Auto-dismiss** — after `handoffDisplayDuration` seconds, automatically continue.
/// 5. **On dismiss**: switch the active player, then check the round cap:
///    - Cap not reached → `AimState` (normal next turn).
///    - Cap reached     → evaluate HP to set `GameManager.lastOutcome`, then `RoundOverState`.
///
/// ## Why advance cycle before switchPlayer?
/// `activePlayerIndex` must still reflect the player who just FINISHED so the
/// "P2 just finished" check (`activePlayerIndex == 1`) is correct. `switchPlayer()`
/// changes `activePlayerIndex` to the next player, so it must happen after the check.
final class TurnHandoffState: GKState {

    // MARK: - Configuration

    /// How long the "Player X's Turn" overlay stays visible before auto-dismissing.
    private let handoffDisplayDuration: TimeInterval = 2.0

    // MARK: - State

    /// Guard against the dismiss firing after the state has already exited.
    private var dismissed = false

    // MARK: - Valid Transitions

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == AimState.self || stateClass == RoundOverState.self
    }

    // MARK: - Entry

    override func didEnter(from previousState: GKState?) {
        dismissed = false

        // Step 1: Advance the damage cycle at the end of each complete round (P2 just finished).
        if GameManager.shared.activePlayerIndex == 1 {
            DamageCycleManager.shared.advance()
        }

        // Step 2: Count this completed player-turn and notify the HUD.
        RoundCounterManager.shared.incrementTurn()

        // Step 3: Show the handoff overlay for the NEXT player (not the one who just finished).
        let nextIndex = GameManager.shared.nextPlayerIndex
        EventBus.shared.post(.showTurnHandoff(nextPlayerIndex: nextIndex))

        // Step 4: Auto-dismiss after the display duration (no tap required per GDD §3.1).
        DispatchQueue.main.asyncAfter(deadline: .now() + handoffDisplayDuration) { [weak self] in
            guard let self, !self.dismissed else { return }
            self.handoffDismissed()
        }
    }

    // MARK: - Exit

    override func willExit(to nextState: GKState) {
        dismissed = true
    }

    // MARK: - Dismiss Logic

    private func handoffDismissed() {
        // Step 5a: Switch active player AFTER the cycle-advance check above.
        GameManager.shared.switchPlayer()

        // Step 5b: Route based on whether the 20-turn cap has been reached.
        if RoundCounterManager.shared.isMatchOver {
            determineRoundCapOutcome()
            GameStateMachine.shared.enter(RoundOverState.self)
        } else {
            GameStateMachine.shared.enter(AimState.self)
        }
    }

    /// Compare both players' HP to set `GameManager.lastOutcome` for the round-cap win.
    private func determineRoundCapOutcome() {
        let p1HP = GameManager.shared.player(index: 0)
            .component(ofType: HealthComponent.self)?.hp ?? 0
        let p2HP = GameManager.shared.player(index: 1)
            .component(ofType: HealthComponent.self)?.hp ?? 0

        if p1HP > p2HP {
            GameManager.shared.lastOutcome = .roundCapWin(winner: 0)
        } else if p2HP > p1HP {
            GameManager.shared.lastOutcome = .roundCapWin(winner: 1)
        } else {
            GameManager.shared.lastOutcome = .draw
        }
    }
}
