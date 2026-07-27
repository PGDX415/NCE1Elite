//
//  LessonListView.swift
//  NCE1Elite
//
//  Main lesson list tab — flat list of all 144 lessons with search,
//  quick-jump scroll bar, and import interception.
//

import SwiftUI

/// Primary lesson list with search and quick-jump navigation.
struct LessonListView: View {
    let viewModel: LessonListViewModel
    let importService: ImportService
    var onSelectLesson: (Lesson) -> Void

    @State private var showImportAlert = false
    @State private var selectedForImport: Lesson?

    // Quick jump anchors: every 24 lessons
    private let jumpAnchors = [1, 25, 49, 73, 97, 121]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            // Search bar
            searchBar

            // Lesson list
            ScrollViewReader { proxy in
                List {
                    ForEach(viewModel.filteredLessons) { lesson in
                        LessonRowView(
                            lesson: lesson,
                            isAvailable: viewModel.isAvailable(lesson),
                            formattedDuration: viewModel.formattedDuration(for: lesson),
                            progress: viewModel.progress(for: lesson),
                            isFavorite: viewModel.isFavorite(lesson.id),
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

                // Quick jump bar
                quickJumpBar(proxy: proxy)
            }
        }
        .background(NCE1Colors.background)
        .alert("内容未导入", isPresented: $showImportAlert) {
            Button("去导入", role: .none) {
                // Opens settings for import
                // This would trigger a tab switch or modal
            }
            Button("取消", role: .cancel) {}
        } message: {
            if let lesson = selectedForImport {
                Text("Lesson \(lesson.lessonNumber): \(lesson.title) 的音频尚未导入。请前往设置 > 内容导入 添加音频文件。")
            }
        }
        .onAppear {
            viewModel.refreshProgress()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 10) {
            MiniUnionJack()

            VStack(alignment: .leading, spacing: 2) {
                Text("NCE1 Elite")
                    .font(NCE1Typography.brandTitle())
                    .foregroundStyle(NCE1Colors.oxfordBlue)
                Text("新概念英语 第一册 🇬🇧")
                    .font(NCE1Typography.caption())
                    .foregroundStyle(NCE1Colors.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(NCE1Colors.card)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(NCE1Colors.textSecondary)
            TextField("搜索课号或标题...", text: Binding(
                get: { viewModel.searchText },
                set: { viewModel.searchText = $0 }
            ))
            .font(NCE1Typography.body(16))
            .foregroundStyle(NCE1Colors.text)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(NCE1Colors.textSecondary)
                }
            }
        }
        .padding(10)
        .background(NCE1Colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(NCE1Colors.background)
    }

    // MARK: - Quick Jump Bar

    private func quickJumpBar(proxy: ScrollViewProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(jumpAnchors, id: \.self) { anchor in
                    Button {
                        withAnimation {
                            proxy.scrollTo(anchor, anchor: .top)
                        }
                    } label: {
                        Text("\(anchor)")
                            .font(NCE1Typography.monoDigit(13))
                            .foregroundStyle(NCE1Colors.oxfordBlue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(NCE1Colors.card)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(NCE1Colors.background)
    }

    // MARK: - Actions

    private func handleLessonTap(_ lesson: Lesson) {
        if viewModel.isAvailable(lesson) {
            onSelectLesson(lesson)
        } else {
            selectedForImport = lesson
            showImportAlert = true
        }
    }
}
