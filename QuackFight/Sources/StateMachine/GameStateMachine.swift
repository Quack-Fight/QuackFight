//
//  GameStateMachine.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import GameplayKit

// MARK: - GKStateMachine Contract (#19)
//
// GKStateMachine requires every possible state to be instantiated and passed into
// the machine at initialisation time. Two rules govern runtime behaviour:
//
// 1. UNDECLARED STATE CRASHES: Calling `machine.enter(SomeState.self)` crashes
//    at runtime if `SomeState` was not included in `states:` at init. The machine
//    has no way to allocate or reason about states it has never seen.
//
// 2. isValidNextState ENFORCEMENT: Each GKState subclass overrides
//    `isValidNextState(_:)` to declare which states it may transition to.
//    `GKStateMachine.canEnterState(_:)` returns false for transitions not listed
//    by the current state, even if the target state was declared at init.
//    The `enter<S>(_:)` wrapper below asserts this in DEBUG builds so a mis-wired
//    transition crashes loudly rather than silently failing in production.
//
// All 11 states are declared below. Any future state must be added to this list
// or the first `machine.enter(NewState.self)` call will crash at runtime.

// MARK: - State Transition Map (#20)
//
// Current State          │ Trigger                              │ Next State
// ───────────────────────────────────────────────────────────────────────────────
// InitState              │ first match                          │ PreviewPanState
// InitState              │ rematch                              │ SkillSelectState
// PreviewPanState        │ .previewPanComplete event            │ SkillSelectState
// SkillSelectState       │ skill == .heal selected              │ HealResolveState
// SkillSelectState       │ skill == .fixedHit selected          │ FixedHitResolveState
// SkillSelectState       │ skill == .damageMultiplier / skip    │ AimState
// AimState               │ .aimLockConfirmed event              │ PowerState
// PowerState             │ .powerLockConfirmed event            │ ThrowResolveState
// ThrowResolveState      │ miss (.throwResolved hit:false)      │ TurnHandoffState
// ThrowResolveState      │ hit + no KO (.turnEnded)             │ TurnHandoffState
// ThrowResolveState      │ KO (.gameOver)                       │ GameOverState
// HealResolveState       │ .healApplied event                   │ TurnHandoffState
// FixedHitResolveState   │ no KO (.turnEnded)                   │ TurnHandoffState
// FixedHitResolveState   │ KO (.gameOver)                       │ GameOverState
// TurnHandoffState       │ .handoffDismissed, round cap not hit │ SkillSelectState
// TurnHandoffState       │ .handoffDismissed, round cap hit     │ RoundOverState
// RoundOverState         │ 1.5 s elapsed                        │ GameOverState
// GameOverState          │ rematch (via GameScene / UISystem)   │ InitState

/// Singleton wrapper around `GKStateMachine` orchestrating the 11-state match FSM.
///
/// All state transitions go through `enter<S>(_:)` which asserts the transition
/// is declared valid before delegating to GKStateMachine. This surfaces wiring
/// errors immediately in DEBUG rather than silently no-oping.
///
/// ## Ownership
/// - `start()` is called once by `GameScene.didMove(to:)` after players are registered.
/// - `update(deltaTime:)` is forwarded from `GameScene.update(_:)` each frame.
/// - `enter<S>(_:)` is called by individual state files, never by external systems.
final class GameStateMachine {

    static let shared = GameStateMachine()

    // MARK: - State

    /// True only on the very first match; `PreviewPanState` (camera pan) runs only then.
    /// Set to false by `InitState` after the first entry.
    private(set) var isFirstMatch: Bool = true

    private let machine: GKStateMachine

    // MARK: - Init

    private init() {
        // All 11 states must be declared here. Adding a 12th state later requires
        // adding it to this array, or the first enter(NewState.self) call will crash.
        machine = GKStateMachine(states: [
            InitState(),
            PreviewPanState(),
            SkillSelectState(),
            AimState(),
            PowerState(),
            ThrowResolveState(),
            HealResolveState(),
            FixedHitResolveState(),
            TurnHandoffState(),
            RoundOverState(),
            GameOverState()
        ])
    }

    // MARK: - Public Interface

    var currentState: GKState? { machine.currentState }

    /// Entry point called by `GameScene.didMove(to:)` after both players are registered.
    func start() {
        machine.enter(InitState.self)
    }

    /// Forward the game loop tick to the active state's `update(deltaTime:)`.
    /// Call from `GameScene.update(_:)`.
    func update(deltaTime: TimeInterval) {
        machine.update(deltaTime: deltaTime)
    }

    /// Transition to `stateType`. Asserts in DEBUG that the current state's
    /// `isValidNextState(_:)` allows this transition before delegating.
    func enter<S: GKState>(_ stateType: S.Type) {
        assert(
            machine.canEnterState(stateType),
            "GameStateMachine: invalid transition from \(String(describing: machine.currentState)) → \(stateType). " +
            "Check isValidNextState(_:) on the current state."
        )
        machine.enter(stateType)
    }

    // MARK: - Internal

    /// Mark the first match as complete. Called by `InitState` on first entry
    /// so subsequent rematches skip `PreviewPanState`.
    func setFirstMatchComplete() {
        isFirstMatch = false
    }
}
