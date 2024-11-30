//
//  LyricsExcerpt.swift
//  Melodic Stamp
//
//  Created by KrLite on 2024/11/30.
//

import SwiftUI

struct LyricsExcerpt: View {
    var body: some View {
        VStack {
            EmptyMusicNoteView(systemSymbol: SidebarTab.lyrics.systemSymbol)
                .frame(height: 64)
                .alignmentGuide(ExcerptAlignment.alignment) { d in
                    d[.bottom]
                }
            
            Text("Lyrics")
                .font(.title3)
                .foregroundStyle(.quaternary)
        }
    }
}

#Preview {
    MetadataExcerpt()
}
