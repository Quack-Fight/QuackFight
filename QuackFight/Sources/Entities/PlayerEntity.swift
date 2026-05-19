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

    init(playerIndex: PlayerIndex, scene: GameScene) {
        self.playerIndex = playerIndex
        super.init()

        let viewportWidth = scene.size.width
        let worldWidth = max(scene.playableWorldWidth, viewportWidth)
        let xPos = playerIndex == 0 ? viewportWidth * 0.5 : worldWidth - viewportWidth * 0.5
        let yPos = playerIndex == 0 ? GameConstants.player1YPosition : GameConstants.player2YPosition
        self.throwOrigin = CGPoint(x: xPos, y: yPos)

        addComponent(HealthComponent())
        addComponent(SkillComponent())
        addComponent(InputStateComponent())

        // Player 1 (index 0) = Goose; Player 2 (index 1) = Duck.
        // HUDNode uses GooseHPBar for P1 and DuckHPBar for P2, confirming this mapping.
        let imageName = playerIndex == 0 ? "BaseGoose" : "BaseDuck"
        let spriteComp = SpriteComponent(imageName: imageName)
        spriteComp.node.size = CGSize(width: 170, height: 170)
        spriteComp.node.zPosition = 1
        scene.addChild(spriteComp.node)
        addComponent(spriteComp)

        // TransformComponent seeds the initial world position so RenderSystem
        // places the sprite at throwOrigin on the very first frame.
        addComponent(TransformComponent(position: throwOrigin))

        scene.registerEntity(self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported for PlayerEntity")
    }
}
