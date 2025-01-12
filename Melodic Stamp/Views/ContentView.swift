//
//  ContentView.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/23.
//

import Defaults
import SwiftUI

struct ContentView: View {
    // MARK: - Environments

    @Environment(FloatingWindowsModel.self) private var floatingWindows

    @Environment(\.appearsActive) private var appearsActive
    @Environment(\.resetFocus) private var resetFocus

    @FocusState private var isFocused

    @Namespace private var namespace

    @Default(.mainWindowBackgroundStyle) private var mainWindowBackgroundStyle
    @Default(.miniPlayerBackgroundStyle) private var miniPlayerBackgroundStyle

    // MARK: - Fields

    // MARK: Models

    @State private var windowManager: WindowManagerModel = .init()
    @State private var fileManager: FileManagerModel = .init()
    @State private var player: PlayerModel = .init(SFBAudioEnginePlayer())
    @State private var playerKeyboardControl: PlayerKeyboardControlModel = .init()
    @State private var metadataEditor: MetadataEditorModel = .init()
    @State private var visualizer: VisualizerModel = .init()

    // MARK: Sidebar & Inspector

    @State private var isInspectorPresented: Bool = false
    @SceneStorage(AppSceneStorage.contentTab()) private var selectedContentTab: SidebarContentTab = .playlist
    @SceneStorage(AppSceneStorage.inspectorTab()) private var selectedInspectorTab: SidebarInspectorTab = .commonMetadata

    // MARK: Sizing

    @State private var minWidth: CGFloat?
    @State private var maxWidth: CGFloat?

    // MARK: - Body

    var body: some View {
        CatchWindow { window in
            Group {
                switch windowManager.style {
                case .main:
                    mainView(window)
                        .presentedWindowStyle(.titleBar)
                case .miniPlayer:
                    miniPlayerView(window)
                        .presentedWindowStyle(.hiddenTitleBar)
                }
            }

            // MARK: Utility views

            .background {
                Group {
                    FileImporters()

                    DelegatedPlayerSceneStorage()
                }
                .allowsHitTesting(false)
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
                player.updateOutputDevices()
            }
            .onChange(of: windowManager.style, initial: true) { _, _ in
                isFocused = true
                resetFocus(in: namespace)
            }
            .onChange(of: minWidth) { _, newValue in
                guard newValue != nil else { return }
                DispatchQueue.main.async {
                    minWidth = nil
                }
            }
            .onChange(of: maxWidth) { _, newValue in
                guard newValue != nil else { return }
                DispatchQueue.main.async {
                    maxWidth = nil
                }
            }

            // MARK: Receivers

            .onReceive(player.visualizationDataPublisher) { fftData in
                visualizer.normalizeData(fftData: fftData)
            }
        }
        .frame(minWidth: minWidth, maxWidth: maxWidth)

        // MARK: Environments

        .environment(floatingWindows)
        .environment(windowManager)
        .environment(fileManager)
        .environment(player)
        .environment(playerKeyboardControl)
        .environment(metadataEditor)
        .environment(visualizer)

        // MARK: Focus Management

        .focusable()
        .focusEffectDisabled()
        .prefersDefaultFocus(in: namespace)
        .focused($isFocused)

        // MARK: Focused Values

        .focusedValue(\.windowManager, windowManager)
        .focusedValue(\.fileManager, fileManager)
        .focusedValue(\.player, player)
        .focusedValue(\.playerKeyboardControl, playerKeyboardControl)
        .focusedValue(\.metadataEditor, metadataEditor)

        // MARK: Navigation

        .navigationTitle(title)
        .navigationSubtitle(subtitle)
    }

    private var title: String {
        if player.isPlayable, let track = player.track {
            MusicTitle.stringifiedTitle(mode: .title, for: track)
        } else {
            Bundle.main.displayName
        }
    }

    private var subtitle: String {
        if player.isPlayable, let track = player.track {
            MusicTitle.stringifiedTitle(mode: .artists, for: track)
        } else if !player.isPlaylistEmpty {
            .init(localized: .init(
                "App: (Subtitle) Songs",
                defaultValue: "\(player.playlist.count) Songs",
                comment: "The subtitle displayed when there are songs in the playlist and nothing is playing"
            ))
        } else {
            ""
        }
    }

    // MARK: - Main View

    @ViewBuilder private func mainView(_ window: NSWindow? = nil) -> some View {
        MainView(
            namespace: namespace,
            isInspectorPresented: $isInspectorPresented,
            selectedContentTab: $selectedContentTab,
            selectedInspectorTab: $selectedInspectorTab
        )
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { _ in
            floatingWindows.updateTabBarPosition(in: window)
            floatingWindows.updatePlayerPosition(in: window)
        }
        .background {
            switch mainWindowBackgroundStyle {
            case .opaque:
                OpaqueBackgroundView()
            case .vibrant:
                VibrantBackgroundView()
            case .ethereal:
                EtherealBackgroundView()
            }
        }
        .ignoresSafeArea()
        .frame(minHeight: 600)
        .ignoresSafeArea()
        .onAppear {
            minWidth = 960

            DispatchQueue.main.async {
                initializeFloatingWindows(to: window)
            }
        }
        .onDisappear {
            destroyFloatingWindows()
        }
        .onChange(of: appearsActive) { _, newValue in
            if newValue {
                DispatchQueue.main.async {
                    initializeFloatingWindows(to: window)
                }
            } else {
                destroyFloatingWindows(from: window)
            }
        }
    }

    // MARK: - Mini Player View

    @ViewBuilder private func miniPlayerView(_ window: NSWindow? = nil) -> some View {
        MiniPlayerView(namespace: namespace)
            .padding(12)
            .padding(.top, 4)
            .background {
                switch miniPlayerBackgroundStyle {
                case .opaque:
                    OpaqueBackgroundView()
                case .vibrant:
                    VibrantBackgroundView()
                case .ethereal:
                    EtherealBackgroundView()
                case .chroma:
                    // TODO: Implement this
                    Color.red
                }
            }
            .padding(.bottom, -32)
            .ignoresSafeArea()
            .frame(minWidth: 500, idealWidth: 500)
            .fixedSize(horizontal: false, vertical: true)
            .onAppear {
                maxWidth = 500
                destroyFloatingWindows(from: window)
            }
    }

    // MARK: - Functions

    private func initializeFloatingWindows(to mainWindow: NSWindow? = nil) {
        floatingWindows.addTabBar(to: mainWindow) {
            FloatingTabBarView(
                isInspectorPresented: $isInspectorPresented,
                selectedContentTab: $selectedContentTab,
                selectedInspectorTab: $selectedInspectorTab
            )
            .environment(floatingWindows)
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { _ in
                DispatchQueue.main.async {
                    floatingWindows.updateTabBarPosition(in: mainWindow)
                }
            }
        }
        floatingWindows.addPlayer(to: mainWindow) {
            FloatingPlayerView()
                .environment(floatingWindows)
                .environment(windowManager)
                .environment(player)
                .environment(playerKeyboardControl)
                .onGeometryChange(for: CGSize.self) { proxy in
                    proxy.size
                } action: { _ in
                    DispatchQueue.main.async {
                        floatingWindows.updatePlayerPosition(in: mainWindow)
                    }
                }
        }
    }

    private func destroyFloatingWindows(from mainWindow: NSWindow? = nil) {
        floatingWindows.removeTabBar(from: mainWindow)
        floatingWindows.removePlayer(from: mainWindow)
    }
}
