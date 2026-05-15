//
//  ThrowSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import Foundation

/// Executes a bread-projectile throw for the active player.
///
/// Called directly by `ThrowResolveState.didEnter(_:)`. After the projectile
/// lands (or leaves the arena), this system posts `.throwResolved(hit:)`.
///
/// ## Intended implementation
/// 1. Read `activePlayer.throwOrigin`, `InputStateComponent.aimAngle`, and
///    `InputStateComponent.power`.
/// 2. Spawn a `ProjectileEntity` at `throwOrigin`.
/// 3. Apply velocity computed by `PhysicsEngine.calculateVelocity(angle:power:)`.
/// 4. Post `.throwStarted` so `CameraSystem` switches to `.followBread`.
/// 5. On collision (hit) or out-of-bounds (miss): post `.throwResolved(hit:)`.
final class ThrowSystem {

    static let shared = ThrowSystem()
    private init() {}

    // MARK: - Execute

    /// Spawn the projectile and run the throw sequence.
    /// Posts `.throwStarted`, then `.throwResolved(hit:)` when the projectile lands.
    func executeThrow() {
        // TODO: Implement projectile spawn, physics integration, hit detection.
        // Stubbed so ThrowResolveState can compile and wire the event flow.
    }

    // MARK: - System Lifecycle

    /// Re-register EventBus subscriptions. Called by `InitState` after
    /// `clearAllSubscriptions()` at match start.
    func setupSubscriptions() {
        // TODO: Subscribe to relevant events (e.g. physics collision callbacks).
    }
}
