//
//  PlaylistItem.swift
//  MelodicStamp
//
//  Created by Xinshao_Air on 2024/11/20.
//

import SwiftUI
import AppKit
import CSFBAudioEngine

struct PlaylistItem: Identifiable {
    let id = UUID()
    let url: URL
    @State var editableMetadata: EditableMetadata

    init?(url: URL) async throws {
        self.url = url
        
        guard let metadata = try await EditableMetadata(url: url) else { return nil }
        self.editableMetadata = metadata
    }

    func decoder(enableDoP: Bool = false) throws -> PCMDecoding? {
        guard url.startAccessingSecurityScopedResource() else { return nil }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let pathExtension = url.pathExtension.lowercased()
        if AudioDecoder.handlesPaths(withExtension: pathExtension) {
            return try AudioDecoder(url: url)
        } else if DSDDecoder.handlesPaths(withExtension: pathExtension) {
            let dsdDecoder = try DSDDecoder(url: url)
            return enableDoP ? try DoPDecoder(decoder: dsdDecoder) : try DSDPCMDecoder(decoder: dsdDecoder)
        }
        
        return nil
    }
}

extension PlaylistItem: Equatable {
    static func ==(lhs: PlaylistItem, rhs: PlaylistItem) -> Bool {
        lhs.id == rhs.id
    }
}

extension PlaylistItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
