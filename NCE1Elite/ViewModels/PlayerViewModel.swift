//
//  PlayerViewModel.swift
//  NCE1Elite
//
//  ViewModel bridging audio playback to UI state.
//  Handles 4-second countdown, playback control, progress persistence,
//  and night reading mode switching.
//

import SwiftUI
import Combine
import SwiftData

/// Identifiable wrapper for triggering fullScreenCover.
struct PlayerPresentation: Identifiable {
    let id = UUID()
}

/// Manages player UI state and audio interactions.
@Observable
final class PlayerViewModel {
    // MARK: - Published State
    var currentLesson: Lesson?
    var isPlaying: Bool = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var playbackRate: Float = 1.0
    var loopMode: LoopMode = .none
    var sleepTimerMinutes: Int = 0
    var isSleepTimerActive: Bool = false
    var sleepTimerRemaining: TimeInterval = 0

    // Countdown
    var countdownSeconds: Int = 0
    var isCountingDown: Bool = false

    // Display mode
    var isReadingMode: Bool = false

    // Available speeds
    let availableSpeeds: [Float] = [0.75, 1.0, 1.25, 1.5]

    // Sleep timer options
    let sleepTimerOptions: [Int] = [15, 30, 45, 60]

    // MARK: - Dependencies
    private let audioService: AudioPlayerService
    private let importService: ImportService
    private let listViewModel: LessonListViewModel
    private var modelContext: ModelContext?
    private var countdownTask: Task<Void, Never>?

    // MARK: - Init
    init(audioService: AudioPlayerService, importService: ImportService, listViewModel: LessonListViewModel) {
        self.audioService = audioService
        self.importService = importService
        self.listViewModel = listViewModel
        audioService.delegate = self
    }

    // MARK: - Playback Actions

    /// Starts the pre-play countdown, then plays.
    func play(lesson: Lesson) {
        // Cancel any existing countdown
        cancelCountdown()

        currentLesson = lesson
        startCountdown()
    }

    /// Skips the countdown and plays immediately.
    func skipCountdown() {
        cancelCountdown()
        startPlayback()
    }

    /// Cancels the countdown without playing.
    func cancelCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
        isCountingDown = false
        countdownSeconds = 0
    }

    /// Toggles play/pause.
    func togglePlayPause() {
        guard let lesson = currentLesson else { return }
        if isPlaying {
            audioService.pause()
        } else {
            audioService.play(lesson: lesson)
        }
    }

    /// Plays the previous lesson in the flat list.
    func playPrevious() {
        guard let current = currentLesson else { return }

        let allLessons = listViewModel.lessons
        guard let index = allLessons.firstIndex(where: { $0.id == current.id }) else { return }
        let prevIndex = index > 0 ? index - 1 : allLessons.count - 1

        // Reset to listening mode when switching lessons
        isReadingMode = false
        play(lesson: allLessons[prevIndex])
    }

    /// Plays the next lesson in the flat list.
    func playNext() {
        guard let current = currentLesson else { return }

        let allLessons = listViewModel.lessons
        guard let index = allLessons.firstIndex(where: { $0.id == current.id }) else { return }
        let nextIndex = index < allLessons.count - 1 ? index + 1 : 0

        // Reset to listening mode when switching lessons
        isReadingMode = false
        play(lesson: allLessons[nextIndex])
    }

    // MARK: - Seek

    func seek(to time: TimeInterval) {
        audioService.seek(to: time)
    }

    func seekForward15() {
        audioService.seekRelative(15)
    }

    func seekBackward15() {
        audioService.seekRelative(-15)
    }

    // MARK: - Rate

    func setRate(_ rate: Float) {
        audioService.setRate(rate)
        playbackRate = rate
    }

    // MARK: - Loop

    func cycleLoopMode() {
        switch loopMode {
        case .none: loopMode = .one
        case .one: loopMode = .list
        case .list: loopMode = .none
        }
        audioService.setLoopMode(loopMode)
    }

    // MARK: - Sleep Timer

    func toggleSleepTimer(minutes: Int) {
        if isSleepTimerActive && sleepTimerMinutes == minutes {
            // Toggle off
            audioService.stopSleepTimer()
            isSleepTimerActive = false
            sleepTimerMinutes = 0
            sleepTimerRemaining = 0
        } else {
            audioService.startSleepTimer(minutes: minutes)
            isSleepTimerActive = true
            sleepTimerMinutes = minutes
            sleepTimerRemaining = TimeInterval(minutes * 60)
        }
    }

    // MARK: - Reading Mode

    func toggleReadingMode() {
        isReadingMode.toggle()
    }

    /// Returns the font size from UserDefaults (synchronized with @AppStorage in SettingsView).
    var lessonFontSize: CGFloat {
        let stored = UserDefaults.standard.double(forKey: "lessonFontSize")
        if stored >= 13 && stored <= 24 {
            return stored
        }
        return 17 // default
    }

    /// Returns English text for the current lesson (user-imported or bundle).
    var englishText: String? {
        guard let lesson = currentLesson else { return nil }
        return importService.englishText(for: lesson)
    }

    /// Returns Chinese text for the current lesson (user-imported or bundle).
    var chineseText: String? {
        guard let lesson = currentLesson else { return nil }
        return importService.chineseText(for: lesson)
    }

    /// Injects the SwiftData model context.
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Persistence

    /// Saves the current playback position.
    private func saveProgress() {
        guard let lesson = currentLesson else { return }
        listViewModel.saveProgress(
            lessonId: lesson.id,
            position: currentTime,
            isCompleted: duration > 0 && currentTime >= duration - 1.0
        )
    }

    // MARK: - Countdown

    private func startCountdown() {
        isCountingDown = true
        countdownSeconds = 4

        countdownTask = Task {
            for i in (0...4).reversed() {
                guard !Task.isCancelled else { return }
                countdownSeconds = i
                if i > 0 {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
            guard !Task.isCancelled else { return }
            isCountingDown = false
            startPlayback()
        }
    }

    private func startPlayback() {
        guard let lesson = currentLesson else { return }
        audioService.play(lesson: lesson)
    }
}

// MARK: - AudioPlayerServiceDelegate

extension PlayerViewModel: AudioPlayerServiceDelegate {
    func audioPlayerDidFinishPlaying() {
        saveProgress()

        switch loopMode {
        case .none:
            // Do nothing; stop and show the lesson ended
            audioService.stop()
            isPlaying = false
        case .one:
            // Replay
            guard let lesson = currentLesson else { return }
            audioService.play(lesson: lesson)
        case .list:
            // Advance to next
            playNext()
        }
    }

    func audioPlayerDidUpdateProgress(currentTime: TimeInterval, duration: TimeInterval) {
        self.currentTime = currentTime
        self.duration = duration

        // Sync sleep timer
        self.isSleepTimerActive = audioService.isSleepTimerActive
        self.sleepTimerRemaining = audioService.sleepTimerRemaining

        // Auto-save every 5 seconds
        if Int(currentTime) % 5 == 0 && Int(currentTime) != 0 {
            saveProgress()
        }
    }
}
