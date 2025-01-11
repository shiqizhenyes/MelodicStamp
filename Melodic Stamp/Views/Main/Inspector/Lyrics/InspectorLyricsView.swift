//
//  InspectorLyricsView.swift
//  MelodicStamp
//
//  Created by Xinshao_Air on 2024/12/1.
//

import SwiftUI

struct InspectorLyricsView: View {
    @Environment(PlayerModel.self) private var player
    @Environment(MetadataEditorModel.self) private var metadataEditor
    @Environment(LyricsModel.self) private var lyrics

    @Environment(\.appearsActive) private var appearsActive

    var body: some View {
        // Avoids multiple instantializations
        let lines = lyrics.lines

        // Use ZStack to avoid reinstantializing toolbar content
        ZStack {
            if appearsActive {
                switch entries.type {
                case .none, .varied:
                    ExcerptView(tab: SidebarInspectorTab.lyrics)
                case .identical:
                    ScrollView {
                        // Don't apply `.contentMargins()`, otherwise causing `LazyVStack` related glitches
                        LazyVStack(alignment: alignment, spacing: 10) {
                            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                                lyricLine(line: line, index: index)
                            }
                            .textSelection(.enabled)
                        }
                        .padding(.horizontal)
                        .safeAreaPadding(.top, 64)
                        .safeAreaPadding(.bottom, 94)

                        Spacer()
                            .frame(height: 150)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scrollContentBackground(.hidden)
                    .contentMargins(.top, 64, for: .scrollIndicators)
                    .contentMargins(.bottom, 94, for: .scrollIndicators)
                }
            } else {
                ExcerptView(tab: SidebarInspectorTab.lyrics)
            }
        }
        .onChange(of: entries, initial: true) { _, _ in
            Task {
                await loadLyrics()
            }
        }
    }

    private var alignment: HorizontalAlignment {
        if let type = lyrics.type {
            switch type {
            case .raw:
                .leading
            case .lrc:
                .center
            case .ttml:
                .leading
            }
        } else {
            .leading
        }
    }

    private var entries: MetadataBatchEditingEntries<RawLyrics?> {
        metadataEditor[extracting: \.lyrics]
    }

    private var highlightedRange: Range<Int> {
        if let elapsedTime = player.playbackTime?.elapsed {
            lyrics.highlight(at: elapsedTime, in: player.track?.url)
        } else {
            0 ..< 0
        }
    }

    @ViewBuilder private func lyricLine(line: any LyricLine, index: Int) -> some View {
        switch line {
        case let line as RawLyricLine:
            rawLyricLine(line: line, index: index)
        case let line as LRCLyricLine:
            lrcLyricLine(line: line, index: index)
        case let line as TTMLLyricLine:
            ttmlLyricLine(line: line, index: index)
        default:
            EmptyView()
        }
    }

    @ViewBuilder private func rawLyricLine(line: RawLyricLine, index _: Int) -> some View {
        Text(line.content)
    }

    @ViewBuilder private func lrcLyricLine(line: LRCLyricLine, index: Int) -> some View {
        let isHighlighted = highlightedRange.contains(index)

        HStack {
            Text(line.content)

            if let translation = line.translation {
                Text(translation)
            }
        }
        .foregroundStyle(.tint)
        .tint(isHighlighted ? .accent : .secondary)
        .scaleEffect(isHighlighted ? 1.1 : 1)
        .animation(.bouncy, value: isHighlighted)
        .padding(.vertical, 4)
    }

    @ViewBuilder private func ttmlLyricLine(line: TTMLLyricLine, index: Int)
        -> some View {
        let isHighlighted = highlightedRange.contains(index)

        TTMLInspectorLyricLineView(isHighlighted: isHighlighted, line: line)
    }

    private func loadLyrics() async {
        let binding = entries.projectedValue
        await lyrics.read(binding?.wrappedValue)
    }
}
