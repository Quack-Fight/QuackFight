//
//  GameOverOverlay.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import SpriteKit

class GameOverScene: SKSpriteNode {
    
    // MARK: - Properties
    private let outcome: GameOutcome

    private var rematchButton: SKSpriteNode!
    private var menuButton: SKSpriteNode!
    private var subtitleLabel: SKLabelNode
    
    // Closure (Callback) untuk memberi tahu UISystem saat tombol diklik
    var onRematchTapped: (() -> Void)?
    var onMenuTapped: (() -> Void)?
    
    // MARK: - Initialization
    
    init(size: CGSize, outcome: GameOutcome) {
        self.outcome = outcome
        self.subtitleLabel = SKLabelNode()
        
        super.init(texture: nil, color: SKColor(white: 0.1, alpha: 0.8), size: size)
        
        // HUKUM WAJIB UNTUK OVERLAY NODE: Aktifkan interaksi sentuhan
        self.isUserInteractionEnabled = true
        self.zPosition = 100
        
        setupPopupBoard()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI Elements
    
    private func setupPopupBoard() {
        var titleText = ""
        var subtitleText = ""
        var titleColor = UIColor.white
        
        switch outcome {
        case .knockout(let winner):
            let characterName = winner == 0 ? "GOOSE" : "DUCK"
            titleText = "\(characterName)"
            subtitleText = "By Knockout (K.O.)"
            titleColor = winner == 0 ? .yellowQuack : .systemRed
            
        case .roundCapWin(let winner):
            let characterName = winner == 0 ? "GOOSE" : "DUCK"
            titleText = "\(characterName)"
            subtitleText = "Round Cap Reached"
            titleColor = winner == 0 ? .yellowQuack : .systemRed
            
        case .draw:
            titleText = "DRAW!"
            subtitleText = "Equal HP Remaining"
            titleColor = .lightGray
        }
        
        // Karena titik tengah node ini ada di (0,0), bukan (width/2, height/2),
        let trophy = SKSpriteNode(imageNamed: "Trophy")
        trophy.setScale(0.1)
        trophy.position = CGPoint(x: 0, y: size.height * 0.18)
        trophy.zPosition = 2
        addChild(trophy)
        
        let winnerLabel = SKLabelNode()
        winnerLabel.attributedText = createRoundedText("Winner", fontSize: 20, color: .white)
        winnerLabel.position = CGPoint(x: 0, y: trophy.position.y - trophy.size.height)
        winnerLabel.zPosition = 2
        addChild(winnerLabel)
        
        let titleLabel = SKLabelNode()
        titleLabel.attributedText = createRoundedText(titleText, fontSize: 40, color: titleColor)
        titleLabel.position = CGPoint(x: 0, y: winnerLabel.position.y - 40)
        titleLabel.zPosition = 2
        addChild(titleLabel)
        
        subtitleLabel = SKLabelNode()
        subtitleLabel.attributedText = createRoundedText(subtitleText, fontSize: 18, color: .lightGray)
        subtitleLabel.position = CGPoint(x: 0, y: titleLabel.position.y - 40)
        subtitleLabel.zPosition = 2
        addChild(subtitleLabel)
        
        setupButtons()
    }
    
    private func setupButtons() {
        rematchButton = SKSpriteNode(imageNamed: "Button")
        rematchButton.setScale(0.28)
        rematchButton.position = CGPoint(x: 0, y: subtitleLabel.position.y - subtitleLabel.frame.height - 40)
        rematchButton.name = "rematchButton"
        rematchButton.zPosition = 2
        
        let rematchText = SKLabelNode()
        rematchText.attributedText = createRoundedText("Rematch", fontSize: 92, color: .white)
        rematchText.verticalAlignmentMode = .center
        rematchText.zPosition = 3
        rematchButton.addChild(rematchText)
        addChild(rematchButton)
        
        menuButton = SKSpriteNode(imageNamed: "Button")
        menuButton.setScale(0.23)
        menuButton.position = CGPoint(x: 0, y: rematchButton.position.y - rematchButton.size.height * 1.2)
        menuButton.name = "menuButton"
        menuButton.zPosition = 2
        
        let menuText = SKLabelNode()
        menuText.attributedText = createRoundedText("Main Menu", fontSize: 88, color: .white)
        menuText.verticalAlignmentMode = .center
        menuText.zPosition = 3
        menuButton.addChild(menuText)
        addChild(menuButton)
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNode = atPoint(location)
        
        if tappedNode.name == "rematchButton" || tappedNode.parent?.name == "rematchButton" {
            handleButtonTap(node: rematchButton) { [weak self] in
                self?.onRematchTapped?()
            }
        } else if tappedNode.name == "menuButton" || tappedNode.parent?.name == "menuButton" {
            handleButtonTap(node: menuButton) { [weak self] in
                self?.onMenuTapped?()
            }
        }
    }
    
    private func handleButtonTap(node: SKNode, completion: @escaping () -> Void) {
        let scaleDown = SKAction.scale(by: 0.9, duration: 0.08)
        let scaleUp = SKAction.scale(by: 1.11, duration: 0.08)
        let action = SKAction.run(completion)
        node.run(SKAction.sequence([scaleDown, scaleUp, action]))
    }
    
    // MARK: - Helpers
    
    private func createRoundedText(_ text: String, fontSize: CGFloat, color: UIColor) -> NSAttributedString {
        let systemFont = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        let roundedDescriptor = systemFont.fontDescriptor.withDesign(.rounded) ?? systemFont.fontDescriptor
        let roundedFont = UIFont(descriptor: roundedDescriptor, size: fontSize)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: roundedFont,
            .foregroundColor: color
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    // MARK: - Scene Transitions

        /// Initial load fade duration (Menu -> Game).
        static let fadeDurationInitial: TimeInterval = 0.6

        /// Faster fade duration for Rematch to keep players in the action.
        static let fadeDurationRematch: TimeInterval = 0.5
}
