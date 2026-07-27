//
//  LessonRowView.swift
//  NCE1Elite
//
//  Single row displaying lesson number, title, duration/import status,
//  favorite star, and playback progress bar.
//

import SwiftUI

/// A row in the lesson list representing one lesson.
struct LessonRowView: View {
    let lesson: Lesson
    let isAvailable: Bool
    let formattedDuration: String
    let progress: Double
    let isFavorite: Bool
    let onFavorite: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                HStack(spacing: 12) {
                    // Lesson number
                    Text("\(lesson.lessonNumber)")
                        .font(NCE1Typography.monoDigit(16))
                        .foregroundStyle(NCE1Colors.textSecondary)
                        .frame(width: 36, alignment: .trailing)

                    // Title and meta
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lesson.title)
                            .font(NCE1Typography.lessonTitle())
                            .foregroundStyle(NCE1Colors.text)
                            .lineLimit(2)

                        HStack(spacing: 8) {
                            if isAvailable {
                                Text(formattedDuration)
                                    .font(NCE1Typography.caption())
                                    .foregroundStyle(NCE1Colors.textSecondary)
                            } else {
                                Label("需导入", systemImage: "icloud.and.arrow.down")
                                    .font(NCE1Typography.caption())
                                    .foregroundStyle(NCE1Colors.textSecondary)
                            }
                        }
                    }

                    Spacer()

                    // Favorite star
                    FavoriteStarButton(isFavorite: isFavorite, action: onFavorite)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                // Progress bar
                if progress > 0 {
                    LessonProgressBar(progress: progress)
                        .padding(.horizontal, 16)
                }

                NCE1Divider()
                    .padding(.leading, 16)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
