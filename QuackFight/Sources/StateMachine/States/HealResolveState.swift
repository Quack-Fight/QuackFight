import GameplayKit
import SpriteKit

// MARK: - Entry / Exit Feedback (#27)
//
// didEnter  → Active player plays 7-frame heal animation (1.4s).
//             HP is restored at frame 4 (~0.6s) with green HP bar pulse.
//             After animation completes, sprite reverts to base texture.
// willExit  → HP bar settles at the new value. No further visual changes.

/// Applies the Heal skill: plays the heal animation, restores HP mid-animation,
/// then transitions to TurnHandoffState.
///
/// Animation timing (per user spec):
/// - 7 frames × 0.2s = 1.4s total
/// - HP restore triggers at frame 4 (~0.6s into the animation)
final class HealResolveState: GKState {

    // MARK: - Tokens

    private var healToken: SubscriptionToken?

    // MARK: - Valid Transitions

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == TurnHandoffState.self
    }

    // MARK: - Entry

    override func didEnter(from previousState: GKState?) {
        // Subscribe before animation to guarantee no event is missed.
        healToken = EventBus.shared.subscribe(.healApplied) { [weak self] _ in
            guard self != nil else { return }
            // Don't transition yet — wait for the animation to finish.
        }

        let activePlayer = GameManager.shared.activePlayer
        let playerIndex = GameManager.shared.activePlayerIndex

        guard let spriteComp = activePlayer.component(ofType: SpriteComponent.self) else {
            // Fallback: no sprite, just apply heal immediately.
            HealSystem.shared.applyHeal()
            GameStateMachine.shared.enter(TurnHandoffState.self)
            return
        }

        let spriteNode = spriteComp.node
        let originalTexture = spriteNode.texture

        // Hide the hand during the heal animation — the body texture changes
        // to animation frames and the hand would look out of place.
        activePlayer.setHandVisible(false)

        // Build the 7-frame heal animation textures.
        let prefix = playerIndex == 0 ? "Goose_Heal" : "Duck_Heal"
        let textures = (1...7).map { SKTexture(imageNamed: "\(prefix)-\($0)") }

        // Frames 1–3 (pre-heal visual build-up)
        let preHealFrames = Array(textures[0..<3])
        let preHealAnim = SKAction.animate(with: preHealFrames, timePerFrame: 0.2)

        // Frame 4: the moment HP is restored (via run block)
        let frame4Texture = textures[3]
        let showFrame4 = SKAction.setTexture(frame4Texture)
        let applyHeal = SKAction.run {
            HealSystem.shared.applyHeal()
        }
        let waitFrame4 = SKAction.wait(forDuration: 0.2)

        // Frames 5–7 (post-heal wind-down)
        let postHealFrames = Array(textures[4..<7])
        let postHealAnim = SKAction.animate(with: postHealFrames, timePerFrame: 0.2)

        // Revert to original base texture and restore hand
        let revert = SKAction.run {
            if let tex = originalTexture {
                spriteNode.texture = tex
            }
            activePlayer.setHandVisible(true)
        }

        // Chain the full sequence
        let sequence = SKAction.sequence([
            preHealAnim,        // Frames 1-3 (0.6s)
            showFrame4,         // Frame 4 texture
            applyHeal,          // Apply HP at frame 4
            waitFrame4,         // Hold frame 4 (0.2s)
            postHealAnim,       // Frames 5-7 (0.6s)
            revert              // Back to base sprite
        ])

        spriteNode.run(sequence) { [weak self] in
            guard self != nil else { return }
            GameStateMachine.shared.enter(TurnHandoffState.self)
        }
    }

    // MARK: - Exit

    override func willExit(to nextState: GKState) {
        if let token = healToken {
            EventBus.shared.unsubscribe(token)
        }
        healToken = nil
    }
}
