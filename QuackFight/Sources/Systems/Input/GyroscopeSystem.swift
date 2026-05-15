//
//  GyroscopeSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//



import Foundation
import CoreMotion
import GameplayKit
import CoreGraphics

/*
 Gyroscope Aiming UX Contract

 - Gyroscope hanya aktif saat AimState.
 - Sistem ini hanya boleh mengubah liveAngle kalau InputStateComponent.phase == .aiming.
 - Posisi HP datar / hampir datar akan menghasilkan arc rendah sekitar 5°.
 - Tilt sekitar 45° akan menghasilkan arc sedang sekitar 45°.
 - Tilt tinggi ke atas akan menghasilkan arc tinggi sampai sekitar 85°.
 - Angle akhir harus selalu dibatasi di antara GameConstants.minAimAngle sampai GameConstants.maxAimAngle.
 - Tap saat AimState atau timeout 5 detik akan memicu GameEvent.aimLocked.
 - Saat aim dikunci, lockedAngle diambil dari liveAngle terakhir.
 - Kalau gyroscope belum pernah memberi data valid, lockedAngle akan fallback ke GameConstants.defaultAimAngle.
 - Setelah aim dikunci, gyroscope harus dimatikan.
 - GyroscopeSystem tidak boleh pindah state langsung dan tidak boleh update UI langsung.
 */

/*
 Gyroscope Feedback Moments

 - Saat AimState dimulai, UISystem menampilkan overlay singkat "Tilt to Aim".
 - Selama aiming, GyroscopeSystem mengubah liveAngle setiap frame berdasarkan tilt HP.
 - TrajectoryRenderSystem membaca liveAngle dan menggambar ulang arc preview secara live.
 - Arc preview harus terasa responsif, jadi update dilakukan setiap frame dan tidak dithrottle.
 - Saat player tap atau timer 5 detik habis, GameEvent.aimLocked dipost.
 - Setelah aim terkunci, arc preview boleh diberi flash / freeze singkat sebagai konfirmasi.
 - GyroscopeSystem tidak menjalankan animasi UI langsung; feedback visual dikerjakan oleh TrajectoryRenderSystem / UISystem.
 */

/// Sistem untuk membaca gyroscope / tilt HP lalu mengubahnya menjadi angle lemparan.
///
/// Penjelasan gampang:
/// - `activate()` = mulai baca gerakan HP.
/// - `update(deltaTime:)` = tiap frame baca kemiringan HP.
/// - hasil kemiringan HP disimpan ke `liveAngle`.
/// - `lockAim()` = simpan `liveAngle` terakhir ke `lockedAngle`.
/// - `deactivate()` = berhenti baca gyroscope.
final class GyroscopeSystem: GKComponentSystem<InputStateComponent> {

    /// Satu instance global supaya sistem lain bisa akses GyroscopeSystem yang sama.
    static let shared = GyroscopeSystem()

    /// Object dari CoreMotion untuk membaca motion / tilt HP.
    private let motionManager = CMMotionManager()

    /// Menandakan apakah gyroscope sedang aktif atau tidak.
    private var isActive = false

    /// Menandakan apakah gyroscope sudah pernah memberi data valid.
    /// Ini dipakai untuk menentukan apakah kita pakai liveAngle atau fallback 45°.
    private var hasReceivedMotionData = false

    // MARK: - Init

    private override init() {
        super.init(componentClass: InputStateComponent.self)
        setupSubscriptions()
    }

    // MARK: - Event Subscription

    /// Daftar event yang didengar oleh GyroscopeSystem.
    ///
    /// Kalau ada event `.aimLocked`, berarti player sudah tap atau timer aim habis.
    /// Saat itu angle harus dikunci.
    func setupSubscriptions() {
        EventBus.shared.subscribe(.aimLocked) { [weak self] _ in
            guard let self else { return }
            self.lockAim()
        }
    }

    // MARK: - Lifecycle

    /// Mulai membaca gyroscope.
    ///
    /// Biasanya dipanggil saat game masuk ke AimState.
    func activate() {
        // Kalau sudah aktif, tidak perlu start lagi.
        guard !isActive else { return }

        // Reset status data motion setiap mulai aim baru.
        hasReceivedMotionData = false

        // Set seberapa sering motion data di-update.
        // Contoh: 1/60 berarti sekitar 60 kali per detik.
        motionManager.deviceMotionUpdateInterval = GameConstants.gyroUpdateInterval

        // Mulai ambil data gerakan HP.
        motionManager.startDeviceMotionUpdates()

        isActive = true
    }

    /// Berhenti membaca gyroscope.
    ///
    /// Biasanya dipanggil setelah angle dikunci atau saat keluar dari AimState.
    func deactivate() {
        // Kalau memang belum aktif, tidak perlu stop.
        guard isActive else { return }

        motionManager.stopDeviceMotionUpdates()
        isActive = false
    }

    // MARK: - Update Loop

    /// Fungsi ini dipanggil setiap frame oleh GameScene / GameplayKit.
    ///
    /// Alurnya:
    /// 1. Cek gyroscope aktif atau tidak.
    /// 2. Ambil InputStateComponent milik player yang sedang aktif.
    /// 3. Pastikan sekarang memang sedang fase aiming.
    /// 4. Baca pitch / kemiringan HP.
    /// 5. Ubah pitch menjadi angle lemparan.
    /// 6. Simpan hasilnya ke liveAngle.
    override func update(deltaTime seconds: TimeInterval) {
        // Kalau gyro belum aktif, tidak usah melakukan apa-apa.
        guard isActive else { return }

        // Ambil input component dari player yang sedang jalan.
        guard let inputState = activePlayerInputComponent() else { return }

        // Gyroscope hanya boleh mengubah angle saat phase-nya .aiming.
        guard inputState.phase == .aiming else { return }

        // Ambil pitch dari sensor HP.
        // Kalau datanya belum tersedia, skip frame ini.
        guard let pitch = motionManager.deviceMotion?.attitude.pitch else { return }

        // Kalau sampai sini, berarti kita sudah dapat data gyro valid.
        hasReceivedMotionData = true

        // Ubah pitch HP menjadi angle lemparan, lalu simpan ke liveAngle.
        inputState.liveAngle = mapPitchToAimAngle(pitch)
    }

    // MARK: - Aim Lock

    /// Mengunci angle saat player tap atau timer aim habis.
    private func lockAim() {
        guard let inputState = activePlayerInputComponent() else { return }

        if hasReceivedMotionData {
            // Kalau gyro sudah pernah memberi data,
            // pakai liveAngle terakhir sebagai angle final.
            inputState.lockedAngle = inputState.liveAngle
        } else {
            // Kalau gyro belum memberi data sama sekali,
            // pakai default angle 45° supaya game tetap bisa lanjut.
            inputState.lockedAngle = GameConstants.defaultAimAngle
        }

        // Setelah angle dikunci, gyro tidak perlu jalan lagi.
        deactivate()

        // Beri tahu AimState bahwa angle sudah berhasil dikunci.
        EventBus.shared.post(.aimLockConfirmed)
    }

    // MARK: - Angle Mapping

    /// Mengubah pitch / kemiringan HP menjadi angle lemparan.
    ///
    /// Penjelasan gampang:
    /// - pitch rendah berarti lemparan datar.
    /// - pitch tinggi berarti lemparan lebih melambung.
    /// - hasil akhirnya selalu dibatasi agar tidak kurang dari minAngle dan tidak lebih dari maxAngle.
    private func mapPitchToAimAngle(_ pitch: Double) -> Double {
        // Batasi pitch dari 0 sampai 90 derajat dalam radians.
        // 0 = HP datar / low arc.
        // .pi / 2 = HP tegak / high arc.
        let clampedPitch = max(0.0, min(pitch, .pi / 2.0))

        // Ubah pitch menjadi nilai progress 0.0 sampai 1.0.
        // 0.0 = angle minimum.
        // 1.0 = angle maksimum.
        let progress = clampedPitch / (.pi / 2.0)

        // Hitung jarak antara angle minimum dan maksimum.
        let angleRange = GameConstants.maxAimAngle - GameConstants.minAimAngle

        // Mapping progress ke range angle game.
        let rawAngle = GameConstants.minAimAngle + progress * angleRange

        // Safety clamp supaya angle final tetap aman.
        return max(GameConstants.minAimAngle, min(rawAngle, GameConstants.maxAimAngle))
    }

    // MARK: - Helper

    /// Mengambil InputStateComponent dari player yang sedang aktif.
    private func activePlayerInputComponent() -> InputStateComponent? {
        GameManager.shared.activePlayer.component(ofType: InputStateComponent.self)
    }
}


