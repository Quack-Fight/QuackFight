//
//  GameScene.swift
//  QuackFight
//
//  Created by Nathan Sudiara on 07/05/26.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {

    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    private(set) var playableWorldWidth: CGFloat = 0
    private(set) var playableWorldHeight: CGFloat = 0
    private var backgroundLayers: [SKSpriteNode] = []

    private var lastUpdateTime: TimeInterval = 0

    // MARK: - GKComponentSystem Array (#116)
    //
    // addComponent(foundIn:) scans an entity for a component matching the system's
    // componentClass and registers it automatically — no manual cast required.
    //
    // Update order constraint (#60):
    // PhysicsSystem must precede HitDetectionSystem so collision checks always
    // see the projectile's already-advanced position. PhysicsSystem is listed
    // first here so registerEntity wires it before HitDetectionSystem.
    //
    // ObjC generic erasure: GKComponentSystem<T> is the same ObjC class regardless of T,
    // so unsafeBitCast is safe here where as! would fail Swift's runtime type check.
    private lazy var componentSystems: [GKComponentSystem<GKComponent>] = [
        unsafeBitCast(PhysicsSystem.shared,  to: GKComponentSystem<GKComponent>.self),
        unsafeBitCast(TapInputSystem.shared, to: GKComponentSystem<GKComponent>.self)
    ]

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        self.lastUpdateTime = 0

        // Origin at bottom-left so x ∈ [0, sceneWidth] and y ∈ [0, sceneHeight],
        // matching the physics bounds in PhysicsSystem and GameConstants.groundY = 0.
        self.anchorPoint = CGPoint(x: 0, y: 0)

        setupBackground()

        // 1. Camera must exist before players so camera-related systems can reference it.
        let cameraEntity = CameraEntity(scene: self)

        // 2. Create both players.
        let p1 = PlayerEntity(playerIndex: 0, scene: self)
        let p2 = PlayerEntity(playerIndex: 1, scene: self)

        // 3. Register players and scene in GameManager.
        //
        // This is important because AudioManager.playSFX uses:
        // GameManager.shared.scene
        GameManager.shared.registerPlayers(p1, p2, scene: self)

        // 4. Setup UI.
        //
        // HUD is attached to the camera node so it stays fixed on screen.
        setupUI(cameraNode: cameraEntity.cameraNode)
        TrajectoryRenderSystem.shared.setup(in: self)

        // 5. Start BGM.
        //
        // Only BGM starts here.
        //
        // Do NOT call AudioManager.shared.setupSubscriptions() here
        // if InitState calls EventBus.shared.clearAllSubscriptions().
        //
        // SFX subscriptions should be registered in InitState AFTER clearAllSubscriptions().
        AudioManager.shared.startBGM()

        // TEMP SFX TEST:
        // Uncomment this line only for testing.
        // If this does not play, the .wav file is not in the app bundle / target membership.
        //
        // run(SKAction.playSoundFileNamed("throw.wav", waitForCompletion: false))

        // 6. Start the state machine.
        //
        // InitState will clear and re-register EventBus subscriptions.
        GameStateMachine.shared.start()
    }

    private func setupBackground() {
        let viewportWidth = self.size.width

        // 1. World is multiple phone screens wide.
        playableWorldWidth = viewportWidth * GameConstants.worldScreenMultiplier

        // 2. Auto-calculate height from the background's native aspect ratio.
        let sampleTexture = SKTexture(imageNamed: "Background1")
        let aspectRatio = sampleTexture.size().height / sampleTexture.size().width
        playableWorldHeight = playableWorldWidth * aspectRatio

        // 3. Stack all 8 parallax layers, back to front.
        //    Layer 1 = farthest (sky), Layer 8 = closest (ground/foreground).
        //    Distant layers are scaled larger so they don’t appear “zoomed in”
        //    when parallax position offsets show a different portion of the image.
        backgroundLayers.removeAll()
        let count = GameConstants.backgroundLayerCount
        for i in 1...count {
            let layer = SKSpriteNode(imageNamed: "Background\(i)")

            // t=0 for Background1 (farthest), t=1 for Background8 (closest).
//            let t = count > 1 ? CGFloat(i - 1) / CGFloat(count - 1) : 1.0
            let t = 0.0
            // Farthest layer gets parallaxDistantScale (1.3×), closest gets 1.0×.
//            let sizeScale = GameConstants.parallaxDistantScale
//                + (1.0 - GameConstants.parallaxDistantScale) * t
            let sizeScale: CGFloat = 1.0
            let layerWidth = playableWorldWidth * sizeScale
            let layerHeight = playableWorldHeight * sizeScale
            layer.size = CGSize(width: layerWidth, height: layerHeight)

            // Anchor at center so the larger layers extend equally on all sides.
            layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            layer.position = CGPoint(x: playableWorldWidth / 2, y: playableWorldHeight / 2)
            layer.zPosition = GameConstants.backgroundBaseZPosition + CGFloat(i)
            addChild(layer)
            backgroundLayers.append(layer)
        }
    }

    // MARK: - Parallax

    /// Updates parallax layer positions based on the current camera position.
    ///
    /// Called every frame after CameraSystem has moved the camera.
    private func updateParallax() {
        guard let cameraNode = self.camera else { return }

        let cameraPos = cameraNode.position
        let worldCenterX = playableWorldWidth / 2
        let worldCenterY = playableWorldHeight / 2
        let offsetX = cameraPos.x - worldCenterX
        let offsetY = cameraPos.y - worldCenterY

        let count = GameConstants.backgroundLayerCount

        for (i, layer) in backgroundLayers.enumerated() {
            // Layer 0 = farthest, gets smallest factor.
            // Last layer = closest, gets factor 1.0.
            let t = count > 1 ? CGFloat(i) / CGFloat(count - 1) : 1.0

            let factor = GameConstants.parallaxMinFactor
                + (1.0 - GameConstants.parallaxMinFactor) * t

            // Each layer is centered at the world center.
            // Shift it by the camera offset scaled by (1 - factor).
            // factor=1.0 (closest) → no shift (moves with camera).
            // factor=0.1 (farthest) → large shift (moves much less).
            layer.position.x = worldCenterX + offsetX * (1.0 - factor)
            layer.position.y = worldCenterY + offsetY * (1.0 - factor)
        }
    }

    private func setupUI(cameraNode: SKCameraNode) {
        let hud = HUDNode(size: self.size)
        let powerBar = PowerBarNode()
        let turnHandoff = TurnHandoffOverlay(size: self.size)
        let skillSelection = SkillSelection(size: self.size)

        cameraNode.addChild(hud)
        cameraNode.addChild(powerBar)
        cameraNode.addChild(turnHandoff)
        cameraNode.addChild(skillSelection)

        UISystem.shared.setup(
            hud: hud,
            powerBar: powerBar,
            turnHandoff: turnHandoff,
            skillSelection: skillSelection,
            viewportSize: self.size
        )
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        TapInputSystem.shared.handleTap()
    }

    // MARK: - Game Loop

    override func update(_ currentTime: TimeInterval) {
        if self.lastUpdateTime == 0 {
            self.lastUpdateTime = currentTime
        }

        // Cap at 1/30 s so a long background pause doesn't produce a giant physics jump.
        let dt = min(currentTime - self.lastUpdateTime, 1.0 / 30.0)
        self.lastUpdateTime = currentTime

        // State machine first — may change which systems are relevant this frame.
        GameStateMachine.shared.update(deltaTime: dt)

        GyroscopeSystem.shared.update(deltaTime: dt)
        TrajectoryRenderSystem.shared.update(deltaTime: dt)

        // Turn timer.
        TurnSystem.shared.update(deltaTime: dt)

        // Physics before hit-detection:
        // projectile position must be updated before collision checks.
        PhysicsSystem.shared.update(deltaTime: dt)
        HitDetectionSystem.shared.update(deltaTime: dt)

        // Camera after projectile movement so followBread sees the latest position.
        CameraSystem.shared.update(deltaTime: dt)

        // Parallax after camera movement.
        updateParallax()

        // Entity component updates.
        for entity in entities {
            entity.update(deltaTime: dt)
        }

        // RenderSystem last:
        // single-writer rule — only RenderSystem writes SKNode.position.
        RenderSystem.shared.update(entities: entities, deltaTime: dt)
    }

    // MARK: - ECS Management (#120)

    /// Register an entity with the scene and all GKComponentSystems.
    ///
    /// `addComponent(foundIn:)` scans the entity for a component whose type matches
    /// the system's `componentClass` and registers it automatically.
    func registerEntity(_ entity: GKEntity) {
        guard !entities.contains(entity) else { return }

        entities.append(entity)

        for system in componentSystems {
            system.addComponent(foundIn: entity)
        }
    }

    /// Remove an entity from the scene and all GKComponentSystems.
    func removeEntity(_ entity: GKEntity) {
        guard let index = entities.firstIndex(of: entity) else { return }

        entities.remove(at: index)

        for system in componentSystems {
            system.removeComponent(foundIn: entity)
        }
    }
}
