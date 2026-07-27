//
//  LessonProgress.swift
//  NCE1Elite
//
//  SwiftData model for persisting user progress per lesson.
//

import Foundation
import SwiftData

/// Tracks a user's playback and preference state for a single lesson.
@Model
final class LessonProgress {
    @Attribute(.unique) var lessonId: Int
    var isFavorite: Bool = false
    var lastPlayedPosition: Double = 0
    var isCompleted: Bool = false
    var lastPlayedDate: Date?

    init(lessonId: Int,
         isFavorite: Bool = false,
         lastPlayedPosition: Double = 0,
         isCompleted: Bool = false,
         lastPlayedDate: Date? = nil) {
        self.lessonId = lessonId
        self.isFavorite = isFavorite
        self.lastPlayedPosition = lastPlayedPosition
        self.isCompleted = isCompleted
        self.lastPlayedDate = lastPlayedDate
    }
}
