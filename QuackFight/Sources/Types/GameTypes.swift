//
//  GameTypes.swift
//  QuackFight
//
//  Created by Nathan Sudiara on 12/05/26.
//

import Foundation

enum PlayerID: String {
    case player1 = "player1"
    case player2 = "player2"
}

enum SkillType {
    case damageMultiplier
    case heal
    case fixedHit
}

/// **Game Event Ownership and Subscriber Table**
///
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
}
