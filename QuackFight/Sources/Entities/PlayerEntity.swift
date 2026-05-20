//
//  PlayerEntity.swift
//  QuackFight
//
//  Created by Nathan Sudiara on 08/05/26.
//

import GameplayKit
import SpriteKit

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
/// | `sprite`             | `SpriteComponent`                | References the `SKSpriteNode` for this player          |
/// | `animation`          | `AnimationComponent` (future)    | Stores animation frame sequences                       |
/// | `hitbox`             | `HitboxComponent`                | Collision radius for hit detection                     |
///
class PlayerEntity: GKEntity {

    /// Which player this entity represents: 0 = Player 1, 1 = Player 2.
    let playerIndex: PlayerIndex

    /// Throw direction multiplier used by PhysicsEngine to flip projectile velocity.
    /// Player 1 throws right (+1), Player 2 throws left (−1).
    /// NOTE: This does NOT affect visual xScale — both assets are pre-oriented
    /// (Goose faces right, Duck faces left) and should never be flipped.
    var facing: CGFloat { playerIndex == 0 ? 1.0 : -1.0 }

    /// The world-space point from which projectiles originate.
    /// Derived from the sprite position at the moment of throw.
    var throwOrigin: CGPoint = .zero

    /// The hand/wing sprite that rotates with the aim angle.
    /// Child of the body sprite node so it moves with the player.
    private(set) var handNode: SKSpriteNode?

    // MARK: - Init

    init(playerIndex: PlayerIndex, scene: GameScene) {
        self.playerIndex = playerIndex
        super.init()

        let worldWidth = scene.playableWorldWidth
        let xPos = playerIndex == 0
            ? GameConstants.playerXInset
            : worldWidth - GameConstants.playerXInset
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

        // Attach the hand sprite as a child of the body.
        setupHand(on: spriteComp.node)

        // HitboxComponent defines the collision radius for HitDetectionSystem.
        // A radius of 60pt covers ~70% of the 170px sprite width for generous hit detection.
        addComponent(HitboxComponent(radius: 60.0))

        // TransformComponent seeds the initial world position so RenderSystem
        // places the sprite at throwOrigin on the very first frame.
        addComponent(TransformComponent(position: throwOrigin))

        scene.registerEntity(self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported for PlayerEntity")
    }

    // MARK: - Hand Setup

    /// Creates the hand sprite and attaches it to the body at the shoulder position.
    ///
    /// The hand asset is 513×281px. Scaled to ~90×49 to be proportional with the 170px body.
    /// Anchor point is set at the shoulder joint so rotation pivots naturally.
    ///
    /// - Goose (P1, faces right): anchor (0, 0.5) — left edge is the shoulder pivot.
    ///   Hand extends to the right.
    /// - Duck (P2, faces left): anchor (1, 0.5) — right edge is the shoulder pivot.
    ///   Hand extends to the left.
    private func setupHand(on bodyNode: SKSpriteNode) {
        let handImageName = playerIndex == 0 ? "HandGoose" : "HandDuck"
        let hand = SKSpriteNode(imageNamed: handImageName)

        // Scale to be proportional with the 170px body.
        // Original aspect ratio: 513:281 ≈ 1.83:1
        let handWidth: CGFloat = 90
        let handHeight: CGFloat = handWidth / 1.83
        hand.size = CGSize(width: handWidth, height: handHeight)

        // Anchor at the shoulder joint so rotation pivots from the body connection point.
        if playerIndex == 0 {
            // Goose faces right — shoulder is at the left edge of the hand sprite.
            hand.anchorPoint = CGPoint(x: 0, y: 0.5)
            hand.position = CGPoint(x: 20, y: 15)
        } else {
            // Duck faces left — shoulder is at the right edge of the hand sprite.
            hand.anchorPoint = CGPoint(x: 1, y: 0.5)
            hand.position = CGPoint(x: -20, y: 15)
        }

        hand.zPosition = -1  // Behind the body so the wing appears underneath
        bodyNode.addChild(hand)
        self.handNode = hand
    }

    // MARK: - Hand Animation

    /// Rotates the hand to match the given aim angle (in radians).
    ///
    /// Called every frame by `TrajectoryRenderSystem` during `AimState`.
    /// Pass `nil` to reset the hand to its neutral resting position.
    ///
    /// - Goose (P1): hand.zRotation = angle (positive angle aims up-right)
    /// - Duck (P2): hand.zRotation = −angle (negated to mirror aim up-left)
    func setHandAngle(_ angle: Double?) {
        guard let hand = handNode else { return }

        guard let angle = angle else {
            // Reset to resting position (slightly downward).
            hand.zRotation = 0
            return
        }

        if playerIndex == 0 {
            // Goose faces right — direct angle mapping.
            // angle=0 → hand points right, angle=π/4 → hand points up-right.
            hand.zRotation = CGFloat(angle)
        } else {
            // Duck faces left — the hand sprite extends leftward from anchor (1, 0.5).
            // Negating the angle mirrors the rotation so aiming "up" goes up-left.
            // angle=0 → hand points left, angle=π/4 → hand points up-left.
            hand.zRotation = -CGFloat(angle)
        }
    }
}
