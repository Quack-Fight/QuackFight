//
//  HitDetectionSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import GameplayKit
import CoreGraphics

/// # HitDetectionSystem
///
/// Beginner-friendly:
///
/// `HitDetectionSystem` bertugas mengecek apakah projectile kena lawan.
///
/// Sistem ini TIDAK menggerakkan projectile.
/// Gerakan projectile sudah dilakukan oleh `PhysicsSystem`.
///
/// Sistem ini juga TIDAK memberi damage.
/// Kalau projectile kena, sistem ini hanya mengumumkan:
///
///     EventBus.shared.post(.throwResolved(hit: true))
///
/// Setelah event itu dipost:
/// - `DamageSystem` akan mengurangi HP lawan.
/// - `WinCheckSystem` akan mengecek apakah game selesai.
/// - `UISystem` / `AudioManager` bisa menampilkan feedback.
///
/// Update order penting:
/// `HitDetectionSystem` harus jalan SETELAH `PhysicsSystem`.
/// Alasannya: posisi projectile harus diperbarui dulu, baru dicek collision.
final class HitDetectionSystem {

    // MARK: - Singleton

    static let shared = HitDetectionSystem()

    private init() {}

    // MARK: - Update

    /// Dipanggil setiap frame oleh `GameScene.update(_:)`.
    func update(deltaTime seconds: TimeInterval) {
        guard ThrowSystem.shared.isInFlight else {
            return
        }

        guard let bread = ThrowSystem.shared.activeBread else {
            return
        }

        guard let breadTransform = bread.component(ofType: TransformComponent.self) else {
            print("Warning: Active projectile is missing TransformComponent.")
            return
        }

        let opponent = GameManager.shared.opponentPlayer
        let breadPosition = breadTransform.position
        let opponentPosition = opponentHitboxCenter(opponent)

        let distance = distanceBetween(breadPosition, opponentPosition)
        let hitDistance = combinedHitDistance(projectile: bread, opponent: opponent)

        if distance <= hitDistance {
            resolveHit()
        }
    }

    // MARK: - Position Helpers

    /// Mengambil titik tengah hitbox lawan.
    ///
    /// Kalau PlayerEntity sudah punya TransformComponent, pakai itu.
    /// Kalau belum, fallback ke `throwOrigin`.
    private func opponentHitboxCenter(_ opponent: PlayerEntity) -> CGPoint {
        if let transform = opponent.component(ofType: TransformComponent.self) {
            return transform.position
        }

        return opponent.throwOrigin
    }

    /// Menghitung jarak antara dua titik.
    private func distanceBetween(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return hypot(dx, dy)
    }

    // MARK: - Hitbox Helpers

    /// Menghitung total jarak collision.
    ///
    /// Projectile dan opponent dianggap sebagai dua lingkaran.
    /// Kalau jarak antar pusat lingkaran <= jumlah radius,
    /// berarti mereka bersentuhan.
    private func combinedHitDistance(
        projectile: ProjectileEntity,
        opponent: PlayerEntity
    ) -> CGFloat {
        let projectileRadius =
            projectile.component(ofType: HitboxComponent.self)?.radius
            ?? GameConstants.defaultHitBoxRadius

        let opponentRadius =
            opponent.component(ofType: HitboxComponent.self)?.radius
            ?? GameConstants.defaultHitBoxRadius

        return projectileRadius + opponentRadius
    }

    // MARK: - Hit Resolution

    /// Menyelesaikan throw sebagai hit.
    ///
    /// Tidak memberi damage langsung.
    /// DamageSystem yang akan merespons event `.throwResolved(hit: true)`.
    private func resolveHit() {
        ThrowSystem.shared.isInFlight = false
        EventBus.shared.post(.throwResolved(hit: true))
    }
}
