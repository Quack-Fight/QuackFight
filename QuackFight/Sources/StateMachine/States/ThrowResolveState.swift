//
//  ThrowResolveState.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//

import GameplayKit

// MARK: - Entry / Exit Feedback (#27, #61, #66)
//
// Throw Resolution Rules (#61):
//
// Hit:
// - Projectile menyentuh hitbox lawan.
// - HitDetectionSystem akan post event: .throwResolved(hit: true).
// - DamageSystem akan menangani damage.
// - DamageCycleManager akan advance setelah damage diterapkan.
// - Kalau Damage Multiplier aktif, damage akan dikali 2.
// - Setelah damage selesai, DamageSystem harus post .turnEnded.
// - Kalau HP lawan habis, WinCheckSystem akan post .gameOver.
//
// Miss:
// - Projectile tidak mengenai lawan.
// - Projectile jatuh atau keluar dari area permainan.
// - PhysicsSystem akan post event: .throwResolved(hit: false).
// - Tidak ada damage.
// - DamageCycleManager tetap advance karena turn sudah selesai.
// - Skill aktif tetap dikonsumsi, termasuk Damage Multiplier.
// - Setelah itu masuk ke TurnHandoffState.
//
// Out of Bounds:
// - Projectile dianggap out-of-bounds kalau keluar dari sisi kiri, kanan,
//   atau bawah playable world.
// - Sisi atas tidak dihitung miss, karena high arc tetap boleh.
// - Out-of-bounds diperlakukan sama seperti miss.
//
// Feedback Moments (#66):
//
// didEnter:
// - ThrowSystem spawn BreadEntity / projectile.
// - Camera pindah ke mode .followBread.
// - Throw SFX dipicu oleh AudioManager lewat event .throwStarted.
//
// On hit:
// - Impact SFX.
// - Camera shake.
// - Damage text muncul di atas target.
// - Target / HP bar flash merah.
// - BreadImpact particle muncul.
// - Kalau tidak KO, lanjut ke TurnHandoffState.
// - Kalau KO, lanjut ke GameOverState.
//
// On miss:
// - Miss SFX.
// - BreadMiss crumb puff particle muncul.
// - Lanjut ke TurnHandoffState.
//
// willExit:
// - Projectile dibersihkan dari scene.
// - Subscription EventBus dilepas supaya tidak terjadi double event / memory leak.

/// State ini aktif saat projectile sedang terbang.
///
/// Tugas utama `ThrowResolveState`:
/// 1. Memulai lemparan lewat `ThrowSystem`.
/// 2. Menunggu hasil lemparan dari EventBus.
/// 3. Menentukan state berikutnya:
///    - Miss  → `TurnHandoffState`
///    - Hit tanpa KO → `TurnHandoffState`
///    - Hit dengan KO → `GameOverState`
///
/// Catatan penting:
/// State ini tidak menghitung damage secara langsung.
/// Damage tetap menjadi tanggung jawab `DamageSystem`.
final class ThrowResolveState: GKState {

    // MARK: - EventBus Subscription Tokens

    /// Token untuk mendengar event `.throwResolved`.
    ///
    /// Event ini dikirim oleh:
    /// - `HitDetectionSystem` saat projectile mengenai lawan.
    /// - `PhysicsSystem` saat projectile miss / out-of-bounds.
    private var throwToken: SubscriptionToken?

    /// Token untuk mendengar event `.turnEnded`.
    ///
    /// Untuk hit yang tidak KO, `DamageSystem` sebaiknya post `.turnEnded`
    /// setelah damage selesai dihitung dan damage cycle sudah advance.
    private var turnEndedToken: SubscriptionToken?

    /// Token untuk mendengar event `.gameOver`.
    ///
    /// Event ini dikirim oleh `WinCheckSystem` jika setelah damage,
    /// salah satu player memiliki HP <= 0.
    private var gameOverToken: SubscriptionToken?

    /// Flag untuk mencegah state berpindah dua kali.
    ///
    /// Contoh kasus:
    /// - Projectile hit.
    /// - DamageSystem post `.damageApplied`.
    /// - WinCheckSystem post `.gameOver`.
    /// - DamageSystem mungkin juga post `.turnEnded`.
    ///
    /// Tanpa flag ini, state bisa mencoba masuk ke `GameOverState`
    /// lalu langsung mencoba masuk ke `TurnHandoffState`.
    private var resolved = false

    // MARK: - Valid Transitions

    /// Menentukan state apa saja yang boleh dimasuki setelah ThrowResolveState.
    ///
    /// ThrowResolveState hanya boleh pindah ke:
    /// - `TurnHandoffState` kalau turn selesai dan game belum berakhir.
    /// - `GameOverState` kalau ada KO / game over.
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        stateClass == TurnHandoffState.self ||
        stateClass == GameOverState.self
    }

    // MARK: - Entry

    /// Dipanggil otomatis saat GameStateMachine masuk ke ThrowResolveState.
    ///
    /// Urutan penting:
    /// 1. Reset `resolved`.
    /// 2. Subscribe ke semua event yang dibutuhkan.
    /// 3. Baru execute throw.
    ///
    /// Kenapa subscribe dulu?
    /// Karena kalau `executeThrow()` langsung menghasilkan event,
    /// state ini sudah siap menangkap event tersebut.
    override func didEnter(from previousState: GKState?) {
        resolved = false

        subscribeToThrowResolved()
        subscribeToTurnEnded()
        subscribeToGameOver()

        executeThrow()
    }

    // MARK: - Event Subscriptions

    /// Mendengar hasil lemparan dari `.throwResolved(hit:)`.
    ///
    /// Di state ini, kita hanya menangani MISS secara langsung.
    ///
    /// Kenapa HIT tidak langsung ditangani di sini?
    /// Karena kalau hit, damage harus diproses dulu oleh `DamageSystem`.
    /// Setelah DamageSystem selesai, ia akan post `.turnEnded`
    /// atau WinCheckSystem akan post `.gameOver`.
    private func subscribeToThrowResolved() {
        throwToken = EventBus.shared.subscribe(.throwResolved) { [weak self] event in
            guard let self else { return }

            guard case .throwResolved(let hit) = event else {
                return
            }

            guard !self.resolved else {
                return
            }

            if hit {
                // Hit path:
                // Jangan pindah state di sini.
                // Biarkan DamageSystem menghitung damage dulu.
                //
                // Expected flow:
                // .throwResolved(hit: true)
                // → DamageSystem applies damage
                // → DamageSystem advances damage cycle
                // → DamageSystem posts .damageApplied
                // → WinCheckSystem may post .gameOver
                // → DamageSystem posts .turnEnded if no KO
                return
            }

            // Miss path:
            // Tidak ada DamageSystem yang akan jalan,
            // jadi ThrowResolveState sendiri harus menyelesaikan turn miss.
            self.resolveMiss()
        }
    }

    /// Mendengar `.turnEnded`.
    ///
    /// Event ini menandakan turn sudah selesai secara normal.
    /// Biasanya terjadi setelah:
    /// - Hit berhasil dan DamageSystem sudah selesai apply damage.
    /// - Tidak ada KO.
    ///
    /// Kalau event ini diterima, kita lanjut ke TurnHandoffState.
    private func subscribeToTurnEnded() {
        turnEndedToken = EventBus.shared.subscribe(.turnEnded) { [weak self] _ in
            guard let self else { return }

            guard !self.resolved else {
                return
            }

            self.resolved = true
            GameStateMachine.shared.enter(TurnHandoffState.self)
        }
    }

    /// Mendengar `.gameOver`.
    ///
    /// Event ini dikirim saat WinCheckSystem mendeteksi:
    /// - Salah satu player HP <= 0.
    /// - Atau game selesai karena round cap.
    ///
    /// Kalau game over, outcome disimpan ke GameManager,
    /// lalu masuk ke GameOverState.
    private func subscribeToGameOver() {
        gameOverToken = EventBus.shared.subscribe(.gameOver) { [weak self] event in
            guard let self else { return }

            guard !self.resolved else {
                return
            }

            guard case .gameOver(let outcome) = event else {
                return
            }

            self.resolved = true
            GameManager.shared.lastOutcome = outcome
            GameStateMachine.shared.enter(GameOverState.self)
        }
    }

    // MARK: - Throw Start

    /// Memulai lemparan projectile.
    ///
    /// ThrowSystem bertanggung jawab untuk:
    /// - Membaca angle dan power yang sudah di-lock.
    /// - Membuat BreadEntity / projectile.
    /// - Memberi velocity awal.
    /// - Menambahkan projectile ke scene.
    /// - Mengubah camera ke mode follow projectile.
    private func executeThrow() {
        guard let scene = GameManager.shared.scene else {
            print("Warning: GameManager.shared.scene is nil; cannot execute throw.")
            return
        }

        ThrowSystem.shared.executeThrow(
            player: GameManager.shared.activePlayer,
            scene: scene
        )
    }

    // MARK: - Miss Resolution

    /// Menyelesaikan turn ketika projectile miss.
    ///
    /// Aturan miss:
    /// - Tidak ada damage.
    /// - Skill aktif tetap dikonsumsi.
    /// - Damage cycle tetap maju.
    /// - State lanjut ke TurnHandoffState.
    ///
    /// Kenapa DamageCycle advance di sini?
    /// Karena DamageSystem hanya berjalan saat hit.
    /// Kalau miss, tidak ada sistem lain yang otomatis memajukan cycle.
    private func resolveMiss() {
        resolved = true

        consumeActiveSkillOnMiss()

        // NOTE: DamageCycleManager.advance() is NOT called here.
        // The cycle advances only in TurnHandoffState after P2 finishes,
        // matching the GDD rule: "advance after each complete round."

        // Memberi tahu sistem lain bahwa turn throw sudah selesai.
        //
        // Karena `resolved` sudah true, subscription `.turnEnded`
        // di file ini tidak akan menjalankan transition kedua kali.
        EventBus.shared.post(.turnEnded)

        GameStateMachine.shared.enter(TurnHandoffState.self)
    }

    /// Mengonsumsi skill aktif saat miss.
    ///
    /// Contoh:
    /// Player mengaktifkan Damage Multiplier,
    /// tapi lemparannya meleset.
    ///
    /// Skill tetap hilang karena sudah dipakai untuk turn ini.
    private func consumeActiveSkillOnMiss() {
        GameManager.shared.activePlayer
            .component(ofType: SkillComponent.self)?
            .consumeActive()
    }

    /// Memajukan damage cycle saat miss.
    ///
    /// Cycle damage adalah:
    /// 10 → 10 → 15 → 10 → ...
    ///
    /// Miss tetap dianggap completed throw turn,
    /// jadi cycle tetap maju.
    private func advanceDamageCycleOnMiss() {
        DamageCycleManager.shared.advance()
    }

    // MARK: - Exit

    /// Dipanggil otomatis saat keluar dari ThrowResolveState.
    ///
    /// Di sini kita membersihkan:
    /// - Semua EventBus subscription.
    /// - Projectile dari scene.
    ///
    /// Ini penting supaya:
    /// - Event lama tidak terpanggil di turn berikutnya.
    /// - Projectile lama tidak tertinggal di scene.
    /// - Tidak ada memory leak dari closure subscription.
    override func willExit(to nextState: GKState) {
        unsubscribeFromEvents()
        clearProjectile()
        CameraSystem.shared.returnToPlayer(index: GameManager.shared.nextPlayerIndex)
    }

    /// Melepas semua subscription EventBus yang dibuat saat `didEnter`.
    private func unsubscribeFromEvents() {
        [throwToken, turnEndedToken, gameOverToken]
            .compactMap { $0 }
            .forEach { EventBus.shared.unsubscribe($0) }

        throwToken = nil
        turnEndedToken = nil
        gameOverToken = nil
    }

    /// Menghapus projectile aktif dari scene.
    private func clearProjectile() {
        guard let scene = GameManager.shared.scene else {
            return
        }

        ThrowSystem.shared.clearBread(scene: scene)
    }
}
