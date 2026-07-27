//
//  AudioPlayerService.swift
//  NCE1Elite
//
//  Core audio playback service with Now Playing integration,
//  remote command handling, sleep timer, and loop support.
//

import AVFoundation
import MediaPlayer
import UIKit

/// Loop mode for audio playback.
enum LoopMode {
    case none       // Stop when the current track ends
    case one        // Repeat the current track
    case list       // Advance to next track; wraps around
}

/// Delegate protocol for audio player events.
protocol AudioPlayerServiceDelegate: AnyObject {
    func audioPlayerDidFinishPlaying()
    func audioPlayerDidUpdateProgress(currentTime: TimeInterval, duration: TimeInterval)
}

/// Central audio playback service.
final class AudioPlayerService: NSObject {
    // MARK: - State
    private(set) var isPlaying: Bool = false
    private(set) var currentLesson: Lesson?
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var playbackRate: Float = 1.0
    private(set) var loopMode: LoopMode = .none
    private(set) var sleepTimerRemaining: TimeInterval = 0
    private(set) var isSleepTimerActive: Bool = false

    // MARK: - Dependencies
    private let importService: ImportService
    weak var delegate: AudioPlayerServiceDelegate?

    // MARK: - Audio Engine
    private var player: AVAudioPlayer?
    private var displayLink: CADisplayLink?
    private var sleepTimer: Timer?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    // MARK: - Init
    init(importService: ImportService) {
        self.importService = importService
        super.init()
        configureAudioSession()
        configureRemoteCommands()
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay])
            try session.setActive(true)
        } catch {
            print("❌ AudioPlayerService: Failed to configure audio session: \(error)")
        }
    }

    // MARK: - Playback Control

    /// Begins playback of a given lesson with rate control support.
    func play(lesson: Lesson) {
        // If already playing the same lesson, toggle pause
        if currentLesson?.id == lesson.id, player != nil {
            if isPlaying {
                pause()
            } else {
                resume()
            }
            return
        }

        // Stop any existing playback
        stop()

        // Load audio URL
        guard let audioURL = importService.audioURL(for: lesson) else {
            print("⚠️ AudioPlayerService: No audio found for lesson \(lesson.id)")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: audioURL)
            player?.delegate = self
            player?.enableRate = true
            player?.rate = playbackRate
            player?.prepareToPlay()
            player?.play()

            currentLesson = lesson
            isPlaying = true
            duration = player?.duration ?? 0

            startDisplayLink()
            updateNowPlayingInfo()
            beginBackgroundTask()

            delegate?.audioPlayerDidUpdateProgress(currentTime: 0, duration: duration)
        } catch {
            print("❌ AudioPlayerService: Failed to create player: \(error)")
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopDisplayLink()
        updateNowPlayingInfo()
    }

    func resume() {
        player?.play()
        isPlaying = true
        startDisplayLink()
        updateNowPlayingInfo()
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentLesson = nil
        currentTime = 0
        duration = 0
        stopDisplayLink()
        stopSleepTimer()
        endBackgroundTask()
    }

    // MARK: - Seek

    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
        updateNowPlayingInfo()
        delegate?.audioPlayerDidUpdateProgress(currentTime: time, duration: duration)
    }

    func seekRelative(_ delta: TimeInterval) {
        guard let player = player else { return }
        let newTime = max(0, min(player.duration, player.currentTime + delta))
        seek(to: newTime)
    }

    // MARK: - Playback Rate

    func setRate(_ rate: Float) {
        playbackRate = rate
        player?.rate = rate
        updateNowPlayingInfo()
    }

    // MARK: - Loop Mode

    func setLoopMode(_ mode: LoopMode) {
        loopMode = mode
    }

    // MARK: - Sleep Timer

    func startSleepTimer(minutes: Int) {
        stopSleepTimer()
        sleepTimerRemaining = TimeInterval(minutes * 60)
        isSleepTimerActive = true

        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.sleepTimerRemaining -= 1
            if self.sleepTimerRemaining <= 0 {
                self.pause()
                self.stopSleepTimer()
            }
        }
    }

    func stopSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        isSleepTimerActive = false
        sleepTimerRemaining = 0
    }

    // MARK: - Display Link (Progress Updates)

    private func startDisplayLink() {
        stopDisplayLink()
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkFired))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func displayLinkFired() {
        guard let player = player else { return }
        currentTime = player.currentTime
        delegate?.audioPlayerDidUpdateProgress(currentTime: currentTime, duration: duration)
        updateNowPlayingInfo()
    }

    // MARK: - Background Task

    private func beginBackgroundTask() {
        endBackgroundTask()
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(expirationHandler: { [weak self] in
            self?.endBackgroundTask()
        })
    }

    private func endBackgroundTask() {
        guard backgroundTaskID != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
    }

    // MARK: - Now Playing Info

    private func updateNowPlayingInfo() {
        guard let lesson = currentLesson else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: lesson.title,
            MPMediaItemPropertyAlbumTitle: "新概念英语 第一册",
            MPMediaItemPropertyArtist: "NCE1 Elite",
            MPNowPlayingInfoPropertyPlaybackRate: playbackRate,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0,
        ]

        // Artwork
        if let image = generateArtwork(lessonNumber: lesson.lessonNumber, title: lesson.title) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    /// Generates a simple artwork image for the lock screen.
    private func generateArtwork(lessonNumber: Int, title: String) -> UIImage? {
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // Background
            let bgColor = UIColor(red: 0.1020, green: 0.2275, blue: 0.4196, alpha: 1) // Oxford Blue
            bgColor.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            // Title
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor.white,
            ]
            let text = "Lesson \(lessonNumber)"
            let textSize = text.size(withAttributes: attrs)
            text.draw(at: CGPoint(x: (size.width - textSize.width) / 2, y: size.height / 2 - 60), withAttributes: attrs)

            // Lesson title
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
                .foregroundColor: UIColor(red: 0.8314, green: 0.6588, blue: 0.2627, alpha: 1), // Antique Gold
            ]
            let titleSize = title.size(withAttributes: titleAttrs)
            title.draw(at: CGPoint(x: (size.width - titleSize.width) / 2, y: size.height / 2 + 10), withAttributes: titleAttrs)

            // NCE1 Elite branding
            let brandAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: UIColor(red: 0.7216, green: 0.5922, blue: 0.2471, alpha: 1),
            ]
            let brand = "NCE1 Elite"
            let brandSize = brand.size(withAttributes: brandAttrs)
            brand.draw(at: CGPoint(x: (size.width - brandSize.width) / 2, y: size.height / 2 + 50), withAttributes: brandAttrs)
        }
    }

    // MARK: - Remote Commands

    private func configureRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            self?.seekRelative(event.interval)
            return .success
        }

        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            self?.seekRelative(-event.interval)
            return .success
        }

        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: event.positionTime)
            return .success
        }

        commandCenter.changePlaybackRateCommand.supportedPlaybackRates = [0.75, 1.0, 1.25, 1.5]
        commandCenter.changePlaybackRateCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackRateCommandEvent else { return .commandFailed }
            self?.setRate(event.playbackRate)
            return .success
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard flag else { return }
        delegate?.audioPlayerDidFinishPlaying()
    }
}
