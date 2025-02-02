//
//  ContentView.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/23.
//

import Defaults
import Luminare
import SwiftUI

extension ContentView: TypeNameReflectable {}

struct ContentView: View {
    struct Sizer: Equatable, Hashable {
        var minWidth: CGFloat?
        var maxWidth: CGFloat?
        var minHeight: CGFloat?
        var maxHeight: CGFloat?

        mutating func with(windowStyle: MelodicStampWindowStyle) {
            switch windowStyle {
            case .main:
                minWidth = 960
                maxWidth = nil
                minHeight = 550
                maxHeight = 550
            case .miniPlayer:
                minWidth = nil
                maxWidth = 500
                minHeight = nil
                maxHeight = nil
            }
        }

        mutating func reset() {
            minWidth = nil
            maxWidth = nil
            minHeight = nil
            maxHeight = nil
        }
    }

    // MARK: - Environments

    @Environment(FloatingWindowsModel.self) private var floatingWindows
    @Environment(LibraryModel.self) private var library

    @Environment(\.appearsActive) private var appearsActive
    @Environment(\.resetFocus) private var resetFocus
    @Environment(\.dismissWindow) private var dismissWindow

    @FocusState private var isFocused

    @Namespace private var namespace

    @Default(.mainWindowBackgroundStyle) private var mainWindowBackgroundStyle
    @Default(.miniPlayerBackgroundStyle) private var miniPlayerBackgroundStyle

    // MARK: - Fields

    private var concreteParameters: CreationParameters?

    // MARK: Models

    @State private var windowManager: WindowManagerModel
    @State private var presentationManager: PresentationManagerModel
    @State private var fileManager: FileManagerModel
    @State private var playlist: PlaylistModel
    @State private var player: PlayerModel
    @State private var keyboardControl: KeyboardControlModel
    @State private var metadataEditor: MetadataEditorModel
    @State private var audioVisualizer: AudioVisualizerModel
    @State private var gradientVisualizer: GradientVisualizerModel

    // MARK: Window

    @State private var sizer: Sizer = .init()
    @State private var floatingWindowsTargetWindow: NSWindow?

    // MARK: - Initializers

    init(_ parameters: CreationParameters, appDelegate: AppDelegate, library: LibraryModel) {
        let date = Date()

        let windowManager = WindowManagerModel(style: parameters.initialWindowStyle, appDelegate: appDelegate)
        let playlist = PlaylistModel(bindingTo: parameters.id, library: library)
        let player = PlayerModel(SFBAudioEnginePlayer(), library: library, playlist: playlist)

        self.windowManager = windowManager
        self.presentationManager = PresentationManagerModel(windowManager: windowManager)
        self.fileManager = FileManagerModel(player: player, playlist: playlist)
        self.playlist = playlist
        self.player = player
        self.keyboardControl = KeyboardControlModel(player: player)
        self.metadataEditor = MetadataEditorModel(playlist: playlist)
        self.audioVisualizer = AudioVisualizerModel()
        self.gradientVisualizer = GradientVisualizerModel()

        if parameters.isConcrete {
            self.concreteParameters = parameters
        }

        let elapsedTime = Date().timeIntervalSince(date)
        Self.logger.info("Initializing content with \("\(parameters)"), took \(elapsedTime) seconds")
    }

    // MARK: - Body

    var body: some View {
        CatchWindow { window in
            Group {
                switch windowManager.style {
                case .main:
                    mainView(window)
                case .miniPlayer:
                    miniPlayerView(window)
                }
            }
            .onChange(of: concreteParameters, initial: true) { _, newValue in
                guard let newValue else { return }
                processConcreteParameters(newValue)
            }
            .dropDestination(for: Track.self) { tracks, _ in
                Task.detached {
                    await playlist.append(tracks.map(\.url))
                }
                return true
            }
            .background {
                FileImporters()

                DelegatedPlaylistStorage()
                DelegatedPlaylistStateStorage()

                UnsavedChangesPresentation()
                UnsavedPlaylistPresentation()
                PlaylistPresentation()
            }

            // MARK: Window Styling

            .onAppear {
                isFocused = true
                resetFocus(in: namespace)
            }
            .onChange(of: appearsActive, initial: true) { _, newValue in
                guard newValue else { return }
                isFocused = true
                resetFocus(in: namespace)

                floatingWindows.observe(window)
                windowManager.observe(window)
                player.updateOutputDevices()
            }
            .onChange(of: windowManager.style, initial: true) { _, newValue in
                isFocused = true
                resetFocus(in: namespace)
                sizer.with(windowStyle: newValue)

                DispatchQueue.main.async {
                    sizer.reset()
                }
            }

            // MARK: Updates

            .onChange(of: playlist.currentTrack) { _, newValue in
                Task {
                    if let newValue, let attachedPictures = newValue.metadata[extracting: \.attachedPictures]?.current {
                        let cover = ThumbnailMaker.getCover(from: attachedPictures)?.image
                        await gradientVisualizer.updateDominantColors(from: cover)
                    } else {
                        await gradientVisualizer.updateDominantColors()
                    }
                }
            }
            .onReceive(player.visualizationDataPublisher) { buffer in
                audioVisualizer.updateData(from: buffer)
            }
            .onChange(of: player.isPlaying) { _, newValue in
                guard !newValue else { return }
                audioVisualizer.clearData()
            }

            // MARK: Unsaved Changes

            .modifier(WindowTerminationPresentationInjectorModifier(window: window))
        }
        .frame(minWidth: sizer.minWidth, maxWidth: sizer.maxWidth, minHeight: sizer.minHeight, maxHeight: sizer.maxHeight)

        // MARK: Floating Windows

        .modifier(FloatingWindowsModifier(targetWindow: floatingWindowsTargetWindow))

        // MARK: Navigation Titles

        .modifier(NavigationTitlesModifier())

        // MARK: Environments

        .environment(windowManager)
        .environment(presentationManager)
        .environment(fileManager)
        .environment(playlist)
        .environment(player)
        .environment(keyboardControl)
        .environment(metadataEditor)
        .environment(audioVisualizer)
        .environment(gradientVisualizer)

        // MARK: Focus Management

        .focusable()
        .focusEffectDisabled()
        .prefersDefaultFocus(in: namespace)
        .focused($isFocused)

        // MARK: Focused Values

        .focusedValue(windowManager)
        .focusedValue(presentationManager)
        .focusedValue(fileManager)
        .focusedValue(playlist)
        .focusedValue(player)
        .focusedValue(keyboardControl)
        .focusedValue(metadataEditor)
        .focusedValue(audioVisualizer)
        .focusedValue(gradientVisualizer)
    }

    // MARK: - Main View

    @ViewBuilder private func mainView(_ window: NSWindow? = nil) -> some View {
        MainView(namespace: namespace)
            .background {
                Group {
                    if windowManager.isInFullScreen {
                        OpaqueBackgroundView()
                    } else {
                        switch mainWindowBackgroundStyle {
                        case .opaque:
                            OpaqueBackgroundView()
                        case .vibrant:
                            VibrantBackgroundView()
                        case .ethereal:
                            EtherealBackgroundView()
                        }
                    }
                }
                .ignoresSafeArea()
            }
            .onDisappear {
                floatingWindowsTargetWindow = nil
            }
            .onChange(of: appearsActive, initial: true) { _, newValue in
                if newValue {
                    floatingWindowsTargetWindow = window
                } else {
                    floatingWindowsTargetWindow = nil
                }
            }
            .onChange(of: appearsActive, initial: true) { _, newValue in
                guard newValue else { return }

                Task {
                    await library.loadPlaylists()
                }
            }
    }

    // MARK: - Mini Player View

    @ViewBuilder private func miniPlayerView(_: NSWindow? = nil) -> some View {
        MiniPlayerView(namespace: namespace)
            .padding(12)
            .padding(.top, 4)
            .padding(.bottom, -32)
            .ignoresSafeArea()
            .frame(minWidth: 500, idealWidth: 500)
            .fixedSize(horizontal: false, vertical: true)
            .background {
                Group {
                    switch miniPlayerBackgroundStyle {
                    case .opaque:
                        OpaqueBackgroundView()
                    case .vibrant:
                        VibrantBackgroundView()
                    case .ethereal:
                        EtherealBackgroundView()
                    case .chroma:
                        ChromaBackgroundView()
                            .overlay(.ultraThinMaterial)
                    }
                }
                .ignoresSafeArea()
            }
            .onAppear {
                floatingWindowsTargetWindow = nil
            }
    }

    // MARK: - Functions

    private func processConcreteParameters(_ parameters: CreationParameters) {
        if !windowManager.hasConcreteParameters {
            windowManager.hasConcreteParameters = true

            Task.detached {
                switch parameters.playlist {
                case let .referenced(urls):
                    await playlist.bindTo(parameters.id, mode: .referenced)
                    await playlist.append(urls)

                    logger.info("Created window from referenced URLs: \(urls)")
                case let .canonical(id):
                    await playlist.bindTo(parameters.id, mode: .canonical)
                    await playlist.loadTracks()

                    logger.info("Created window with canonical ID: \(id)")
                }

                if parameters.shouldPlay, let firstTrack = await playlist.tracks.first {
                    await player.play(firstTrack.url)
                }
            }
        }
    }
}
