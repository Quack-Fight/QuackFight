//
//  FixedHitResolveState.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import GameplayKit
import SpriteKit

// MARK: - Entry / Exit Feedback (#27)
//
// didEnter  → Phase 1: Active player plays 4-frame missile launch animation (0.8s).
//             Phase 2: Background dims, camera pans to opponent (0.8s).
//             Phase 3: Missile drops from top of screen, screen shakes on impact.
//             Phase 4: 11-frame explosion animation on opponent, damage applied.
// willExit  → Dim overlay removed. Camera returns. Sprites revert to base.

/// Applies the Fixed Hit skill via a multi-phase cinematic sequence.
///
/// ## Phases
/// 1. **Launch** — 4-frame missile launch animation on the active player (0.8s).
/// 2. **Pan** — Dim background + camera pans to opponent (0.8s).
/// 3. **Missile Drop** — FixedHitMissile sprite drops from above screen to opponent.
///    Screen shake on impact. Damage applied at this point.
/// 4. **Explosion** — 11-frame explosion on opponent body (1.1s).
///    Transition to TurnHandoffState (or GameOverState on KO).
final class FixedHitResolveState: GKState {

    // MARK: - Tokens

    private var turnEndedToken: SubscriptionToken?
    private var gameOverToken: SubscriptionToken?

    private var resolved = false

    /// The dim overlay node added during the cinematic.
    private var dimOverlay: SKSpriteNode?

    /// The missile sprite that drops onto the opponent.
    private var missileNode: SKSpriteNode?

    // MARK: - Valid Transitions

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == TurnHandoffState.self || stateClass == GameOverState.self
    }

    // MARK: - Entry

    override func didEnter(from previousState: GKState?) {
        resolved = false

        // Subscribe BEFORE the cinematic to guarantee no event is missed.
        turnEndedToken = EventBus.shared.subscribe(.turnEnded) { [weak self] _ in
            guard let self, !self.resolved else { return }
            self.resolved = true
            // Delay transition slightly to let explosion finish visually.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                GameStateMachine.shared.enter(TurnHandoffState.self)
            }
        }

        gameOverToken = EventBus.shared.subscribe(.gameOver) { [weak self] event in
            guard let self,
                  !self.resolved,
                  case .gameOver(let outcome) = event
            else { return }
            self.resolved = true
            GameManager.shared.lastOutcome = outcome
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                GameStateMachine.shared.enter(GameOverState.self)
            }
        }

        // Start the cinematic chain.
        phase1_launchAnimation()
    }

    // MARK: - Exit

    override func willExit(to nextState: GKState) {
        [turnEndedToken, gameOverToken]
            .compactMap { $0 }
            .forEach { EventBus.shared.unsubscribe($0) }
        turnEndedToken = nil
        gameOverToken = nil

        // Clean up cinematic nodes
        dimOverlay?.removeFromParent()
        dimOverlay = nil
        missileNode?.removeFromParent()
        missileNode = nil
    }

    // MARK: - Phase 1: Launch Animation

    /// Play 4-frame missile launch animation on the active player (0.8s total).
    private func phase1_launchAnimation() {
        // Phase 1 SFX:
        // - skill2Click = feedback saat skill Fixed Hit dipilih / tombol ditekan
        // - beep = lock-on / warning beep sebelum missile cinematic
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {

                AudioManager.shared.playSFX(.skill2ClickFix)

            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {

                AudioManager.shared.playSFX(.beepFix)

            }

        let activePlayer = GameManager.shared.activePlayer
        let playerIndex = GameManager.shared.activePlayerIndex

        guard let spriteComp = activePlayer.component(ofType: SpriteComponent.self) else {
            phase2_panToOpponent()
            return
        }

        let spriteNode = spriteComp.node
        let originalTexture = spriteNode.texture

        activePlayer.setHandVisible(false)

        let prefix = playerIndex == 0 ? "Goose_Missile" : "Duck_Missile"
        let textures = (1...4).map { SKTexture(imageNamed: "\(prefix)-\($0)") }

        let launchAnim = SKAction.animate(with: textures, timePerFrame: 0.2)
        let revert = SKAction.run {
            if let tex = originalTexture {
                spriteNode.texture = tex
            }
            activePlayer.setHandVisible(true)
        }

        spriteNode.run(SKAction.sequence([launchAnim, revert])) { [weak self] in
            self?.phase2_panToOpponent()
        }
    }

    // MARK: - Phase 2: Camera Pan + Dim

    /// Dim the background and pan the camera to the opponent.
    private func phase2_panToOpponent() {
        // Add dim overlay to the camera node so it covers the whole viewport.
        if let cameraNode = GameManager.shared.scene?.camera {
            let viewSize = GameManager.shared.scene?.size ?? CGSize(width: 400, height: 800)
            let dim = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.4), size: viewSize)
            dim.zPosition = 500  // Above game elements, below HUD (900+)
            dim.alpha = 0
            cameraNode.addChild(dim)
            dim.run(SKAction.fadeAlpha(to: 1.0, duration: 0.3))
            self.dimOverlay = dim
        }

        // Pan camera to opponent
        CameraSystem.shared.panToOpponent { [weak self] in
            self?.phase3_missileDrop()
        }
    }

    // MARK: - Phase 3: Missile Drop + Impact

    /// Spawn a missile above the opponent and animate it dropping down.
    /// Screen shake + damage on impact.
    private func phase3_missileDrop() {
        // Phase 3 SFX:
        // skill3Full already contains missile drop + explosion sound,
        // so it starts when the missile begins falling.
        AudioManager.shared.playSFX(.skill3Full)
        let opponent = GameManager.shared.opponentPlayer
        guard let opponentTransform = opponent.component(ofType: TransformComponent.self),
              let scene = GameManager.shared.scene else {
            FixedHitSystem.shared.applyFixedHit()
            return
        }

        let targetPos = opponentTransform.position

        // Create missile sprite with 2-frame loop animation.
        let missile = SKSpriteNode(imageNamed: "FixedHitMissile1")
        missile.size = CGSize(width: 80, height: 80)
        missile.zPosition = 50
        missile.position = CGPoint(x: targetPos.x, y: targetPos.y + 500)
        scene.addChild(missile)
        self.missileNode = missile

        // 2-frame loop on the missile while it falls.
        let frame1 = SKTexture(imageNamed: "FixedHitMissile1")
        let frame2 = SKTexture(imageNamed: "FixedHitMissile2")
        let loop = SKAction.repeatForever(
            SKAction.animate(with: [frame1, frame2], timePerFrame: 0.1)
        )
        missile.run(loop, withKey: "missileLoop")

        // Drop missile to the opponent position.
        let drop = SKAction.move(to: targetPos, duration: 0.5)
        drop.timingMode = .easeIn

        missile.run(drop) { [weak self] in
            // Impact!
            missile.removeAllActions()
            missile.removeFromParent()
            self?.missileNode = nil

            // Screen shake on impact.
            CameraSystem.shared.shakeCamera(intensity: 15, duration: 0.5)

            // Apply damage at the moment of impact.
            FixedHitSystem.shared.applyFixedHit()

            // Start explosion animation on the opponent.
            self?.phase4_explosion()
        }
    }

    // MARK: - Phase 4: Explosion on Opponent

    /// Play 11-frame explosion animation on the opponent's body sprite.
    private func phase4_explosion() {
        let opponent = GameManager.shared.opponentPlayer
        let opponentIndex = GameManager.shared.nextPlayerIndex

        guard let spriteComp = opponent.component(ofType: SpriteComponent.self) else {
            cleanupCinematic()
            return
        }

        let spriteNode = spriteComp.node
        let originalTexture = spriteNode.texture

        // Hide the opponent's hand during the explosion animation.
        opponent.setHandVisible(false)

        // Build 11-frame explosion textures.
        // The explosion assets use the OPPONENT's prefix (Duck_Meledak when Duck is hit).
        let prefix = opponentIndex == 0 ? "Goose_Meledak" : "Duck_Meledak"
        let textures = (1...11).map { SKTexture(imageNamed: "\(prefix)-\($0)") }

        let explosionAnim = SKAction.animate(with: textures, timePerFrame: 0.1)
        let revert = SKAction.run { [weak self] in
            if let tex = originalTexture {
                spriteNode.texture = tex
            }
            opponent.setHandVisible(true)
            self?.cleanupCinematic()
        }

        spriteNode.run(SKAction.sequence([explosionAnim, revert]))
    }

    // MARK: - Cleanup

    /// Remove the dim overlay and restore normal camera state.
    private func cleanupCinematic() {
        // Fade out dim overlay
        if let dim = dimOverlay {
            dim.run(SKAction.sequence([
                SKAction.fadeAlpha(to: 0, duration: 0.3),
                SKAction.removeFromParent()
            ]))
            dimOverlay = nil
        }

        // Return camera to the next active player
        CameraSystem.shared.returnToPlayer(index: GameManager.shared.activePlayerIndex)
    }
}
