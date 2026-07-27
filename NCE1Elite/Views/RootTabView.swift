//
//  RootTabView.swift
//  NCE1Elite
//
//  Root TabView with lesson list (home), favorites, and full-screen
//  player overlay using fullScreenCover(item:) to prevent duplicate modals.
//

import SwiftUI
import SwiftData

/// The root view of the app after the splash screen.
struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0

    // Services and ViewModels
    let lessonDataService: LessonDataService
    let importService: ImportService
    let audioService: AudioPlayerService
    let listViewModel: LessonListViewModel
    let playerViewModel: PlayerViewModel
    let favoritesViewModel: FavoritesViewModel

    // Player presentation
    @State private var playerPresentationID: PlayerPresentation?
    @State private var showSettings = false

    @AppStorage("colorSchemeMode") private var colorSchemeModeRaw: String = ColorSchemeMode.system.rawValue

    private var colorSchemeMode: ColorSchemeMode {
        ColorSchemeMode(rawValue: colorSchemeModeRaw) ?? .system
    }

    init() {
        // Initialize services
        let lds = LessonDataService()
        let isv = ImportService()
        let asv = AudioPlayerService(importService: isv)
        let lvm = LessonListViewModel(dataService: lds, importService: isv)
        let pvm = PlayerViewModel(audioService: asv, importService: isv, listViewModel: lvm)
        let fvm = FavoritesViewModel(dataService: lds, importService: isv, listViewModel: lvm)

        self.lessonDataService = lds
        self.importService = isv
        self.audioService = asv
        self.listViewModel = lvm
        self.playerViewModel = pvm
        self.favoritesViewModel = fvm
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Lesson List
            NavigationStack {
                LessonListView(
                    viewModel: listViewModel,
                    importService: importService,
                    onSelectLesson: { lesson in
                        playerViewModel.play(lesson: lesson)
                        playerPresentationID = PlayerPresentation()
                    }
                )
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(NCE1Colors.oxfordBlue)
                        }
                    }
                }
            }
            .tabItem {
                Label("课程", systemImage: "book")
            }
            .tag(0)

            // Tab 2: Favorites
            NavigationStack {
                FavoritesView(
                    viewModel: favoritesViewModel,
                    onSelectLesson: { lesson in
                        playerViewModel.play(lesson: lesson)
                        playerPresentationID = PlayerPresentation()
                    }
                )
            }
            .tabItem {
                Label("收藏", systemImage: "star")
            }
            .tag(1)
        }
        .tint(NCE1Colors.oxfordBlue)
        .preferredColorScheme(colorSchemeMode.colorScheme)
        // Full-screen player
        .fullScreenCover(item: $playerPresentationID) {
            // Dismiss on close
        } content: { _ in
            PlayerView(viewModel: playerViewModel)
        }
        // Settings sheet
        .sheet(isPresented: $showSettings) {
            SettingsView(importService: importService)
        }
        .onAppear {
            listViewModel.setModelContext(modelContext)
            favoritesViewModel.setModelContext(modelContext)
            playerViewModel.setModelContext(modelContext)
        }
    }
}
