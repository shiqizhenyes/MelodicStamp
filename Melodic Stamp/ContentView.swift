//
//  ContentView.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/23.
//

import Combine
import SwiftUI

enum MelodicStampWindowStyle: String, Equatable, Hashable, Identifiable {
    case main
    case miniPlayer

    var id: Self {
        self
    }
}

struct ContentView: View {
    @Environment(\.appearsActive) private var isActive

    @Namespace private var namespace

    @State private var isInspectorPresented: Bool = false
    @State private var selectedTab: SidebarTab = .inspector

    @State private var floatingWindows: FloatingWindowsModel = .init()
    @State private var fileManager: FileManagerModel = .init()
    @State private var player: PlayerModel = .init()
    @State private var playerKeyboardControl: PlayerKeyboardControlModel = .init()

    @State private var windowStyle: MelodicStampWindowStyle = .main
    @State private var widthRestriction: CGFloat?

    var body: some View {
        Group {
            switch windowStyle {
            case .main:
                MainView(fileManager: fileManager, player: player, isInspectorPresented: $isInspectorPresented, selectedTab: $selectedTab)
                    .onGeometryChange(for: CGRect.self) { proxy in
                        proxy.frame(in: .global)
                    } action: { _ in
                        floatingWindows.updateTabBarPosition()
                        floatingWindows.updatePlayerPosition()
                    }
                    .frame(minHeight: 600)
                    .ignoresSafeArea()
                    .onChange(of: isActive, initial: true) { _, _ in
                        DispatchQueue.main.async {
                            NSApp.mainWindow?.titlebarAppearsTransparent = true
                            NSApp.mainWindow?.titleVisibility = .visible
                        }
                    }
            case .miniPlayer:
                MiniPlayer(player: player, playerKeyboardControl: playerKeyboardControl, namespace: namespace)
                    .padding(8)
                    .background {
                        VisualEffectView(material: .headerView, blendingMode: .behindWindow)
                    }
                    .padding(.bottom, -32)
                    .ignoresSafeArea()
                    .frame(minWidth: 500, idealWidth: 500)
                    .fixedSize(horizontal: false, vertical: true)
                    .environment(\.melodicStampWindowStyle, windowStyle)
                    .environment(\.changeMelodicStampWindowStyle) { windowStyle in
                        self.windowStyle = windowStyle
                    }
                    .onChange(of: isActive, initial: true) { _, _ in
                        DispatchQueue.main.async {
                            NSApp.mainWindow?.titlebarAppearsTransparent = true
                            NSApp.mainWindow?.titleVisibility = .hidden
                        }
                    }
            }
        }
        .background {
            FileImporters(fileManager: fileManager, player: player)
                .allowsHitTesting(false)
        }
        .onAppear {
            floatingWindows.observeFullScreen()
        }
        .onChange(of: isActive, initial: true) { _, _ in
            switch windowStyle {
            case .main:
                if isActive {
                    initializeFloatingWindows()
                } else {
                    destroyFloatingWindows()
                }
            case .miniPlayer:
                destroyFloatingWindows()
            }
        }
        .onChange(of: windowStyle) { _, newValue in
            switch newValue {
            case .main:
                initializeFloatingWindows()
                widthRestriction = 960
            case .miniPlayer:
                destroyFloatingWindows()
                widthRestriction = 500
            }
        }
        .onChange(of: widthRestriction) { _, newValue in
            guard newValue != nil else { return }
            DispatchQueue.main.async {
                widthRestriction = nil
            }
        }
        .frame(maxWidth: widthRestriction)
        .focusable()
        .focusEffectDisabled()
        .focusedValue(\.fileManager, fileManager)
        .focusedValue(\.player, player)
        .focusedValue(\.playerKeyboardControl, playerKeyboardControl)
    }

    private func initializeFloatingWindows() {
        floatingWindows.addTabBar {
            FloatingTabBarView(
                floatingWindows: floatingWindows,
                sections: [
                    .init(tabs: [.inspector, .metadata]),
                    .init(title: .init(localized: "Lyrics"), tabs: [.lyrics])
                ],
                isInspectorPresented: $isInspectorPresented,
                selectedTab: $selectedTab
            )
        }
        floatingWindows.addPlayer {
            FloatingPlayerView(
                floatingWindows: floatingWindows,
                player: player,
                playerKeyboardControl: playerKeyboardControl
            )
            .environment(\.melodicStampWindowStyle, windowStyle)
            .environment(\.changeMelodicStampWindowStyle) { newValue in
                windowStyle = newValue
            }
        }
    }

    private func destroyFloatingWindows() {
        floatingWindows.removeTabBar()
        floatingWindows.removePlayer()
    }
}
