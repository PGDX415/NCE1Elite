//
//  LessonDataService.swift
//  NCE1Elite
//
//  Service to load and provide lesson metadata from the bundled lessons.json.
//

import Foundation

/// Provides lesson data from the bundled `lessons.json`.
final class LessonDataService {
    /// All lessons, sorted by lesson number ascending.
    private(set) var lessons: [Lesson] = []

    init() {
        loadLessons()
    }

    /// Loads lessons from the bundled JSON resource.
    private func loadLessons() {
        guard let url = Bundle.main.url(forResource: "lessons", withExtension: "json") else {
            print("⚠️ LessonDataService: lessons.json not found in bundle.")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            lessons = try decoder.decode([Lesson].self, from: data).sorted(by: { $0.lessonNumber < $1.lessonNumber })
            print("✅ LessonDataService: Loaded \(lessons.count) lessons.")
        } catch {
            print("❌ LessonDataService: Failed to decode lessons.json: \(error)")
        }
    }

    /// Returns a lesson by ID (1-indexed).
    func lesson(for id: Int) -> Lesson? {
        lessons.first { $0.id == id }
    }
}
