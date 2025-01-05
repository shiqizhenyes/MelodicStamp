//
//  MelodicStampApp.swift
//  MelodicStamp
//
//  Created by Xinshao_Air on 2024/11/19.
//

import CSFBAudioEngine
import SwiftUI
import UniformTypeIdentifiers

enum WindowID: String {
    case content
    case about
    case settings
}

@main
struct MelodicStampApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    @FocusedValue(\.windowManager) private var windowManager

    @State private var isAboutPresented: Bool = false
    @State private var isSettingsPresented: Bool = false

    var body: some Scene {
        WindowGroup(id: "content") {
            ContentView()
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
                .onDisappear {
                    dismissWindow(id: WindowID.about.rawValue)
                    dismissWindow(id: WindowID.settings.rawValue)
                }
        }
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unified)
        .commands {
            InspectorCommands()

            CommandGroup(replacing: .appInfo) {
                Button("About \(Bundle.main.displayName)") {
                    if isAboutPresented {
                        dismissWindow(id: WindowID.about.rawValue)
                    } else {
                        openWindow(id: WindowID.about.rawValue)
                    }
                }

                Button("Settings…") {
                    if isSettingsPresented {
                        dismissWindow(id: WindowID.settings.rawValue)
                    } else {
                        openWindow(id: WindowID.settings.rawValue)
                    }
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            FileCommands()

            EditingCommands()

            PlayerCommands()

            PlaylistCommands()

            WindowCommands()
        }

        Window("About \(Bundle.main.displayName)", id: WindowID.about.rawValue) {
            AboutView()
                .onAppear {
                    isAboutPresented = true
                }
                .onDisappear {
                    isAboutPresented = false
                }
        }
        .defaultLaunchBehavior(.suppressed)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)

        Window("", id: WindowID.settings.rawValue) {
            SettingsView()
                .onAppear {
                    isSettingsPresented = true
                }
                .onDisappear {
                    isSettingsPresented = false
                }
        }
        .defaultLaunchBehavior(.suppressed)
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unified)
    }
}

// TODO: Improve this
let allowedContentTypes: [UTType] = {
    var types = [UTType]()
    types.append(contentsOf: AudioDecoder.supportedMIMETypes.compactMap { UTType(mimeType: $0) })
    types.append(contentsOf: DSDDecoder.supportedMIMETypes.compactMap { UTType(mimeType: $0) })
    types.append(UTType.ogg)
    return types
}()
