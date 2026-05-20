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

        // 1. Camera (must exist before players so CameraSystem can reference it)
        let cameraEntity = CameraEntity(scene: self)

        // 2. Players
        let p1 = PlayerEntity(playerIndex: 0, scene: self)
        let p2 = PlayerEntity(playerIndex: 1, scene: self)

        GameManager.shared.registerPlayers(p1, p2, scene: self)

        // 3. HUD — attached to the camera node so it stays fixed on screen
        setupUI(cameraNode: cameraEntity.cameraNode)
        TrajectoryRenderSystem.shared.setup(in: self)

        // 4. Start the state machine (InitState → PreviewPanState / AimState)
        GameStateMachine.shared.start()
    }

    private func setupBackground() {
        let viewportWidth = self.size.width

        // 1. World is 6 phone screens wide
        playableWorldWidth = viewportWidth * GameConstants.worldScreenMultiplier

        // 2. Auto-calculate height from the background's native aspect ratio.
        //    All 8 layers are 8000×4000px (2:1), so height = width × 0.5.
        let sampleTexture = SKTexture(imageNamed: "Background1")
        let aspectRatio = sampleTexture.size().height / sampleTexture.size().width
        playableWorldHeight = playableWorldWidth * aspectRatio

        // 3. Stack all 8 parallax layers, back to front.
        //    Layer 1 = farthest (sky), Layer 8 = closest (ground/foreground).
        backgroundLayers.removeAll()
        for i in 1...GameConstants.backgroundLayerCount {
            let layer = SKSpriteNode(imageNamed: "Background\(i)")
            layer.size = CGSize(width: playableWorldWidth, height: playableWorldHeight)
            layer.anchorPoint = CGPoint(x: 0, y: 0)   // bottom-left origin
            layer.position   = .zero                    // aligned with scene origin
            layer.zPosition  = GameConstants.backgroundBaseZPosition + CGFloat(i)
            addChild(layer)
            backgroundLayers.append(layer)
        }
    }

    // MARK: - Parallax

    /// Updates parallax layer positions based on the current camera position.
    /// Called every frame after CameraSystem has moved the camera.
    ///
    /// Layers closer to the viewer scroll faster (factor → 1.0),
    /// while distant layers scroll slower (factor → parallaxMinFactor).
    /// Offsets are calculated from the world center to prevent edge gaps.
    private func updateParallax() {
        guard let cameraNode = self.camera else { return }

        let cameraPos = cameraNode.position
        let worldCenterX = playableWorldWidth / 2
        let worldCenterY = playableWorldHeight / 2
        let offsetX = cameraPos.x - worldCenterX
        let offsetY = cameraPos.y - worldCenterY

        let count = GameConstants.backgroundLayerCount
        for (i, layer) in backgroundLayers.enumerated() {
            // Layer 0 (Background1) = farthest, gets smallest factor.
            // Layer 7 (Background8) = closest, gets factor 1.0.
            let t = count > 1 ? CGFloat(i) / CGFloat(count - 1) : 1.0
            let factor = GameConstants.parallaxMinFactor
                + (1.0 - GameConstants.parallaxMinFactor) * t

            layer.position.x = offsetX * (1.0 - factor)
            layer.position.y = offsetY * (1.0 - factor)
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

        UISystem.shared.setup(hud: hud, powerBar: powerBar, turnHandoff: turnHandoff, skillSelection: skillSelection, viewportSize: self.size)
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

        // Physics before hit-detection: positions must be updated before collision checks.
        TurnSystem.shared.update(deltaTime: dt)
        PhysicsSystem.shared.update(deltaTime: dt)
        HitDetectionSystem.shared.update(deltaTime: dt)
        CameraSystem.shared.update(deltaTime: dt)
        updateParallax()

        for entity in entities {
            entity.update(deltaTime: dt)
        }

        // RenderSystem last: single-writer rule — only it writes to SKNode.position.
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
