//
//  VoiceInputSystem.swift
//  QuackFight
//
//  Created by Justin Chow on 12/05/26.
//


import Foundation
import AVFoundation
import GameplayKit

/*
 Voice Power UX Contract

 - Voice input hanya aktif saat PowerState.
 - Sistem ini hanya boleh mengubah livePower kalau InputStateComponent.phase == .power.
 - Suara pelan / silence tetap menghasilkan minimum power sekitar 10%.
 - Suara keras / shouting menghasilkan power mendekati 100%.
 - Power bar bersifat live / oscillating, bukan accumulating.
   Artinya player harus lock power di momen yang tepat, bukan mengisi bar sampai penuh.
 - Tap saat PowerState atau timeout 5 detik akan memicu GameEvent.powerLocked.
 - Saat power dikunci, lockedPower diambil dari livePower terakhir.
 - Kalau microphone belum pernah memberi data valid, lockedPower fallback ke minimum power 10%.
 - Setelah power dikunci, microphone input harus dimatikan.
 - VoiceInputSystem tidak boleh pindah state langsung dan tidak boleh update UI langsung.
 */

/*
 Voice Power Feedback Moments

 - Saat PowerState dimulai, UISystem menampilkan overlay singkat "Shout!".
 - Selama power phase, VoiceInputSystem membaca microphone dan mengubah livePower secara live.
 - Setiap perubahan livePower mem-post GameEvent.amplitudeUpdated.
 - UISystem / PowerBarNode memakai amplitudeUpdated untuk mengubah fill power bar secara live.
 - Warna power bar berubah mengikuti power:
   low power = hijau, medium power = kuning, high power = merah.
 - Saat player tap atau timer 5 detik habis, GameEvent.powerLocked dipost.
 - Setelah power terkunci, power bar boleh diberi flash / pulse singkat sebagai konfirmasi.
 - VoiceInputSystem tidak menjalankan animasi UI langsung; feedback visual dikerjakan oleh UISystem / PowerBarNode.
 */

/// Sistem untuk membaca suara dari microphone lalu mengubahnya menjadi power lemparan.
///
/// Penjelasan gampang:
/// - `activate()` = mulai mendengarkan microphone.
/// - `update` microphone terjadi lewat AVAudioEngine tap, bukan lewat frame biasa.
/// - setiap buffer audio dihitung RMS-nya.
/// - RMS diubah menjadi power 0.1 sampai 1.0. (RMS itu root mean square jadi ini untuk ngukur seberapa keras suara yang masuk)
/// - hasilnya disimpan ke `livePower`.
/// - `lockPower()` menyimpan `livePower` terakhir ke `lockedPower`.
/// - `deactivate()` = berhenti mendengarkan microphone.
final class VoiceInputSystem: GKComponentSystem<InputStateComponent> {

    /// Satu instance global supaya sistem lain memakai VoiceInputSystem yang sama.
    static let shared = VoiceInputSystem()

    /// AVAudioEngine dipakai untuk membaca input microphone.
    private let audioEngine = AVAudioEngine()

    /// Menandakan apakah microphone sedang aktif.
    private var isActive = false

    /// Menandakan apakah microphone sudah pernah memberi data valid.
    /// Kalau belum pernah, nanti fallback ke minimum power.
    private var hasReceivedAudioData = false

    /// Power minimum supaya lemparan tidak pernah benar-benar 0.
    private let minimumPower: Double = 0.1

    /// Nilai power yang sudah dihaluskan.
    /// Ini membantu supaya power bar tidak terlalu kasar / lompat-lompat.
    private var smoothedPower: Double = 0.1

    // MARK: - Init

    private override init() {
        super.init(componentClass: InputStateComponent.self)
        setupSubscriptions()
    }

    // MARK: - Event Subscription

    /// Daftar event yang didengar oleh VoiceInputSystem.
    ///
    /// Kalau ada event `.powerLocked`, berarti player sudah tap atau timer power habis.
    /// Saat itu power harus dikunci.
    func setupSubscriptions() {
        EventBus.shared.subscribe(.powerLocked) { [weak self] _ in
            guard let self else { return }
            self.lockPower()
        }
    }

    // MARK: - Lifecycle

    /// Mulai membaca suara dari microphone.
    ///
    /// Biasanya dipanggil saat game masuk ke PowerState.
    func activate() {
        // Kalau sudah aktif, jangan start ulang.
        guard !isActive else { return }

        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            startListening()

        case .undetermined:
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if granted {
                        self.startListening()
                    } else {
                        print("VoiceInputSystem: microphone permission denied")
                    }
                }
            }

        case .denied:
            print("VoiceInputSystem: microphone permission denied")

        @unknown default:
            print("VoiceInputSystem: unknown microphone permission state")
        }
    }

    private func startListening() {
        guard !isActive else { return }

        hasReceivedAudioData = false
        smoothedPower = minimumPower

        // Mark active before dispatching to background to prevent a second
        // activate() call sneaking in while audioEngine.start() is in flight.
        isActive = true

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        // Safety: hapus tap lama dulu supaya tidak terjadi double tap.
        inputNode.removeTap(onBus: 0)

        // Pasang tap untuk membaca audio buffer dari microphone.
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: format
        ) { [weak self] buffer, _ in
            guard let self else { return }

            // Hitung RMS dari audio buffer.
            let rms = self.computeRMS(from: buffer)

            // Ubah RMS menjadi power 0.1...1.0.
            let normalisedPower = self.normalisePower(from: rms)

            // AVAudioEngine callback bisa jalan di background thread.
            // Karena kita akan update component dan post EventBus,
            // pindahkan ke main thread agar aman untuk GameplayKit/SpriteKit.
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.writeLivePower(normalisedPower)
            }
        }

        // audioEngine.start() melibatkan inisialisasi hardware audio dan bisa
        // memblok main thread beberapa milidetik — pindahkan ke background.
        // Session sudah dikonfigurasi oleh AudioManager sejak awal game.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            do {
                try self.audioEngine.start()
                DispatchQueue.main.async {
                    self.writeLivePower(self.minimumPower)
                }
            } catch {
                print("VoiceInputSystem: failed to start audio engine - \(error)")
                DispatchQueue.main.async {
                    self.isActive = false
                    self.audioEngine.inputNode.removeTap(onBus: 0)
                }
            }
        }
    }

    /// Berhenti membaca microphone.
    ///
    /// Biasanya dipanggil setelah power dikunci atau saat keluar dari PowerState.
    func deactivate() {
        guard isActive else { return }

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        // Audio session lifecycle is owned by AudioManager — do not deactivate here.
        isActive = false
    }

    // MARK: - Power Lock

    /// Mengunci power saat player tap atau timer power habis.
    private func lockPower() {
        guard let inputState = activePlayerInputComponent() else { return }

        if hasReceivedAudioData {
            // Kalau microphone sudah pernah memberi data,
            // pakai livePower terakhir sebagai power final.
            inputState.lockedPower = inputState.livePower
        } else {
            // Kalau belum ada data microphone sama sekali,
            // pakai minimum power supaya game tetap bisa lanjut.
            inputState.lockedPower = minimumPower
        }

        deactivate()

        // Beri tahu PowerState bahwa power sudah berhasil dikunci.
        EventBus.shared.post(.powerLockConfirmed)
    }

    // MARK: - Live Power Write

    /// Menulis power terbaru ke InputStateComponent.
    ///
    /// Fungsi ini hanya boleh menulis saat phase == .power.
    private func writeLivePower(_ power: Double) {
        guard isActive else { return }
        guard let inputState = activePlayerInputComponent() else { return }

        // VoiceInputSystem hanya boleh update power saat phase .power.
        guard inputState.phase == .power else { return }

        hasReceivedAudioData = true

        // Smooth power supaya power bar tidak terlalu patah-patah.
        let alpha = GameConstants.micSmoothingFactor
        smoothedPower = (alpha * power) + ((1.0 - alpha) * smoothedPower)

        inputState.livePower = smoothedPower

        // Kirim event supaya UISystem bisa update power bar.
        EventBus.shared.post(.amplitudeUpdated(Float(smoothedPower)))
    }

    // MARK: - Audio Processing

    /// Menghitung RMS dari audio buffer.
    ///
    /// RMS adalah cara sederhana untuk mengukur "kerasnya" suara.
    /// Semakin besar RMS, semakin keras suara yang masuk.
    private func computeRMS(from buffer: AVAudioPCMBuffer) -> Double {
        guard let channelData = buffer.floatChannelData?[0] else {
            return 0.0
        }

        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else {
            return 0.0
        }

        var sumSquares: Double = 0.0

        for frame in 0..<frameLength {
            let sample = Double(channelData[frame])
            sumSquares += sample * sample
        }

        let meanSquare = sumSquares / Double(frameLength)
        return sqrt(meanSquare)
    }

    /// Mengubah RMS menjadi power 0.1...1.0.
    ///
    /// - RMS di bawah noise floor dianggap silence.
    /// - RMS di atas ceiling dianggap shouting / max power.
    /// - Di antara keduanya, power naik secara linear.
    private func normalisePower(from rms: Double) -> Double {
        if rms <= GameConstants.micNoiseFloor {
            return minimumPower
        }

        if rms >= GameConstants.micCeiling {
            return 1.0
        }

        let range = GameConstants.micCeiling - GameConstants.micNoiseFloor
        let progress = (rms - GameConstants.micNoiseFloor) / range

        return minimumPower + (progress * (1.0 - minimumPower))
    }

    // MARK: - Helper

    /// Mengambil InputStateComponent dari player yang sedang aktif.
    private func activePlayerInputComponent() -> InputStateComponent? {
        GameManager.shared.activePlayer.component(ofType: InputStateComponent.self)
    }
}
