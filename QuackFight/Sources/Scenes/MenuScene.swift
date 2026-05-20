//
//  MenuScene.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import Foundation
import SpriteKit
import GameplayKit

//  =========================================================================
//  GDD §8.1 SCREEN INVENTORY & SCENE FLOW MAP
//  =========================================================================
//  - Screen Identity: Main Menu Screen (MenuScene)
//  - Current Flow: [MenuScene] ➔ (On Start Tap) ➔ [GameScene]
//
//  - Screen Inventory:
//    1. Game Title Label / Logo
//    2. "Start Game" Interactive Button
//    3. Background Decorative Elements (Water/Ducks)
//  =========================================================================

class MenuScene: SKScene {
    
    private var localButton: SKSpriteNode!
    private var onlineButton: SKSpriteNode!
    private var titleNode: SKSpriteNode!
    private var isStartingGame = false
    
    //    private let systemRoundedFont = ".SFProRounded-Bold"
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "BackgroundMenu")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = -1
        background.size = self.size
        
        addChild(background)
        setupTitle()
        setupLocalButton()
        setupOnlineButton()
        
    }
    
    // MARK: - Setup UI Elements
    
    private func setupTitle() {
        titleNode = SKSpriteNode(imageNamed: "LogoOutline")
        
        titleNode.setScale(0.06)
        titleNode.position = CGPoint(x: size.width / 2, y: size.height * 0.7)
        titleNode.zPosition = 1
        
        addChild(titleNode)
        
    }
    
    private func setupLocalButton() {
        localButton = SKSpriteNode(imageNamed: "Button")
        localButton.position = CGPoint(x: size.width / 2, y: titleNode.position.y - titleNode.size.height * 1.2)
        localButton.zPosition = 1
        localButton.name = "localButton"
        localButton.setScale(0.28)
        
        let buttonText = SKLabelNode()
        buttonText.attributedText = createRoundedText("Play Local", fontSize: 92, color: .white)
        buttonText.verticalAlignmentMode = .center
        buttonText.horizontalAlignmentMode = .center
        buttonText.zPosition = 2
        
        localButton.addChild(buttonText)
        addChild(localButton)
    }
    
    private func setupOnlineButton() {
        onlineButton = SKSpriteNode(imageNamed: "Button")
        onlineButton.position = CGPoint(x: size.width / 2, y: localButton.position.y - localButton.size.height * 1.2)
        onlineButton.zPosition = 1
        onlineButton.name = "onlineButton"
        onlineButton.alpha = 0.5
        onlineButton.setScale(0.28)
        
        
        let buttonText = SKLabelNode()
        buttonText.attributedText = createRoundedText("Play Online", fontSize: 92, color: .white)
        buttonText.verticalAlignmentMode = .center
        buttonText.horizontalAlignmentMode = .center
        buttonText.zPosition = 2
        
        onlineButton.addChild(buttonText)
        addChild(onlineButton)
    }
    
    //MARK: Create Rounded Text
    ///function untuk membuat font SF Pro Rounded - Bold
    func createRoundedText(_ text: String, fontSize: CGFloat, color: UIColor) -> NSAttributedString {
        let systemFont = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        let roundedDescriptor = systemFont.fontDescriptor.withDesign(.rounded) ?? systemFont.fontDescriptor
        let roundedFont = UIFont(descriptor: roundedDescriptor, size: fontSize)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: roundedFont,
            .foregroundColor: color
        ]
        
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNode = atPoint(location)
        
        // Memeriksa apakah area tombol atau area teks di dalam tombol yang ditekan
        if tappedNode.name == "localButton" || tappedNode.parent?.name == "localButton" {
            handleStartButtonTap()
        }
    }
    
    private func handleStartButtonTap() {
        // Play button click SFX langsung dari MenuScene
        // karena GameManager.shared.scene belum tentu ada saat masih di menu.
        run(SKAction.playSoundFileNamed("buttonClick.wav", waitForCompletion: false))

        // Memberikan umpan balik visual (juiciness): tombol sedikit mengecil lalu membesar
        let scaleDown = SKAction.scale(to: 0.20, duration: 0.08)
        let scaleUp = SKAction.scale(to: 0.28, duration: 0.08)
        
        // Eksekusi transisi scene tepat setelah animasi klik selesai berjalan
        let transitionAction = SKAction.run { [weak self] in
            self?.navigateToGameScene()
        }
        
        localButton.run(SKAction.sequence([scaleDown, scaleUp, transitionAction]))
    }
    
    private func navigateToGameScene() {
        // Menyiapkan GameScene arena pertempuran bebek
        let gameScene = GameScene(size: self.size)
        gameScene.scaleMode = self.scaleMode
        
        // Transisi memudar halus berdurasi 0.6 detik sesuai spesifikasi kontrak preview
        let fadeTransition = SKTransition.fade(withDuration: 0.6)
        
        self.view?.presentScene(gameScene, transition: fadeTransition)
    }
    
    
}
