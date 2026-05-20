//
//  AudioManager.swift
//  QuackFight
//
//  Created by Justin Chow on 20/05/26.
//

import AVFoundation
import SpriteKit
import UIKit

/// `AudioManager` mengatur audio game.
///
/// Pembagian:
/// - BGM panjang pakai `AVAudioPlayer`.
/// - SFX pendek pakai `SKAction.playSoundFileNamed`.
///
/// Kenapa SFX pakai SpriteKit?
/// Karena SFX seperti hit, throw, click, explosion biasanya pendek.
/// SpriteKit bisa langsung menjalankan sound sebagai action di scene.
///
/// Kenapa BGM tetap pakai AVFoundation?
/// Karena BGM perlu loop, pause, resume, dan volume control yang lebih stabil.
final class AudioManager: NSObject {

    // MARK: - Singleton

    static let shared = AudioManager()

    // MARK: - BGM

    private var bgmPlayer: AVAudioPlayer?

    /// Player khusus untuk skill 1 burning/fire loop.
    /// Dipisah dari SFX SpriteKit karena sound ini perlu bisa distop manual.
    private var skill1LoopPlayer: AVAudioPlayer?
    

    // MARK: - Init

    private override init() {
        super.init()

        configureAudioSession()
        prepareBGM()
        observeInterruptions()
        observeAppLifecycle()
    }

    // MARK: - Audio Session

    /// Mengatur audio session iOS.
    ///
    /// `.ambient` artinya audio mengikuti silent mode.
    /// Kalau mau audio tetap bunyi walaupun silent mode aktif,
    /// ganti `.ambient` menjadi `.playback`.
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )

            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioManager: failed to configure audio session — \(error)")
        }
    }

    // MARK: - EventBus Subscriptions

    /// Panggil function ini saat game setup, misalnya di `GameScene.didMove(to:)`.
    ///
    /// Kalau `EventBus.shared.clearAllSubscriptions()` dipanggil saat reset,
    /// function ini perlu dipanggil ulang setelah clear.
    func setupSubscriptions() {

        EventBus.shared.subscribe(.throwStarted) { [weak self] _ in
            self?.playSFX(.throw)
        }

        EventBus.shared.subscribe(.throwResolved) { [weak self] event in
            guard case .throwResolved(let hit) = event else {
                return
            }

            // Throw sudah selesai, jadi fire/burning sound Skill 1 harus berhenti.
            self?.stopSkill1Loop()

            if hit {
                self?.playImpactForCurrentProjectile()
            } else {
                self?.playSFX(.quackSfx)
            }
        }

        EventBus.shared.subscribe(.healApplied) { [weak self] _ in
            self?.playSFX(.skill2Fix)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self?.playSFX(.heal)
            }
        }

        EventBus.shared.subscribe(.skillSelected) { [weak self] event in
            guard case .skillSelected(let skill) = event else {
                return
            }

            switch skill {
            case .damageMultiplier:
                self?.startSkill1Loop()
                
/*
 heal sebaiknya jangan play skill2Fix di skillSelected, karena nanti .healApplied sudah play skill2Fix + heal
 */
            case .heal:
                break

            case .fixedHit:
                self?.playSFX(.explosion)
            }
        }

        EventBus.shared.subscribe(.gameOver) { [weak self] _ in
            self?.stopSkill1Loop()
            self?.playSFX(.laugh)
        }
    }

    // MARK: - SFX with SpriteKit

    /// Memainkan SFX pendek menggunakan SpriteKit.
    ///
    /// SFX dijalankan di `GameScene` lewat `scene.run(...)`.
    ///
    /// File yang dipanggil:
    /// - throw.wav
    /// - breadImpact.wav
    /// - toasterImpact.wav
    /// - dan lainnya
    func playSFX(_ sound: SoundEffect) {
        guard let scene = GameManager.shared.scene else {
            print("AudioManager: cannot play SFX \(sound.fileName) because scene is nil.")
            return
        }

        scene.run(
            SKAction.playSoundFileNamed(
                sound.fileName,
                waitForCompletion: false
            )
        )
    }

    /// Memainkan impact sound sesuai projectile aktif.
    ///
    /// Kalau projectile adalah toaster, pakai `toasterImpact.wav`.
    /// Kalau bukan, pakai `breadImpact.wav`.
    private func playImpactForCurrentProjectile() {
        let currentDamage = DamageCycleManager.shared.currentDamage
        let isToasterCycle = currentDamage == 15

        if isToasterCycle {
            playSFX(.toasterImpact)
        } else {
            playSFX(.breadImpactFix)
        }

        // Reaction sound saat player terkena hit.
        playSFX(.quackAngry)
    }
    
    
    // MARK: - Skill 1 Looping SFX

    /// Memulai SFX fire/burning untuk Skill 1.
    ///
    /// Skill 1 audio panjang, jadi tidak cocok memakai SKAction.playSoundFileNamed
    /// karena SKAction sulit dihentikan di tengah.
    /// Dengan AVAudioPlayer, audio bisa loop dan bisa distop saat throw selesai.
    func startSkill1Loop() {
        if skill1LoopPlayer?.isPlaying == true {
            return
        }

        guard let url = Bundle.main.url(forResource: "skill1", withExtension: "wav") else {
            print("AudioManager: skill1.wav not found in bundle.")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.75
            player.prepareToPlay()
            player.play()

            skill1LoopPlayer = player
        } catch {
            print("AudioManager: failed to start skill1 loop — \(error)")
        }
    }

    /// Menghentikan SFX fire/burning Skill 1.
    ///
    /// Dipanggil saat projectile sudah selesai: hit, miss, atau game over.
    func stopSkill1Loop() {
        skill1LoopPlayer?.stop()
        skill1LoopPlayer?.currentTime = 0
        skill1LoopPlayer = nil
    }
    
    // MARK: - BGM with AVFoundation

    private func prepareBGM() {
        guard let url = Bundle.main.url(forResource: "bgm", withExtension: "mp3") else {
            print("AudioManager: bgm.mp3 not found in bundle.")
            return
        }

        do {
            bgmPlayer = try AVAudioPlayer(contentsOf: url)
            bgmPlayer?.numberOfLoops = -1
            bgmPlayer?.volume = 0.6
            bgmPlayer?.prepareToPlay()
        } catch {
            print("AudioManager: failed to prepare BGM — \(error)")
        }
    }

    func startBGM() {
        guard let player = bgmPlayer, !player.isPlaying else {
            return
        }

        player.play()
    }

    func pauseBGM() {
        bgmPlayer?.pause()
    }

    func resumeBGM() {
        guard let player = bgmPlayer, !player.isPlaying else {
            return
        }

        player.play()
    }

    func stopBGM() {
        bgmPlayer?.stop()
        bgmPlayer?.currentTime = 0
    }

    // MARK: - Interruption Handling

    private func observeInterruptions() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else {
            return
        }

        switch type {
        case .began:
            pauseBGM()

        case .ended:
            let options = AVAudioSession.InterruptionOptions(
                rawValue: info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            )

            if options.contains(.shouldResume) {
                resumeBGM()
            }

        @unknown default:
            break
        }
    }

    // MARK: - App Lifecycle

    private func observeAppLifecycle() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func appDidBackground() {
        pauseBGM()
        stopSkill1Loop()
    }

    @objc private func appWillForeground() {
        resumeBGM()
    }
}

// MARK: - SoundEffect

/// Daftar semua SFX `.wav`.
///
/// Nama file harus sama persis dengan asset/resource:
/// - breadImpact.wav
/// - buttonClick.wav
/// - explosion.wav
/// - laugh.wav
/// - quackEmotions.wav
/// - quackSfx.wav
/// - skill1.wav
/// - skill2.wav
/// - throw.wav
/// - toasterImpact.wav
enum SoundEffect: String, CaseIterable {
    case breadImpactFix
    case buttonClick
    case explosion
    case heal
    case laugh
    case quackAngry
    case quackSfx
    case skill1
    case skill2Fix
    case `throw`
    case toasterImpact

    var resourceName: String {
        rawValue
    }

    var fileExtension: String {
        "wav"
    }

    var fileName: String {
        "\(resourceName).\(fileExtension)"
    }
}
