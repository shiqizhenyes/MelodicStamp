//
//  PlaylistItemView.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/23.
//

import CSFBAudioEngine
import SwiftUI

struct PlaylistItemView: View {
    @Bindable var player: PlayerModel

    var item: PlaylistItem
    var isSelected: Bool

    @State private var isHovering: Bool = false

    var body: some View {
        HStack(alignment: .center) {
            let isMetadataLoaded = item.metadata.state.isLoaded
            let isMetadataModified = item.metadata.isModified

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    if isMetadataLoaded {
                        if isPlaying {
                            MarqueeScrollView(animate: false) {
                                MusicTitle(item: item)
                            }
                        } else {
                            MusicTitle(item: item)
                        }
                    } else {
                        Text("Loading…")
                            .foregroundStyle(.placeholder)
                    }
                }
                .font(.title3)
                .frame(height: 24)
                .opacity(!player.hasCurrentTrack || isPlaying ? 1 : 0.5)

                HStack(alignment: .center, spacing: 4) {
                    if isMetadataModified {
                        Circle()
                            .foregroundStyle(.tint)
                            .padding(2)
                    }

                    Text(item.url.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(.placeholder)
                }
                .frame(height: 12)
            }
            .transition(.blurReplace)
            .animation(.default.speed(2), value: isMetadataLoaded)
            .animation(.default.speed(2), value: isMetadataModified)
            .animation(.default.speed(2), value: isPlaying)

            Spacer()

            AliveButton {
                player.play(item: item)
            } label: {
                ZStack {
                    if isMetadataLoaded {
                        let attachedPictures = item.metadata[extracting: \.attachedPictures]
                        if let cover = getCover(from: attachedPictures.current), let image = cover.image {
                            Group {
                                MusicCover(cornerRadius: 0, images: [image], hasPlaceholder: false, maxResolution: 32)
                                    .overlay {
                                        if isHovering {
                                            Rectangle()
                                                .foregroundStyle(.black)
                                                .opacity(0.25)
                                                .blendMode(.darken)
                                        }
                                    }
                            }
                            .clipShape(.rect(cornerRadius: 8))
                            
                            if isHovering {
                                Image(systemSymbol: isMetadataLoaded ? .playFill : .playSlashFill)
                                    .foregroundStyle(.white)
                            }
                        } else {
                            if isHovering {
                                Image(systemSymbol: isMetadataLoaded ? .playFill : .playSlashFill)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
                .frame(width: 50, height: 50)
                .font(.title3)
                .contentTransition(.symbolEffect(.replace))
            }
        }
        .padding(.vertical, 10)
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .onHover { hover in
            withAnimation(.default.speed(5)) {
                isHovering = hover
            }
        }
    }

    private var isPlaying: Bool {
        player.current == item
    }

    private func getCover(from attachedPictures: Set<AttachedPicture>) -> AttachedPicture? {
        guard !attachedPictures.isEmpty else { return nil }
        let frontCover = attachedPictures.first { $0.type == .frontCover }
        let backCover = attachedPictures.first { $0.type == .backCover }
        let illustration = attachedPictures.first { $0.type == .illustration }
        let fileIcon = attachedPictures.first { $0.type == .fileIcon }
        return frontCover ?? backCover ?? illustration ?? fileIcon ?? attachedPictures.first
    }
}
