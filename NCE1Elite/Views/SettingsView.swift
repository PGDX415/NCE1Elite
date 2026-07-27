//
//  SettingsView.swift
//  NCE1Elite
//
//  App settings: font size, display mode, content import,
//  import guide, and privacy policy.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Color Scheme Mode

enum ColorSchemeMode: String, CaseIterable {
    case system = "跟随系统"
    case light = "浅色"
    case dark = "深色"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("lessonFontSize") private var lessonFontSize: Double = 17
    @AppStorage("colorSchemeMode") private var colorSchemeModeRaw: String = ColorSchemeMode.system.rawValue

    let importService: ImportService

    @State private var showImportGuide = false
    @State private var showPrivacyPolicy = false
    @State private var importMessage: String = ""

    private var colorSchemeMode: ColorSchemeMode {
        ColorSchemeMode(rawValue: colorSchemeModeRaw) ?? .system
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Display Settings
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("字体大小")
                                .foregroundStyle(NCE1Colors.text)
                            Spacer()
                            Text("\(Int(lessonFontSize))pt")
                                .font(NCE1Typography.monoDigit(14))
                                .foregroundStyle(NCE1Colors.textSecondary)
                        }
                        Slider(value: $lessonFontSize, in: 13...24, step: 1) {
                            Text("字体大小")
                        }
                        .tint(NCE1Colors.oxfordBlue)

                        Text("Aa Bb Cc · 新概念英语")
                            .font(NCE1Typography.body(CGFloat(lessonFontSize)))
                            .foregroundStyle(NCE1Colors.text)
                            .padding(.vertical, 4)
                    }

                    Picker("显示模式", selection: $colorSchemeModeRaw) {
                        ForEach(ColorSchemeMode.allCases, id: \.rawValue) { mode in
                            Text(mode.rawValue).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(NCE1Colors.oxfordBlue)
                } header: {
                    Text("显示设置")
                        .foregroundStyle(NCE1Colors.textSecondary)
                }
                .listRowBackground(NCE1Colors.card)

                // MARK: Content Import
                Section {
                    Button {
                        importAudio()
                    } label: {
                        HStack {
                            Image(systemName: "music.note.list")
                                .foregroundStyle(NCE1Colors.oxfordBlue)
                            Text("导入音频文件 (MP3)")
                                .foregroundStyle(NCE1Colors.text)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(NCE1Colors.textSecondary)
                        }
                    }

                    Button {
                        importTexts()
                    } label: {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundStyle(NCE1Colors.oxfordBlue)
                            Text("导入课文文本 (JSON)")
                                .foregroundStyle(NCE1Colors.text)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(NCE1Colors.textSecondary)
                        }
                    }

                    if !importMessage.isEmpty {
                        Text(importMessage)
                            .font(NCE1Typography.caption())
                            .foregroundStyle(NCE1Colors.antiqueGold)
                    }
                } header: {
                    Text("内容导入")
                        .foregroundStyle(NCE1Colors.textSecondary)
                } footer: {
                    Text("支持从「文件」App 批量导入音频和课文文本。音频按文件名自动匹配课号。")
                        .foregroundStyle(NCE1Colors.textSecondary)
                }
                .listRowBackground(NCE1Colors.card)

                // MARK: Info
                Section {
                    Button {
                        showImportGuide = true
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(NCE1Colors.oxfordBlue)
                            Text("导入指南")
                                .foregroundStyle(NCE1Colors.text)
                        }
                    }

                    Button {
                        showPrivacyPolicy = true
                    } label: {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundStyle(NCE1Colors.oxfordBlue)
                            Text("隐私政策")
                                .foregroundStyle(NCE1Colors.text)
                        }
                    }
                } header: {
                    Text("关于")
                        .foregroundStyle(NCE1Colors.textSecondary)
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NCE1 Elite v1.0")
                            .foregroundStyle(NCE1Colors.textSecondary)
                        Text("新概念英语 第一册 · 英音发音")
                            .foregroundStyle(NCE1Colors.textSecondary)
                        Text("App 不包含版权内容，用户需自行导入合法获取的学习材料。")
                            .foregroundStyle(NCE1Colors.textSecondary)
                    }
                }
                .listRowBackground(NCE1Colors.card)
            }
            .scrollContentBackground(.hidden)
            .background(NCE1Colors.background)
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundStyle(NCE1Colors.oxfordBlue)
                }
            }
            .sheet(isPresented: $showImportGuide) {
                ImportGuideView()
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
        }
    }

    // MARK: - Import Actions

    /// Triggers audio file import via UIKit document picker.
    private func importAudio() {
        FileImporter.present(contentTypes: [.mp3, .audio]) { result in
            DispatchQueue.main.async {
                handleImportResult(result, type: "audio")
            }
        }
    }

    /// Triggers text file import via UIKit document picker.
    private func importTexts() {
        FileImporter.present(contentTypes: [.json]) { result in
            DispatchQueue.main.async {
                handleImportResult(result, type: "text")
            }
        }
    }

    /// Copies imported files to the appropriate Documents subdirectory.
    private func handleImportResult(_ result: Result<[URL], Error>, type: String) {
        switch result {
        case .success(let urls):
            guard !urls.isEmpty else { return }
            var count = 0
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }

                let subdir = type == "audio" ? "ImportedAudio" : "ImportedTexts"
                let destDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    .appendingPathComponent(subdir, isDirectory: true)
                try? FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
                let dest = destDir.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.removeItem(at: dest)
                try? FileManager.default.copyItem(at: url, to: dest)
                count += 1
            }
            importMessage = type == "audio"
                ? "成功导入 \(count) 个音频文件"
                : "成功导入 \(count) 个课文文本文件"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                importMessage = ""
            }
        case .failure(let error):
            importMessage = "导入失败: \(error.localizedDescription)"
        }
    }
}

// MARK: - Import Guide View

struct ImportGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("如何获取学习内容")
                        .font(NCE1Typography.playerTitle(20))
                        .foregroundStyle(NCE1Colors.oxfordBlue)

                    Text("""
                    本 App 是一个音频学习框架，不内置版权内容。您需要通过以下方式获取合法学习材料：

                    1. 购买正版教材
                    《新概念英语》第一册配套录音可从外研社（外语教学与研究出版社）或其他授权渠道购买正版 CD/MP3。

                    2. 音频格式要求
                    MP3 格式，建议 128kbps 以上。文件名需包含课号以便自动匹配（如 Lesson1.mp3 或 001-002－Excuse Me.mp3）。

                    3. 课文文本格式
                    JSON 格式，每课一个文件。格式示例：
                    {
                      "englishText": "...",
                      "chineseText": "..."
                    }

                    4. 导入方式
                    在设置页点击"导入音频文件"或"导入课文文本"，从「文件」App 中选择对应文件即可批量导入。
                    """)
                    .font(NCE1Typography.body(16))
                    .foregroundStyle(NCE1Colors.text)
                    .lineSpacing(6)

                    NCE1Divider()

                    Text("版权声明")
                        .font(NCE1Typography.playerTitle(20))
                        .foregroundStyle(NCE1Colors.oxfordBlue)

                    Text("""
                    本 App 不包含任何受版权保护的内容。用户需自行确保其导入的学习材料来源合法。App 开发者不提供、不存储、不分发任何版权内容。

                    新概念英语（New Concept English）为 L.G. Alexander 及朗文出版社（Longman）版权所有。请支持正版。
                    """)
                    .font(NCE1Typography.body(16))
                    .foregroundStyle(NCE1Colors.text)
                    .lineSpacing(6)
                }
                .padding(20)
            }
            .background(NCE1Colors.background)
            .navigationTitle("导入指南")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(NCE1Colors.oxfordBlue)
                }
            }
        }
    }
}

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("隐私政策 · Privacy Policy")
                        .font(NCE1Typography.playerTitle(20))
                        .foregroundStyle(NCE1Colors.oxfordBlue)

                    Text("""
                    中文：
                    NCE1 Elite 不会收集、存储或传输您的任何个人数据。

                    - 应用内所有数据（播放进度、收藏记录、设置偏好）均仅保存在您的设备本地。
                    - 应用不请求网络访问权限。
                    - 应用不使用任何第三方分析或广告 SDK。
                    - 用户导入的音频和文本文件仅存储在应用的沙盒文件系统中。

                    English:
                    NCE1 Elite does not collect, store, or transmit any of your personal data.

                    - All in-app data (playback progress, favorites, settings preferences) is stored locally on your device only.
                    - The app does not request network access.
                    - The app does not use any third-party analytics or advertising SDKs.
                    - User-imported audio and text files are stored solely within the app's sandboxed file system.
                    """)
                    .font(NCE1Typography.body(15))
                    .foregroundStyle(NCE1Colors.text)
                    .lineSpacing(6)
                }
                .padding(20)
            }
            .background(NCE1Colors.background)
            .navigationTitle("隐私政策")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(NCE1Colors.oxfordBlue)
                }
            }
        }
    }
}
