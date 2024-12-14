//
//  NSImage+Extensions.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/24.
//

import AppKit
import CSFBAudioEngine
import MediaPlayer

extension NSImage: @retroactive @unchecked Sendable {}

extension NSImage {
    var attachedPicture: AttachedPicture? {
        tiffRepresentation.flatMap { .init(imageData: $0) }
    }

    func attachedPicture(of type: AttachedPicture.`Type`) -> AttachedPicture? {
        guard let tiffRepresentation else { return nil }
        return .init(imageData: tiffRepresentation, type: type)
    }
}

extension NSImage {
    var mediaItemArtwork: MPMediaItemArtwork {
        .init(boundsSize: size) { _ in
            self
        }
    }
}
