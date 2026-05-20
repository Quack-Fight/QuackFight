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
            
            // Langsung memuat MenuScene saat aplikasi pertama kali dibuka
            let menuScene = MenuScene(size: view.bounds.size)
            menuScene.scaleMode = .aspectFill
            
            view.presentScene(menuScene)
            view.ignoresSiblingOrder = true
            
            // Debug info bisa dinyalakan lagi selama development berjalan
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : .all
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
