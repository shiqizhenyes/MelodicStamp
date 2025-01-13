//
//  AppSceneStorage.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/12.
//

import SwiftUI

enum AppSceneStorage: String, Hashable, Equatable, CaseIterable, Identifiable, Codable {
    // MARK: Player

    case playlistURLs
    case track

    case playbackMode
    case playbackLooping

    case playbackPosition
    case playbackVolume
    case playbackMuted
    
    case shouldUseRemainingDuration

    // MARK: Lyrics

    case lyricsAttachments
    case lyricsTypeSize

    var id: Self { self }

    func callAsFunction() -> String { rawValue }
}
