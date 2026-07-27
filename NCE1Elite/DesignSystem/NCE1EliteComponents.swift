//
//  NCE1EliteComponents.swift
//  NCE1Elite
//
//  Reusable design components for NCE1 Elite.
//

import SwiftUI

// MARK: - Favorite Star Button

/// A toggle button for favoriting/unfavoriting a lesson.
struct FavoriteStarButton: View {
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.system(size: 18))
                .foregroundStyle(isFavorite ? NCE1Colors.antiqueGold : NCE1Colors.textSecondary)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Lesson Progress Bar

/// Displays the playback progress of a lesson as a horizontal bar.
struct LessonProgressBar: View {
    let progress: Double // 0.0 ... 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(NCE1Colors.separator)
                    .frame(height: 4)

                if progress > 0 {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(NCE1Colors.oxfordBlue)
                        .frame(width: max(0, geometry.size.width * progress), height: 4)
                }
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Speed Chip

/// Displays the current playback speed as a chip/pill.
struct SpeedChip: View {
    let speed: Float
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(String(format: "%.2fx", speed))
                .font(NCE1Typography.caption())
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isActive ? NCE1Colors.oxfordBlue : Color.clear)
                .foregroundStyle(isActive ? .white : NCE1Colors.text)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isActive ? Color.clear : NCE1Colors.separator, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - NCE1 Divider

/// A subtle divider line.
struct NCE1Divider: View {
    var body: some View {
        Rectangle()
            .fill(NCE1Colors.separator)
            .frame(height: 1)
    }
}

// MARK: - Mini Union Jack Flag

/// A decorative mini Union Jack flag (stylized).
struct MiniUnionJack: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(NCE1Colors.oxfordBlue)
            // Stylized cross
            VStack(spacing: 0) {
                Rectangle()
                    .fill(.white)
                    .frame(width: 2)
                Spacer()
                Rectangle()
                    .fill(.white)
                    .frame(width: 2)
            }
            .frame(height: 12)
            HStack(spacing: 0) {
                Rectangle()
                    .fill(.white)
                    .frame(width: 2)
                    .padding(.horizontal, 4)
                Spacer()
                Rectangle()
                    .fill(.white)
                    .frame(width: 2)
                    .padding(.horizontal, 4)
            }
            .frame(height: 12)
        }
        .frame(width: 18, height: 12)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}

// MARK: - Player Countdown Overlay

/// Animated countdown ring for the player pre-roll.
struct CountdownOverlay: View {
    let countdown: Int // 4 down to 0
    let lessonTitle: String
    let lessonNumber: Int
    let onSkip: () -> Void
    let onCancel: () -> Void
    @State private var animationProgress: CGFloat = 0

    var body: some View {
        ZStack {
            NCE1Colors.background
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Cancel button
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(NCE1Colors.textSecondary)
                    }
                    .padding(.leading, 20)
                    Spacer()
                }

                Spacer()

                // Lesson info
                Text("Lesson \(lessonNumber)")
                    .font(NCE1Typography.monoDigit(14))
                    .foregroundStyle(NCE1Colors.textSecondary)

                Text(lessonTitle)
                    .font(NCE1Typography.playerTitle(24))
                    .foregroundStyle(NCE1Colors.text)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Countdown ring
                ZStack {
                    Circle()
                        .stroke(NCE1Colors.separator, lineWidth: 6)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: animationProgress)
                        .stroke(NCE1Colors.oxfordBlue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))

                    Text("\(countdown)")
                        .font(NCE1Typography.monoDigit(48))
                        .foregroundStyle(NCE1Colors.oxfordBlue)
                }
                .onAppear {
                    withAnimation(.linear(duration: 4)) {
                        animationProgress = 1
                    }
                }

                // Skip button
                Button(action: onSkip) {
                    Text("立即播放")
                        .font(NCE1Typography.caption())
                        .foregroundStyle(NCE1Colors.textSecondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .overlay(
                            Capsule()
                                .stroke(NCE1Colors.textSecondary, lineWidth: 1)
                        )
                }

                Spacer()
            }
        }
    }
}
