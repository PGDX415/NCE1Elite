//
//  LessonListViewModel.swift
//  NCE1Elite
//
//  ViewModel for the lesson list — loads lessons, manages search,
//  favorites cache, and progress tracking.
//

import SwiftUI
import SwiftData

/// Manages the lesson list state and interactions.
@Observable
final class LessonListViewModel {
    // MARK: - Published State
    var lessons: [Lesson] = []
    var searchText: String = ""
    var favoriteLessonIDs: Set<Int> = []
    var progressMap: [Int: Double] = [:] // lessonId -> progress (0.0...1.0)
    var audioDurationCache: [Int: Double] = [:] // lessonId -> duration in seconds

    // MARK: - Dependencies
    private let dataService: LessonDataService
    private let importService: ImportService
    private var modelContext: ModelContext?

    // MARK: - Init
    init(dataService: LessonDataService, importService: ImportService) {
        self.dataService = dataService
        self.importService = importService
        self.lessons = dataService.lessons
    }

    /// Sets the model context for SwiftData operations.
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadFavoritesAndProgress()
    }

    // MARK: - Filtered Lessons

    /// Lessons filtered by search text.
    var filteredLessons: [Lesson] {
        guard !searchText.isEmpty else { return lessons }
        let query = searchText.lowercased()
        return lessons.filter {
            String($0.lessonNumber).contains(query) ||
            $0.title.lowercased().contains(query)
        }
    }

    // MARK: - Progress

    /// Returns the playback progress (0.0–1.0) for a lesson.
    func progress(for lesson: Lesson) -> Double {
        if let cached = progressMap[lesson.id] {
            return cached
        }
        return 0
    }

    /// Returns the audio duration for a lesson.
    func audioDuration(for lesson: Lesson) -> Double {
        if let cached = audioDurationCache[lesson.id] {
            return cached
        }
        let duration = importService.audioDuration(for: lesson)
        audioDurationCache[lesson.id] = duration
        return duration
    }

    /// Returns formatted duration string like "1:23".
    func formattedDuration(for lesson: Lesson) -> String {
        let dur = audioDuration(for: lesson)
        guard dur > 0 else { return "--:--" }
        let minutes = Int(dur) / 60
        let seconds = Int(dur) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Returns whether audio is available for the lesson.
    func isAvailable(_ lesson: Lesson) -> Bool {
        importService.isAudioAvailable(for: lesson)
    }

    // MARK: - Favorites

    func isFavorite(_ lessonId: Int) -> Bool {
        favoriteLessonIDs.contains(lessonId)
    }

    func toggleFavorite(_ lessonId: Int) {
        guard let context = modelContext else { return }
        if favoriteLessonIDs.contains(lessonId) {
            favoriteLessonIDs.remove(lessonId)
            updateProgress(lessonId: lessonId, isFavorite: false)
        } else {
            favoriteLessonIDs.insert(lessonId)
            updateProgress(lessonId: lessonId, isFavorite: true)
        }
        try? context.save()
    }

    // MARK: - Data Loading

    private func loadFavoritesAndProgress() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<LessonProgress>()
        guard let all = try? context.fetch(descriptor) else { return }

        favoriteLessonIDs = Set(all.filter { $0.isFavorite }.map { $0.lessonId })

        for progress in all {
            let duration = audioDurationCache[progress.lessonId] ?? 0
            if duration > 0 {
                progressMap[progress.lessonId] = progress.lastPlayedPosition / duration
            }
        }
    }

    /// Reloads all progress data from SwiftData.
    func refreshProgress() {
        loadFavoritesAndProgress()
        // Refresh all duration caches
        for lesson in lessons {
            _ = audioDuration(for: lesson)
        }
        // Recalculate progress map
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<LessonProgress>()
        guard let all = try? context.fetch(descriptor) else { return }
        progressMap.removeAll()
        for progress in all {
            let duration = audioDuration(for: dataService.lesson(for: progress.lessonId) ?? Lesson(id: progress.lessonId, lessonNumber: progress.lessonId, title: "", audioFileName: "", durationSeconds: 0))
            if duration > 0 {
                progressMap[progress.lessonId] = progress.lastPlayedPosition / duration
            }
        }
    }

    // MARK: - Persistence Helpers

    private func getOrCreateProgress(lessonId: Int) -> LessonProgress? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<LessonProgress>(
            predicate: #Predicate { $0.lessonId == lessonId }
        )
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let new = LessonProgress(lessonId: lessonId)
        context.insert(new)
        return new
    }

    private func updateProgress(lessonId: Int, isFavorite: Bool? = nil, position: Double? = nil, isCompleted: Bool? = nil) {
        guard let progress = getOrCreateProgress(lessonId: lessonId) else { return }
        if let isFavorite = isFavorite {
            progress.isFavorite = isFavorite
        }
        if let position = position {
            progress.lastPlayedPosition = position
        }
        if let isCompleted = isCompleted {
            progress.isCompleted = isCompleted
        }
        progress.lastPlayedDate = Date()
    }

    /// Call from PlayerViewModel to save playback position.
    func saveProgress(lessonId: Int, position: Double, isCompleted: Bool) {
        updateProgress(lessonId: lessonId, position: position, isCompleted: isCompleted)
        try? modelContext?.save()

        let duration = audioDurationCache[lessonId] ?? 1
        progressMap[lessonId] = duration > 0 ? position / duration : 0
    }
}
