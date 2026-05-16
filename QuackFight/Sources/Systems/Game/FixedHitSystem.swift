//
//  FixedHitSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import Foundation
import GameplayKit

/// Applies a guaranteed fixed-damage hit to the opponent when the Fixed Hit skill is used.
///
/// Called directly by `FixedHitResolveState.didEnter(_:)`. Posts `.damageApplied`
/// and `.hpChanged` (triggering `WinCheckSystem`), then posts `.turnEnded`.
///
/// ## Intended implementation
/// 1. Read `DamageCycleManager.shared.currentDamage` as the fixed damage amount.
/// 2. Look up opponent via `GameManager.shared.opponentPlayer`.
/// 3. Call `HealthComponent.takeDamage(amount)`.
/// 4. Call `SkillComponent.consumeActive()` on the active player.
/// 5. Post `.damageApplied(amount:to:)` and `.hpChanged(playerIndex:hp:)`.
/// 6. Post `.turnEnded` to signal the round is complete.
///    `WinCheckSystem` will also receive `.damageApplied` and post `.gameOver`
///    if the opponent's HP reached 0 — that event is routed by `FixedHitResolveState`.
///
/// ## Visual & Audio Feedback (#75)
/// - **Visual**: Orange "FIXED HIT" label. Target flashes red.
/// - **Audio**: Missile Explosion SFX triggers on impact.
final class FixedHitSystem {

    static let shared = FixedHitSystem()
    private init() {}

    // MARK: - Apply Fixed Hit

    /// Apply the current cycle's damage value to the opponent (guaranteed, no throw).
    func applyFixedHit() {
        let activePlayer = GameManager.shared.activePlayer
        let opponent = GameManager.shared.opponentPlayer
        let fixedDamage = DamageCycleManager.shared.currentDamage
        
        // Apply damage to opponent
        if let healthComp = opponent.component(ofType: HealthComponent.self) {
            healthComp.takeDamage(fixedDamage)
            
            // Post event for UI and WinCheckSystem
            EventBus.shared.post(.damageApplied(amount: fixedDamage, to: GameManager.shared.nextPlayerIndex))
        }
        
        // Consume the skill permanently
        activePlayer.component(ofType: SkillComponent.self)?.consumeActive()
        
        // Notify state machine
        EventBus.shared.post(.turnEnded)
    }

    // MARK: - System Lifecycle

    /// Re-register EventBus subscriptions. Called by `InitState` after
    /// `clearAllSubscriptions()` at match start.
    func setupSubscriptions() {
        // TODO: Subscribe to relevant events if needed.
    }
}
