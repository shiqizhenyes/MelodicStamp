//
//  LeafletView.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/12/13.
//

import DominantColors
import SwiftUI

struct LeafletView: View {
    @Environment(PlayerModel.self) private var player
    @Environment(MetadataEditorModel.self) private var metadataEditor
    @Environment(LyricsModel.self) private var lyrics

    @State private var dominantColors: [Color] = [.init(hex: 0x929292), .init(hex: 0xFFFFFF), .init(hex: 0x929292)]
    @State private var interactionState: AppleMusicLyricsViewInteractionState = .following

    @State private var isPlaying: Bool = false
    @State private var isShowingLyrics: Bool = true

    @State private var interactionStateDelegationProgress: CGFloat = .zero
    @State private var interactionStateDispatch: DispatchWorkItem?
    @State private var hasInteractionStateProgressRing: Bool = true

    var body: some View {
        if !player.hasCurrentTrack {
            ExcerptView(tab: SidebarContentTab.leaflet)
        } else {
            ZStack {
                if hasCover || hasLyrics {
                    HStack(spacing: 50) {
                        @Bindable var player = player

                        if let cover {
                            AliveButton(isOn: hasLyrics ? $isShowingLyrics : $player.isPlaying) {
                                MusicCover(
                                    images: [cover], hasPlaceholder: true,
                                    cornerRadius: 12
                                )
                            }
                            .containerRelativeFrame(.vertical, alignment: .center) { length, axis in
                                switch axis {
                                case .horizontal:
                                    length
                                case .vertical:
                                    min(500, length * 0.5)
                                }
                            }
                            .scaleEffect(isPlaying ? 1 : 0.85, anchor: .center)
                            .shadow(radius: isPlaying ? 20 : 10)
                            .animation(.spring(duration: 0.65, bounce: 0.45, blendDuration: 0.75), value: isPlaying)
                            .onChange(of: player.currentIndex, initial: true) { _, _ in
                                Task { @MainActor in
                                    dominantColors = try await extractDominantColors(from: cover)
                                }
                            }
                        }

                        if hasLyrics, isShowingLyrics {
                            DisplayLyricsView(interactionState: $interactionState) { position, _ in
                                guard position.isPositionedByUser else { return }
                                guard !interactionState.isIsolated else { return }
                                interactionStateDispatch?.cancel()
                                interactionState = .intermediate

                                let dspatch = DispatchWorkItem {
                                    interactionState = .countingDown
                                }
                                interactionStateDispatch = dspatch
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: dspatch)
                            }
                            .overlay(alignment: .trailing) {
                                Group {
                                    if !interactionState.isDelegated {
                                        AppleMusicLyricsViewInteractionStateButton(
                                            interactionState: $interactionState,
                                            progress: interactionStateDelegationProgress,
                                            hasProgressRing: hasInteractionStateProgressRing && interactionStateDelegationProgress > 0
                                        )
                                        .tint(.white)
                                        .transition(.blurReplace(.downUp))
                                    }
                                }
                                .animation(.bouncy, value: interactionState.isDelegated)
                                .padding(12)
                                .alignmentGuide(.trailing) { d in
                                    d[.leading]
                                }
                            }
                            .transition(.blurReplace(.downUp))
                            .onChange(of: interactionState) { _, _ in
                                switch interactionState {
                                case .following:
                                    interactionStateDispatch?.cancel()
                                    hasInteractionStateProgressRing = false
                                case .countingDown:
                                    interactionStateDispatch?.cancel()
                                    hasInteractionStateProgressRing = true

                                    interactionStateDelegationProgress = .zero
                                    withAnimation(.smooth(duration: 3)) {
                                        interactionStateDelegationProgress = 1
                                    }

                                    let dispatch = DispatchWorkItem {
                                        interactionState = .following
                                    }
                                    interactionStateDispatch = dispatch
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: dispatch)
                                case .isolated:
                                    interactionStateDispatch?.cancel()
                                    hasInteractionStateProgressRing = false

                                    withAnimation(.smooth) {
                                        interactionStateDelegationProgress = 1
                                    }
                                default:
                                    break
                                }
                            }
                        }
                    }
                    .containerRelativeFrame(.horizontal, alignment: .center) { length, axis in
                        switch axis {
                        case .horizontal:
                            let padding = length * 0.1
                            return length - 2 * min(100, padding)
                        case .vertical:
                            return length
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .animation(.bouncy, value: hasLyrics)
            .animation(.bouncy, value: isShowingLyrics)
            .background {
                if hasCover {
                    ZStack {
                        AnimatedGrid(colors: dominantColors)

                        Color.black
                            .opacity(0.35)
                    }
                } else {
                    ZStack {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .opacity(0.5)

                        LinearGradient(
                            colors: [.clear, .accent],
                            startPoint: .top, endPoint: .bottom
                        )
                        .opacity(0.65)
                        .brightness(-0.075)
                        .blendMode(.multiply)
                    }
                    .onAppear {
                        dominantColors = []
                    }
                }
            }

            // Read lyrics
            // Don't extract this logic or modify the tasks!
            .onAppear {
                guard let current = player.current else { return }

                Task {
                    let raw = await current.metadata.poll(for: \.lyrics).current
                    await lyrics.read(raw)
                }
            }
            .onChange(of: player.current) { _, newValue in
                guard let newValue else { return }
                lyrics.clear(newValue.url)

                Task {
                    let raw = await newValue.metadata.poll(for: \.lyrics).current
                    await lyrics.read(raw)
                }
            }

            .onReceive(player.isPlayingPublisher) { isPlaying in
                self.isPlaying = isPlaying
            }
            .colorScheme(.dark)
        }
    }

    private var cover: NSImage? {
        if
            let attachedPictures = player.current?.metadata[extracting: \.attachedPictures]?.current,
            let cover = ThumbnailMaker.getCover(from: attachedPictures)?.image {
            cover
        } else { nil }
    }

    private var hasCover: Bool { cover != nil }

    private var hasLyrics: Bool {
        !lyrics.lines.isEmpty
    }

    private func extractDominantColors(from image: NSImage) async throws -> [Color] {
        let colors = try DominantColors.dominantColors(
            nsImage: image, quality: .fair,
            algorithm: .CIEDE2000, maxCount: 3, options: [.excludeWhite], sorting: .lightness
        )
        return colors.map(Color.init)
    }
}

#Preview(traits: .modifier(SampleEnvironmentsPreviewModifier())) {
    @Previewable @State var lyrics: LyricsModel = .init()

    LeafletView()
        .environment(lyrics)
}
