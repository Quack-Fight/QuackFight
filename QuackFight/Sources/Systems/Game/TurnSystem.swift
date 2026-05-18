//
//  TurnSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import Foundation

// MARK: - Timer-as-System Pattern (#77)
//
// TurnSystem NEVER calls GameStateMachine.enter() directly.
// On timeout it posts .aimLocked or .powerLocked to the EventBus instead.
//
// Why this preserves single-responsibility:
//   - TurnSystem owns only time: it counts down and reports expiry via events.
//   - States own only transitions: AimState subscribes to .aimLockConfirmed
//     (which GyroscopeSystem posts in response to .aimLocked) and calls enter(PowerState.self).
//   - Systems own only their domain: GyroscopeSystem listens to .aimLocked,
//     locks the angle, and posts .aimLockConfirmed.
//
// If TurnSystem called enter() directly it would need to import and be coupled
// to every possible destination state, making the timer aware of state topology.
// By posting events it stays ignorant of what comes next — any subscriber can react
// independently, and the state graph can change without touching the timer.
//
// MARK: - Timer Urgency Feedback (#83)
//
// timerTick(remaining:) is posted every frame while the countdown is active.
// UISystem observes these ticks and applies urgency feedback based on thresholds:
//   remaining ≤ 2.0 s  →  UISystem flashes the timer label red on each tick.
//   remaining ≤ 1.0 s  →  UISystem triggers a tick SFX once per whole-second boundary.
//
// TurnSystem itself never touches UI. It only posts the remaining time.
// The thresholds live here (not in UISystem) so the single source of truth
// for "what counts as urgent" stays with the timer that generates the data.

/// Frame-driven countdown timer for the Aim and Power input phases.
///
/// `AimState.didEnter` calls `startAimTimer()`;
/// `PowerState.didEnter` calls `startPowerTimer()`.
/// Both states call `stopTimer()` in `willExit` to halt the countdown cleanly.
/// `GameScene.update(_:)` drives `TurnSystem.shared.update(deltaTime:)` each frame.
///
/// On expiry, the system fires the phase-appropriate lock event:
/// `.aimLocked` from the Aim phase, `.powerLocked` from the Power phase.
/// These events are handled by `GyroscopeSystem` and `VoiceInputSystem` respectively,
/// which then post the confirmed variants that trigger state transitions.
final class TurnSystem {

    static let shared = TurnSystem()

    // MARK: - Private Phase Enum

    /// Tracks which input phase is timing so the correct lock event fires on expiry.
    private enum TimerPhase { case aim, power }

    // MARK: - State

    private var countdown: TimeInterval = 0
    private var isRunning: Bool = false
    private var phase: TimerPhase = .aim

    private init() {}

    // MARK: - Public Interface

    /// Start a countdown for the Aim phase using `GameConstants.aimingDuration`.
    /// On expiry posts `.aimLocked` so `GyroscopeSystem` can lock the angle.
    func startAimTimer() {
        startTimer(duration: GameConstants.aimingDuration, phase: .aim)
    }

    /// Start a countdown for the Power phase using `GameConstants.powerDuration`.
    /// On expiry posts `.powerLocked` so `VoiceInputSystem` can lock the power value.
    func startPowerTimer() {
        startTimer(duration: GameConstants.powerDuration, phase: .power)
    }

    /// Halt the running countdown without firing a timeout event.
    /// Call from `willExit(to:)` of any state that started a timer.
    func stopTimer() {
        isRunning = false
        countdown = 0
    }

    // MARK: - Game Loop

    /// Decrement the countdown and post tick / timeout events each frame.
    /// Called every frame by `GameScene.update(_:)`.
    func update(deltaTime: TimeInterval) {
        guard isRunning else { return }

        countdown -= deltaTime
        let remaining = max(countdown, 0)

        // Broadcast remaining time so UISystem can apply urgency feedback:
        //   ≤ 2.0 s → flash timer label red
        //   ≤ 1.0 s → play tick SFX at each whole-second boundary
        EventBus.shared.post(.timerTick(remaining: remaining))

        if countdown <= 0 {
            isRunning = false
            countdown = 0
            fireTimeoutEvent()
        }
    }

    // MARK: - Private

    private func startTimer(duration: TimeInterval, phase: TimerPhase) {
        self.phase = phase
        self.countdown = duration
        self.isRunning = true
    }

    /// Translate expiry to the phase-appropriate lock event.
    /// This is the only site where timeout → event — never a direct enter() call.
    private func fireTimeoutEvent() {
        switch phase {
        case .aim:   EventBus.shared.post(.aimLocked)
        case .power: EventBus.shared.post(.powerLocked)
        }
    }
}
