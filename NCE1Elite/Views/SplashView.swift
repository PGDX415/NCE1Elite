//
//  SplashView.swift
//  NCE1Elite
//
//  Full-screen launch splash with animated equalizer,
//  dark gradient background, and staggered fade-in effects.
//  Adapted from NCE3/NCE4 Elite splash style.
//

import SwiftUI

// MARK: - Splash View

/// Splash screen shown on app cold start, transitions to main content after animation.
struct SplashView: View {
    @State private var glowOpacity: Double = 0
    @State private var barScales: [CGFloat] = [0, 0, 0, 0, 0, 0, 0]
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var lineWidth: CGFloat = 0

    var onComplete: () -> Void

    private let barHeights: [CGFloat] = [32, 68, 46, 80, 52, 36, 60]

    var body: some View {
        ZStack {
            // Deep gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.01, green: 0.04, blue: 0.10),
                    Color(red: 0.02, green: 0.08, blue: 0.18)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                Spacer()

                iconSection

                Spacer().frame(height: 80)

                Text("NCE1 Elite")
                    .font(.system(size: 54, weight: .ultraLight, design: .default))
                    .kerning(4)
                    .foregroundStyle(.white)
                    .opacity(titleOpacity)

                Spacer().frame(height: 18)

                RoundedRectangle(cornerRadius: 0.5)
                    .fill(Color(red: 0.85, green: 0.70, blue: 0.28).opacity(0.6))
                    .frame(width: lineWidth, height: 1)

                Spacer().frame(height: 22)

                Text("新概念英语第一册 · 有声伴读")
                    .font(.system(size: 20, weight: .light))
                    .kerning(2)
                    .foregroundStyle(Color(red: 0.55, green: 0.60, blue: 0.70))
                    .opacity(subtitleOpacity)

                Spacer()
            }
        }
        .ignoresSafeArea()
        .onAppear { animateSplash() }
    }

    // MARK: - Icon Section

    private var iconSection: some View {
        ZStack {
            // Glow rings
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(
                        Color(red: 0.85, green: 0.70, blue: 0.28)
                            .opacity(0.04 - Double(i) * 0.012),
                        lineWidth: 1
                    )
                    .frame(
                        width: CGFloat(280 + i * 40),
                        height: CGFloat(280 + i * 40)
                    )
                    .opacity(glowOpacity)
            }

            // Main circle
            Circle()
                .stroke(.white.opacity(0.06), lineWidth: 1.5)
                .frame(width: 280, height: 280)
                .opacity(glowOpacity)

            // Equalizer bars
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(0..<7, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.85, green: 0.70, blue: 0.28),
                                    Color(red: 0.95, green: 0.82, blue: 0.45)
                                ]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 10, height: barHeights[i] * barScales[i])
                }
            }
            .offset(y: 20)

            // Book icon
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(.white.opacity(0.12), lineWidth: 1.5)
                    .frame(width: 40, height: 56)
                RoundedRectangle(cornerRadius: 3)
                    .stroke(.white.opacity(0.12), lineWidth: 1.5)
                    .frame(width: 40, height: 56)
            }
            .offset(y: -50)
            .opacity(glowOpacity)
        }
    }

    // MARK: - Animation

    private func animateSplash() {
        withAnimation(.easeOut(duration: 0.6)) {
            glowOpacity = 1
        }

        for i in 0..<barHeights.count {
            withAnimation(
                .spring(response: 0.5, dampingFraction: 0.6)
                .delay(0.15 + Double(i) * 0.06)
            ) {
                barScales[i] = 1
            }
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
            titleOpacity = 1
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.8)) {
            lineWidth = 100
        }

        withAnimation(.easeOut(duration: 0.4).delay(1.0)) {
            subtitleOpacity = 1
        }

        // Dismiss after hold
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.4)) {
                glowOpacity = 0
                titleOpacity = 0
                subtitleOpacity = 0
                lineWidth = 0
                barScales = Array(repeating: 0, count: barHeights.count)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onComplete()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SplashView(onComplete: {})
}
