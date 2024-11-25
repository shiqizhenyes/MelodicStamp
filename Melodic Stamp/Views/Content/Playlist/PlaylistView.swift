//
//  PlaylistView.swift
//  MelodicStamp
//
//  Created by Xinshao_Air on 2024/11/22.
//

import AppKit
import SwiftUI
import Luminare
import SFSafeSymbols

struct PlaylistView: View {
    @Bindable var player: PlayerModel
    @Bindable var metadataEditor: MetadataEditorModel
    
    @State private var lastSelection: PlaylistItem?
    
    @State private var isFileOpenerPresented: Bool = false
    @State private var isFileAdderPresented: Bool = false
    
    var body: some View {
        Group {
            if !player.isPlaylistEmpty {
                AutoScrollView(.vertical) {
                    LazyVStack(spacing: 12) {
                        LuminareList(
                            items: $player.playlist,
                            selection: $metadataEditor.items,
                            id: \.id
                        ) { item in
                            PlaylistItemView(
                                player: player,
                                item: item.wrappedValue,
                                isSelected: metadataEditor.items.contains(item.wrappedValue)
                            )
                            .swipeActions {
                                Button {
                                    player.play(item: item.wrappedValue)
                                } label: {
                                    Image(systemSymbol: .play)
                                    Text("Play")
                                }
                                .tint(.accentColor)
                                
                                Button {
                                    player.removeFromPlaylist(urls: [item.wrappedValue.url])
                                } label: {
                                    Image(systemSymbol: .trash)
                                    Text("Delete")
                                }
                                .tint(.red)
                            }
                        } actions: {
                            Button {
                                let hasShift = NSEvent.modifierFlags.contains(.shift)
                                player.playbackMode = player.playbackMode.cycle(negate: hasShift)
                            } label: {
                                HStack {
                                    player.playbackMode.image
                                    
                                    switch player.playbackMode {
                                    case .single:
                                        Text("Single Loop")
                                    case .sequential:
                                        Text("Sequential")
                                    case .loop:
                                        Text("Sequential Loop")
                                    case .shuffle:
                                        Text("Shuffle")
                                    }
                                }
                            }
                        } removeView: {
                            Image(systemSymbol: .trashFill)
                        }
                    }
                    .padding(8)
                }
                .contentMargins(.top, 48)
                .contentMargins(.bottom, 72)
                .onChange(of: metadataEditor.items) { oldValue, newValue in
                    // TODO: update this
                    lastSelection = newValue.first
                }
            } else {
                EmptyMusicNoteView(systemSymbol: SidebarTab.playlist.systemSymbol)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar(content: toolbar)
    }
    
    @ViewBuilder private func toolbar() -> some View {
        Group {
            Button {
                isFileOpenerPresented = true
            } label: {
                HStack(alignment: .lastTextBaseline) {
                    Image(systemSymbol: .playFill)
                        .imageScale(.small)
                    
                    Text("Open File")
                }
                .padding(.horizontal, 2)
            }
            .fileImporter(isPresented: $isFileOpenerPresented, allowedContentTypes: allowedContentTypes) { result in
                switch result {
                case .success(let url):
                    player.play(url: url)
                case .failure:
                    break
                }
            }
            
            Button {
                isFileAdderPresented = true
            } label: {
                HStack(alignment: .lastTextBaseline) {
                    Image(systemSymbol: .textLineLastAndArrowtriangleForward)
                        .imageScale(.small)
                    
                    Text("Add to Playlist")
                }
                .padding(.horizontal, 2)
            }
            .fileImporter(isPresented: $isFileAdderPresented, allowedContentTypes: allowedContentTypes, allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls):
                    player.addToPlaylist(urls: urls)
                case .failure:
                    break
                }
            }
        }
        .background(.thinMaterial)
        .clipShape(.buttonBorder)
    }
}
