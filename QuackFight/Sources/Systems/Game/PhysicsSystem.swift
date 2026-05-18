//
//  PhysicsSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import GameplayKit
import CoreGraphics

/// # PhysicsSystem
///
/// Beginner-friendly:
///
/// `PhysicsSystem` bertugas menggerakkan projectile secara matematis.
///
/// Kalau `ThrowSystem` adalah bagian yang "melempar" projectile pertama kali,
/// maka `PhysicsSystem` adalah bagian yang membuat projectile terus bergerak
/// setiap frame.
///
/// Tugas utama:
/// 1. Ambil projectile aktif dari `ThrowSystem.shared.activeBread`.
/// 2. Ambil posisi projectile dari `TransformComponent`.
/// 3. Ambil kecepatan projectile dari `VelocityComponent`.
/// 4. Kurangi velocity Y dengan gravity.
/// 5. Update posisi berdasarkan velocity.
/// 6. Kalau projectile keluar arena, anggap miss.
///
/// Yang TIDAK dilakukan PhysicsSystem:
/// - Tidak mengecek hit ke player. Itu tugas `HitDetectionSystem`.
/// - Tidak memberi damage. Itu tugas `DamageSystem`.
/// - Tidak update `sprite.node.position`. Itu tugas `RenderSystem`.
///
/// Update Order constraint (#60):
/// `PhysicsSystem` harus jalan sebelum `HitDetectionSystem`.
/// Alasannya: posisi projectile harus diperbarui dulu, baru dicek apakah kena lawan.
final class PhysicsSystem: GKComponentSystem<TransformComponent> {

    // MARK: - Singleton

    static let shared = PhysicsSystem()

    private init() {
        super.init(componentClass: TransformComponent.self)
    }

    // MARK: - Update

    /// Dipanggil setiap frame oleh `GameScene.update(_:)`.
    ///
    /// `seconds` adalah delta time, yaitu waktu sejak frame sebelumnya.
    override func update(deltaTime seconds: TimeInterval) {
        guard ThrowSystem.shared.isInFlight else {
            return
        }

        guard let bread = ThrowSystem.shared.activeBread else {
            return
        }

        guard let transform = bread.component(ofType: TransformComponent.self) else {
            print("Warning: Active projectile is missing TransformComponent.")
            return
        }

        guard let velocityComp = bread.component(ofType: VelocityComponent.self) else {
            print("Warning: Active projectile is missing VelocityComponent.")
            return
        }

        let dt = CGFloat(seconds)

        // 1. Apply gravity.
        //
        // Gravity mengurangi velocity arah Y.
        // Awalnya projectile naik karena dy positif.
        // Lama-lama dy turun, menjadi negatif, lalu projectile jatuh.
        velocityComp.vector.dy -= GameConstants.gravity * dt

        // 2. Advance position.
        //
        // Rumus:
        // posisi baru = posisi lama + velocity * deltaTime
        transform.position.x += velocityComp.vector.dx * dt
        transform.position.y += velocityComp.vector.dy * dt

        // Jangan update sprite.node.position di sini.
        // RenderSystem yang akan membaca TransformComponent
        // dan menyamakan posisi node secara visual.

        // 3. Out-of-bounds detection.
        if isOutOfBounds(transform.position) {
            resolveMiss()
        }
    }

    // MARK: - Out of Bounds

    /// Mengecek apakah projectile keluar dari arena.
    ///
    /// Rule:
    /// - kiri  = miss
    /// - kanan = miss
    /// - bawah = miss
    /// - atas tidak dihitung miss, supaya high arc tetap boleh
    private func isOutOfBounds(_ position: CGPoint) -> Bool {
        let sceneWidth = GameManager.shared.scene?.size.width ?? 2000

        // Catatan:
        // Ini memakai asumsi posisi X dunia dimulai dari 0 sampai sceneWidth.
        // Kalau scene kamu pakai origin tengah, batasnya perlu diganti ke:
        // leftBound = -sceneWidth / 2
        // rightBound = sceneWidth / 2
        let leftBound: CGFloat = -100
        let rightBound: CGFloat = sceneWidth + 100
        let bottomBound = GameConstants.groundY

        let isPastLeft = position.x < leftBound
        let isPastRight = position.x > rightBound
        let isBelowGround = position.y < bottomBound

        return isPastLeft || isPastRight || isBelowGround
    }

    /// Menyelesaikan throw sebagai miss.
    private func resolveMiss() {
        ThrowSystem.shared.isInFlight = false
        EventBus.shared.post(.throwResolved(hit: false))
    }
}
