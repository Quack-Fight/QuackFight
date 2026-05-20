//
//  AudioManager.swift
//  QuackFight
//
//  Created by Justin Chow on 20/05/26.
//

import AVFoundation
import UIKit

final class AudioManager: NSObject {

    static let shared = AudioManager()

    private var bgmPlayer: AVAudioPlayer?

    private override init() {
        super.init()
        prepareBGM()
        observeInterruptions()
        observeAppLifecycle()
    }

    // MARK: - BGM

    private func prepareBGM() {
        guard let url = Bundle.main.url(forResource: "bgm", withExtension: "mp3") else {
            print("AudioManager: bgm.mp3 not found in bundle — add it to the Xcode target's Copy Bundle Resources phase")
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
        guard let player = bgmPlayer, !player.isPlaying else { return }
        player.play()
    }

    func pauseBGM() {
        bgmPlayer?.pause()
    }

    func resumeBGM() {
        guard let player = bgmPlayer, !player.isPlaying else { return }
        player.play()
    }

    // MARK: - Interruption Handling (phone calls, Siri, etc.)

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
        else { return }

        switch type {
        case .began:
            pauseBGM()
        case .ended:
            let options = AVAudioSession.InterruptionOptions(
                rawValue: info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            )
            if options.contains(.shouldResume) { resumeBGM() }
        @unknown default:
            break
        }
    }

    // MARK: - App Lifecycle

    private func observeAppLifecycle() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(appDidBackground),
            name: UIApplication.didEnterBackgroundNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(appWillForeground),
            name: UIApplication.willEnterForegroundNotification, object: nil
        )
    }

    @objc private func appDidBackground() { pauseBGM() }
    @objc private func appWillForeground() { resumeBGM() }
}
