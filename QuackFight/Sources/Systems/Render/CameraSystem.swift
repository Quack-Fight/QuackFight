//
//  CameraSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import Foundation
import GameplayKit
import CoreGraphics
import SpriteKit

/// System that handles all cinematic camera movements (pan, follow, return) and static views.
///
/// Beginner-friendly:
///
/// CameraSystem adalah sistem yang menggerakkan camera.
///
/// Dia tidak membuat projectile.
/// Dia tidak memberi damage.
/// Dia hanya membaca `CameraComponent.state`, lalu menggerakkan `SKCameraNode`.
///
/// Contoh:
/// - `.staticOnPlayer(index:)`
///   Camera diam di posisi player.
///
/// - `.previewPan`
///   Camera pan dari Player 2 ke Player 1.
///
/// - `.followBread`
///   Camera mengikuti projectile yang sedang terbang.
///
/// - `.returnToPlayer(index:)`
///   Camera balik lagi ke player setelah throw selesai.
final class CameraSystem {
    static let shared = CameraSystem()
    private init() {}

    // MARK: - Feel Constants (#90)

    /// Nilai kecil = camera lebih lambat mengikuti target.
    /// Nilai besar = camera lebih cepat mengikuti target.
    private let cameraFollowLerp: CGFloat = 0.12

    /// Lerp factor for following the active player (smooth tracking for knockback).
    private let cameraPlayerLerp: CGFloat = 0.15

    /// Return dibuat lebih pelan agar terasa cinematic.
    private let cameraReturnLerp: CGFloat = 0.08

    /// Durasi preview pan dari P2 ke P1.
    private let previewPanDuration: TimeInterval = 2.5

    /// Duration of the pause at the enemy position before panning back.
    private let previewPauseDuration: TimeInterval = 1.0

    // MARK: - State

    /// Progress waktu untuk preview pan.
    private var panProgress: TimeInterval = 0.0

    /// Countdown timer for the pause-at-player state.
    private var pauseTimer: TimeInterval = 0.0



    // MARK: - Public Camera Controls

    /// Start the Round 1 preview pan: snap camera to Player 2's position,
    /// then let `update(deltaTime:)` lerp it across to Player 1.
    /// Called by `PreviewPanState.didEnter`.
    func startPreviewPan() {
        guard let cameraComp = currentCameraComponent() else { return }
        // Snap to P2 so the preview begins from the opponent's side.
        cameraComp.node.position = playerCameraTarget(index: 1)
        // Pause at P2 for 1 second before panning back to P1.
        pauseTimer = previewPauseDuration
        cameraComp.state = .pauseAtPlayer(index: 1)
    }

    /// Mengubah camera ke mode mengikuti projectile.
    ///
    /// Function ini tidak langsung menggerakkan camera.
    /// Dia hanya mengubah state.
    ///
    /// Gerakan camera tetap dilakukan di `update(deltaTime:)`.
    func followBread() {
        guard let cameraComp = currentCameraComponent() else {
            print("Warning: CameraComponent not found. Cannot follow bread.")
            return
        }

        cameraComp.state = .followBread
    }

    /// Mengubah camera supaya kembali ke player tertentu.
    ///
    /// Biasanya dipanggil setelah throw selesai.
    func returnToPlayer(index: Int) {
        guard let cameraComp = currentCameraComponent() else {
            print("Warning: CameraComponent not found. Cannot return to player.")
            return
        }

        cameraComp.state = .returnToPlayer(index: index)
    }

    // MARK: - Update

    func update(deltaTime: TimeInterval) {
        guard let cameraComp = currentCameraComponent() else {
            return
        }

        let cameraNode = cameraComp.node

        switch cameraComp.state {
        case .staticOnPlayer(let index):
            // Smooth-follow the player's live position (supports knockback).
            let target = playerCameraTarget(index: index)
            cameraNode.position = clampedCameraPosition(CGPoint.lerp(
                from: cameraNode.position,
                to: target,
                t: cameraPlayerLerp
            ))

        case .pauseAtPlayer(let index):
            // Hold the camera still on this player, counting down.
            let target = playerCameraTarget(index: index)
            cameraNode.position = clampedCameraPosition(target)
            pauseTimer -= deltaTime
            if pauseTimer <= 0 {
                // Pause complete — begin the pan to P1.
                cameraComp.state = .previewPan
                panProgress = 0.0
            }

        case .previewPan:
            let p1Target = playerCameraTarget(index: 0)
            let p2Target = playerCameraTarget(index: 1)

            panProgress += deltaTime
            let t = min(CGFloat(panProgress / previewPanDuration), 1.0)

            cameraNode.position = clampedCameraPosition(CGPoint.lerp(
                from: p2Target,
                to: p1Target,
                t: t
            ))

            if t >= 1.0 {
                cameraComp.state = .staticOnPlayer(index: 0)
                panProgress = 0.0
                EventBus.shared.post(.previewPanComplete)
            }

        case .followBread:
            guard let activeBread = ThrowSystem.shared.activeBread,
                  let targetPos = activeBread.component(ofType: TransformComponent.self)?.position else {
                return
            }

            cameraNode.position = clampedCameraPosition(CGPoint.lerp(
                from: cameraNode.position,
                to: targetPos,
                t: cameraFollowLerp
            ))

        case .returnToPlayer(let index):
            let targetPos = playerCameraTarget(index: index)

            cameraNode.position = clampedCameraPosition(CGPoint.lerp(
                from: cameraNode.position,
                to: targetPos,
                t: cameraReturnLerp
            ))

            if cameraNode.position.distance(to: targetPos) < 4.0 {
                cameraNode.position = clampedCameraPosition(targetPos)
                cameraComp.state = .staticOnPlayer(index: index)
                EventBus.shared.post(.cameraReturnComplete)
            }
        }
    }

    // MARK: - Helpers

    /// Mengambil CameraComponent aktif dari scene.
    ///
    /// Dibuat helper supaya kode tidak mengulang guard panjang berkali-kali.
    private func currentCameraComponent() -> CameraComponent? {
        guard let scene = GameManager.shared.scene,
              let cameraEntity = scene.entities.first(where: { $0 is CameraEntity }) as? CameraEntity,
              let cameraComp = cameraEntity.component(ofType: CameraComponent.self) else {
            return nil
        }

        return cameraComp
    }

    /// Compute the camera target for a given player.
    /// Reads live position from TransformComponent (supports knockback)
    /// and applies the configurable Y offset for camera height tuning.
    private func playerCameraTarget(index: Int) -> CGPoint {
        let player = GameManager.shared.player(index: index)
        let pos = player.component(ofType: TransformComponent.self)?.position
            ?? player.throwOrigin
        return CGPoint(
            x: pos.x,
            y: pos.y + GameConstants.cameraPlayerYOffset
        )
    }

    private func clampedCameraPosition(_ target: CGPoint) -> CGPoint {
        guard let scene = GameManager.shared.scene else { return target }

        let halfW = scene.size.width / 2.0
        let halfH = scene.size.height / 2.0

        // X clamp: keep viewport within world bounds
        let leftX = halfW
        let rightX = max(leftX, scene.playableWorldWidth - halfW)
        let x = min(max(target.x, leftX), rightX)

        // Y clamp: keep viewport within background top edge only.
        // Bottom is unclamped so the camera can look below the background
        // to frame players above the large bottom HUD overlay.
        let topY = max(halfH, scene.playableWorldHeight - halfH)
        let y = min(target.y, topY)

        return CGPoint(x: x, y: y)
    }

    // MARK: - Cinematic Effects

    /// Smooth pan the camera to the opponent player's position.
    /// Used by FixedHitResolveState for the cinematic missile sequence.
    func panToOpponent(completion: @escaping () -> Void) {
        let opponentIndex = GameManager.shared.nextPlayerIndex
        let target = playerCameraTarget(index: opponentIndex)

        guard let cameraComp = currentCameraComponent() else {
            completion()
            return
        }

        let move = SKAction.move(to: target, duration: 0.8)
        move.timingMode = .easeInEaseOut
        cameraComp.node.run(move) {
            cameraComp.state = .staticOnPlayer(index: opponentIndex)
            completion()
        }
    }

    /// Shake the camera to create an impact effect.
    /// Intensity = max offset in points, duration = total shake time.
    func shakeCamera(intensity: CGFloat = 12, duration: TimeInterval = 0.4) {
        guard let cameraComp = currentCameraComponent() else { return }
        let node = cameraComp.node
        let originalPos = node.position

        let shakeCount = 6
        let interval = duration / Double(shakeCount)
        var actions: [SKAction] = []

        for i in 0..<shakeCount {
            // Decay intensity over time
            let decay = CGFloat(1.0 - Double(i) / Double(shakeCount))
            let offsetX = CGFloat.random(in: -intensity...intensity) * decay
            let offsetY = CGFloat.random(in: -intensity...intensity) * decay
            let shakePoint = CGPoint(x: originalPos.x + offsetX, y: originalPos.y + offsetY)
            actions.append(SKAction.move(to: shakePoint, duration: interval))
        }

        // Snap back to original position
        actions.append(SKAction.move(to: originalPos, duration: interval / 2))

        node.run(SKAction.sequence(actions))
    }
}
