//
//  GameTypes.swift
//  QuackFight
//
//  Created by Nathan Sudiara on 12/05/26.
//

import Foundation

// MARK: - Player Identification

/// Integer index for a player: 0 = Player 1, 1 = Player 2.
/// Toggle between players with `1 - playerIndex`. Index into `GameManager.player(index:)`.
typealias PlayerIndex = Int

// MARK: - Skill

/// The three one-time skills each player may use per match.
/// `CaseIterable` lets SkillSelectionViewController iterate all options.
/// `String` raw value provides human-readable display labels.
enum SkillType: String, CaseIterable, Hashable {
    case damageMultiplier = "Damage Multiplier"
    case heal             = "Heal"
    case fixedHit         = "Fixed Hit"
}

// MARK: - Input

/// Lifecycle of a single turn's input capture.
/// GyroscopeSystem writes liveAngle only when `.aiming`;
/// VoiceInputSystem writes livePower only when `.power`.
enum InputPhase {
    case idle
    case aiming
    case power
    case locked
}

// MARK: - Tap Context

/// Konteks tap yang sedang aktif.
///
<<<<<<< HEAD
/// Dipakai oleh TapInputSystem untuk menentukan event apa yang harus dipost
/// saat player menyentuh layar.
enum TapContext {
    case none
    case aiming
    case power
    case turnHandoff
}

// MARK: - Camera

/// All four camera operating modes managed by CameraSystem.
enum CameraState {
    /// Camera is pinned exactly on the player at the given index.
    case staticOnPlayer(index: Int)
    /// Camera pans from Player 2 → Player 1 during round-start preview.
    case previewPan
    /// Camera lerps toward the bread entity while it is in flight.
    case followBread
    /// Camera lerps back to the player at the given index after throw resolution.
    case returnToPlayer(index: Int)
}

// MARK: - Game Outcome

/// The three ways a match can end.
enum GameOutcome {
    /// A player's HP reached 0 — immediate knockout.
    case knockout(winner: Int)
    /// 20 turns elapsed; the player with more HP wins.
    case roundCapWin(winner: Int)
    /// 20 turns elapsed with equal HP on both sides.
    case draw
}

// MARK: - Events

/// Typed publish-subscribe messages for the EventBus.
///
/// ## Ownership Table
///
/// | Event                          | Publisher                                | Subscribers                             |
/// |-------------------------------|------------------------------------------|-----------------------------------------|
/// | `.aimLocked`                  | `TapInputSystem` / `TurnSystem` (timeout)| `GyroscopeSystem`                       |
/// | `.aimLockConfirmed`           | `GyroscopeSystem`                        | `AimState`                              |
/// | `.powerLocked`                | `TapInputSystem` / `TurnSystem` (timeout)| `VoiceInputSystem`                      |
/// | `.powerLockConfirmed`         | `VoiceInputSystem`                       | `PowerState`                            |
/// | `.handoffDismissed`           | `TapInputSystem`                         | `TurnHandoffState`                      |
/// | `.throwStarted`               | `ThrowSystem`                            | `UISystem`                              |
/// | `.throwResolved(hit:)`        | `HitDetectionSystem` / `PhysicsSystem`   | `DamageSystem`, `ThrowResolveState`     |
/// | `.damageApplied(amount:to:)`  | `DamageSystem` / `FixedHitSystem`        | `WinCheckSystem`, `UISystem`            |
/// | `.healApplied(amount:to:)`    | `HealSystem`                             | `UISystem`                              |
/// | `.turnEnded`                  | `DamageSystem`, `HealSystem`, `FixedHitSystem` | `WinCheckSystem`                  |
/// | `.gameOver(outcome:)`         | `WinCheckSystem`                         | State machine                           |
/// | `.timerTick(remaining:)`      | `TurnSystem`                             | `UISystem`                              |
/// | `.amplitudeUpdated(_:)`       | `VoiceInputSystem`                       | `UISystem`                              |
/// | `.cycleAdvanced(newDamage:)`  | `DamageCycleManager`                     | `UISystem`                              |
/// | `.roundCountUpdated(turn:max:)`| `RoundCounterManager`                   | `UISystem`, `WinCheckSystem`            |
/// | `.previewPanComplete`         | `CameraSystem`                           | `PreviewPanState`                       |
/// | `.cameraReturnComplete`       | `CameraSystem`                           | `ThrowResolveState`                     |
/// | `.showSkillSelection`         | `SkillSelectState`                       | `UISystem`                              |
/// | `.skillSelected(_:)`          | `SkillSelectionViewController`           | `SkillSelectState`                      |
/// | `.skillSkipped`               | `SkillSelectionViewController`           | `SkillSelectState`                      |
/// | `.skillUsed(playerIndex:skill:)`| `SkillSelectState`                     | `UISystem`                              |
/// | `.showTurnHandoff(nextPlayerIndex:)`| `TurnHandoffState`                 | `UISystem`                              |
/// | `.hpChanged(playerIndex:hp:)` | `DamageSystem`, `HealSystem`, `FixedHitSystem` | `UISystem`                      |
enum GameEvent {

    // MARK: Input lifecycle
    case aimLocked
    case aimLockConfirmed
    case powerLocked
    case powerLockConfirmed
    case handoffDismissed

    // MARK: Throw lifecycle
    case throwStarted
    case throwResolved(hit: Bool)

    // MARK: Outcome events
    case damageApplied(amount: Int, to: Int)
    case healApplied(amount: Int, to: Int)
    case turnEnded
    case gameOver(outcome: GameOutcome)

    // MARK: Timer
    case timerTick(remaining: TimeInterval)

    // MARK: Mic / voice
    case amplitudeUpdated(Float)

    // MARK: Cycle & rounds
    case cycleAdvanced(newDamage: Int)
    case roundCountUpdated(turn: Int, max: Int)

    // MARK: Camera
    case previewPanComplete
    case cameraReturnComplete

    // MARK: Skill selection
    case showSkillSelection
    case skillSelected(SkillType)
    case skillSkipped
    case skillUsed(playerIndex: Int, skill: SkillType)

    // MARK: UI
    case showTurnHandoff(nextPlayerIndex: Int)
    case hpChanged(playerIndex: Int, hp: Int)

    // MARK: - Key

    /// Stripped-association-value key used as the EventBus dictionary key.
    /// One `Key` case per `GameEvent` case, no associated values.
    enum Key: Hashable {
        case aimLocked, aimLockConfirmed, powerLocked, powerLockConfirmed
        case handoffDismissed, throwStarted, throwResolved, damageApplied
        case healApplied, turnEnded, gameOver, timerTick, amplitudeUpdated
        case cycleAdvanced, roundCountUpdated, previewPanComplete
        case cameraReturnComplete, showSkillSelection, skillSelected
        case skillSkipped, skillUsed, showTurnHandoff, hpChanged
    }

    /// Derives the `Key` from `self`, stripping associated values so it can
    /// serve as a dictionary key for EventBus subscriptions.
    var key: Key {
        switch self {
        case .aimLocked:           return .aimLocked
        case .aimLockConfirmed:    return .aimLockConfirmed
        case .powerLocked:         return .powerLocked
        case .powerLockConfirmed:  return .powerLockConfirmed
        case .handoffDismissed:    return .handoffDismissed
        case .throwStarted:        return .throwStarted
        case .throwResolved:       return .throwResolved
        case .damageApplied:       return .damageApplied
        case .healApplied:         return .healApplied
        case .turnEnded:           return .turnEnded
        case .gameOver:            return .gameOver
        case .timerTick:           return .timerTick
        case .amplitudeUpdated:    return .amplitudeUpdated
        case .cycleAdvanced:       return .cycleAdvanced
        case .roundCountUpdated:   return .roundCountUpdated
        case .previewPanComplete:  return .previewPanComplete
        case .cameraReturnComplete: return .cameraReturnComplete
        case .showSkillSelection:  return .showSkillSelection
        case .skillSelected:       return .skillSelected
        case .skillSkipped:        return .skillSkipped
        case .skillUsed:           return .skillUsed
        case .showTurnHandoff:     return .showTurnHandoff
        case .hpChanged:           return .hpChanged
        }
    }
=======
/// | Event                            | Publisher                                    | Subscriber(s)                                              |
/// |----------------------------------|----------------------------------------------|------------------------------------------------------------|
/// | `damageApplied(amount:to:)`      | `DamageSystem`                               | `HUDNode` (flash red, update HP), `GameScene` (float text) |
/// | `healApplied(amount:to:)`        | `HealSystem`                                 | `HUDNode` (flash green, update HP)                         |
/// | `cycleAdvanced(newDamage:)`      | `DamageSystem` / `FixedHitSystem`            | `HUDNode` (update damage label if any)                     |
/// | `turnEnded`                      | `DamageSystem` / `HealSystem` / `FixedHitSystem` | `GameStateMachine` (trigger handoff/round over)       |
/// | `turnChanged(activePlayer:)`     | `GameStateMachine` (`TurnHandoffState`)      | `HUDNode` (glow active side), `TurnHandoffOverlay`         |
/// | `skillSelected(skill:)`          | `SkillSelectionViewController`               | `HUDNode` (gray out icon), `SkillSystem` (process effect)  |
/// | `timerTick(timeLeft:)`           | `AimState` / `PowerState`                    | `HUDNode` (shrink timer bar, turn red at ≤ 2s)             |
/// | `throwResolved(hit:)`            | `HitDetectionSystem`                         | `DamageSystem` (apply damage)                              |
/// | `roundCountUpdated(turnCount:)`  | `RoundCounterManager`                        | `GameStateMachine` (check win conditions)                  |
enum GameEvent {
    case damageApplied(amount: Int, to: PlayerID)
    case healApplied(amount: Int, to: PlayerID)
    case cycleAdvanced(newDamage: Int)
    case turnEnded
    case turnChanged(activePlayer: PlayerID)
    case skillSelected(skill: SkillType)
    case timerTick(timeLeft: TimeInterval)
    case throwResolved(hit: Bool)
    case roundCountUpdated(turnCount: Int)
>>>>>>> 6838055 (feat: Implement core ECS foundation and components (#30, #34, #39, #68))
}
