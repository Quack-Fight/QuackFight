//
//  HealSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import Foundation

/// Applies a heal to the active player when the Heal skill is used.
///
/// Called directly by `HealResolveState.didEnter(_:)`. Posts `.healApplied`
/// and `.hpChanged` so the HUD updates, then posts `.turnEnded`.
///
/// ## Intended implementation
/// 1. Read `DamageCycleManager.shared.currentDamage` as the heal amount.
/// 2. Look up active player via `GameManager.shared.activePlayer`.
/// 3. Call `HealthComponent.heal(amount)`.
/// 4. Call `SkillComponent.consumeActive()` to permanently use the skill.
/// 5. Post `.healApplied(amount:to:)` and `.hpChanged(playerIndex:hp:)`.
/// 6. Post `.turnEnded` to signal the round is complete.
final class HealSystem {

    static let shared = HealSystem()
    private init() {}

    // MARK: - Apply Heal

    /// Apply the current cycle's damage value as healing to the active player.
    func applyHeal() {
        // TODO: Implement heal logic per the doc block above.
        // Stubbed so HealResolveState can compile and wire the event flow.
    }

    // MARK: - System Lifecycle

    /// Re-register EventBus subscriptions. Called by `InitState` after
    /// `clearAllSubscriptions()` at match start.
    func setupSubscriptions() {
        // TODO: Subscribe to relevant events if needed.
    }
}
