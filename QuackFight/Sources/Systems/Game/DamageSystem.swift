//
//  DamageSystem.swift
//  QuackFight
//
//  Created by Nathan Sudiara on 12/05/26.
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
/// ## GDD Table: Cycle Position × Skill Used
///
/// | Cycle Index | Base Dmg | Skill Used         | Expected Damage / Result             |
/// |-------------|----------|--------------------|--------------------------------------|
/// | 0 / 1       | 10       | None               | 10 damage                            |
/// | 2           | 15       | None               | 15 damage                            |
/// | 0 / 1       | 10       | 2x Damage          | 20 damage                            |
/// | 2           | 15       | 2x Damage          | 30 damage                            |
/// | 0 / 1       | 10       | Heal               | Heals self for 10 (Max 100)          |
/// | 2           | 15       | Heal               | Heals self for 15 (Max 100)          |
/// | 0 / 1       | 10       | Fixed Hit          | 10 damage (unmissable)               |
/// | 2           | 15       | Fixed Hit          | 15 damage (unmissable)               |
///
/// ## Edge Cases (GDD 10.2)
///
/// 1. **Miss with 2x Damage**: The damage multiplier is permanently consumed, but no damage is applied.
/// 2. **Heal at Max HP**: Skill is consumed, HP clamped to maxHP.
/// 3. **Cycle Wrapping**: After position 2 (15 dmg), round advances back to position 0 (10 dmg).
/// 4. **Throw Out-of-Bounds**: Resolves as a miss, no damage applied, active skill consumed.
/// 5. **Zero HP**: Hit reduces opponent HP to <= 0, triggers KO and transitions to GameOverState.
///
/// ## Visual & Audio Feedback
/// - **Visual**: Red floating damage text above the target (`-10` or `-20` or `-15` or `-30`). Target flashes red briefly.
/// - **Audio**: Impact / Hit SFX triggers.
class DamageSystem {

    static let shared = DamageSystem()
    private init() {}

    // MARK: - System Lifecycle

    /// Re-register EventBus subscriptions. Called by `InitState` after
    /// `clearAllSubscriptions()` wipes the previous match's handlers.
    func setupSubscriptions() {
        // Reacts to: .throwResolved — subscribe ONCE per match, see doc-block above.
        EventBus.shared.subscribe(.throwResolved) { [weak self] event in
            guard let self, case .throwResolved(let hit) = event, hit else { return }
            self.applyDamage()
        }
    }

    // MARK: - Damage Logic

    /// Look up the opponent's `HealthComponent` and apply the current cycle damage.
    private func applyDamage() {
        let activePlayer = GameManager.shared.activePlayer
        let opponent = GameManager.shared.opponentPlayer
        
        let baseDamage = DamageCycleManager.shared.currentDamage
        var finalDamage = baseDamage
        
        let skillComp = activePlayer.component(ofType: SkillComponent.self)
        if skillComp?.activeSkill == .damageMultiplier {
            finalDamage *= 2
        }
        
        // Apply damage to opponent
        let opponentIndex = GameManager.shared.nextPlayerIndex
        if let healthComp = opponent.component(ofType: HealthComponent.self) {
            healthComp.takeDamage(finalDamage)
            EventBus.shared.post(.damageApplied(amount: finalDamage, to: opponentIndex))
            EventBus.shared.post(.hpChanged(playerIndex: opponentIndex, hp: healthComp.hp))
        }
        
        // Consume the skill permanently
        skillComp?.consumeActive()
        
        // Notify state machine
        EventBus.shared.post(.turnEnded)
    }
}
