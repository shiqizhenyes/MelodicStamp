//
//  DisplayLyricsView.swift
//  MelodicStamp
//
//  Created by Xinshao_Air on 2024/12/24.
//

import Luminare
import SwiftUI

struct DisplayLyricsView: View {
    @Environment(PlayerModel.self) private var player
    @Environment(LyricsModel.self) private var lyrics

    @Environment(\.luminareAnimation) private var animation

    @Binding var scrollability: BouncyScrollViewScrollability

    @State private var isHovering: Bool = false
    @State private var elapsedTime: TimeInterval = .zero

    @State private var scrollabilityDispatch: DispatchWorkItem?

    var body: some View {
        // Avoid multiple instantializations
        let lines = lyrics.lines
        let highlightedRange = highlightedRange

        Group {
            if !lines.isEmpty {
                BouncyScrollView(
                    scrollability: scrollability,
                    bounceDelay: 0.085,
                    range: 0 ..< lines.count,
                    highlightedRange: highlightedRange,
                    alignment: .center
                ) { index, isHighlighted in
                    lyricLine(
                        line: lines[index], index: index, isHighlighted: isHighlighted,
                        highlightedRange: highlightedRange
                    )
                } indicator: { index, _ in
                    let span = lyrics.storage?.parser.duration(before: index)
                    let beginTime = span?.begin
                    let endTime = span?.end

                    if let beginTime, let endTime {
                        let duration = endTime - beginTime
                        let progress = (elapsedTime - beginTime) / duration

                        return if duration >= 4, progress <= 1 {
                            .visible {
                                ProgressDotsContainerView(elapsedTime: elapsedTime, beginTime: beginTime, endTime: endTime)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.bottom, 32)
                            }
                        } else { .invisible }
                    } else { return .invisible }
                } onScrolling: { position, _ in
                    guard position.isPositionedByUser else { return }
                    guard !scrollability.isControlledByUser else { return }

                    scrollability = .waitsForScroll
                    scrollabilityDispatch?.cancel()

                    let dspatch = DispatchWorkItem {
                        scrollability = .definedByApplication
                    }
                    scrollabilityDispatch = dspatch
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: dspatch)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Color.clear
            }
        }
        .onHover { hover in
            withAnimation(.smooth(duration: 0.45)) {
                isHovering = hover
            }
        }
        .onReceive(player.playbackTimePublisher) { playbackTime in
            guard let elapsed = playbackTime?.elapsed else { return }
            elapsedTime = elapsed
        }
    }

    private var highlightedRange: Range<Int> {
        lyrics.highlight(at: elapsedTime)
    }

    @ViewBuilder private func lyricLine(
        line: any LyricLine, index: Int, isHighlighted: Bool,
        highlightedRange: Range<Int>
    ) -> some View {
        // Avoid multiple instantializations
        let isActive = isHighlighted || isHovering
        let blurRadius = blurRadius(for: index, in: highlightedRange)
        let opacity = opacity(for: index, in: highlightedRange)

        VStack(spacing: .zero) {
            switch line {
            case let line as RawLyricLine:
                rawLyricLine(line: line, index: index, isHighlighted: isHighlighted)
            case let line as LRCLyricLine:
                lrcLyricLine(line: line, index: index, isHighlighted: isHighlighted)
            case let line as TTMLLyricLine:
                ttmlLyricLine(line: line, index: index, isHighlighted: isHighlighted)
            default:
                EmptyView()
            }
        }
        .padding(.bottom, 32)
        .blur(radius: isActive ? 0 : blurRadius)
        .opacity(isActive ? 1 : opacity)
    }

    @ViewBuilder private func rawLyricLine(line: RawLyricLine, index _: Int, isHighlighted _: Bool) -> some View {
        Text(line.content)
            .font(.title)
            .bold()
            .foregroundStyle(.white)
    }

    @ViewBuilder private func lrcLyricLine(line: LRCLyricLine, index _: Int, isHighlighted: Bool) -> some View {
        Group {
            switch line.type {
            case .main:
                Text(line.content)
            // .foregroundStyle(.white)
            case let .translation(locale):
                Text(locale)
                // .foregroundStyle(.placeholder)

                Text(line.content)
                // .foregroundStyle(.white.secondary)
            }
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(isHighlighted ? Color.white : Color.white.opacity(0.5))
        .font(.title)
        .bold()
    }

    @ViewBuilder private func ttmlLyricLine(line: TTMLLyricLine, index _: Int, isHighlighted: Bool) -> some View {
        TTMLDisplayLyricLineView(
            line: line, elapsedTime: elapsedTime,
            isHighlighted: isHighlighted
        )
    }

    private func opacity(for index: Int, in highlightedRange: Range<Int>) -> CGFloat {
        let distance = abs(index - (highlightedRange.lowerBound))
        let maxOpacity = 0.55
        let minOpacity = 0.125
        let factor = maxOpacity - (CGFloat(distance) * 0.05)
        return max(minOpacity, min(factor, maxOpacity))
    }

    private func blurRadius(for index: Int, in highlightedRange: Range<Int>) -> CGFloat {
        let distance = abs(index - (highlightedRange.lowerBound))
        let maxBlur = 5.0
        let minBlur = 0.0
        let factor = CGFloat(distance) * 1.0
        return max(minBlur, min(factor, maxBlur))
    }
}
