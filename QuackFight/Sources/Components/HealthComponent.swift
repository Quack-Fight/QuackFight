//
//  HealthComponent.swift
//  QuackFight
//
//  Created by Justin Chow on 08/05/26.
//

import GameplayKit

/// Pure-data component that tracks a player's hit points.
///
/// ## HP Bar Visual Parameters (GDD §7 / Issue #39)
///
/// | Parameter         | Value / Rule                                                          |
/// |-------------------|-----------------------------------------------------------------------|
/// | Red flash         | Triggered on damage; duration **0.2 s**; applies to HP bar fill node  |
/// | Green flash       | Triggered on heal;   duration **0.2 s**; applies to HP bar fill node  |
/// | Bar scale driver  | `hpFraction` (0.0 … 1.0) maps linearly to the bar's `xScale`          |
/// | Overheal guard    | `hp` is clamped to `0 ... maxHP` — heal can never exceed cap          |
/// | Death trigger     | When `isDead == true`, the `AnimationSystem` queues the death anim    |
///
class HealthComponent: GKComponent {

    /// Maximum HP this player can have (matches `GameConstants.maxHP`).
    let maxHP: Int

    /// Current hit points, clamped between 0 and `maxHP`.
    private(set) var hp: Int {
        didSet { hp = min(max(hp, 0), maxHP) }
    }

    /// `true` when HP has reached zero.
    var isDead: Bool { hp <= 0 }

    /// Normalised health value (0.0 … 1.0) used to drive the HP bar scale.
    var hpFraction: CGFloat { CGFloat(hp) / CGFloat(maxHP) }

    // MARK: - Init

    init(maxHP: Int = GameConstants.maxHP) {
        self.maxHP = maxHP
        self.hp = maxHP
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported for HealthComponent")
    }

    // MARK: - Mutations

    /// Apply damage. Value is clamped so HP never drops below 0.
    func takeDamage(_ amount: Int) {
        hp -= amount
    }

    /// Apply healing. Value is clamped so HP never exceeds `maxHP`.
    func heal(_ amount: Int) {
        hp += amount
    }
}
