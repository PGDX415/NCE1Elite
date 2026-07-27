//
//  Lesson.swift
//  NCE1Elite
//
//  Data model for a single lesson.
//

import Foundation

/// Represents one lesson (1–144) in New Concept English Book 1.
struct Lesson: Identifiable, Codable, Equatable {
    let id: Int              // 1–144
    let lessonNumber: Int     // 1–144 (same as id, preserved for display formatting)
    let title: String
    let audioFileName: String // e.g. "001-002－Excuse Me"
    var englishText: String?  // Embedded English text (for development)
    var chineseText: String?  // Embedded Chinese translation (AI-generated)
    var durationSeconds: Double // Populated by AVAudioPlayer / AVURLAsset at runtime

    enum CodingKeys: String, CodingKey {
        case id
        case lessonNumber
        case title
        case audioFileName
        case englishText
        case chineseText
        case durationSeconds
    }

    /// Returns a clean display string like "Lesson 1"
    var displayNumber: String {
        "Lesson \(lessonNumber)"
    }

    /// Clean English text without LRC metadata header lines
    var cleanEnglishText: String? {
        guard let text = englishText else { return nil }
        let lines = text.components(separatedBy: "\n")
        let filtered = lines.filter { line in
            !line.hasPrefix("[al:") &&
            !line.hasPrefix("[ar:") &&
            !line.hasPrefix("[ti:") &&
            !line.hasPrefix("[by:") &&
            !line.hasPrefix("[offset:") &&
            !line.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return filtered.joined(separator: "\n")
    }
}
