//
//  FavoritesViewModel.swift
//  NCE1Elite
//
//  ViewModel for the favorites tab — provides the list of favorited lessons.
//

import SwiftUI
import SwiftData

/// Manages the favorites list.
@Observable
final class FavoritesViewModel {
    // MARK: - Published State
    var favoriteLessons: [Lesson] = []

    // MARK: - Dependencies
    private let dataService: LessonDataService
    private let importService: ImportService
    private let listViewModel: LessonListViewModel
    private var modelContext: ModelContext?

    // MARK: - Init
    init(dataService: LessonDataService, importService: ImportService, listViewModel: LessonListViewModel) {
        self.dataService = dataService
        self.importService = importService
        self.listViewModel = listViewModel
    }

    /// Loads favorited lessons from the current state.
    func loadFavorites() {
        favoriteLessons = dataService.lessons.filter {
            listViewModel.favoriteLessonIDs.contains($0.id)
        }
    }

    /// Returns whether audio is available for the lesson.
    func isAvailable(_ lesson: Lesson) -> Bool {
        importService.isAudioAvailable(for: lesson)
    }

    /// Formatted duration string.
    func formattedDuration(for lesson: Lesson) -> String {
        listViewModel.formattedDuration(for: lesson)
    }

    /// Toggles favorite status.
    func toggleFavorite(_ lessonId: Int) {
        listViewModel.toggleFavorite(lessonId)
        loadFavorites()
    }

    /// Injects the SwiftData model context.
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadFavorites()
    }
}
