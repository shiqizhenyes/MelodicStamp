//
//  MakeCloseDelegated.swift
//  Melodic Stamp
//
//  Created by KrLite on 2025/1/26.
//

import SwiftUI

struct MakeCloseDelegated: NSViewControllerRepresentable {
    var shouldClose: Bool = false
    var onClose: (NSWindow, Bool) -> ()

    func makeNSViewController(context: Context) -> NSViewController {
        let hostingController = CloseDelegatedWindowHostingController(
            rootView: EmptyView(),
            shouldClose: shouldClose, onClose: onClose
        )
        context.coordinator.hostingController = hostingController

        return hostingController
    }

    func updateNSViewController(_: NSViewController, context: Context) {
        context.coordinator.hostingController.delegate.shouldClose = shouldClose
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var hostingController: CloseDelegatedWindowHostingController<EmptyView>!
    }
}

class CloseDelegatedWindowHostingController<Content: View>: NSHostingController<Content> {
    var delegate: CloseDelegatedWindowDelegate

    init(rootView: Content, shouldClose: Bool = false, onClose: @escaping (NSWindow, Bool) -> ()) {
        self.delegate = .init(shouldClose: shouldClose, onClose: onClose)
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    @MainActor @preconcurrency dynamic required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillLayout() {
        super.viewWillLayout()

        guard let window = view.window else { return }
        window.delegate = delegate
    }
}

class CloseDelegatedWindowDelegate: NSObject, NSWindowDelegate {
    var shouldClose: Bool
    var onClose: (NSWindow, Bool) -> ()

    init(shouldClose: Bool = false, onClose: @escaping (NSWindow, Bool) -> ()) {
        self.shouldClose = shouldClose
        self.onClose = onClose
    }

    func windowShouldClose(_ window: NSWindow) -> Bool {
        onClose(window, shouldClose)
        return shouldClose
    }
}
