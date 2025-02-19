//
//  DisplayLyricLineView.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/3.
//

import Defaults
import SwiftUI

struct DisplayLyricLineView: View {
    @Environment(PlayerModel.self) private var player

    @Default(.isLyricsFadingEffectEnabled) private var isLyricsFadingEffectEnabled

    var line: any LyricLine
    var index: Int
    var highlightedRange: Range<Int>
    var elapsedTime: TimeInterval
    var shouldFade: Bool = false
    var shouldAnimate: Bool = true

    @State private var isHovering: Bool = false

    var body: some View {
        // Avoids multiple instantializations
        let isActive = isActive
        let hasFadingEffect = isLyricsFadingEffectEnabled && shouldFade && !isActive

        let blurRadius = blurRadius(for: index, in: highlightedRange)
        let opacity = opacity(for: index, in: highlightedRange)

        Button {
            guard let beginTime = line.beginTime else { return }
            player.time = beginTime + 0.01 // To make sure it's highlighting the current line
        } label: {
            // Preserves the view hierarchy
            VStack {
                switch line {
                case let line as RawLyricLine:
                    RawDisplayLyricLineView(line: line)
                case let line as LRCLyricLine:
                    LRCDisplayLyricLineView(
                        line: line, isHighlighted: isHighlighted
                    )
                case let line as TTMLLyricLine:
                    TTMLDisplayLyricLineView(
                        line: line, elapsedTime: elapsedTime,
                        isHighlighted: isHighlighted,
                        shouldAnimate: shouldAnimate
                    )
                default:
                    EmptyView()
                }
            }
            .padding(8.5)
            .blur(radius: hasFadingEffect ? blurRadius : 0)
            .opacity(hasFadingEffect ? opacity : 1)
            .hoverableBackground()
            .clipShape(.rect(cornerRadius: 12))
            .animation(.smooth(duration: 0.8), value: hasFadingEffect)
            .onHover { hover in
                isHovering = hover
            }
        }
        .buttonStyle(.alive(enabledStyle: .white))
    }

    private var isHighlighted: Bool {
        highlightedRange.contains(index)
    }

    private var isActive: Bool {
        isHighlighted || isHovering || !shouldAnimate
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
        let maxBlur = 6.0
        let minBlur = 1.0
        let factor = CGFloat(distance) * 1.0
        return max(minBlur, min(factor, maxBlur))
    }
}
