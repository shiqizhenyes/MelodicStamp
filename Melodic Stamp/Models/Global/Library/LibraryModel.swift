//
//  LibraryModel.swift
//  Melodic Stamp
//
//  Created by KrLite on 2025/1/29.
//

import SwiftUI

extension LibraryModel: TypeNameReflectable {}

@MainActor @Observable final class LibraryModel {
    private(set) var playlists: [Playlist] = []
    private(set) var indexer: PlaylistIndexer = .init()

    private(set) var isLoadingPlaylists: Bool = false

    init() {
        Task {
            loadIndexer()
        }
    }
}

extension LibraryModel: @preconcurrency Sequence {
    func makeIterator() -> Array<Playlist>.Iterator {
        playlists.makeIterator()
    }

    var isEmpty: Bool {
        playlists.isEmpty
    }

    var count: Int {
        playlists.count
    }
}

extension LibraryModel {
    private func captureIndices() -> PlaylistIndexer.Value {
        playlists.map(\.id)
    }

    private func indexPlaylists(with value: PlaylistIndexer.Value) throws {
        indexer.value = value
        try indexer.write()
    }

    func loadIndexer() {
        indexer.value = indexer.read() ?? []
    }

    func loadPlaylists() async {
        guard !isLoadingPlaylists else { return }
        isLoadingPlaylists = true
        loadIndexer()

        var playlists: [Playlist] = []
        for await playlist in indexer.loadPlaylists() {
            playlists.append(playlist)
        }
        self.playlists = playlists
        isLoadingPlaylists = false
    }
}

extension LibraryModel {
    private static func deletePlaylist(at url: URL) throws {
        Task {
            try FileManager.default.removeItem(at: url)

            logger.info("Deleted playlist at \(url)")
        }
    }
}

extension LibraryModel {
    func move(fromOffsets indices: IndexSet, toOffset destination: Int) {
        playlists.move(fromOffsets: indices, toOffset: destination)

        try? indexPlaylists(with: captureIndices())
    }

    func add(_ playlists: [Playlist]) {
        for playlist in playlists {
            guard !self.playlists.contains(playlist) else { continue }
            self.playlists.append(playlist)
        }

        try? indexPlaylists(with: captureIndices())
    }

    func remove(_ playlists: [Playlist]) {
        for playlist in playlists {
            self.playlists.removeAll { $0 == playlist }
            try? Self.deletePlaylist(at: playlist.possibleURL)
        }

        try? indexPlaylists(with: captureIndices())
    }
}
