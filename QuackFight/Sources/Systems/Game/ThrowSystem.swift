//
//  ThrowSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import Foundation
import GameplayKit

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

    // MARK: - State

    var activeBread: ProjectileEntity?
    var isInFlight: Bool = false

    // MARK: - Execute

    /// Spawn the projectile and run the throw sequence.
    /// Posts `.throwStarted`, then `.throwResolved(hit:)` when the projectile lands.
    func executeThrow(player: PlayerEntity, scene: GameScene) {
        let input = player.component(ofType: InputStateComponent.self)
        let angle = input?.lockedAngle ?? GameConstants.defaultAimAngle
        let power = input?.lockedPower ?? 0.5
        
        let facing = player.facing
        let velocity = PhysicsEngine.calculateVelocity(angle: angle, power: power, facing: facing)
        
        // Determine projectile image
        let activeSkill = player.component(ofType: SkillComponent.self)?.activeSkill
        let cyclePos = DamageCycleManager.shared.position
        
        let imageName: String
        if activeSkill == .damageMultiplier {
            imageName = (cyclePos == 2) ? "Skill1Toaster" : "Skill1Bread"
        } else {
            imageName = (cyclePos == 2) ? "BaseToaster" : "BaseBread"
        }
        
        // Create and setup the projectile
        let projectile = ProjectileEntity(
            imageName: imageName,
            position: player.throwOrigin,
            velocity: velocity,
            radius: GameConstants.defaultHitBoxRadius
        )
        
        projectile.addToScene(scene)
        self.activeBread = projectile
        self.isInFlight = true
        
        EventBus.shared.post(.throwStarted)
    }
    
    /// Removes the bread and nils the reference.
    func clearBread(scene: GameScene) {
        activeBread?.removeFromScene(scene)
        activeBread = nil
        isInFlight = false
    }

    // MARK: - System Lifecycle

    /// Re-register EventBus subscriptions. Called by `InitState` after
    /// `clearAllSubscriptions()` at match start.
    func setupSubscriptions() {
        // TODO: Subscribe to relevant events (e.g. physics collision callbacks).
    }
}
