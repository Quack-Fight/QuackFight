//
//  DamageSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import GameplayKit

/// `DamageSystem` listens for `throwResolved(hit: true)` events on the `EventBus`
/// and applies the current cycle's damage to the target player's `HealthComponent`.
///
/// ## Why subscribe in `init()` instead of `update()` (Issue #68)
///
/// Game systems that react to events must subscribe **once** during initialisation.
/// If we placed `EventBus.shared.subscribe(...)` inside `update(deltaTime:)`,
/// a new closure would be appended to the observer list **every single frame**
/// (60 times per second), causing:
///
/// 1. **Exponential callback growth** — after 5 seconds there would be ~300
///    duplicate handlers, each applying damage independently.
/// 2. **Memory bloat** — every closure captures `self`, so none of those
///    closures (or the system itself) can ever be deallocated.
///
/// ## Why `[weak self]` is critical
///
/// `EventBus.shared` is a **singleton** that outlives every system instance.
/// If the closure captures `self` strongly, a **retain cycle** forms:
///
///     EventBus (singleton) → closure → DamageSystem → (keeps itself alive forever)
///
/// Using `[weak self]` breaks this cycle: when the system is removed from the
/// entity/component graph, its reference count drops to zero and it deallocates
/// normally, and the closure becomes a harmless no-op (`self` is `nil`).
///
class DamageSystem {

    /// Reference to player entities so we can look up HealthComponents.
    private weak var player1: PlayerEntity?
    private weak var player2: PlayerEntity?

    // MARK: - Init

    init(player1: PlayerEntity, player2: PlayerEntity) {
        self.player1 = player1
        self.player2 = player2

        // Reacts to: .throwResolved — subscribe ONCE at init, see doc-block above.
        EventBus.shared.subscribe(.throwResolved) { [weak self] event in
            guard let self, case .throwResolved(let hit) = event, hit else { return }
            self.applyDamage()
        }
    }

    // MARK: - Damage Logic

    /// Look up the opponent's `HealthComponent` and apply the current cycle damage.
    private func applyDamage() {
        // TODO: Wire up active player tracking + DamageCycleManager
        // Placeholder logic shows the intended data flow:
        //
        // 1. Determine which player is defending (opposite of active player).
        // 2. Read base damage from DamageCycleManager.currentDamage.
        // 3. Check if a damageMultiplier skill is active → multiply.
        // 4. Call defender.component(ofType: HealthComponent.self)?.takeDamage(amount).
        // 5. Publish .damageApplied(amount:to:) so HUD reacts.
        // 6. Publish .turnEnded so the state machine advances.
    }
}
