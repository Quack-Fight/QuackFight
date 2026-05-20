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

    // MARK: - State

    /// Progress waktu untuk preview pan.
    private var panProgress: TimeInterval = 0.0



    // MARK: - Public Camera Controls

    /// Start the Round 1 preview pan: snap camera to Player 2's position,
    /// then let `update(deltaTime:)` lerp it across to Player 1.
    /// Called by `PreviewPanState.didEnter`.
    func startPreviewPan() {
        guard let cameraComp = currentCameraComponent() else { return }
        // Snap to P2 so the pan begins from the correct side.
        cameraComp.node.position = playerCameraTarget(index: 1)
        cameraComp.state = .previewPan
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
}
