//
//  FloatingPlayerView.swift
//  MelodicStamp
//
//  Created by Xinshao_Air on 2024/11/22.
//

import SwiftUI

struct FloatingPlayerView: View {
    @Environment(FloatingWindowsModel.self) var floatingWindows
    @Environment(WindowManagerModel.self) var windowManager
    @Environment(PlayerModel.self) var player
    @Environment(PlayerKeyboardControlModel.self) var playerKeyboardControl

    @Namespace private var namespace

    var body: some View {
        ZStack {
            VisualEffectView(material: .popover, blendingMode: .behindWindow)

            Player(namespace: namespace)
        }
        .frame(width: 800, height: 100)
        .clipShape(.rect(cornerRadius: 25))
    }
}
