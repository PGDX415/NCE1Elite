//
//  FavoritesView.swift
//  NCE1Elite
//
//  Favorites tab — lists all favorited lessons with playback access.
//

import SwiftUI

/// Displays lessons marked as favorites.
struct FavoritesView: View {
    let viewModel: FavoritesViewModel
    var onSelectLesson: (Lesson) -> Void

    @State private var showImportAlert = false
    @State private var selectedForImport: Lesson?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("收藏")
                        .font(NCE1Typography.brandTitle())
                        .foregroundStyle(NCE1Colors.oxfordBlue)
                    Text("已收藏 \(viewModel.favoriteLessons.count) 课")
                        .font(NCE1Typography.caption())
                        .foregroundStyle(NCE1Colors.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(NCE1Colors.card)

            if viewModel.favoriteLessons.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "star")
                        .font(.system(size: 48))
                        .foregroundStyle(NCE1Colors.textSecondary.opacity(0.5))
                    Text("还没有收藏的课程")
                        .font(NCE1Typography.body(17))
                        .foregroundStyle(NCE1Colors.textSecondary)
                    Text("在课程列表中点击星标即可收藏")
                        .font(NCE1Typography.caption())
                        .foregroundStyle(NCE1Colors.textSecondary.opacity(0.7))
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.favoriteLessons) { lesson in
                        LessonRowView(
                            lesson: lesson,
                            isAvailable: viewModel.isAvailable(lesson),
                            formattedDuration: viewModel.formattedDuration(for: lesson),
                            progress: 0,
                            isFavorite: true,
                            onFavorite: {
                                viewModel.toggleFavorite(lesson.id)
                            },
                            onTap: {
                                handleLessonTap(lesson)
                            }
                        )
                        .id(lesson.id)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(NCE1Colors.background)
            }
        }
        .background(NCE1Colors.background)
        .alert("内容未导入", isPresented: $showImportAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            if let lesson = selectedForImport {
                Text("Lesson \(lesson.lessonNumber): \(lesson.title) 的音频尚未导入。请前往设置 > 内容导入 添加音频文件。")
            }
        }
        .onAppear {
            viewModel.loadFavorites()
        }
    }

    private func handleLessonTap(_ lesson: Lesson) {
        if viewModel.isAvailable(lesson) {
            onSelectLesson(lesson)
        } else {
            selectedForImport = lesson
            showImportAlert = true
        }
    }
}
