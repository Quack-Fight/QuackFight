//
//  UISystem.swift
//  QuackFight
//

import SpriteKit
import GameplayKit

/// Coordinates UI updates by subscribing to the EventBus.
/// Holds references to the visual SKNode overlays and passes data to them.
final class UISystem {
    
    static let shared = UISystem()
    
    private var hudNode: HUDNode?
    private var powerBar: PowerBarNode?
    private var turnHandoff: TurnHandoffOverlay?
    private var skillSelection: SkillSelection?
    private var viewportSize: CGSize = .zero
    
    private init() {}
    
    /// Binds the system to the scene's UI nodes.
    func setup(hud: HUDNode, powerBar: PowerBarNode, turnHandoff: TurnHandoffOverlay, skillSelection: SkillSelection, viewportSize: CGSize) {
        self.hudNode = hud
        self.powerBar = powerBar
        self.turnHandoff = turnHandoff
        self.skillSelection = skillSelection
        self.viewportSize = viewportSize
        
        setupSubscriptions()
    }
    
    func setupSubscriptions() {
        EventBus.shared.subscribe(.hpChanged) { [weak self] event in
            guard let self, case .hpChanged(let playerIndex, let hp) = event else { return }
            self.hudNode?.updateHP(playerIndex: playerIndex, current: hp, max: GameConstants.maxHP)
        }
        
        EventBus.shared.subscribe(.timerTick) { [weak self] event in
            guard let self, case .timerTick(let remaining) = event else { return }
            let maxTime: TimeInterval = 5.0 // Aim/Power time limit
            self.hudNode?.updateTimer(percentage: CGFloat(remaining / maxTime))
            self.hudNode?.updateCountdown(remaining: remaining)
        }
        
        EventBus.shared.subscribe(.damageApplied) { [weak self] event in
            guard let self, case .damageApplied(let amount, let target) = event else { return }
            self.hudNode?.showDamagePopup(playerIndex: target, amount: amount)
        }
        
        EventBus.shared.subscribe(.amplitudeUpdated) { [weak self] event in
            guard let self, case .amplitudeUpdated(let amplitude) = event else { return }
            self.powerBar?.updateFill(CGFloat(amplitude))
        }
        
        EventBus.shared.subscribe(.roundCountUpdated) { [weak self] event in
            guard let self, case .roundCountUpdated(let turn, _) = event else { return }
            self.hudNode?.updateRoundCounter(round: turn)
        }
        
        EventBus.shared.subscribe(.showTurnHandoff) { [weak self] event in
            guard let self, case .showTurnHandoff(let nextPlayer) = event else { return }
            self.hudNode?.showActivePlayerGlow(playerIndex: nextPlayer)
            self.turnHandoff?.show(forPlayer: nextPlayer)
            
            // Hide after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.turnHandoff?.hide()
            }
        }
        
        EventBus.shared.subscribe(.showInstruction) { [weak self] event in
            guard let self, case .showInstruction(let text) = event else { return }
            self.turnHandoff?.showInstruction(text)
            
            // Show power bar only if instruction is Shout!
            if text == "Shout!" {
                self.powerBar?.positionForActivePlayer(GameManager.shared.activePlayerIndex, viewportSize: self.viewportSize)
                self.powerBar?.show()
            } else {
                self.powerBar?.hide()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.turnHandoff?.hide()
            }
        }
        
        EventBus.shared.subscribe(.throwStarted) { [weak self] _ in
            guard let self else { return }
            self.powerBar?.hide()
        }
        
        EventBus.shared.subscribe(.showSkillSelection) { [weak self] _ in
            guard let self else { return }
            let activePlayer = GameManager.shared.activePlayerIndex
            let player = GameManager.shared.player(index: activePlayer)
            
            if let skillComp = player.component(ofType: SkillComponent.self) {
                self.skillSelection?.show(forPlayer: activePlayer, availableSkills: skillComp.availableSkills)
            }
        }
        
        EventBus.shared.subscribe(.skillUsed) { _ in
            // Let the HUD trigger any specific animations if needed.
        }

        EventBus.shared.subscribe(.gameOver) { [weak self] event in
            guard let self, case .gameOver(let outcome) = event else { return }
            let message = Self.outcomeMessage(outcome)
            self.turnHandoff?.showInstruction(message)
        }
    }

    private static func outcomeMessage(_ outcome: GameOutcome) -> String {
        switch outcome {
        case .knockout(let winner):     return "Player \(winner + 1) Wins!\nTap to Rematch"
        case .roundCapWin(let winner):  return "Player \(winner + 1) Wins!\nTap to Rematch"
        case .draw:                      return "Draw!\nTap to Rematch"
        }
    }
}
