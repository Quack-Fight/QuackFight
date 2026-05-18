//
//  GameViewController.swift
//  QuackFight
//
//  Created by Nathan Sudiara on 07/05/26.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as? SKView {
            // Attempt to load 'GameScene.sks' as a GKScene
            if let scene = GKScene(fileNamed: "GameScene"), let sceneNode = scene.rootNode as? GameScene {
                // Copy gameplay relatedx content over to the scene
                sceneNode.entities = scene.entities
                sceneNode.graphs = scene.graphs
                sceneNode.scaleMode = .aspectFill
                
                view.presentScene(sceneNode)
                view.ignoresSiblingOrder = true
                view.showsFPS = true
                view.showsNodeCount = true
            } else {
                // Fallback if GameScene.sks is missing or its Custom Class isn't set
                let fallbackScene = GameScene(size: view.bounds.size)
                fallbackScene.scaleMode = .aspectFill
                view.presentScene(fallbackScene)
                view.ignoresSiblingOrder = true
                view.showsFPS = true
                view.showsNodeCount = true
            }
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
