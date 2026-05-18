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
    
    private var lastUpdateTime : TimeInterval = 0
    
    override func didMove(to view: SKView) {
        self.lastUpdateTime = 0
        
        // 1. Setup Camera
        let cameraEntity = CameraEntity(scene: self)
        
        // 2. Setup Players
        let p1 = PlayerEntity(playerIndex: 0)
        let p2 = PlayerEntity(playerIndex: 1)
        
        // P1 starts at -300x, P2 at +300x
        if let t1 = p1.component(ofType: TransformComponent.self) {
            t1.position = CGPoint(x: -300, y: 0)
        }
        if let t2 = p2.component(ofType: TransformComponent.self) {
            t2.position = CGPoint(x: 300, y: 0)
        }
        
        registerEntity(p1)
        registerEntity(p2)
        
        if let sprite1 = p1.component(ofType: SpriteComponent.self)?.node {
            addChild(sprite1)
        }
        if let sprite2 = p2.component(ofType: SpriteComponent.self)?.node {
            addChild(sprite2)
        }
        
        GameManager.shared.registerPlayers(p1, p2, scene: self)
        
        // 3. Setup UI and attach to Camera
        setupUI(cameraNode: cameraEntity.cameraNode)
        
        // 4. Start Game State Machine
        GameStateMachine.shared.start()
    }
    
    private func setupUI(cameraNode: SKCameraNode) {
        let hud = HUDNode(size: self.size)
        let powerBar = PowerBarNode()
        let turnHandoff = TurnHandoffOverlay(size: self.size)
        let skillSelection = SkillSelection(size: self.size)
        
        // Add all to camera so they stay on screen
        cameraNode.addChild(hud)
        cameraNode.addChild(powerBar)
        cameraNode.addChild(turnHandoff)
        cameraNode.addChild(skillSelection)
        
        // Bind UI nodes to the system
        UISystem.shared.setup(hud: hud, powerBar: powerBar, turnHandoff: turnHandoff, skillSelection: skillSelection)
    }
    
    override func update(_ currentTime: TimeInterval) {
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        let dt = currentTime - self.lastUpdateTime
        
        // Update state machine and systems
        GameStateMachine.shared.update(deltaTime: dt)
        TurnSystem.shared.update(deltaTime: dt)
        PhysicsSystem.shared.update(deltaTime: dt)
        HitDetectionSystem.shared.update(deltaTime: dt)
        CameraSystem.shared.update(deltaTime: dt)
        
        // Update entities
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }
        
        self.lastUpdateTime = currentTime
    }
    
    // MARK: - ECS Management
    
    func registerEntity(_ entity: GKEntity) {
        if !entities.contains(entity) {
            entities.append(entity)
        }
    }
    
    func removeEntity(_ entity: GKEntity) {
        if let index = entities.firstIndex(of: entity) {
            entities.remove(at: index)
        }
    }
}
