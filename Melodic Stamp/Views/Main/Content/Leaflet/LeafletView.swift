//
//  LeafletView.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/12/13.
//

import Defaults
import DominantColors
import SwiftUI

struct LeafletView: View {
    // MARK: - Environments

    @Environment(FloatingWindowsModel.self) private var floatingWindows
    @Environment(PlayerKeyboardControlModel.self) private var playerKeyboardControl
    @Environment(PlayerModel.self) private var player
    @Environment(MetadataEditorModel.self) private var metadataEditor
    @Environment(LyricsModel.self) private var lyrics
    @Environment(AudioVisualizerModel.self) private var audioVisualizer
    @Environment(GradientVisualizerModel.self) private var gradientVisualizer

    @Environment(\.appearsActive) private var appearsActive

    @FocusState private var isFocused: Bool

    @Default(.lyricsTypeSizes) private var typeSizes
    @Default(.lyricsMaxWidth) private var maxWidth

    // MARK: - Fields

    @State private var innerSize: CGSize = .zero
    @State private var isShowingLyrics: Bool = true
    @State private var isControlsHovering: Bool = false

    @SceneStorage(AppSceneStorage.lyricsTypeSize()) private var typeSize: DynamicTypeSize = Defaults[.lyricsTypeSize]

    @State private var interaction: AppleMusicLyricsViewInteractionModel = .init()

    // MARK: - Body

    var body: some View {
        @Bindable var floatingWindows = floatingWindows

        if !player.hasCurrentTrack {
            ExcerptView(tab: SidebarContentTab.leaflet)
        } else {
            ZStack {
                if hasCover || hasLyrics {
                    HStack(spacing: 0) {
                        if hasCover {
                            Spacer(minLength: 0)
                        }

                        HStack(spacing: 50) {
                            // MARK: Cover

                            if hasCover, let cover {
                                coverView(cover)
                            }

                            // MARK: Lyrics

                            if hasLyrics, isShowingLyrics {
                                lyricsView()
                                    .transition(.blurReplace(.downUp))
                                    .dynamicTypeSize(typeSize)
                                    .frame(maxWidth: max(Double(maxWidth), innerSize.width / 2))
                            }
                        }

                        if !hasLyrics || !isShowingLyrics {
                            Spacer(minLength: 0)
                        }
                    }
                    .containerRelativeFrame(.horizontal, alignment: .center) { length, axis in
                        switch axis {
                        case .horizontal:
                            let padding = length * 0.1
                            return length - 2 * max(100, padding)
                        case .vertical:
                            return length
                        }
                    }
                    .onGeometryChange(for: CGSize.self) { proxy in
                        proxy.size
                    } action: { newValue in
                        innerSize = newValue
                    }
                    .overlay(alignment: .leading) {
                        Group {
                            if hasLyrics, isShowingLyrics {
                                LeafletLyricsControlsView(
                                    isHidden: $floatingWindows.isHidden,
                                    typeSize: $typeSize
                                )
                                .transition(.blurReplace(.downUp))
                                .environment(\.availableTypeSizes, typeSizes)
                                .onChange(of: typeSizes) { _, _ in
                                    typeSize = typeSize.dynamicallyClamped
                                }
                            }
                        }
                        .padding(12)
                        .alignmentGuide(.leading) { d in
                            d[.trailing]
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .containerBackground(for: .window) {
                if hasCover {
                    ChromaBackgroundView()
                        .environment(player)
                        .environment(audioVisualizer)
                        .environment(gradientVisualizer)
                        .overlay {
                            Color.black
                                .opacity(0.225)
                                .blendMode(.multiply)
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
                }
            }
            .animation(.bouncy, value: hasLyrics)
            .animation(.bouncy, value: isShowingLyrics)
            .focusable()
            .focusEffectDisabled()
            .focused($isFocused)
            .onChange(of: appearsActive, initial: true) { _, newValue in
                isFocused = newValue
            }

            // MARK: Lyrics

            // Don't extract this logic or modify the tasks!
            .onAppear {
                guard let track = player.track else { return }

                Task {
                    let raw = await track.metadata.poll(for: \.lyrics).current
                    await lyrics.read(raw)
                }
            }
            .onChange(of: player.track) { _, newValue in
                lyrics.clear(newValue?.url)
                guard let newValue else { return }

                Task {
                    let raw = await newValue.metadata.poll(for: \.lyrics).current
                    await lyrics.read(raw)
                }
            }

            // MARK: Color Scheme

            .colorScheme(.dark)

            // MARK: Keyboard Handlers

            // Handle [space / ⏎] -> toggle play / pause
            .onKeyPress(keys: [.space, .return], phases: .all) { key in
                playerKeyboardControl.handlePlayPause(
                    in: player, phase: key.phase, modifiers: key.modifiers
                )
            }

            // Handle [← / →] -> adjust progress
            .onKeyPress(keys: [.leftArrow, .rightArrow], phases: .all) { key in
                let sign: FloatingPointSign = key.key == .leftArrow ? .minus : .plus

                return playerKeyboardControl.handleProgressAdjustment(
                    in: player, phase: key.phase, modifiers: key.modifiers,
                    sign: sign
                )
            }

            // Handle [↑ / ↓] -> adjust volume
            .onKeyPress(keys: [.leftArrow, .rightArrow], phases: .all) { key in
                let sign: FloatingPointSign = key.key == .leftArrow ? .minus : .plus

                return playerKeyboardControl.handleVolumeAdjustment(
                    in: player, phase: key.phase, modifiers: key.modifiers,
                    sign: sign
                )
            }

            // Handle [m] -> toggle muted
            .onKeyPress(keys: ["m"], phases: .down) { _ in
                player.isMuted.toggle()
                return .handled
            }
        }
    }

    private var cover: NSImage? {
        if
            let attachedPictures = player.track?.metadata[extracting: \.attachedPictures]?.current,
            let cover = ThumbnailMaker.getCover(from: attachedPictures)?.image {
            cover
        } else { nil }
    }

    private var hasCover: Bool { cover != nil }

    private var hasLyrics: Bool {
        !lyrics.lines.isEmpty
    }

    // MARK: - Cover View

    @ViewBuilder private func coverView(_ cover: NSImage) -> some View {
        AliveButton(scaleFactor: hasLyrics ? 0.85 : 1) {
            if hasLyrics {
                isShowingLyrics.toggle()
            } else {
                player.isPlaying.toggle()
            }
        } label: {
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
        .scaleEffect(player.isPlaying ? 1 : 0.85, anchor: .center)
        .shadow(radius: player.isPlaying ? 20 : 10)
        .animation(.spring(duration: 0.65, bounce: 0.45, blendDuration: 0.75).delay(0.25), value: player.isPlaying)
    }

    // MARK: - Lyrics View

    @ViewBuilder private func lyricsView() -> some View {
        DisplayLyricsView(interactionState: $interaction.state) { position, _ in
            guard position.isPositionedByUser else { return }
            interaction.reset()
        }
        .overlay(alignment: .trailing) {
            Group {
                if !interaction.state.isDelegated {
                    AppleMusicLyricsViewInteractionStateButton(
                        interactionState: $interaction.state,
                        progress: interaction.delegationProgress,
                        hasProgressRing: interaction.hasProgressRing && interaction.delegationProgress > 0
                    )
                    .tint(.white)
                    .transition(.blurReplace(.downUp))
                }
            }
            .animation(.bouncy, value: interaction.state.isDelegated)
            .padding(12)
            .alignmentGuide(.trailing) { d in
                d[.leading]
            }
        }
    }
}

#Preview(traits: .modifier(SampleEnvironmentsPreviewModifier())) {
    @Previewable @State var lyrics: LyricsModel = .init()

    LeafletView()
        .environment(lyrics)
}
