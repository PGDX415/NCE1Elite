//
//  ImportService.swift
//  NCE1Elite
//
//  Manages user-imported audio and text files, checks availability,
//  and provides audio duration caching.
//

import Foundation
import AVFoundation

/// Observes changes to the app's Documents directory for imported content.
final class ImportService {
    /// Lesson IDs that are available as sample/preview from the bundle.
    /// During development: all 144 lessons. Before App Store submission: change to [1, 2].
    var sampleLessonIDs: Set<Int> = Set(1...144)

    /// Cached audio durations keyed by lesson ID.
    private var durationCache: [Int: Double] = [:]

    /// Base directories for user-imported content.
    private var audioDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("ImportedAudio", isDirectory: true)
    }

    private var textsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("ImportedTexts", isDirectory: true)
    }

    init() {
        createDirectories()
    }

    private func createDirectories() {
        try? FileManager.default.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: textsDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Audio Availability

    /// Returns the URL for a lesson's audio file, checking user imports first, then bundle.
    func audioURL(for lesson: Lesson) -> URL? {
        // Try user-imported first
        let userURL = audioDirectory.appendingPathComponent("\(lesson.audioFileName).mp3")
        if FileManager.default.fileExists(atPath: userURL.path) {
            return userURL
        }

        // Try bundle (sample lessons only)
        if sampleLessonIDs.contains(lesson.id) {
            // Try multiple subdirectory paths (Xcode folder structure varies)
            let subdirs = ["Resources/Audio", "Audio", nil as String?]
            let extensions = ["mp3", "MP3"]
            for subdir in subdirs {
                for ext in extensions {
                    if let url = Bundle.main.url(forResource: lesson.audioFileName,
                                                  withExtension: ext,
                                                  subdirectory: subdir ?? "") {
                        return url
                    }
                }
            }
            // Also try direct resource without subdirectory
            for ext in extensions {
                if let url = Bundle.main.url(forResource: lesson.audioFileName,
                                              withExtension: ext) {
                    return url
                }
            }
        }

        return nil
    }

    /// Returns true if audio is available for this lesson.
    func isAudioAvailable(for lesson: Lesson) -> Bool {
        audioURL(for: lesson) != nil
    }

    // MARK: - Audio Duration

    /// Returns the duration in seconds for a lesson's audio, using cache.
    func audioDuration(for lesson: Lesson) -> Double {
        if let cached = durationCache[lesson.id] {
            return cached
        }

        guard let url = audioURL(for: lesson) else { return 0 }

        let asset = AVURLAsset(url: url)
        let duration = asset.duration.seconds
        guard duration.isFinite, duration > 0 else { return 0 }

        durationCache[lesson.id] = duration
        return duration
    }

    // MARK: - Text Import

    /// Returns user-imported text for a lesson, if available.
    func importedText(for lessonId: Int) -> (english: String?, chinese: String?)? {
        let url = textsDirectory.appendingPathComponent("Lesson\(lessonId).json")
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return nil
        }
        return (json["englishText"], json["chineseText"])
    }

    /// Returns the best available English text: user-imported > bundle.
    func englishText(for lesson: Lesson) -> String? {
        if let imported = importedText(for: lesson.id)?.english, !imported.isEmpty {
            return imported
        }
        return lesson.cleanEnglishText
    }

    /// Returns the best available Chinese text: user-imported > bundle.
    func chineseText(for lesson: Lesson) -> String? {
        if let imported = importedText(for: lesson.id)?.chinese, !imported.isEmpty {
            return imported
        }
        return lesson.chineseText
    }

    // MARK: - Import Helpers

    /// Batch imports audio files from a given directory.
    func importAudioFiles(from sourceDir: URL) -> Int {
        guard let files = try? FileManager.default.contentsOfDirectory(at: sourceDir,
                                                                        includingPropertiesForKeys: nil) else {
            return 0
        }
        var count = 0
        for file in files where file.pathExtension.lowercased() == "mp3" {
            let dest = audioDirectory.appendingPathComponent(file.lastPathComponent)
            try? FileManager.default.copyItem(at: file, to: dest)
            count += 1
        }
        // Clear duration cache after import
        durationCache.removeAll()
        return count
    }

    /// Batch imports lesson text JSON files from a given directory.
    func importTextFiles(from sourceDir: URL) -> Int {
        guard let files = try? FileManager.default.contentsOfDirectory(at: sourceDir,
                                                                        includingPropertiesForKeys: nil) else {
            return 0
        }
        var count = 0
        for file in files where file.pathExtension.lowercased() == "json" {
            let dest = textsDirectory.appendingPathComponent(file.lastPathComponent)
            try? FileManager.default.copyItem(at: file, to: dest)
            count += 1
        }
        return count
    }

    /// Clears all user-imported content.
    func clearAllImports() {
        try? FileManager.default.removeItem(at: audioDirectory)
        try? FileManager.default.removeItem(at: textsDirectory)
        durationCache.removeAll()
        createDirectories()
    }
}
