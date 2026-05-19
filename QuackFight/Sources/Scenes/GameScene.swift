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

        // 4. Start the state machine (InitState → PreviewPanState / AimState)
        GameStateMachine.shared.start()
    }

    private func setupBackground() {
        let bg = SKSpriteNode(imageNamed: "Background1")
        // Widen by 1.5× so the background covers camera movement left/right.
        bg.size = CGSize(width: self.size.width * 1.5, height: self.size.height)
        bg.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        bg.zPosition = -10
        addChild(bg)
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

        UISystem.shared.setup(hud: hud, powerBar: powerBar, turnHandoff: turnHandoff, skillSelection: skillSelection)
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

        // Physics before hit-detection: positions must be updated before collision checks.
        TurnSystem.shared.update(deltaTime: dt)
        PhysicsSystem.shared.update(deltaTime: dt)
        HitDetectionSystem.shared.update(deltaTime: dt)
        CameraSystem.shared.update(deltaTime: dt)

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
