//
//  PlayerEntity.swift
//  QuackFight
//
//  Created by Nathan Sudiara on 08/05/26.
//

import GameplayKit

/// `PlayerEntity` is a `GKEntity` container that represents a single player in the game.
///
/// ## PlayerData → GKComponent Mapping (GDD §9.4)
///
/// | GDD PlayerData Field | ECS Component / Property         | Notes                                                  |
/// |----------------------|----------------------------------|--------------------------------------------------------|
/// | `id`                 | `PlayerEntity.playerIndex`       | 0 = Player 1, 1 = Player 2; set at init                |
/// | `hp`                 | `HealthComponent.hp`             | Clamped 0…maxHP; `isDead` / `hpFraction` computed      |
/// | `skills`             | `SkillComponent.availableSkills` | Set of `SkillType`; consumed via `consumeActive()`     |
/// | `throwOrigin`        | `PlayerEntity.throwOrigin`       | `CGPoint` derived from sprite position at throw time   |
/// | `aimAngle`           | `InputStateComponent.liveAngle`  | Degrees; updated by `GyroscopeSystem`                  |
/// | `power`              | `InputStateComponent.livePower`  | 0…1 normalised; updated by `VoiceInputSystem`          |
/// | `isActive`           | Managed by `GameStateMachine`    | The state machine tracks whose turn it is externally   |
/// | `sprite`             | `SpriteComponent` (future)       | References the `SKSpriteNode` for this player          |
/// | `animation`          | `AnimationComponent` (future)    | Stores animation frame sequences                       |
/// | `hitbox`             | `HitboxComponent` (future)       | Physics body dimensions for collision detection        |
///
class PlayerEntity: GKEntity {

    /// Which player this entity represents: 0 = Player 1, 1 = Player 2.
    let playerIndex: PlayerIndex

    /// Facing direction: +1 for Player 1 (faces right), -1 for Player 2 (faces left).
    var facing: CGFloat { playerIndex == 0 ? 1 : -1 }

    /// The world-space point from which projectiles originate.
    /// Derived from the sprite position at the moment of throw.
    var throwOrigin: CGPoint = .zero

    // MARK: - Init

    init(playerIndex: PlayerIndex) {
        self.playerIndex = playerIndex
        super.init()

        addComponent(HealthComponent())
        addComponent(SkillComponent())
        addComponent(InputStateComponent())
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported for PlayerEntity")
    }
}
