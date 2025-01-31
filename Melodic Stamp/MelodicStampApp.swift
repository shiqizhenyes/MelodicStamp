//
//  MelodicStampApp.swift
//  MelodicStamp
//
//  Created by Xinshao_Air on 2024/11/19.
//

import CSFBAudioEngine
import SwiftUI
import UniformTypeIdentifiers

enum WindowID: String, Equatable, Hashable, CaseIterable, Identifiable, Codable {
    case content
    case about

    var id: Self { self }
}

@main
struct MelodicStampApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    @FocusedValue(WindowManagerModel.self) private var windowManager

    // Globally managed models, uniqueness ensured
    @State private var floatingWindows: FloatingWindowsModel = .init()
    @State private var library: LibraryModel = .init()

    @State private var isAboutWindowPresented: Bool = false

    var body: some Scene {
        WindowGroup(id: WindowID.content.rawValue, for: CreationParameters.self) { $parameters in
            ContentView(parameters, library: library)
                .environment(\.appDelegate, appDelegate)
                .environment(floatingWindows)
                .environment(library)
                .onAppear {
                    appDelegate.resumeWindowSuspension()
                }
        } defaultValue: {
            CreationParameters()
        }
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unified)
        .windowManagerRole(.principal)
        .handlesExternalEvents(matching: []) // Crucial for handling custom external events in `AppDelegate`
        .commands {
            // `InspectorCommands` isn't localized...
            CommandGroup(before: .sidebar) {
                Group {
                    if let windowManager {
                        Button {
                            windowManager.isInspectorPresented.toggle()
                        } label: {
                            if windowManager.isInspectorPresented {
                                Text("Hide Inspector")
                            } else {
                                Text("Show Inspector")
                            }
                        }
                    } else {
                        Button("Show Inspector") {}
                    }
                }
                .keyboardShortcut("i", modifiers: [.command, .option])
            }

            CommandGroup(replacing: .appInfo) {
                Button("About \(Bundle.main[localized: .displayName])") {
                    if isAboutWindowPresented {
                        dismissWindow(id: WindowID.about.rawValue)
                    } else {
                        openWindow(id: WindowID.about.rawValue)
                    }
                }
            }

            FileCommands()

            EditingCommands()

            PlayerCommands()

            PlaylistCommands(library: library)

            WindowCommands()
        }

        Window("About \(Bundle.main[localized: .displayName])", id: WindowID.about.rawValue) {
            AboutView()
                .onAppear {
                    isAboutWindowPresented = true
                }
                .onDisappear {
                    isAboutWindowPresented = false
                }
                .windowMinimizeBehavior(.disabled)
                .windowFullScreenBehavior(.disabled)
                .safeAreaPadding(.top, 0)
        }
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .windowManagerRole(.associated)
        .handlesExternalEvents(matching: []) // Crucial for handling custom external events in `AppDelegate`

        Settings {
            SettingsView()
                .windowMinimizeBehavior(.disabled)
                .windowFullScreenBehavior(.disabled)
        }
        .windowToolbarStyle(.unified)
        .windowManagerRole(.associated)
        .handlesExternalEvents(matching: []) // Crucial for handling custom external events in `AppDelegate`
    }
}

// TODO: Improve this
let allowedContentTypes: Set<UTType> = {
    var types: Set<UTType> = []
    types.formUnion(AudioDecoder.supportedMIMETypes.compactMap { UTType(mimeType: $0) })
    types.formUnion(DSDDecoder.supportedMIMETypes.compactMap { UTType(mimeType: $0) })
    types.formUnion([.ogg])
    return types
}()
