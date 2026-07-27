//
//  PlayerView.swift
//  NCE1Elite
//
//  Full-screen player with playback controls, progress bar,
//  reading mode, speed/loop/sleep timer settings.
//

import SwiftUI

/// Full-screen audio player overlay.
struct PlayerView: View {
    let viewModel: PlayerViewModel
    @Environment(\.dismiss) private var dismiss

    @AppStorage("lessonFontSize") private var lessonFontSize: Double = 17

    var body: some View {
        ZStack {
            // Show countdown overlay if counting down
            if viewModel.isCountingDown, let lesson = viewModel.currentLesson {
                CountdownOverlay(
                    countdown: viewModel.countdownSeconds,
                    lessonTitle: lesson.title,
                    lessonNumber: lesson.lessonNumber,
                    onSkip: { viewModel.skipCountdown() },
                    onCancel: {
                        viewModel.cancelCountdown()
                        dismiss()
                    }
                )
            } else {
                mainPlayerContent
            }
        }
        .background(NCE1Colors.background)
        .onDisappear {
            viewModel.cancelCountdown()
        }
    }

    // MARK: - Main Content

    private var mainPlayerContent: some View {
        VStack(spacing: 0) {
            // Top bar
            topBar

            if viewModel.isReadingMode {
                readingContentView
            } else {
                listeningModeContent
            }

            // Control bar
            playbackControls
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                viewModel.cancelCountdown()
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.title3)
                    .foregroundStyle(NCE1Colors.text)
                    .padding(12)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Lesson \(viewModel.currentLesson?.lessonNumber ?? 0)")
                    .font(NCE1Typography.monoDigit(13))
                    .foregroundStyle(NCE1Colors.textSecondary)
                Text(viewModel.currentLesson?.title ?? "")
                    .font(NCE1Typography.playerTitle(17))
                    .foregroundStyle(NCE1Colors.text)
                    .lineLimit(1)
            }

            Spacer()

            // Reading mode toggle
            Button {
                viewModel.toggleReadingMode()
            } label: {
                Image(systemName: viewModel.isReadingMode ? "text.book.closed.fill" : "text.book.closed")
                    .font(.title3)
                    .foregroundStyle(viewModel.isReadingMode ? NCE1Colors.oxfordBlue : NCE1Colors.textSecondary)
                    .padding(12)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(NCE1Colors.card)
    }

    // MARK: - Listening Mode

    private var listeningModeContent: some View {
        VStack(spacing: 24) {
            Spacer()

            // Artwork / Lesson info
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(NCE1Colors.oxfordBlue.opacity(0.1))
                        .frame(width: 160, height: 160)

                    VStack(spacing: 6) {
                        Text("\(viewModel.currentLesson?.lessonNumber ?? 0)")
                            .font(NCE1Typography.monoDigit(40))
                            .foregroundStyle(NCE1Colors.oxfordBlue)
                        Text("Lesson")
                            .font(NCE1Typography.caption())
                            .foregroundStyle(NCE1Colors.textSecondary)
                    }
                }

                Text(viewModel.currentLesson?.title ?? "")
                    .font(NCE1Typography.playerTitle(22))
                    .foregroundStyle(NCE1Colors.text)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
    }

    // MARK: - Reading Mode Content

    private var readingContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // English text
                if let english = viewModel.englishText, !english.isEmpty {
                    Text(english)
                        .font(NCE1Typography.body(CGFloat(lessonFontSize)))
                        .foregroundStyle(NCE1Colors.text)
                        .lineSpacing(6)
                } else {
                    Text("暂无课文文本")
                        .font(NCE1Typography.body(17))
                        .foregroundStyle(NCE1Colors.textSecondary)
                }

                NCE1Divider()

                // Chinese text
                if let chinese = viewModel.chineseText, !chinese.isEmpty {
                    Text(chinese)
                        .font(NCE1Typography.body(CGFloat(lessonFontSize - 2)))
                        .foregroundStyle(NCE1Colors.textSecondary)
                        .lineSpacing(6)
                } else {
                    Text("暂无中文译文")
                        .font(NCE1Typography.body(15))
                        .foregroundStyle(NCE1Colors.textSecondary.opacity(0.7))
                }
            }
            .padding(20)
        }
        .background(NCE1Colors.background)
    }

    // MARK: - Progress Bar

    private var progressBarSection: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(NCE1Colors.separator)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(NCE1Colors.oxfordBlue)
                        .frame(width: viewModel.duration > 0
                               ? max(0, geometry.size.width * (viewModel.currentTime / viewModel.duration))
                               : 0, height: 4)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 20)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let ratio = value.location.x / UIScreen.main.bounds.width
                        viewModel.seek(to: viewModel.duration * max(0, min(1, ratio)))
                    }
            )

            HStack {
                Text(formatTime(viewModel.currentTime))
                    .font(NCE1Typography.monoDigit(12))
                    .foregroundStyle(NCE1Colors.textSecondary)
                Spacer()
                Text(formatTime(viewModel.duration))
                    .font(NCE1Typography.monoDigit(12))
                    .foregroundStyle(NCE1Colors.textSecondary)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Playback Controls

    private var playbackControls: some View {
        VStack(spacing: 20) {
            // Main controls: prev, rewind 15s, play/pause, fwd 15s, next
            HStack(spacing: 28) {
                Button { viewModel.playPrevious() } label: {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                        .foregroundStyle(NCE1Colors.text)
                }

                Button { viewModel.seekBackward15() } label: {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                        .foregroundStyle(NCE1Colors.text)
                }

                Button { viewModel.togglePlayPause() } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(NCE1Colors.oxfordBlue)
                }

                Button { viewModel.seekForward15() } label: {
                    Image(systemName: "goforward.15")
                        .font(.title2)
                        .foregroundStyle(NCE1Colors.text)
                }

                Button { viewModel.playNext() } label: {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundStyle(NCE1Colors.text)
                }
            }

            // Speed & Loop & Sleep Timer
            HStack(spacing: 16) {
                // Speed
                HStack(spacing: 4) {
                    ForEach(viewModel.availableSpeeds, id: \.self) { speed in
                        SpeedChip(
                            speed: speed,
                            isActive: speed == viewModel.playbackRate,
                            action: { viewModel.setRate(speed) }
                        )
                    }
                }

                Spacer()

                // Loop mode
                Button {
                    viewModel.cycleLoopMode()
                } label: {
                    Image(systemName: loopIcon)
                        .font(.system(size: 16))
                        .foregroundStyle(viewModel.loopMode != .none ? NCE1Colors.oxfordBlue : NCE1Colors.textSecondary)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(viewModel.loopMode != .none ? NCE1Colors.oxfordBlue.opacity(0.1) : Color.clear)
                        )
                }

                // Sleep timer
                Menu {
                    Button("关闭") {
                        viewModel.toggleSleepTimer(minutes: 0)
                    }
                    ForEach(viewModel.sleepTimerOptions, id: \.self) { minutes in
                        Button("\(minutes) 分钟") {
                            viewModel.toggleSleepTimer(minutes: minutes)
                        }
                    }
                } label: {
                    Image(systemName: viewModel.isSleepTimerActive ? "timer" : "timer")
                        .font(.system(size: 16))
                        .foregroundStyle(viewModel.isSleepTimerActive ? NCE1Colors.oxfordBlue : NCE1Colors.textSecondary)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(viewModel.isSleepTimerActive ? NCE1Colors.oxfordBlue.opacity(0.1) : Color.clear)
                        )
                }
            }
            .padding(.horizontal, 20)

            // Sleep timer indicator
            if viewModel.isSleepTimerActive {
                Text("睡眠定时器: \(formatTime(viewModel.sleepTimerRemaining))")
                    .font(NCE1Typography.caption())
                    .foregroundStyle(NCE1Colors.antiqueGold)
            }
        }
        .padding(.bottom, 30)
    }

    // MARK: - Helpers

    private var loopIcon: String {
        switch viewModel.loopMode {
        case .none: return "repeat"
        case .one: return "repeat.1"
        case .list: return "repeat"
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
