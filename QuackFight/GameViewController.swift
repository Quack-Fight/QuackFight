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
            
            // Opsi 1: Jika kamu punya file visual "MenuScene.sks"
            if let menuScene = SKScene(fileNamed: "MenuScene") as? MenuScene {
                menuScene.scaleMode = .aspectFill
                view.presentScene(menuScene)
            }
            // Opsi 2: Jika MenuScene murni dari kode (tanpa .sks file)
            else {
                let fallbackMenu = MenuScene(size: view.bounds.size)
                fallbackMenu.scaleMode = .aspectFill
                view.presentScene(fallbackMenu)
            }
            
            // Konfigurasi performa view
            view.ignoresSiblingOrder = true
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
