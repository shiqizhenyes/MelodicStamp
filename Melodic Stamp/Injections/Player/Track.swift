//
//  Track.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/20.
//

import AppKit
import CSFBAudioEngine
import Luminare
import SwiftUI

@Observable final class Track: Identifiable {
    let id = UUID()
    let url: URL
    var metadata: Metadata

    init?(url: URL) {
        self.url = url

        guard let metadata = Metadata(url: url) else { return nil }
        self.metadata = metadata
    }

    init(url: URL, metadata: Metadata) {
        self.url = url
        self.metadata = metadata
    }
}

extension Track: Equatable {
    static func == (lhs: Track, rhs: Track) -> Bool {
        lhs.id == rhs.id
    }
}

extension Track: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Track: LuminareSelectionData {
    var isSelectable: Bool {
        metadata.state.isLoaded
    }
}
