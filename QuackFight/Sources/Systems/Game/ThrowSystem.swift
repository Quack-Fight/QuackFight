//
//  ThrowSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import Foundation
import GameplayKit
import SpriteKit

/// `ThrowSystem` bertugas untuk memulai lemparan projectile.
///
/// Beginner-friendly:
///
/// Class ini hanya melakukan "setup awal" lemparan.
/// Dia tidak menggerakkan projectile setiap frame.
/// Dia juga tidak mengecek hit atau miss.
///
/// Pembagian tugas:
///
/// - ThrowSystem:
///   Membuat projectile, memberi velocity awal, memasukkan projectile ke scene.
///
/// - PhysicsSystem:
///   Menggerakkan projectile setiap frame.
///
/// - HitDetectionSystem:
///   Mengecek apakah projectile kena lawan.
///
/// - DamageSystem:
///   Memberikan damage kalau projectile hit.
///
/// Flow normal:
///
/// AimState
/// → menyimpan `lockedAngle`
///
/// PowerState
/// → menyimpan `lockedPower`
///
/// ThrowResolveState
/// → memanggil `ThrowSystem.executeThrow(...)`
///
/// ThrowSystem
/// → spawn projectile dan post `.throwStarted`
final class ThrowSystem {

    // MARK: - Singleton

    /// Satu instance global untuk ThrowSystem.
    static let shared = ThrowSystem()

    private init() {}

    // MARK: - State

    /// Projectile yang sedang aktif / sedang terbang.
    ///
    /// Nil kalau tidak ada projectile.
    var activeBread: ProjectileEntity?

    /// Menandakan apakah projectile sedang dalam fase terbang.
    var isInFlight: Bool = false

    // MARK: - Execute Throw

    /// Memulai lemparan projectile.
    ///
    /// Parameter:
    /// - player: player aktif yang sedang melempar.
    /// - scene: GameScene tempat projectile dimasukkan.
    func executeThrow(player: PlayerEntity, scene: GameScene) {

        guard let input = player.component(ofType: InputStateComponent.self) else {
            print("Warning: Player is missing InputStateComponent. Cannot execute throw.")
            return
        }

        // lockedAngle memakai radian.
        //
        // PhysicsEngine kamu juga memakai radian.
        // Jadi fallback yang benar adalah GameConstants.defaultAimAngle,
        // bukan GameConstants.defaultAimAngleDegrees.
        let angle = input.lockedAngle ?? GameConstants.defaultAimAngle

        // lockedPower normalnya 0.0 sampai 1.0.
        //
        // Kalau nil, pakai defaultThrowPower.
        let power = input.lockedPower ?? GameConstants.defaultThrowPower

        executeThrowWithValues(
            player: player,
            scene: scene,
            angle: angle,
            power: power
        )
    }

    /// Logic utama untuk membuat projectile.
    ///
    /// Function ini dipisah agar `executeThrow` fokus mengambil input,
    /// sedangkan function ini fokus membuat dan mendaftarkan projectile.
    private func executeThrowWithValues(
        player: PlayerEntity,
        scene: GameScene,
        angle: Double,
        power: Double
    ) {
        // Hitung velocity awal projectile.
        //
        // PhysicsEngine.calculateVelocity menerima:
        // - angle dalam radian
        // - power 0.0 sampai 1.0
        // - facing +1 atau -1
        let velocity = PhysicsEngine.calculateVelocity(
            angle: angle,
            power: power,
            facing: player.facing
        )

        // Tentukan asset projectile.
        let imageName = projectileImageName(for: player)

        // Buat ProjectileEntity.
        let projectile = ProjectileEntity(
            imageName: imageName,
            position: player.throwOrigin,
            velocity: velocity,
            radius: GameConstants.defaultHitBoxRadius
        )

        // Tambahkan sprite projectile ke scene.
        if let spriteNode = projectile.component(ofType: SpriteComponent.self)?.node {
            scene.addChild(spriteNode)
        } else {
            print("Warning: ProjectileEntity is missing SpriteComponent.")
        }

        // Register entity ke ECS systems.
        //
        // Ini penting supaya PhysicsSystem, RenderSystem,
        // dan HitDetectionSystem bisa memproses component projectile.
        scene.registerEntity(projectile)

        // Simpan sebagai projectile aktif.
        activeBread = projectile
        isInFlight = true
        
        CameraSystem.shared.followBread()

        // If 2x damage skill is active, add a 2-frame looping animation to the projectile.
        if let activeSkill = player.component(ofType: SkillComponent.self)?.activeSkill,
           activeSkill == .damageMultiplier,
           let spriteNode = projectile.component(ofType: SpriteComponent.self)?.node {
            let baseName = projectileBaseName(for: player)
            let frame1 = SKTexture(imageNamed: "\(baseName)1")
            let frame2 = SKTexture(imageNamed: "\(baseName)2")
            let loop = SKAction.repeatForever(
                SKAction.animate(with: [frame1, frame2], timePerFrame: 0.15)
            )
            spriteNode.run(loop, withKey: "skill1Loop")
        }

        // Umumkan bahwa throw sudah dimulai.
        EventBus.shared.post(.throwStarted)
    }

    // MARK: - Clear Bread

    /// Membersihkan projectile aktif dari scene.
    ///
    /// Dipanggil saat keluar dari ThrowResolveState.
    func clearBread(scene: GameScene) {
        guard let bread = activeBread else {
            isInFlight = false
            return
        }

        // Hapus visual node dari scene.
        if let spriteNode = bread.component(ofType: SpriteComponent.self)?.node {
            spriteNode.removeFromParent()
        }

        // Hapus entity dari semua component systems.
        scene.removeEntity(bread)

        // Reset state.
        activeBread = nil
        isInFlight = false
    }

    /// Convenience version kalau caller tidak punya scene.
    func clearBread() {
        guard let scene = GameManager.shared.scene else {
            activeBread?.component(ofType: SpriteComponent.self)?.node.removeFromParent()
            activeBread = nil
            isInFlight = false
            return
        }

        clearBread(scene: scene)
    }

    // MARK: - Projectile Asset Selection

    /// Menentukan asset projectile berdasarkan damage cycle dan skill aktif.
    ///
    /// Rule:
    /// - Damage 10 memakai bread.
    /// - Damage 15 memakai toaster.
    /// - Damage Multiplier memakai versi Skill1 (frame 1 as initial sprite).
    private func projectileImageName(for player: PlayerEntity) -> String {
        let baseName = projectileBaseName(for: player)
        let activeSkill = player.component(ofType: SkillComponent.self)?.activeSkill
        if activeSkill == .damageMultiplier {
            return "\(baseName)1"  // Start on frame 1; the loop animation handles the rest.
        }
        return baseName
    }

    /// Returns the base asset prefix for the current cycle + skill state.
    /// Used by both `projectileImageName` (initial frame) and the loop animation (frames 1+2).
    private func projectileBaseName(for player: PlayerEntity) -> String {
        let isToasterCycle = DamageCycleManager.shared.currentDamage == 15
        let activeSkill = player.component(ofType: SkillComponent.self)?.activeSkill
        if activeSkill == .damageMultiplier {
            return isToasterCycle ? "Skill1Toaster" : "Skill1Bread"
        }
        return isToasterCycle ? "BaseToaster" : "BaseBread"
    }

    // MARK: - System Lifecycle

    /// Saat ini ThrowSystem tidak perlu subscribe ke event apa pun.
    ///
    /// Hit/miss diproses oleh PhysicsSystem dan HitDetectionSystem.
    func setupSubscriptions() {
        // No subscriptions needed for now.
    }
}
