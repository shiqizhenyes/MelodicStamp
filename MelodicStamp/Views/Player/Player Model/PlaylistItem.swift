//
//  PlaylistItem.swift
//  MelodicStamp
//
//  Created by Xinshao_Air on 2024/11/20.
//

import Foundation
import AppKit
import CSFBAudioEngine

struct PlaylistItem: Identifiable, Equatable, Hashable {
    let id = UUID()
    let url: URL
    var properties: AudioProperties
    var metadata: AudioMetadata

    init?(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return nil }
        defer { url.stopAccessingSecurityScopedResource() }
        
        self.url = url
        if let audioFile = try? AudioFile(readingPropertiesAndMetadataFrom: url) {
            self.properties = audioFile.properties
            self.metadata = audioFile.metadata
        } else {
            self.properties = AudioProperties()
            self.metadata = AudioMetadata()
        }
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

    static func ==(lhs: PlaylistItem, rhs: PlaylistItem) -> Bool {
        lhs.id == rhs.id
    }
}

extension AttachedPicture {
    var image: NSImage? {
        NSImage(data: imageData)
    }
}
