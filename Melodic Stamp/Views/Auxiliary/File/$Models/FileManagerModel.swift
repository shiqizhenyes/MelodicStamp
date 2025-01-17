//
//  FileManagerModel.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/25.
//

import CSFBAudioEngine
import SwiftUI
import UniformTypeIdentifiers

enum FileOpenerPresentationStyle {
    case inCurrentPlaylist
    case replacingCurrentPlaylistOrSelection
    case formingNewPlaylist
}

enum FileAdderPresentationStyle {
    case toCurrentPlaylist
    case replacingCurrentPlaylistOrSelection
    case formingNewPlaylist
}

@Observable class FileManagerModel {
    var isFileOpenerPresented: Bool = false
    private var fileOpenerPresentationStyle: FileOpenerPresentationStyle = .inCurrentPlaylist

    var isFileAdderPresented: Bool = false
    private var fileAdderPresentationStyle: FileAdderPresentationStyle = .toCurrentPlaylist

    func emitOpen(style: FileOpenerPresentationStyle = .inCurrentPlaylist) {
        isFileOpenerPresented = true
        fileOpenerPresentationStyle = style
    }

    func emitAdd(style: FileAdderPresentationStyle = .toCurrentPlaylist) {
        isFileAdderPresented = true
        fileAdderPresentationStyle = style
    }

    func open(url: URL, using player: PlayerModel) {
        guard url.startAccessingSecurityScopedResource() else { return }

        switch fileOpenerPresentationStyle {
        case .inCurrentPlaylist:
            player.play(url: url)
        case .replacingCurrentPlaylistOrSelection:
            player.removeAll()
            player.play(url: url)
        case .formingNewPlaylist:
            break
        }
    }

    func add(urls: [URL], to player: PlayerModel) {
        let urls = urls.flatMap { url in
            FileHelper.flatten(contentsOfFolder: url, allowedContentTypes: .init(allowedContentTypes))
        }

        switch fileAdderPresentationStyle {
        case .toCurrentPlaylist:
            player.addToPlaylist(urls: urls)
        case .replacingCurrentPlaylistOrSelection:
            player.removeAll()
            player.addToPlaylist(urls: urls)
        case .formingNewPlaylist:
            break
        }
    }
}
