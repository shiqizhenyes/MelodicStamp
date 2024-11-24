//
//  Metadata.swift
//  Melodic Stamp
//
//  Created by KrLite on 2024/11/24.
//

import SwiftUI
import CSFBAudioEngine

struct Metadata: Identifiable {
    var id: URL {
        url
    }
    var url: URL
    
    var coverImages: Set<NSImage>?
    
    var title: String?
    var titleSortOrder: String?
    var artist: String?
    var artistSortOrder: String?
    var composer: String?
    var composerSortOrder: String?
    var genre: String?
    var genreSortOrder: String?
    var bpm: Int?
    
    var albumTitle: String?
    var albumTitleSortOrder: String?
    var albumArtist: String?
    var albumArtistSortOrder: String?
    
    var trackNumber: Int?
    var trackTotal: Int?
    var discNumber: Int?
    var discTotal: Int?
    
    var comment: String?
    var grouping: String?
    var isCompilation: Bool?
    
    var isrc: String?
    var lyrics: String?
    var mcn: String?
    
    var musicBrainzRecordingID: String?
    var musicBrainzReleaseID: String?
    
    var rating: Int?
    var releaseDate: String?
    
    var replayGainAlbumGain: Double?
    var replayGainAlbumPeak: Double?
    var replayGainTrackGain: Double?
    var replayGainTrackPeak: Double?
    var replayGainReferenceLoudness: Double?
    
    init(
        url: URL,
        coverImages: Set<NSImage>? = nil,
        title: String? = nil, titleSortOrder: String? = nil,
        artist: String? = nil, artistSortOrder: String? = nil,
        composer: String? = nil, composerSortOrder: String? = nil,
        genre: String? = nil, genreSortOrder: String? = nil,
        bpm: Int? = nil,
        albumTitle: String? = nil, albumTitleSortOrder: String? = nil,
        albumArtist: String? = nil, albumArtistSortOrder: String? = nil,
        trackNumber: Int? = nil, trackTotal: Int? = nil,
        discNumber: Int? = nil, discTotal: Int? = nil,
        comment: String? = nil,
        grouping: String? = nil,
        isCompilation: Bool? = nil,
        isrc: String? = nil,
        lyrics: String? = nil,
        mcn: String? = nil,
        musicBrainzRecordingID: String? = nil, musicBrainzReleaseID: String? = nil,
        rating: Int? = nil,
        releaseDate: String? = nil,
        replayGainAlbumGain: Double? = nil, replayGainAlbumPeak: Double? = nil,
        replayGainTrackGain: Double? = nil, replayGainTrackPeak: Double? = nil,
        replayGainReferenceLoudness: Double? = nil
    ) {
        self.url = url
        self.coverImages = coverImages ?? .init()
        self.title = title
        self.titleSortOrder = titleSortOrder
        self.artist = artist
        self.artistSortOrder = artistSortOrder
        self.composer = composer
        self.composerSortOrder = composerSortOrder
        self.genre = genre
        self.genreSortOrder = genreSortOrder
        self.bpm = bpm
        self.albumTitle = albumTitle
        self.albumTitleSortOrder = albumTitleSortOrder
        self.albumArtist = albumArtist
        self.albumArtistSortOrder = albumArtistSortOrder
        self.trackNumber = trackNumber
        self.trackTotal = trackTotal
        self.discNumber = discNumber
        self.discTotal = discTotal
        self.comment = comment
        self.grouping = grouping
        self.isCompilation = isCompilation
        self.isrc = isrc
        self.lyrics = lyrics
        self.mcn = mcn
        self.musicBrainzRecordingID = musicBrainzRecordingID
        self.musicBrainzReleaseID = musicBrainzReleaseID
        self.rating = rating
        self.releaseDate = releaseDate
        self.replayGainAlbumGain = replayGainAlbumGain
        self.replayGainAlbumPeak = replayGainAlbumPeak
        self.replayGainTrackGain = replayGainTrackGain
        self.replayGainTrackPeak = replayGainTrackPeak
        self.replayGainReferenceLoudness = replayGainReferenceLoudness
    }
    
    init(url: URL, from metadata: AudioMetadata?) {
        self.init(
            url: url,
            coverImages: (metadata?.attachedPictures.compactMap(\.image)).map { Set($0) },
            title: metadata?.title, titleSortOrder: metadata?.titleSortOrder,
            artist: metadata?.artist, artistSortOrder: metadata?.artistSortOrder,
            composer: metadata?.composer, composerSortOrder: metadata?.composerSortOrder,
            genre: metadata?.genre, genreSortOrder: metadata?.genreSortOrder,
            bpm: metadata?.bpm,
            albumTitle: metadata?.albumTitle, albumTitleSortOrder: metadata?.albumTitleSortOrder,
            albumArtist: metadata?.albumArtist, albumArtistSortOrder: metadata?.albumArtistSortOrder,
            trackNumber: metadata?.trackNumber, trackTotal: metadata?.trackTotal,
            discNumber: metadata?.discNumber, discTotal: metadata?.discTotal,
            comment: metadata?.comment,
            grouping: metadata?.grouping,
            isCompilation: metadata?.isCompilation,
            isrc: metadata?.isrc,
            lyrics: metadata?.lyrics,
            mcn: metadata?.mcn,
            musicBrainzRecordingID: metadata?.musicBrainzRecordingID, musicBrainzReleaseID: metadata?.musicBrainzReleaseID,
            rating: metadata?.rating, releaseDate: metadata?.releaseDate,
            replayGainAlbumGain: metadata?.replayGainAlbumGain, replayGainAlbumPeak: metadata?.replayGainAlbumPeak,
            replayGainTrackGain: metadata?.replayGainTrackGain, replayGainTrackPeak: metadata?.replayGainTrackPeak,
            replayGainReferenceLoudness: metadata?.replayGainReferenceLoudness
        )
    }
}
