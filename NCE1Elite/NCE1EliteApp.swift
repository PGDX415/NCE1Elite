//
//  NCE1EliteApp.swift
//  NCE1Elite
//
//  App entry point. Configures audio session, SwiftData, and splash screen.
//

import SwiftUI
import SwiftData
import AVFoundation

@main
struct NCE1EliteApp: App {
    @State private var showSplash = true

    /// Shared SwiftData model container for LessonProgress.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            LessonProgress.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(red: 0.01, green: 0.04, blue: 0.10)
                    .ignoresSafeArea()

                RootTabView()
                    .environment(\.modelContext, sharedModelContainer.mainContext)

                if showSplash {
                    SplashView {
                        showSplash = false
                    }
                    .transition(.opacity)
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Audio Session Configuration

    /// Configure AVAudioSession for playback with background audio support.
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay])
            try session.setActive(true)
        } catch {
            print("❌ NCE1EliteApp: Failed to configure audio session: \(error)")
        }
    }
}
